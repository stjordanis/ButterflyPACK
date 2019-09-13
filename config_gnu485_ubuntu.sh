 export TRAVIS_BUILD_DIR=$PWD
 export BLUE="\033[34;1m"
 mkdir -p installDir

 printf  "${BLUE} GC; Installing gcc-4.8 via apt\n"
 sudo apt-get update
 sudo apt-get install build-essential software-properties-common -y
 sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
 sudo apt-get update
 sudo apt-get install gcc-4.8 g++-4.8 -y
 sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.8
 export CXX="g++-4.8"
 export CC="gcc-4.8"
 printf "${BLUE} GC; Done installing gcc-4.8 via apt\n"

 printf "${BLUE} GC; Installing gfortran via apt\n"
 sudo apt-get install gfortran-4.8 -y
 sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-4.8 60
 printf "${BLUE} GC; Done installing gfortran via apt\n"

 printf "${BLUE} GC; Installing openmpi\n"
 sudo apt-get remove openmpi-bin libopenmpi-dev -y
 sudo apt-get install openmpi-bin libopenmpi-dev
 printf "${BLUE} GC; Done installing openmpi\n"

 printf "${BLUE} GC; Installing dos2unixfrom apt\n"
 sudo apt-get install dos2unix
 printf "${BLUE} GC; Done installing dos2unixfrom apt\n"

 printf "${BLUE} GC; Installing BLASfrom apt\n"
 sudo apt-get remove libblas-dev -y
 sudo apt-get install libblas-dev
 export BLAS_LIB=/usr/lib/x86_64-linux-gnu/libblas.so
 printf "${BLUE} GC; Done installing BLASfrom apt\n"

 printf "${BLUE} GC; Installing LAPACKfrom apt\n"
 sudo apt-get remove liblapack-dev -y
 sudo apt-get install liblapack-dev
 export LAPACK_LIB=/usr/lib/x86_64-linux-gnu/liblapack.so
 printf "${BLUE} GC; Done installing LAPACKfrom apt\n"

 printf "${BLUE} GC; Installing ScaLAPACK from source\n"
 cd $TRAVIS_BUILD_DIR/installDir
 wget http://www.netlib.org/scalapack/scalapack-2.0.2.tgz
 tar -xf scalapack-2.0.2.tgz
 cd scalapack-2.0.2
 cp SLmake.inc.example SLmake.inc
 sed -i "s/BLASLIB/#BLASLIB/" SLmake.inc
 sed -i "s/LAPACKLIB/#LAPACKLIB/" SLmake.inc
 sed -i "s/LIBS/#LIBS/" SLmake.inc
 printf "BLASLIB=$BLAS_LIB\n" >> SLmake.inc
 printf "LAPACKLIB=$LAPACK_LIB\n" >> SLmake.inc
 printf "LIBS=$BLAS_LIB $LAPACK_LIB\n" >> SLmake.inc
 sed -i "s/SCA#LAPACKLIB/#SCA#LAPACKLIB/" SLmake.inc
 printf "SCALAPACKLIB=libscalapack.a\n" >> SLmake.inc
 make lib  > tempMakeOutput.txt 2>&1
 export SCALAPACK_LIB=$TRAVIS_BUILD_DIR/installDir/scalapack-2.0.2/libscalapack.a
 printf "${BLUE} GC; Done installing ScaLAPACK from source\n"


 printf "${BLUE} GC; Installing arpack from source\n"
 cd $TRAVIS_BUILD_DIR/installDir
 git clone https://github.com/opencollab/arpack-ng.git
 cd arpack-ng
 rm -rf build
 mkdir -p build
 cd build
    cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=mpicc \
    -DCMAKE_CXX_COMPILER=mpic++ \
    -DCMAKE_Fortran_COMPILER=mpif90 \
    -DCMAKE_INSTALL_PREFIX=. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_Fortran_FLAGS="-fopenmp" \
    -DTPL_BLAS_LIBRARIES="$BLAS_LIB" \
    -DTPL_LAPACK_LIBRARIES="$LAPACK_LIB" \
    -DMPI=ON \
    -DEXAMPLES=ON \
    -DCOVERALLS=ON
 make
 export ARPACK_LIB="$TRAVIS_BUILD_DIR/installDir/arpack-ng/build/lib/libarpack.so;$TRAVIS_BUILD_DIR/installDir/arpack-ng/build/lib/libparpack.so"
 printf "${BLUE} GC; Done installing arpack from source\n"



 export BLUE="\033[34;1m"
 printf "${BLUE} GC; Installing ButterflyPACK from source\n"
 cd $TRAVIS_BUILD_DIR
 rm -rf build
 mkdir -p build
 cd build
 export CRAYPE_LINK_TYPE=dynamic
 rm -rf CMakeCache.txt
 rm -rf DartConfiguration.tcl
 rm -rf CTestTestfile.cmake
 rm -rf cmake_install.cmake
 rm -rf CMakeFiles
    cmake .. \
    -DCMAKE_CXX_FLAGS="-fopenmp" \
    -Denable_blaslib=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_COMPILER=mpicc \
    -DCMAKE_CXX_COMPILER=mpic++ \
    -DCMAKE_Fortran_COMPILER=mpif90 \
    -DCMAKE_INSTALL_PREFIX=. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_Fortran_FLAGS="-fopenmp" \
    -DTPL_BLAS_LIBRARIES="$BLAS_LIB" \
    -DTPL_LAPACK_LIBRARIES="$LAPACK_LIB" \
    -DTPL_SCALAPACK_LIBRARIES="$SCALAPACK_LIB" \
    -DTPL_ARPACK_LIBRARIES="$ARPACK_LIB"
 make
 make install
 printf "${BLUE} GC; Done installing ButterflyPACK from source\n"

