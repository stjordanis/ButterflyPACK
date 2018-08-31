#!/bin/bash
ROOTDIR=$PWD
SRCDIR=$ROOTDIR/SRC
DSRCDIR=$ROOTDIR/SRC_DOUBLE
ZSRCDIR=$ROOTDIR/SRC_DOUBLECOMPLEX

MACRO_FILE=$SRCDIR/HODLR_config.fi
TMP_FILE=$PWD/tmp.txt

dos2unix -q $SRCDIR/* 

############################################################################
echo "-- generating macro definition header ..."
rm -rf $TMP_FILE
rm -rf $MACRO_FILE
grep -h "end subroutine" --include='*.f90' --include='*.c' --include='*.h' $SRCDIR/* |sed 's/[[:blank:]]*$//' | sed 's/.* \([^ ][^ ]*\) */\1/' > $TMP_FILE
grep -h "end function" --include='*.f90' --include='*.c' --include='*.h' $SRCDIR/* |sed 's/[[:blank:]]*$//' | sed 's/.* \([^ ][^ ]*\) */\1/' >> $TMP_FILE
grep -h "end type" --include='*.f90' --include='*.c' --include='*.h' $SRCDIR/* |sed 's/[[:blank:]]*$//' | sed 's/.* \([^ ][^ ]*\) */\1/' >> $TMP_FILE
grep -h "end module" --include='*.f90' --include='*.c' --include='*.h' $SRCDIR/* |sed 's/[[:blank:]]*$//' | sed 's/.* \([^ ][^ ]*\) */\1/' >> $TMP_FILE
> $MACRO_FILE
echo "#ifdef DAT" >> $MACRO_FILE
echo "#if DAT==0" >> $MACRO_FILE
echo " " >> $MACRO_FILE
echo "#define DT complex(kind=8)" >> $MACRO_FILE
echo "#define MPI_DT MPI_DOUBLE_COMPLEX" >> $MACRO_FILE
echo "#define CBIND_DT complex(kind=C_DOUBLE_COMPLEX)" >> $MACRO_FILE
echo "#define C_DT doublecomplex" >> $MACRO_FILE
echo "#define flops_gemm flops_zgemm" >> $MACRO_FILE
echo "#define gemmf77 zgemm" >> $MACRO_FILE
echo " " >> $MACRO_FILE
while IFS= read -r line ; do
    echo "#define $line z_$line" >> $MACRO_FILE
done < "$TMP_FILE"
echo " " >> $MACRO_FILE
echo "#elif DAT==1" >> $MACRO_FILE
echo " " >> $MACRO_FILE
echo "#define DT real(kind=8)" >> $MACRO_FILE
echo "#define MPI_DT MPI_DOUBLE_PRECISION" >> $MACRO_FILE
echo "#define CBIND_DT real(kind=C_DOUBLE)" >> $MACRO_FILE
echo "#define C_DT double" >> $MACRO_FILE
echo "#define flops_gemm flops_dgemm" >> $MACRO_FILE
echo "#define gemmf77 dgemm" >> $MACRO_FILE
echo " " >> $MACRO_FILE
while IFS= read -r line ; do
    echo "#define $line d_$line" >> $MACRO_FILE
done < "$TMP_FILE"
echo "#endif" >> $MACRO_FILE
echo "#endif" >> $MACRO_FILE
rm -rf $TMP_FILE


########################################################### 
# note that module names and *.h headers need to be renamed without macros 
echo "-- copy and modify SRC dir ..."
grep -h "end module" --include='*.f90' --include='*.f' $SRCDIR/* |sed 's/[[:blank:]]*$//' | sed 's/.* \([^ ][^ ]*\) */\1/' > $TMP_FILE
rm -rf $ZSRCDIR
cp -r $SRCDIR $ZSRCDIR
while IFS= read -r line; do
    eval sed -i -e 's/$line/z_$line/g' $ZSRCDIR/*.f90
    eval sed -i -e 's/$line/z_$line/g' $ZSRCDIR/*.f
    eval sed -i -e 's/$line/z_$line/g' $ZSRCDIR/*.h
done < "$TMP_FILE"
sed -i -e 's/\<C_DT\>/doublecomplex/g' $ZSRCDIR/*.h
rm -rf $DSRCDIR
cp -r $SRCDIR $DSRCDIR
while IFS= read -r line; do
	eval sed -i -e 's/$line/d_$line/g' $DSRCDIR/*.f90
	eval sed -i -e 's/$line/d_$line/g' $DSRCDIR/*.f
	eval sed -i -e 's/$line/d_$line/g' $DSRCDIR/*.h
done < "$TMP_FILE"
sed -i -e 's/\<C_DT\>/double/g' $DSRCDIR/*.h


###########################################################
echo "-- copy and modify CMakeLists.txt ..."
cd $ZSRCDIR
for file in *; do
	if [ $file != CMakeLists.txt ] && [ $file != HODLR_config.fi ] ;
	then
		eval sed -i -e 's/$file/z$file/g' $ZSRCDIR/CMakeLists.txt
		mv "$file" "z${file}"
	fi
done
sed -i -e 's/\<hodlrbf\>/zhodlrbf/g' $ZSRCDIR/CMakeLists.txt
sed -i -e 's/-DDAT/-DDAT=0/g' $ZSRCDIR/CMakeLists.txt
cd $DSRCDIR
for file in *; do
	if [ $file != CMakeLists.txt ] && [ $file != HODLR_config.fi ] ;
	then
		mv "$file" "d${file}"
		eval sed -i -e 's/$file/d$file/g' $DSRCDIR/CMakeLists.txt
	fi
done
sed -i -e 's/\<hodlrbf\>/dhodlrbf/g' $DSRCDIR/CMakeLists.txt
sed -i -e 's/-DDAT/-DDAT=1/g' $DSRCDIR/CMakeLists.txt
cd $ROOTDIR
rm -rf $TMP_FILE