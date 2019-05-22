export EXEC=./EXAMPLE/ie2d
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread
THREADS_PER_RANK=`expr 2 \* $OMP_NUM_THREADS`
nmpi=2


for precon in 3  #1: direct 2: no preconditioner 3: LU preconditioner
do


# # ######## cavity
# # Ns=(5000 50000 500000)
# # wavelengths=(0.05 0.005 0.0005)
# Ns=(5000000)
# wavelengths=(0.00005)

# for ((i = 0; i < ${#Ns[@]}; i++)); do
# N=${Ns[i]}
# wavelength=${wavelengths[i]}

# blknum=1
# model=10
# # N=5000
# # wavelength=0.08
# # wavelength=0.01
# tol=1d-4
# errcheck=0
# lrcomp=4
# bACAbatch=16
# LRlevel=100
# xyzsort=0
# leafsize=200
# near=0.01d0

# srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC $blknum $model $N $wavelength $tol $errcheck $lrcomp $bACAbatch $LRlevel $precon $xyzsort $leafsize $near | tee cavity_N_${N}_w_${wavelength}_tol_${tol}_mpi_${nmpi}_nth_${OMP_NUM_THREADS}_LRlevel_${LRlevel}_precon_${precon}_sort_${xyzsort}_near_${near}

# done



# ######## half cyclinder
# Ns=(5000 50000 500000)
# wavelengths=(0.02 0.002 0.0002)
Ns=(40000,400000,4000000)
wavelengths=(0.003,0.003,0.003)


for ((i = 0; i < ${#Ns[@]}; i++)); do
N=${Ns[i]}
wavelength=${wavelengths[i]}

# blknum=1
model=7
# N=5000
# tol=1d-4
errcheck=0
# com_opt=6
bACAbatch=16
LRlevel=0
xyzsort=1
leafsize=200
near=0.01d0

for com_opt in 5
do
for batch in 1 8  
do
for tol in 1e-4
do
for h in 1.0
do
for blknum in 1  4  16 
do
srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC -quant --model2d $model --nunk $N --wavelength $wavelength -option --lr_blk_num $blknum --tol_comp $tol --errfillfull $errcheck --reclr_leaf $com_opt --baca_batch $batch --lrlevel $LRlevel --precon $precon --xyzsort $xyzsort --nmin_leaf $leafsize --near_para $near | tee hcylindar_N_${N}_w_${wavelength}_bnum_${blknum}_comp_${com_opt}_mpi_${nmpi}_bsize_${batch}
done
done
done
done
done
done





# # ######## spiral line
# # Ns=(5000 50000 500000 )
# # wavelengths=(0.06 0.006 0.0006 )
# Ns=(5000000 )
# wavelengths=(0.00006 )

# for ((i = 0; i < ${#Ns[@]}; i++)); do
# N=${Ns[i]}
# wavelength=${wavelengths[i]}

# blknum=1
# model=12
# # N=5000
# # wavelength=0.08
# # wavelength=0.01
# tol=1d-4
# errcheck=0
# lrcomp=4
# bACAbatch=16
# LRlevel=100
# xyzsort=0
# leafsize=200
# near=0.01d0

# srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC $blknum $model $N $wavelength $tol $errcheck $lrcomp $bACAbatch $LRlevel $precon $xyzsort $leafsize $near | tee spiral_N_${N}_w_${wavelength}_tol_${tol}_mpi_${nmpi}_nth_${OMP_NUM_THREADS}_LRlevel_${LRlevel}_precon_${precon}_sort_${xyzsort}_near_${near}

# done



# # ######## rectangular cup
# # Ns=(5000 50000 500000)
# # wavelengths=(0.01 0.001 0.0001)
# Ns=(5000000)
# wavelengths=(0.00001)


# for ((i = 0; i < ${#Ns[@]}; i++)); do
# N=${Ns[i]}
# wavelength=${wavelengths[i]}

# blknum=1
# model=6
# # N=5000
# # wavelength=0.08
# # wavelength=0.01
# tol=1d-4
# errcheck=0
# lrcomp=4
# bACAbatch=16
# LRlevel=100
# xyzsort=0
# leafsize=200
# near=0.01d0

# for near in 0.01d0 2.01d0
# do
# srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC $blknum $model $N $wavelength $tol $errcheck $lrcomp $bACAbatch $LRlevel $precon $xyzsort $leafsize $near | tee rect_N_${N}_w_${wavelength}_tol_${tol}_mpi_${nmpi}_nth_${OMP_NUM_THREADS}_LRlevel_${LRlevel}_precon_${precon}_sort_${xyzsort}_near_${near}
# done
# done



# # ######## parallel strip
# # Ns=(5000 50000 500000)
# # wavelengths=(0.01 0.001 0.0001)
# Ns=(5000000)
# wavelengths=(0.00001)

# for ((i = 0; i < ${#Ns[@]}; i++)); do
# N=${Ns[i]}
# wavelength=${wavelengths[i]}

# blknum=1
# model=3
# # N=5000
# # wavelength=0.08
# # wavelength=0.01
# tol=1d-4
# errcheck=0
# lrcomp=4
# bACAbatch=16
# LRlevel=100
# xyzsort=0
# leafsize=200
# near=0.01d0


# srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC $blknum $model $N $wavelength $tol $errcheck $lrcomp $bACAbatch $LRlevel $precon $xyzsort $leafsize $near | tee parallelstrip_N_${N}_w_${wavelength}_tol_${tol}_mpi_${nmpi}_nth_${OMP_NUM_THREADS}_LRlevel_${LRlevel}_precon_${precon}_sort_${xyzsort}_near_${near}

# done



# # ######## corruaged corner reflector
# # Ns=(5000 50000 500000)
# # wavelengths=(0.012 0.0012 0.00012)
# Ns=(5000000)
# wavelengths=(0.000012)

# for ((i = 0; i < ${#Ns[@]}; i++)); do
# N=${Ns[i]}
# wavelength=${wavelengths[i]}

# blknum=1
# model=9
# # N=5000
# # wavelength=0.08
# # wavelength=0.01
# tol=1d-4
# errcheck=0
# lrcomp=4
# bACAbatch=16
# LRlevel=100
# xyzsort=0
# leafsize=200
# near=0.01d0

# for near in 0.01d0 2.01d0
# do
# srun -n $nmpi -c $THREADS_PER_RANK --cpu_bind=cores $EXEC $blknum $model $N $wavelength $tol $errcheck $lrcomp $bACAbatch $LRlevel $precon $xyzsort $leafsize $near | tee corner_N_${N}_w_${wavelength}_tol_${tol}_mpi_${nmpi}_nth_${OMP_NUM_THREADS}_LRlevel_${LRlevel}_precon_${precon}_sort_${xyzsort}_near_${near}

# done
# done


done

