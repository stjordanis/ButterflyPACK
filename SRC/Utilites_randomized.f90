module Utilites_randomized
use Utilities
use omp_lib 
contains


subroutine copy_randomizedbutterfly(block_i,block_o,memory)
use MODULE_FILE
use misc
implicit none 
type(matrixblock)::block_o
type(butterflyblock_randomized)::block_i

integer i, j, ii, jj, iii, jjj,index_ij,mm,nn,rank,index_i,index_j,levelm,index_i_m,index_j_m
integer level, blocks, edge, patch, node, group,level_c
integer::block_num,block_num_new,num_blocks,level_butterfly	
real*8,optional::memory
if(present(memory))memory=0
! ! block_o%level = block_i%level
! ! block_o%col_group = block_i%col_group
! ! block_o%row_group = block_i%row_group
! ! block_o%nested_num = block_i%nested_num
! ! call assert(block_i%style==2,'this block is not butterfly compressed!')
! ! block_o%style = block_i%style
! ! block_o%data_type = block_i%data_type

block_o%level_butterfly = block_i%level_butterfly


!!!!! be careful here, may need changes later 
block_o%rankmax = block_i%rankmax
block_o%rankmin = block_i%rankmin


level_butterfly = block_i%level_butterfly
num_blocks=2**level_butterfly


allocate(block_o%ButterflyU(num_blocks))
allocate(block_o%ButterflyV(num_blocks))
if (level_butterfly/=0) then
	allocate(block_o%ButterflyKerl(level_butterfly))
end if

do level=0, level_butterfly
	index_ij=0
	if (level>0) then
		block_o%ButterflyKerl(level)%num_row=2**level
		block_o%ButterflyKerl(level)%num_col=2**(level_butterfly-level+1)
		allocate(block_o%ButterflyKerl(level)%blocks(2**level,2**(level_butterfly-level+1)))
	endif
	do index_i=1, 2**level
		do index_j=1, 2**(level_butterfly-level)
			index_ij=index_ij+1
			if (level==0) then
				nn=size(block_i%ButterflyV(index_ij)%matrix,1)
				rank=size(block_i%ButterflyV(index_ij)%matrix,2)
				allocate(block_o%ButterflyV(index_ij)%matrix(nn,rank))
				block_o%ButterflyV(index_ij)%matrix = block_i%ButterflyV(index_ij)%matrix
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyV(index_ij)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyV(index_ij)%matrix,nn,rank)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
			else                    
				nn=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,2)
				rank=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,1)
				allocate(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix(rank,nn))
				block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix = block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,rank,nn)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
				
				nn=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix,2)
				allocate(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix(rank,nn))
				block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix = block_i%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix                    
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix,rank,nn)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
				
			endif
			if (level==level_butterfly) then
				mm=size(block_i%ButterflyU(index_ij)%matrix,1)
				rank=size(block_i%ButterflyU(index_ij)%matrix,2)
				allocate(block_o%ButterflyU(index_ij)%matrix(mm,rank))
				block_o%ButterflyU(index_ij)%matrix = block_i%ButterflyU(index_ij)%matrix					
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyU(index_ij)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyU(index_ij)%matrix,mm,rank)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if				
			endif
		enddo
	enddo
enddo
		
if(allocated(block_i%ButterflyMiddle))then
	levelm = ceiling_safe(dble(level_butterfly)/2d0)
	allocate(block_o%ButterflyMiddle(2**levelm,2**(level_butterfly-levelm)))

	do index_i_m=1, 2**levelm
		do index_j_m=1, 2**(level_butterfly-levelm)	
			rank = size(block_i%ButterflyMiddle(index_i_m,index_j_m)%matrix,1)
			allocate(block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix(rank,rank))
			if(isnan(fnorm(block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix,rank,rank)))then
				write(*,*)'NAN in copy_randomizedbutterfly middle', block_o%row_group,block_o%col_group
			end if			
			block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix = block_i%ButterflyMiddle(index_i_m,index_j_m)%matrix
		end do
	end do
end if

end subroutine copy_randomizedbutterfly




subroutine copy_delete_randomizedbutterfly(block_i,block_o,memory)
use MODULE_FILE
use misc
implicit none 
type(matrixblock)::block_o
type(butterflyblock_randomized)::block_i

integer i, j, ii, jj, iii, jjj,index_ij,mm,nn,rank,index_i,index_j,levelm,index_i_m,index_j_m
integer level, blocks, edge, patch, node, group,level_c
integer::block_num,block_num_new,num_blocks,level_butterfly,num_row,num_col	
real*8,optional::memory
if(present(memory))memory=0

level_butterfly = block_i%level_butterfly
num_blocks=2**level_butterfly


if(allocated(block_i%KerInv))deallocate(block_i%KerInv)



! ! block_o%level = block_i%level
! ! block_o%col_group = block_i%col_group
! ! block_o%row_group = block_i%row_group
! ! block_o%nested_num = block_i%nested_num
! ! call assert(block_i%style==2,'this block is not butterfly compressed!')
! ! block_o%style = block_i%style
! ! block_o%data_type = block_i%data_type

block_o%level_butterfly = block_i%level_butterfly


!!!!! be careful here, may need changes later 
block_o%rankmax = block_i%rankmax
block_o%rankmin = block_i%rankmin





allocate(block_o%ButterflyU(num_blocks))
allocate(block_o%ButterflyV(num_blocks))
if (level_butterfly/=0) then
	allocate(block_o%ButterflyKerl(level_butterfly))
end if

do level=0, level_butterfly
	index_ij=0
	if (level>0) then
		block_o%ButterflyKerl(level)%num_row=2**level
		block_o%ButterflyKerl(level)%num_col=2**(level_butterfly-level+1)
		allocate(block_o%ButterflyKerl(level)%blocks(2**level,2**(level_butterfly-level+1)))
	endif
	do index_i=1, 2**level
		do index_j=1, 2**(level_butterfly-level)
			index_ij=index_ij+1
			if (level==0) then
				nn=size(block_i%ButterflyV(index_ij)%matrix,1)
				rank=size(block_i%ButterflyV(index_ij)%matrix,2)
				allocate(block_o%ButterflyV(index_ij)%matrix(nn,rank))
				block_o%ButterflyV(index_ij)%matrix = block_i%ButterflyV(index_ij)%matrix
				deallocate(block_i%ButterflyV(index_ij)%matrix)
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyV(index_ij)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyV(index_ij)%matrix,nn,rank)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
			else                    
				nn=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,2)
				rank=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,1)
				allocate(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix(rank,nn))
				block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix = block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix
				deallocate(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix)
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,rank,nn)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
				
				nn=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix,2)
				allocate(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix(rank,nn))
				block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix = block_i%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix                    
				deallocate(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix)
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyKerl(level)%blocks(index_i,2*index_j)%matrix,rank,nn)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if
				
			endif
			if (level==level_butterfly) then
				mm=size(block_i%ButterflyU(index_ij)%matrix,1)
				rank=size(block_i%ButterflyU(index_ij)%matrix,2)
				allocate(block_o%ButterflyU(index_ij)%matrix(mm,rank))
				block_o%ButterflyU(index_ij)%matrix = block_i%ButterflyU(index_ij)%matrix					
				deallocate(block_i%ButterflyU(index_ij)%matrix)
				if(present(memory))memory = memory + SIZEOF(block_o%ButterflyU(index_ij)%matrix)/1024.0d3
				if(isnan(fnorm(block_o%ButterflyU(index_ij)%matrix,mm,rank)))then
					write(*,*)'NAN in copy_randomizedbutterfly', block_o%row_group,block_o%col_group
				end if				
			endif
		enddo
	enddo
	if (level>0) then
		deallocate(block_i%ButterflyKerl(level)%blocks)	
	end if
enddo
deallocate(block_i%ButterflyU)
deallocate(block_i%ButterflyV)
if (level_butterfly/=0)deallocate(block_i%ButterflyKerl)

		
if(allocated(block_i%ButterflyMiddle))then
	levelm = ceiling_safe(dble(level_butterfly)/2d0)
	allocate(block_o%ButterflyMiddle(2**levelm,2**(level_butterfly-levelm)))

	do index_i_m=1, 2**levelm
		do index_j_m=1, 2**(level_butterfly-levelm)	
			rank = size(block_i%ButterflyMiddle(index_i_m,index_j_m)%matrix,1)
			allocate(block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix(rank,rank))
			if(isnan(fnorm(block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix,rank,rank)))then
				write(*,*)'NAN in copy_randomizedbutterfly middle', block_o%row_group,block_o%col_group
			end if			
			block_o%ButterflyMiddle(index_i_m,index_j_m)%matrix = block_i%ButterflyMiddle(index_i_m,index_j_m)%matrix
			deallocate(block_i%ButterflyMiddle(index_i_m,index_j_m)%matrix)
		end do
	end do
	deallocate(block_i%ButterflyMiddle)
end if

end subroutine copy_delete_randomizedbutterfly
subroutine get_randomizedbutterfly_minmaxrank(block_i)
use MODULE_FILE
use misc
implicit none 
type(butterflyblock_randomized)::block_i

integer i, j, ii, jj, iii, jjj,index_ij,mm,nn,rank,index_i,index_j,levelm,index_i_m,index_j_m
integer level, blocks, edge, patch, node, group,level_c
integer::block_num,block_num_new,num_blocks,level_butterfly	


block_i%rankmin = 100000
block_i%rankmax = -100000


level_butterfly = block_i%level_butterfly
num_blocks=2**level_butterfly

do level=0, level_butterfly
	index_ij=0
	do index_i=1, 2**level
		do index_j=1, 2**(level_butterfly-level)
			index_ij=index_ij+1
			if (level==0) then
				nn=size(block_i%ButterflyV(index_ij)%matrix,1)
				rank=size(block_i%ButterflyV(index_ij)%matrix,2)
				block_i%rankmin = min(block_i%rankmin,rank)
				block_i%rankmax = max(block_i%rankmax,rank)
			else                    
				nn=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,2)
				rank=size(block_i%ButterflyKerl(level)%blocks(index_i,2*index_j-1)%matrix,1)
				block_i%rankmin = min(block_i%rankmin,rank)
				block_i%rankmax = max(block_i%rankmax,rank)				
			endif
			if (level==level_butterfly) then
				mm=size(block_i%ButterflyU(index_ij)%matrix,1)
				rank=size(block_i%ButterflyU(index_ij)%matrix,2)
				block_i%rankmin = min(block_i%rankmin,rank)
				block_i%rankmax = max(block_i%rankmax,rank)		
			endif
		enddo
	enddo
enddo

end subroutine get_randomizedbutterfly_minmaxrank



subroutine Butterfly_Partial_MVP_Half(chara,level_start,level_end,random,num_vect_sub,nth_s,nth_e,Ng)
    
    use MODULE_FILE
    implicit none
    
    integer n, group_m, group_n, group_mm, group_nn, index_i, index_j, na, nb, index_start
    integer i, j, ii, jj, ij, level, groupm_start, groupn_start, index_iijj, index_ij, k, kk, intemp1, intemp2
    integer header_m, header_n, tailer_m, tailer_n, mm, nn, num_blocks, level_define, col_vector
    integer rank1, rank2, rank, num_groupm, num_groupn, header_nn, header_mm, ma, mb
    integer vector_a, vector_b, nn1, nn2, level_blocks, mm1, mm2, level_end, level_start
    complex(kind=8) ctemp, a, b
    character chara
	integer num_vect_sub,num_vect_subsub,nth_s,nth_e,Ng,nth,dimension_rank,level_butterfly
    
    type(RandomBlock) :: random
    
    type(butterfly_Kerl),allocatable :: ButterflyVector(:)
   
   ! write(*,*)'in '
   
	level_butterfly=butterfly_block_randomized(1)%level_butterfly
	dimension_rank = butterfly_block_randomized(1)%dimension_rank
    num_vect_subsub = num_vect_sub/(nth_e-nth_s+1)
   
    if (chara=='N') then

        num_blocks=2**level_butterfly
        
        do level=level_start, level_end
            if (level==0) then
                num_groupn=num_blocks
                do nth=nth_s, nth_e
					! !$omp parallel do default(shared) private(j,rank,nn,ii,jj,ctemp,kk)
					do j = (nth-1)*Ng+1,nth*Ng
						rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
						nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
						if(.not. allocated(random%RandomVectorRR(1)%blocks(1,j)%matrix))allocate(random%RandomVectorRR(1)%blocks(1,j)%matrix(rank,num_vect_subsub))
						random%RandomVectorRR(1)%blocks(1,j)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
						!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do jj=1, num_vect_subsub						
							do ii=1, rank
								ctemp=(0.,0.)
								do kk=1, nn
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyV(j)%matrix(kk,ii)*random%RandomVectorRR(0)%blocks(1,j)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
								enddo
								random%RandomVectorRR(1)%blocks(1,j)%matrix(ii,jj+(nth-nth_s)*num_vect_subsub)=ctemp
							enddo
						enddo
						!$omp end parallel do
					enddo
					! !$omp end parallel do					
                enddo
            elseif (level==level_butterfly+1) then
                                 
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col
					
				! !$omp parallel do default(shared) private(ij,ii,jj,kk,ctemp,i,j,index_i,index_j,nn1,nn2,mm,nth)
				do ij=1,(num_groupm/2)*(num_groupn/2)
					index_i = (ij-1)/(num_groupn/2)+1
					index_j = mod(ij-1,(num_groupn/2)) + 1
					i = index_i*2-1
					j = index_j*2-1
					
																					  
																						
																					 
					do nth = nth_s,nth_e
																																
						if((j>=(nth-1)*Ng/2**(level-1)+1 .and. j<=nth*Ng/2**(level-1)) .or. &
						& (j+1>=(nth-1)*Ng/2**(level-1)+1 .and. j+1<=nth*Ng/2**(level-1)))then						
							nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,2)
							nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix,2)
							mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,1)
							! write(*,*)ij,i,j,level,'ha',index_i
							if(.not. allocated(random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix))allocate(random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(mm,num_vect_subsub))
							random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
							!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
							do jj=1, num_vect_subsub							
								do ii=1, mm
									ctemp=(0.,0.)
									do kk=1, nn1
										ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
									enddo
									do kk=1, nn2
										ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
									enddo
									random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(ii,jj+(nth-nth_s)*num_vect_subsub)=ctemp
								enddo
							enddo
							!$omp end parallel do
							
							nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix,2)
							nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j+1)%matrix,2)
							mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix,1)
							! write(*,*)ij,i,j,level,'ha',index_i
							if(.not. allocated(random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix))allocate(random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix(mm,num_vect_subsub))
							random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
							!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
							do jj=1, num_vect_subsub							
								do ii=1, mm
									ctemp=(0.,0.)
									do kk=1, nn1
										ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
									enddo
									do kk=1, nn2
										ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j+1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
									enddo
									random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix(ii,jj+(nth-nth_s)*num_vect_subsub)=ctemp
								enddo
							enddo
							!$omp end parallel do							
							
							! write(*,*)ij,i,j,level,'ha done0',index_i
							deallocate(random%RandomVectorRR(level)%blocks(index_i,j)%matrix)
							deallocate(random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix)
							! write(*,*)ij,i,j,level,'ha done',index_i
						end if	
					end do	
				enddo
				! !$omp end parallel do
            endif
        enddo      
        
                    
    elseif (chara=='T') then
    
        num_blocks=2**level_butterfly

        do level=level_start, level_end
            if (level==0) then
                num_groupm=num_blocks
                do nth=nth_s, nth_e
					! !$omp parallel do default(shared) private(i,rank,mm,ii,jj,ctemp,kk)
					do i = (nth-1)*Ng+1,nth*Ng
						rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
						mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
						if(.not. allocated(random%RandomVectorLL(1)%blocks(i,1)%matrix))allocate(random%RandomVectorLL(1)%blocks(i,1)%matrix(rank,num_vect_subsub))
						random%RandomVectorLL(1)%blocks(i,1)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
						!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do jj=1, num_vect_subsub						
							do ii=1, rank
								ctemp=(0.,0.)
								do kk=1, mm
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyU(i)%matrix(kk,ii)*random%RandomVectorLL(0)%blocks(i,1)%matrix(kk,jj+(nth-nth_s)*num_vect_subsub)
								enddo
								random%RandomVectorLL(1)%blocks(i,1)%matrix(ii,jj+(nth-nth_s)*num_vect_subsub)=ctemp
							enddo
						enddo
						!$omp end parallel do
					end do
					! !$omp end parallel do
                enddo
            elseif (level==level_butterfly+1) then               
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_col             

				! !$omp parallel do default(shared) private(ij,ii,jj,kk,ctemp,i,j,index_i,index_j,mm1,mm2,nn,nth)
				do ij=1,(num_groupn/2)*(num_groupm/2)
					index_j = (ij-1)/(num_groupm/2)+1
					index_i = mod(ij-1,(num_groupm/2)) + 1	
					j = 2*index_j-1
					i = 2*index_i-1						
					
																										
																										  
																									   
					do nth = nth_s,nth_e
																																
						if((i>=(nth-1)*Ng/2**(level-1)+1 .and. i<=nth*Ng/2**(level-1)) .or. &
						& (i+1>=(nth-1)*Ng/2**(level-1)+1 .and. i+1<=nth*Ng/2**(level-1)))then
							mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,1)
							mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix,1)
							nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,2)
							if(.not. allocated(random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix))allocate(random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(nn,num_vect_subsub))
							random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
							!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
							do ii=1, num_vect_subsub							
								do jj=1, nn
									ctemp=(0.,0.)
									do kk=1, mm1
										ctemp=ctemp+random%RandomVectorLL(level)%blocks(i,index_j)%matrix(kk,ii+(nth-nth_s)*num_vect_subsub)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix(kk,jj)
									enddo
									do kk=1, mm2
										ctemp=ctemp+random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix(kk,ii+(nth-nth_s)*num_vect_subsub)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix(kk,jj)
									enddo
									random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(jj,ii+(nth-nth_s)*num_vect_subsub)=ctemp
								enddo
							enddo
							!$omp end parallel do
							mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix,1)
							mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j+1)%matrix,1)
							nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix,2)
							if(.not. allocated(random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix))allocate(random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix(nn,num_vect_subsub))
							random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix(:,(nth-nth_s)*num_vect_subsub+1:(nth-nth_s+1)*num_vect_subsub) = 0
							!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
							do ii=1, num_vect_subsub							
								do jj=1, nn
									ctemp=(0.,0.)
									do kk=1, mm1
										ctemp=ctemp+random%RandomVectorLL(level)%blocks(i,index_j)%matrix(kk,ii+(nth-nth_s)*num_vect_subsub)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix(kk,jj)
									enddo
									do kk=1, mm2
										ctemp=ctemp+random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix(kk,ii+(nth-nth_s)*num_vect_subsub)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j+1)%matrix(kk,jj)
									enddo
									random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix(jj,ii+(nth-nth_s)*num_vect_subsub)=ctemp
								enddo
							enddo
							!$omp end parallel do							
							deallocate(random%RandomVectorLL(level)%blocks(i,index_j)%matrix)
							deallocate(random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix)
						end if
					end do
				enddo
				! !$omp end parallel do

            endif
        enddo
    
    endif
       ! write(*,*)'out '
    return
    
end subroutine Butterfly_Partial_MVP_Half

    


subroutine Butterfly_Partial_MVP(chara,level_start,level_end,random)
    
    use MODULE_FILE
    implicit none
    
    integer n, group_m, group_n, group_mm, group_nn, index_i, index_j, na, nb, index_start
    integer i, j, ii, jj, ij, level, groupm_start, groupn_start, index_iijj, index_ij, k, kk, intemp1, intemp2
    integer header_m, header_n, tailer_m, tailer_n, mm, nn, num_blocks, level_define, col_vector
    integer rank1, rank2, rank, num_groupm, num_groupn, header_nn, header_mm, ma, mb, num_vectors
    integer vector_a, vector_b, nn1, nn2, level_blocks, mm1, mm2, level_end, level_start, level_butterfly
    complex(kind=8) ctemp, a, b
    character chara
	integer middleflag,levelm
	complex(kind=8),allocatable::matrixtemp(:,:),matrixtemp1(:,:)
    
    !type(matricesblock), pointer :: blocks
    type(RandomBlock), pointer :: random
    
    type(butterfly_Kerl),allocatable :: ButterflyVector(:)
    
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
    middleflag=0
	if(allocated(butterfly_block_randomized(1)%ButterflyMiddle))middleflag=1
	levelm = ceiling_safe(dble(level_butterfly)/2d0)
	
	if (chara=='N')num_vectors=size(random%RandomVectorRR(0)%blocks(1,1)%matrix,2)
    if (chara=='T')num_vectors=size(random%RandomVectorLL(0)%blocks(1,1)%matrix,2)
	
    if (chara=='N') then

        num_blocks=2**level_butterfly
        
        do level=level_start, level_end
            if (level==0) then
				! write(*,*)'1'
                num_groupn=num_blocks
				!!!!!!  this subourinte is mainly used for testing error, so openmp loop over num_vector is not efficient
				
				!$omp parallel do default(shared) private(j,rank,nn,ii,jj,ctemp,kk)
                do j=1, num_groupn
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    if(.not. allocated(random%RandomVectorRR(1)%blocks(1,j)%matrix))allocate(random%RandomVectorRR(1)%blocks(1,j)%matrix(rank,num_vectors))
					! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do jj=1, num_vectors
						do ii=1, rank
                            ctemp=0
                            do kk=1, nn
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyV(j)%matrix(kk,ii)*random%RandomVectorRR(0)%blocks(1,j)%matrix(kk,jj)
                            enddo
                            random%RandomVectorRR(1)%blocks(1,j)%matrix(ii,jj)=ctemp
							! write(*,*)ctemp
                        enddo
                    enddo
                    ! !$omp end parallel do
                enddo
				!$omp end parallel do
				! write(*,*)'1 done'
			elseif (level==level_butterfly+1) then
                ! write(*,*)'2'
				num_groupm=num_blocks
				!$omp parallel do default(shared) private(i,rank,mm,ii,jj,ctemp,kk)
                do i=1, num_groupm
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    ! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do jj=1, num_vectors
						do ii=1, mm
                            ctemp=0
                            do kk=1, rank
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyU(i)%matrix(ii,kk)*random%RandomVectorRR(level_butterfly+1)%blocks(i,1)%matrix(kk,jj)
                            enddo
                            random%RandomVectorRR(level_butterfly+2)%blocks(i,1)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    ! !$omp end parallel do
					deallocate(random%RandomVectorRR(level_butterfly+1)%blocks(i,1)%matrix)
                enddo 
				!$omp end parallel do	
				! write(*,*)'2 done'				
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col
                if (num_groupn/=1) then
					! write(*,*)'3'
                    !$omp parallel do default(shared) private(ij,ii,jj,kk,ctemp,i,j,index_i,index_j,nn1,nn2,mm)
					do ij=1,(num_groupm/2)*(num_groupn/2)
						i = ((ij-1)/(num_groupn/2)+1)*2-1
						j = (mod(ij-1,(num_groupn/2)) + 1)*2-1
						index_i=int((i+1)/2)
						index_j=int((j+1)/2)
						
						nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,2)
						nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix,2)
						mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,1)
						if(.not. allocated(random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix))allocate(random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(mm,num_vectors))
						! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do jj=1, num_vectors						
							do ii=1, mm
								ctemp=0
								do kk=1, nn1
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j)%matrix(kk,jj)
								enddo
								do kk=1, nn2
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix(kk,jj)
								enddo
								random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(ii,jj)=ctemp
							enddo
						enddo
						! !$omp end parallel do				
						if(level==levelm .and. middleflag==1 .and. level_butterfly>=2)then	
							! ! allocate(matrixtemp(mm,num_vectors))
							! ! call gemm_omp(butterfly_block_randomized(1)%ButterflyMiddle(i,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix,matrixtemp,mm,mm,num_vectors)
							! ! random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix = matrixtemp
							! ! deallocate(matrixtemp)
							
							call gemm_omp(butterfly_block_randomized(1)%ButterflyMiddle(i,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix,mm,mm,num_vectors)
						end if		
						
						nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix,2)
						nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j+1)%matrix,2)
						mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix,1)
						if(.not. allocated(random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix))allocate(random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix(mm,num_vectors))
						! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do jj=1, num_vectors						
							do ii=1, mm
								ctemp=0
								do kk=1, nn1
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j)%matrix(kk,jj)
								enddo
								do kk=1, nn2
									ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j+1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix(kk,jj)
								enddo
								random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix(ii,jj)=ctemp
							enddo
						enddo
						! !$omp end parallel do				
						if(level==levelm .and. middleflag==1 .and. level_butterfly>=2)then	
							! ! allocate(matrixtemp(mm,num_vectors))
							! ! call gemm_omp(butterfly_block_randomized(1)%ButterflyMiddle(i,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix,matrixtemp,mm,mm,num_vectors)
							! ! random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix = matrixtemp
							! ! deallocate(matrixtemp)
							
							call gemm_omp(butterfly_block_randomized(1)%ButterflyMiddle(i+1,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix,random%RandomVectorRR(level+1)%blocks(i+1,index_j)%matrix,mm,mm,num_vectors)
						end if							
						
						
						deallocate(random%RandomVectorRR(level)%blocks(index_i,j)%matrix)
						deallocate(random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix)
						
                    enddo
					!$omp end parallel do
					! write(*,*)'3 done'
				else
					write(*,*)'should not be here'
					stop
                    do i=1, num_groupm
                        index_i=int((i+1)/2)
                        nn=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix,2)
                        mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix,1)
                        if(.not. allocated(random%RandomVectorRR(level+1)%blocks(i,1)%matrix))allocate(random%RandomVectorRR(level+1)%blocks(i,1)%matrix(mm,num_vectors))
						!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do jj=1, num_vectors
							do ii=1, mm
                                ctemp=0                        
                                do kk=1, nn
                                    ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,1)%matrix(kk,jj)
                                enddo
                                random%RandomVectorRR(level+1)%blocks(i,1)%matrix(ii,jj)=ctemp
                            enddo
                        enddo
                        !$omp end parallel do
						! deallocate(random%RandomVectorRR(level)%blocks(index_i,1)%matrix)
                    enddo
                endif
            endif
        enddo      
        
        !deallocate (butterflyvector)
                    
    elseif (chara=='T') then
    
        num_blocks=2**level_butterfly

        do level=level_start, level_end
            if (level==0) then
                num_groupm=num_blocks
                !$omp parallel do default(shared) private(i,rank,mm,ii,jj,ctemp,kk)
				do i=1, num_groupm
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
					if(.not. allocated(random%RandomVectorLL(1)%blocks(i,1)%matrix))allocate(random%RandomVectorLL(1)%blocks(i,1)%matrix(rank,num_vectors))
					! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do jj=1, num_vectors					
						do ii=1, rank
                            ctemp=0
                            do kk=1, mm
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyU(i)%matrix(kk,ii)*random%RandomVectorLL(0)%blocks(i,1)%matrix(kk,jj)
                            enddo
                            random%RandomVectorLL(1)%blocks(i,1)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    ! !$omp end parallel do
                enddo
				!$omp end parallel do
            elseif (level==level_butterfly+1) then
                num_groupn=num_blocks
                !$omp parallel do default(shared) private(j,rank,nn,ii,jj,ctemp,kk)
				do j=1, num_groupn
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    ! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do jj=1, num_vectors					
						do ii=1, nn
                            ctemp=0
                            do kk=1, rank
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyV(j)%matrix(ii,kk)*random%RandomVectorLL(level_butterfly+1)%blocks(1,j)%matrix(kk,jj)
                            enddo
                            random%RandomVectorLL(level_butterfly+2)%blocks(1,j)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    ! !$omp end parallel do
					deallocate(random%RandomVectorLL(level_butterfly+1)%blocks(1,j)%matrix)
                enddo 
				!$omp end parallel do				
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_col
                if (num_groupm/=1) then                
                    !$omp parallel do default(shared) private(ij,ii,jj,kk,ctemp,i,j,index_i,index_j,mm1,mm2,nn)
					do ij=1,(num_groupn/2)*(num_groupm/2)
						j = ((ij-1)/(num_groupm/2)+1)*2-1
						i = (mod(ij-1,(num_groupm/2)) + 1)*2-1	
						index_j=int((j+1)/2)
						index_i=int((i+1)/2)
						mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,1)
						mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix,1)
						nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,2)
						
						if(.not. allocated(random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix))allocate(random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(nn,num_vectors))
						! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do ii=1, num_vectors						
							do jj=1, nn
								ctemp=0
								do kk=1, mm1
									ctemp=ctemp+random%RandomVectorLL(level)%blocks(i,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix(kk,jj)
								enddo
								do kk=1, mm2
									ctemp=ctemp+random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix(kk,jj)
								enddo
								random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(jj,ii)=ctemp
							enddo
						enddo
						! !$omp end parallel do
						if(level_butterfly-level==levelm .and. middleflag==1 .and. level_butterfly>=2)then	
							! allocate(matrixtemp(nn,num_vectors))
							! allocate(matrixtemp1(nn,nn))
							! call copymatT_OMP(butterfly_block_randomized(1)%ButterflyMiddle(index_i,j)%matrix,matrixtemp1,nn,nn)
							! call gemmTN_omp(matrixtemp1,random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix,matrixtemp,nn,nn,num_vectors)
							! random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix = matrixtemp
							! deallocate(matrixtemp)
							! deallocate(matrixtemp1)	
							
							call gemmTN_omp(butterfly_block_randomized(1)%ButterflyMiddle(index_i,j)%matrix,random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix,random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix,nn,nn,num_vectors)							
						end if

						mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix,1)
						mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j+1)%matrix,1)
						nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix,2)
						
						if(.not. allocated(random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix))allocate(random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix(nn,num_vectors))
						! !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
						do ii=1, num_vectors						
							do jj=1, nn
								ctemp=0
								do kk=1, mm1
									ctemp=ctemp+random%RandomVectorLL(level)%blocks(i,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j+1)%matrix(kk,jj)
								enddo
								do kk=1, mm2
									ctemp=ctemp+random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j+1)%matrix(kk,jj)
								enddo
								random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix(jj,ii)=ctemp
							enddo
						enddo
						! !$omp end parallel do
						if(level_butterfly-level==levelm .and. middleflag==1 .and. level_butterfly>=2)then	
							! allocate(matrixtemp(nn,num_vectors))
							! allocate(matrixtemp1(nn,nn))
							! call copymatT_OMP(butterfly_block_randomized(1)%ButterflyMiddle(index_i,j)%matrix,matrixtemp1,nn,nn)
							! call gemmTN_omp(matrixtemp1,random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix,matrixtemp,nn,nn,num_vectors)
							! random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix = matrixtemp
							! deallocate(matrixtemp)
							! deallocate(matrixtemp1)	
							
							call gemmTN_omp(butterfly_block_randomized(1)%ButterflyMiddle(index_i,j+1)%matrix,random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix,random%RandomVectorLL(level+1)%blocks(index_i,j+1)%matrix,nn,nn,num_vectors)							
						end if						
						deallocate(random%RandomVectorLL(level)%blocks(i,index_j)%matrix)
						deallocate(random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix)
                    enddo
					!$omp end parallel do
                else
					write(*,*)'should not be here'
					stop
                    do j=1, num_groupn
                        index_j=int((j+1)/2)
                        nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix,2)
                        mm=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix,1)
                        if(.not. allocated(random%RandomVectorLL(level+1)%blocks(1,j)%matrix))allocate(random%RandomVectorLL(level+1)%blocks(1,j)%matrix(nn,num_vectors))
						!$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                        do jj=1, num_vectors
							do ii=1, nn
                                ctemp=0                         
                                do kk=1, mm
                                    ctemp=ctemp+random%RandomVectorLL(level)%blocks(1,index_j)%matrix(kk,jj)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix(kk,ii)
                                enddo
                                random%RandomVectorLL(level+1)%blocks(1,j)%matrix(ii,jj)=ctemp
                            enddo
                        enddo
                        !$omp end parallel do
						! deallocate(random%RandomVectorLL(level)%blocks(1,index_j)%matrix)
                    enddo
                endif
            endif
        enddo
    
    endif
    
    return
    
end subroutine Butterfly_Partial_MVP	



subroutine condition_internalmatrices(random,chara,level,dimension_rank,level_butterfly,num_vectors,condition_number)

    use MODULE_FILE
    ! use lapack95
    ! use blas95
    implicit none
    
    integer i,j,i_old,j_old,iijj,k,level,num_blocks,num_row,num_col,ii,jj,kk,level_left,level_right, rank
    integer index_i, index_j, mm, nn, iter, vector1, vector2, direction, round, mi, nj, min_mn
    real*8 a,b,c,d,norm1,norm2,norm3,norm4,error,condition_number
    complex(kind=8) ctemp
    character chara
	integer dimension_rank,level_butterfly,num_vectors
    
    type(RandomBlock) :: random
    
    complex(kind=8), allocatable :: matrixtemp1(:,:), UU(:,:), VV(:,:)
    real*8, allocatable :: Singular (:)
    
    num_blocks=2**level_butterfly
    condition_number = 0
	
    if (chara=='R') then
        
        ! if (level==0) then
            ! write(*,*)'level cannot be zero'
			! stop
        ! elseif (level==level_butterfly+2) then
            ! write(*,*)'level cannot be level_butterfly+2'
			! stop
        ! else
            ! rank=dimension_rank
        ! endif
        ! allocate (matrixtemp1(num_blocks*rank,num_vectors))
        ! min_mn=min(num_blocks*rank,num_vectors)
        ! allocate (Singular(min_mn))
        ! num_row=random%RandomVectorRR(level)%num_row
        ! num_col=random%RandomVectorRR(level)%num_col
        ! do i=1, num_row
            ! do j=1, num_col
                ! mm=((i-1)*num_col+j-1)*rank
                ! !$omp parallel do default(shared) private(ii,jj)
                ! do jj=1, num_vectors
                    ! do ii=1, rank
                        ! matrixtemp1(mm+ii,jj)=random%RandomVectorRR(level)%blocks(i,j)%matrix(ii,jj)
                    ! enddo
                ! enddo
                ! !$omp end parallel do
            ! enddo
        ! enddo
        ! call gesvd(matrixtemp1,Singular)
        ! condition_number=Singular(1)/Singular(min_mn)
        ! write(*,*)'haddh',Singular
        ! !open (30,file='Singular_distribution_R.txt')
        ! !do i=1, min_mn
        ! !    write (30,*) i, Singular(i)
        ! !enddo
        ! !close (30)
        ! !pause
        
        ! deallocate (matrixtemp1,Singular)
		
		
		
		
		
        if (level==0) then
            write(*,*)'level cannot be zero'
			stop
        elseif (level==level_butterfly+2) then
            write(*,*)'level cannot be level_butterfly+2'
			stop
        else
            rank=dimension_rank
        endif
        num_row=random%RandomVectorRR(level)%num_row
        num_col=random%RandomVectorRR(level)%num_col

        allocate (matrixtemp1(2*rank,num_vectors))
        min_mn=min(2*rank,num_vectors)
        allocate (Singular(min_mn))
		allocate (UU(2*rank,min_mn))
		allocate (VV(min_mn,num_vectors))
		
		
		iijj = 0
        do i=1, num_row
            do j=1, num_col
				iijj  = iijj + 1
			    if(mod(iijj,2)==0)then
					!$omp parallel do default(shared) private(ii,jj)
					do jj=1, num_vectors
						do ii=1, rank
							matrixtemp1(ii,jj)=random%RandomVectorRR(level)%blocks(i_old,j_old)%matrix(ii,jj)
							matrixtemp1(ii+rank,jj)=random%RandomVectorRR(level)%blocks(i,j)%matrix(ii,jj)
						enddo
					enddo
					!$omp end parallel do
					call gesvd_robust(matrixtemp1,Singular,UU,VV,2*rank,num_vectors,min_mn)
					condition_number=max(condition_number,Singular(1)/Singular(min_mn))
					! write(*,*)'hah',Singular
					! write(*,*)condition_number
				end if
				i_old = i
				j_old = j
			enddo
        enddo
        deallocate (matrixtemp1,Singular,UU,VV)	
		

		
        ! if (level==0) then
            ! write(*,*)'level cannot be zero'
			! stop
        ! elseif (level==level_butterfly+2) then
            ! write(*,*)'level cannot be level_butterfly+2'
			! stop
        ! else
            ! rank=dimension_rank
        ! endif
        ! num_row=random%RandomVectorRR(level)%num_row
        ! num_col=random%RandomVectorRR(level)%num_col

        ! allocate (matrixtemp1(rank,num_vectors))
        ! min_mn=min(rank,num_vectors)
        ! allocate (Singular(min_mn))
		
        ! do i=1, num_row
            ! do j=1, num_col
				! !$omp parallel do default(shared) private(ii,jj)
				! do jj=1, num_vectors
					! do ii=1, rank
						! matrixtemp1(ii,jj)=random%RandomVectorRR(level)%blocks(i,j)%matrix(ii,jj)
					! enddo
				! enddo
				! !$omp end parallel do
				! call gesvd(matrixtemp1,Singular)
				! condition_number=max(condition_number,Singular(1)/Singular(min_mn))
				! ! write(*,*)condition_number
				! write(*,*)Singular(1),Singular(min_mn)
			! enddo
        ! enddo
        ! deallocate (matrixtemp1,Singular)			
		
		
		
		
    elseif (chara=='L') then
    
        ! if (level==0) then
            ! write(*,*)'level cannot be zero'
			! stop
        ! elseif (level==level_butterfly+2) then
            ! write(*,*)'level cannot be level_butterfly+2'
			! stop
        ! else
            ! rank=dimension_rank
        ! endif
        ! allocate (matrixtemp1(num_blocks*rank,num_vectors))
        ! min_mn=min(num_blocks*rank,num_vectors)
        ! allocate (Singular(min_mn))
        ! num_row=random%RandomVectorLL(level)%num_row
        ! num_col=random%RandomVectorLL(level)%num_col
        ! do i=1, num_row
            ! do j=1, num_col
                ! mm=((i-1)*num_col+j-1)*rank
                ! !$omp parallel do default(shared) private(ii,jj)
                ! do jj=1, num_vectors
                    ! do ii=1, rank
                        ! matrixtemp1(ii+mm,jj)=random%RandomVectorLL(level)%blocks(i,j)%matrix(ii,jj)
                    ! enddo
                ! enddo
                ! !$omp end parallel do
            ! enddo
        ! enddo
        ! call gesvd(matrixtemp1,Singular)
		! ! write(*,*)min_mn,num_blocks*rank,num_vectors
        ! condition_number=Singular(1)/Singular(min_mn)
        
        ! deallocate (matrixtemp1,Singular)
        
		
		
		
		
        if (level==0) then
            write(*,*)'level cannot be zero'
			stop
        elseif (level==level_butterfly+2) then
            write(*,*)'level cannot be level_butterfly+2'
			stop
        else
            rank=dimension_rank
        endif
        allocate (matrixtemp1(2*rank,num_vectors))
        min_mn=min(2*rank,num_vectors)
        allocate (Singular(min_mn))
		allocate (UU(2*rank,min_mn))
		allocate (VV(min_mn,num_vectors))
        num_row=random%RandomVectorLL(level)%num_row
        num_col=random%RandomVectorLL(level)%num_col
        iijj = 0
		do j=1, num_col
			do i=1, num_row
                iijj = iijj +1
                if(mod(iijj,2)==0)then
					!$omp parallel do default(shared) private(ii,jj)
					do jj=1, num_vectors
						do ii=1, rank
							matrixtemp1(ii,jj)=random%RandomVectorLL(level)%blocks(i,j)%matrix(ii,jj)
							matrixtemp1(ii+rank,jj)=random%RandomVectorLL(level)%blocks(i_old,j_old)%matrix(ii,jj)
						enddo
					enddo
					!$omp end parallel do
					call gesvd_robust(matrixtemp1,Singular,UU,VV,2*rank,num_vectors,min_mn)
					! write(*,*)min_mn,num_blocks*rank,num_vectors
					condition_number=max(condition_number,Singular(1)/Singular(min_mn))	
				end if	
				i_old = i
				j_old = j
            enddo
        enddo
      
        
        deallocate (matrixtemp1,Singular,UU,VV)		
		
		
    endif
    
    return

end subroutine condition_internalmatrices


subroutine Delete_randomized_butterfly()

    use MODULE_FILE
	use misc
	! use lapack95
	! use blas95
    use omp_lib
	
    implicit none
    
	integer level_c,rowblock
    integer blocks1, blocks2, blocks3, level_butterfly, i, j, k, num_blocks
    integer num_col, num_row, level, mm, nn, ii, jj
    character chara
    real*8 T0
    type(matrixblock),pointer::block_o
    integer rank_new_max
	real*8:: rank_new_avr,error
	integer niter
	real*8:: error_inout
	integer itermax,levelm,index_i_m,index_j_m
	! real*8:: n1,n2
		

    level_butterfly=butterfly_block_randomized(1)%level_butterfly
    num_blocks=2**level_butterfly
	
	
	if(allocated(butterfly_block_randomized(1)%ButterflyMiddle))then
		levelm = ceiling_safe(dble(level_butterfly)/2d0)
		do index_i_m=1, 2**levelm
			do index_j_m=1, 2**(level_butterfly-levelm)	
				if(allocated(butterfly_block_randomized(1)%ButterflyMiddle(index_i_m,index_j_m)%matrix))deallocate(butterfly_block_randomized(1)%ButterflyMiddle(index_i_m,index_j_m)%matrix)
			end do
		end do
		deallocate(butterfly_block_randomized(1)%ButterflyMiddle)
	end if	


	if(allocated(butterfly_block_randomized(1)%KerInv))deallocate(butterfly_block_randomized(1)%KerInv)
	
	
	
	
    do i=1, num_blocks
		if(allocated(butterfly_block_randomized(1)%ButterflyU(i)%matrix))deallocate (butterfly_block_randomized(1)%ButterflyU(i)%matrix)
        if(allocated(butterfly_block_randomized(1)%ButterflyV(i)%matrix))deallocate (butterfly_block_randomized(1)%ButterflyV(i)%matrix)
    enddo
    deallocate (butterfly_block_randomized(1)%ButterflyU, butterfly_block_randomized(1)%ButterflyV)
	
	if (level_butterfly/=0) then
        do level=1, level_butterfly
            num_row=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
            num_col=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col
            do j=1, num_col
                do i=1, num_row
					if(allocated(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix))then
						mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,1)
						nn=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,2)
						deallocate (butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix)
					end if
                enddo
            enddo
            deallocate (butterfly_block_randomized(1)%ButterflyKerl(level)%blocks)
        enddo
        deallocate (butterfly_block_randomized(1)%ButterflyKerl)
    endif
    
    deallocate (butterfly_block_randomized)
    
    return

end subroutine Delete_randomized_butterfly



subroutine Delete_RandVect(chara,random,level_butterfly)
	use MODULE_FILE
	implicit none 
    character chara
	integer num_col,num_row,level,i,j	
	type(RandomBlock):: random
	integer level_butterfly

	if(chara=='T')then
		do level=0, level_butterfly+2
			num_row=random%RandomVectorLL(level)%num_row
			num_col=random%RandomVectorLL(level)%num_col
			do j=1, num_col
				do i=1, num_row
					if(allocated(random%RandomVectorLL(level)%blocks(i,j)%matrix))deallocate (random%RandomVectorLL(level)%blocks(i,j)%matrix)
					if(level/=0 .and. level/=level_butterfly+2)then
						if(allocated(random%RandomVectorLL(level)%blocks(i,j)%null))deallocate (random%RandomVectorLL(level)%blocks(i,j)%null)
					end if
				enddo
			enddo
			deallocate (random%RandomVectorLL(level)%blocks)
		enddo
		deallocate (random%RandomVectorLL)
	else if(chara=='N')then
		do level=0, level_butterfly+2
			num_row=random%RandomVectorRR(level)%num_row
			num_col=random%RandomVectorRR(level)%num_col
			do j=1, num_col
				do i=1, num_row
					if(allocated(random%RandomVectorRR(level)%blocks(i,j)%matrix))deallocate (random%RandomVectorRR(level)%blocks(i,j)%matrix)
					if(level/=0 .and. level/=level_butterfly+2)then
						if(allocated(random%RandomVectorRR(level)%blocks(i,j)%null))deallocate (random%RandomVectorRR(level)%blocks(i,j)%null)
					end if
				enddo
			enddo
			deallocate (random%RandomVectorRR(level)%blocks)
		enddo
		deallocate (random%RandomVectorRR)		
	end if
end subroutine Delete_RandVect

subroutine Init_RandVect(chara,random,num_vect_sub)
    
    use MODULE_FILE
    implicit none
    
    integer n, group_m, group_n, group_mm, group_nn, index_i, index_j, na, nb, index_start
    integer i, j, ii, jj, level, groupm_start, groupn_start, index_iijj, index_ij, k, kk, intemp1, intemp2
    integer header_m, header_n, tailer_m, tailer_n, mm, nn, num_blocks, level_define, col_vector
    integer rank1, rank2, rank, num_groupm, num_groupn, header_nn, header_mm, ma, mb
    integer vector_a, vector_b, nn1, nn2, level_blocks, mm1, mm2,num_vect_sub,level_butterfly
    complex(kind=8) ctemp, a, b
    character chara
	integer num_col,num_row
    real*8:: mem_vec
	
    ! type(matricesblock), pointer :: blocks
    type(RandomBlock), pointer :: random
    
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
	
    if (chara=='N') then

        num_blocks=2**level_butterfly
            
        allocate (random%RandomVectorRR(0)%blocks(1,num_blocks))
        random%RandomVectorRR(0)%num_row=1
        random%RandomVectorRR(0)%num_col=num_blocks

        do i=1, num_blocks
            nn=size(butterfly_block_randomized(1)%butterflyV(i)%matrix,1)
            allocate (random%RandomVectorRR(0)%blocks(1,i)%matrix(nn,num_vect_sub))
			random%RandomVectorRR(0)%blocks(1,i)%matrix = 0
        enddo 

        do level=0, level_butterfly
            if (level==0) then
                num_groupn=num_blocks
                allocate (random%RandomVectorRR(1)%blocks(1,num_groupn))
                random%RandomVectorRR(1)%num_row=1
                random%RandomVectorRR(1)%num_col=num_groupn
                do j=1, num_groupn
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    allocate (random%RandomVectorRR(1)%blocks(1,j)%matrix(rank,num_vect_sub))
					random%RandomVectorRR(1)%blocks(1,j)%matrix = 0
					random%RandomVectorRR(1)%blocks(1,j)%nulldim = rank
					allocate (random%RandomVectorRR(1)%blocks(1,j)%null(rank,rank))
					random%RandomVectorRR(1)%blocks(1,j)%null = 0
					do ii=1,rank
						random%RandomVectorRR(1)%blocks(1,j)%null(ii,ii)=1
					end do
				enddo                    
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col               
				allocate (random%RandomVectorRR(level+1)%blocks(num_groupm,int(num_groupn/2)))
				random%RandomVectorRR(level+1)%num_row=num_groupm
				random%RandomVectorRR(level+1)%num_col=int(num_groupn/2)                    
				do i=1, num_groupm
					index_i=int((i+1)/2)
					do j=1, num_groupn, 2
						index_j=int((j+1)/2)
						nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,2)
						nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix,2)
						mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,1)
						allocate (random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(mm,num_vect_sub))
						random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix = 0
						random%RandomVectorRR(level+1)%blocks(i,index_j)%nulldim = mm
						allocate (random%RandomVectorRR(level+1)%blocks(i,index_j)%null(mm,mm))
						random%RandomVectorRR(level+1)%blocks(i,index_j)%null = 0
						do ii=1,mm
							random%RandomVectorRR(level+1)%blocks(i,index_j)%null(ii,ii)=1
						end do						
					enddo
				enddo               
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorRR(level+2)%blocks(num_blocks,1))
                random%RandomVectorRR(level+2)%num_row=num_blocks
                random%RandomVectorRR(level+2)%num_col=1
                do i=1, num_blocks
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    allocate (random%RandomVectorRR(level+2)%blocks(i,1)%matrix(mm,num_vect_sub))
					random%RandomVectorRR(level+2)%blocks(i,1)%matrix = 0
				enddo
            endif
        enddo      

		mem_vec = 0
		do level=0, level_butterfly+2
			num_row=random%RandomVectorRR(level)%num_row
			num_col=random%RandomVectorRR(level)%num_col
			do j=1, num_col
				do i=1, num_row
					mem_vec =mem_vec + SIZEOF(random%RandomVectorRR(level)%blocks(i,j)%matrix)/1024.0d3
					if(level/=0 .and. level/=level_butterfly+2)mem_vec =mem_vec + SIZEOF(random%RandomVectorRR(level)%blocks(i,j)%null)/1024.0d3
				enddo
			enddo
		enddo
		Memory_int_vec = max(Memory_int_vec,mem_vec) 
        
    elseif (chara=='T') then
    
        num_blocks=2**level_butterfly
        allocate (random%RandomVectorLL(0)%blocks(num_blocks,1))
        random%RandomVectorLL(0)%num_row=num_blocks
        random%RandomVectorLL(0)%num_col=1
        
        do i=1, num_blocks
			mm=size(butterfly_block_randomized(1)%butterflyU(i)%matrix,1)			
            allocate (random%RandomVectorLL(0)%blocks(i,1)%matrix(mm,num_vect_sub))
			random%RandomVectorLL(0)%blocks(i,1)%matrix = 0
        enddo 
        
        do level=0, level_butterfly
            if (level==0) then
                num_groupm=num_blocks
                allocate (random%RandomVectorLL(1)%blocks(num_groupm,1))
                random%RandomVectorLL(1)%num_row=num_groupm
                random%RandomVectorLL(1)%num_col=1
                do i=1, num_groupm
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    allocate (random%RandomVectorLL(1)%blocks(i,1)%matrix(rank,num_vect_sub))
					random%RandomVectorLL(1)%blocks(i,1)%matrix = 0
					random%RandomVectorLL(1)%blocks(i,1)%nulldim = rank
					allocate (random%RandomVectorLL(1)%blocks(i,1)%null(rank,rank))
					random%RandomVectorLL(1)%blocks(i,1)%null = 0
					do ii=1,rank
						random%RandomVectorLL(1)%blocks(i,1)%null(ii,ii)=1
					end do
				enddo                    
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_col
                
				allocate (random%RandomVectorLL(level+1)%blocks(int(num_groupm/2),num_groupn))
				random%RandomVectorLL(level+1)%num_row=int(num_groupm/2)
				random%RandomVectorLL(level+1)%num_col=num_groupn                    
				do j=1, num_groupn
					index_j=int((j+1)/2)
					do i=1, num_groupm, 2
						index_i=int((i+1)/2)
						mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,1)
						mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix,1)
						nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,2)
						allocate (random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(nn,num_vect_sub))
						random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix = 0
						random%RandomVectorLL(level+1)%blocks(index_i,j)%nulldim = nn
						allocate (random%RandomVectorLL(level+1)%blocks(index_i,j)%null(nn,nn))
						random%RandomVectorLL(level+1)%blocks(index_i,j)%null = 0
						do ii =1,nn
							random%RandomVectorLL(level+1)%blocks(index_i,j)%null(ii,ii) = 1
						end do
					enddo
				enddo
                
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorLL(level+2)%blocks(1,num_blocks))
                random%RandomVectorLL(level+2)%num_row=1
                random%RandomVectorLL(level+2)%num_col=num_blocks
                do j=1, num_blocks
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    allocate (random%RandomVectorLL(level+2)%blocks(1,j)%matrix(nn,num_vect_sub))
					random%RandomVectorLL(level+2)%blocks(1,j)%matrix = 0
                enddo
            endif
        enddo
    
		mem_vec = 0
		do level=0, level_butterfly+2
			num_row=random%RandomVectorLL(level)%num_row
			num_col=random%RandomVectorLL(level)%num_col
			do j=1, num_col
				do i=1, num_row
					mem_vec =mem_vec + SIZEOF(random%RandomVectorLL(level)%blocks(i,j)%matrix)/1024.0d3
					if(level/=0 .and. level/=level_butterfly+2)mem_vec =mem_vec + SIZEOF(random%RandomVectorLL(level)%blocks(i,j)%null)/1024.0d3
				enddo
			enddo
		enddo
		Memory_int_vec = max(Memory_int_vec,mem_vec) 
	
	
    endif
    

    return
    
end subroutine Init_RandVect



subroutine Init_RandVect_Empty(chara,random,num_vect_sub)
    
    use MODULE_FILE
    implicit none
        real*8:: mem_vec
    integer n, group_m, group_n, group_mm, group_nn, index_i, index_j, na, nb, index_start
    integer i, j, ii, jj, level, groupm_start, groupn_start, index_iijj, index_ij, k, kk, intemp1, intemp2
    integer header_m, header_n, tailer_m, tailer_n, mm, nn, num_blocks, level_define, col_vector
    integer rank1, rank2, rank, num_groupm, num_groupn, header_nn, header_mm, ma, mb
    integer vector_a, vector_b, nn1, nn2, level_blocks, mm1, mm2,num_vect_sub,level_butterfly
    complex(kind=8) ctemp, a, b
    character chara
	integer num_col,num_row
    
    ! type(matricesblock), pointer :: blocks
    type(RandomBlock), pointer :: random
    
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
	
    if (chara=='N') then

        num_blocks=2**level_butterfly
            
        allocate (random%RandomVectorRR(0)%blocks(1,num_blocks))
        random%RandomVectorRR(0)%num_row=1
        random%RandomVectorRR(0)%num_col=num_blocks
        do i=1, num_blocks
            nn=size(butterfly_block_randomized(1)%butterflyV(i)%matrix,1)
            allocate (random%RandomVectorRR(0)%blocks(1,i)%matrix(nn,num_vect_sub))
			random%RandomVectorRR(0)%blocks(1,i)%matrix = 0
        enddo 
        do level=0, level_butterfly
            if (level==0) then
                num_groupn=num_blocks
                allocate (random%RandomVectorRR(1)%blocks(1,num_groupn))
                random%RandomVectorRR(1)%num_row=1
                random%RandomVectorRR(1)%num_col=num_groupn                   
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col               
				allocate (random%RandomVectorRR(level+1)%blocks(num_groupm,int(num_groupn/2)))
				random%RandomVectorRR(level+1)%num_row=num_groupm
				random%RandomVectorRR(level+1)%num_col=int(num_groupn/2)                    
				           
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorRR(level+2)%blocks(num_blocks,1))
                random%RandomVectorRR(level+2)%num_row=num_blocks
                random%RandomVectorRR(level+2)%num_col=1
                do i=1, num_blocks
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    allocate (random%RandomVectorRR(level+2)%blocks(i,1)%matrix(mm,num_vect_sub))
					random%RandomVectorRR(level+2)%blocks(i,1)%matrix = 0
				enddo
            endif
        enddo      

		mem_vec = 0
		do level=0, level_butterfly+2
			num_row=random%RandomVectorRR(level)%num_row
			num_col=random%RandomVectorRR(level)%num_col
			do j=1, num_col
				do i=1, num_row
					mem_vec =mem_vec + SIZEOF(random%RandomVectorRR(level)%blocks(i,j)%matrix)/1024.0d3
					if(level/=0 .and. level/=level_butterfly+2)mem_vec =mem_vec + SIZEOF(random%RandomVectorRR(level)%blocks(i,j)%null)/1024.0d3
				enddo
			enddo
		enddo
		Memory_int_vec = max(Memory_int_vec,mem_vec) 
        
    elseif (chara=='T') then
    
        num_blocks=2**level_butterfly
        allocate (random%RandomVectorLL(0)%blocks(num_blocks,1))
        random%RandomVectorLL(0)%num_row=num_blocks
        random%RandomVectorLL(0)%num_col=1
        do i=1, num_blocks
			mm=size(butterfly_block_randomized(1)%butterflyU(i)%matrix,1)			
            allocate (random%RandomVectorLL(0)%blocks(i,1)%matrix(mm,num_vect_sub))
			random%RandomVectorLL(0)%blocks(i,1)%matrix = 0
        enddo         
        do level=0, level_butterfly
            if (level==0) then
                num_groupm=num_blocks
                allocate (random%RandomVectorLL(1)%blocks(num_groupm,1))
                random%RandomVectorLL(1)%num_row=num_groupm
                random%RandomVectorLL(1)%num_col=1                
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_col
                
				allocate (random%RandomVectorLL(level+1)%blocks(int(num_groupm/2),num_groupn))
				random%RandomVectorLL(level+1)%num_row=int(num_groupm/2)
				random%RandomVectorLL(level+1)%num_col=num_groupn                    
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorLL(level+2)%blocks(1,num_blocks))
                random%RandomVectorLL(level+2)%num_row=1
                random%RandomVectorLL(level+2)%num_col=num_blocks
                do j=1, num_blocks
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    allocate (random%RandomVectorLL(level+2)%blocks(1,j)%matrix(nn,num_vect_sub))
					random%RandomVectorLL(level+2)%blocks(1,j)%matrix = 0
                enddo
            endif
        enddo
    
		mem_vec = 0
		do level=0, level_butterfly+2
			num_row=random%RandomVectorLL(level)%num_row
			num_col=random%RandomVectorLL(level)%num_col
			do j=1, num_col
				do i=1, num_row
					mem_vec =mem_vec + SIZEOF(random%RandomVectorLL(level)%blocks(i,j)%matrix)/1024.0d3
					if(level/=0 .and. level/=level_butterfly+2)mem_vec =mem_vec + SIZEOF(random%RandomVectorLL(level)%blocks(i,j)%null)/1024.0d3
				enddo
			enddo
		enddo
		Memory_int_vec = max(Memory_int_vec,mem_vec) 
	
	
    endif
    

    return
    
end subroutine Init_RandVect_Empty



subroutine Zero_Butterfly(level_start,level_end)

    use MODULE_FILE
    ! use lapack95
	use misc
    implicit none
    ! type(matricesblock), pointer :: blocks
	integer level_start,level_end,level_butterfly
	
    integer i,j,k,level,num_blocks,num_row,num_col,ii,jj,kk,rank,iii,jjj,index_i,index_j,mm_start,nn_start
    real*8 a,b,c,d
    complex(kind=8) ctemp
    
    complex(kind=8), allocatable :: matrixtemp(:,:), matrixU(:,:), matrixV(:,:)
    real*8, allocatable :: Singular(:)
    
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
    
    num_blocks=2**level_butterfly
	
	do level = level_start,level_end
		if(level==0)then
			do ii=1, num_blocks
				butterfly_block_randomized(1)%ButterflyV(ii)%matrix = 0
			end do
		else if(level==level_butterfly+1)then
			do ii=1, num_blocks
				butterfly_block_randomized(1)%ButterflyU(ii)%matrix = 0
			end do
		else 		
            num_row=2**level
            num_col=2**(level_butterfly-level+1)
			do j=1, num_col, 2
                do i=1, num_row, 2
                    butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix = 0
                    butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j)%matrix = 0
                    butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix = 0
                    butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i+1,j+1)%matrix = 0
                enddo
            enddo		
		end if		
	end do
 
    return

end subroutine Zero_Butterfly

 



subroutine Butterfly_value_randomized(mi,nj,value)

    use MODULE_FILE
    implicit none
    
    integer mm, nn, mi, nj, groupm_start, groupn_start, level_butterfly, flag
    integer i, j, ii, jj, rank, group_m, group_n, header_mm, header_nn, k, kk
    integer group, level, mii, njj, rank1, rank2, index_ij, level_blocks, flag1
    complex(kind=8) ctemp, value
    
    !type(matricesblock), pointer :: blocks
    type(vectorset),allocatable:: vectors_set(:)    
    integer,allocatable :: group_index_mm(:), group_index_nn(:)
    
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
    
    allocate (group_index_mm(0:level_butterfly),group_index_nn(0:level_butterfly))
    
    flag=0; i=0; k=0
    do while (flag==0)
        i=i+1
        if (size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)+k>=mi) then
            flag=1
        endif
        k=k+size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
    enddo
    group_index_mm(0)=i
    mii=mi-k+size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
    
    flag=0; j=0; k=0
    do while (flag==0)
        j=j+1
        if (size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)+k>=nj) then
            flag=1
        endif
        k=k+size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
    enddo
    group_index_nn(0)=j
    njj=nj-k+size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
    
    if (level_butterfly>0) then
        group_index_mm(1)=group_index_mm(0)
        group_index_nn(1)= group_index_nn(0)
        do level=1, level_butterfly-1
            group_index_mm(level+1)=int((group_index_mm(level)+1)/2)
            group_index_nn(level+1)=int((group_index_nn(level)+1)/2)
        enddo
    endif
    
!     if (group_index_mm(0)/=group_m .or. group_index_nn(0)/=group_n) then
!         write (*,*) 'Butterfly_value_func error1!'
!         pause
!         continue
!     endif
    
!     do level=0, level_butterfly
!         group_index_mm(level)=group_index_mm(level)-group_m*2**level+1
!         group_index_nn(level)=group_index_nn(level)-group_n*2**level+1
!     enddo
    
    allocate (vectors_set(0:level_butterfly))
    do level=0, level_butterfly
        if (level==0) then
            rank=size(butterfly_block_randomized(1)%ButterflyV(group_index_nn(0))%matrix,2)
            allocate (vectors_set(level)%vector(rank))
            !!$omp parallel do default(shared) private(i)
            do i=1, rank
                vectors_set(level)%vector(i)=butterfly_block_randomized(1)%ButterflyV(group_index_nn(0))%matrix(njj,i)
            enddo
            !!$omp end parallel do
        else
            rank1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(group_index_mm(level_butterfly-level+1),group_index_nn(level))%matrix,2)
            rank2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(group_index_mm(level_butterfly-level+1),group_index_nn(level))%matrix,1)
            allocate (vectors_set(level)%vector(rank2))
            !!$omp parallel do default(shared) private(i,j,ctemp)
            do i=1, rank2
                ctemp=0
                do j=1, rank1
                    ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(group_index_mm(level_butterfly-level+1),group_index_nn(level))%matrix(i,j)*vectors_set(level-1)%vector(j)
                enddo
                vectors_set(level)%vector(i)=ctemp
            enddo
            !!$omp end parallel do
            deallocate (vectors_set(level-1)%vector)
        endif
        if (level==level_butterfly) then
            rank=size(vectors_set(level)%vector,1)
            ctemp=0
            !!$omp parallel do default(shared) private(i) reduction(+:ctemp)
            do i=1, rank
                ctemp=ctemp+butterfly_block_randomized(1)%butterflyU(group_index_mm(0))%matrix(mii,i)*vectors_set(level)%vector(i)
            enddo
            !!$omp end parallel do
            value=ctemp
            deallocate (vectors_set(level)%vector)
        endif
    enddo
    deallocate (vectors_set)        
     
    return

end subroutine Butterfly_value_randomized


subroutine butterfly_block_MVP_inlitialize_randomized(chara,random)
    
    use MODULE_FILE
    implicit none
    
    integer n, group_m, group_n, group_mm, group_nn, index_i, index_j, na, nb, index_start
    integer i, j, ii, jj, level, groupm_start, groupn_start, index_iijj, index_ij, k, kk, intemp1, intemp2
    integer header_m, header_n, tailer_m, tailer_n, mm, nn, num_blocks, level_define, col_vector
    integer rank1, rank2, rank, num_groupm, num_groupn, header_nn, header_mm, ma, mb
    integer vector_a, vector_b, nn1, nn2, level_blocks, mm1, mm2, num_vectors, level_butterfly
    complex(kind=8) ctemp, a, b
    character chara
    
    type(RandomBlock) :: random
    
    num_vectors=size(RandomVectors_InOutput(1)%vector,2)
    level_butterfly=butterfly_block_randomized(1)%level_butterfly
    
    if (chara=='N') then
	! write(*,*)'dfdfd,hahah'
        num_blocks=2**level_butterfly
            
        allocate (random%RandomVectorRR(0:level_butterfly+2))
        allocate (random%RandomVectorRR(0)%blocks(1,num_blocks))
        random%RandomVectorRR(0)%num_row=1
        random%RandomVectorRR(0)%num_col=num_blocks
        ! write(*,*)'gan'
        k=0
        do i=1, num_blocks
            nn=size(butterfly_block_randomized(1)%butterflyV(i)%matrix,1)
            allocate (random%RandomVectorRR(0)%blocks(1,i)%matrix(nn,num_vectors))
            !$omp parallel do default(shared) private(ii,jj)
            do ii=1, nn
                do jj=1, num_vectors
                    random%RandomVectorRR(0)%blocks(1,i)%matrix(ii,jj)=RandomVectors_InOutput(1)%vector(ii+k,jj)
                enddo
            enddo
            !$omp end parallel do
            k=k+nn
        enddo 
        ! write(*,*)'dfddfdfd'
        do level=0, level_butterfly
            if (level==0) then
                num_groupn=num_blocks
                allocate (random%RandomVectorRR(1)%blocks(1,num_groupn))
                random%RandomVectorRR(1)%num_row=1
                random%RandomVectorRR(1)%num_col=num_groupn
                do j=1, num_groupn
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    allocate (random%RandomVectorRR(1)%blocks(1,j)%matrix(rank,num_vectors))
                    !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do ii=1, rank
                        do jj=1, num_vectors
                            ctemp=0
                            do kk=1, nn
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyV(j)%matrix(kk,ii)*random%RandomVectorRR(0)%blocks(1,j)%matrix(kk,jj)
                            enddo
                            random%RandomVectorRR(1)%blocks(1,j)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    !$omp end parallel do
                enddo                    
            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level)%num_col
                if (num_groupn/=1) then
                    allocate (random%RandomVectorRR(level+1)%blocks(num_groupm,int(num_groupn/2)))
                    random%RandomVectorRR(level+1)%num_row=num_groupm
                    random%RandomVectorRR(level+1)%num_col=int(num_groupn/2)            
                    do i=1, num_groupm
                        index_i=int((i+1)/2)
                        do j=1, num_groupn, 2
                            index_j=int((j+1)/2)
                            nn1=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,2)
                            nn2=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix,2)
                            mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix,1)
                            allocate (random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(mm,num_vectors))
                            !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                            do ii=1, mm
                                do jj=1, num_vectors
                                    ctemp=0
                                    do kk=1, nn1
                                        ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j)%matrix(kk,jj)
                                    enddo
                                    do kk=1, nn2
                                        ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,j+1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,j+1)%matrix(kk,jj)
                                    enddo
                                    random%RandomVectorRR(level+1)%blocks(i,index_j)%matrix(ii,jj)=ctemp
                                enddo
                            enddo
                            !$omp end parallel do
                        enddo
                    enddo
                else
                    allocate (random%RandomVectorRR(level+1)%blocks(num_groupm,1))
                    random%RandomVectorRR(level+1)%num_row=num_groupm
                    random%RandomVectorRR(level+1)%num_col=1
                    do i=1, num_groupm
                        index_i=int((i+1)/2)
                        nn=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix,2)
                        mm=size(butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix,1)
                        allocate (random%RandomVectorRR(level+1)%blocks(i,1)%matrix(mm,num_vectors))
                        !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                        do ii=1, mm
                            do jj=1, num_vectors
                                ctemp=0                             
                                do kk=1, nn
                                    ctemp=ctemp+butterfly_block_randomized(1)%ButterflyKerl(level)%blocks(i,1)%matrix(ii,kk)*random%RandomVectorRR(level)%blocks(index_i,1)%matrix(kk,jj)
                                enddo
                                random%RandomVectorRR(level+1)%blocks(i,1)%matrix(ii,jj)=ctemp
                            enddo
                        enddo
                        !$omp end parallel do
                    enddo
                endif
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorRR(level+2)%blocks(num_blocks,1))
                random%RandomVectorRR(level+2)%num_row=num_blocks
                random%RandomVectorRR(level+2)%num_col=1
                do i=1, num_blocks
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    allocate (random%RandomVectorRR(level+2)%blocks(i,1)%matrix(mm,num_vectors))
                    !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do ii=1, mm
                        do jj=1, num_vectors
                            ctemp=0
                            do kk=1, rank
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyU(i)%matrix(ii,kk)*random%RandomVectorRR(level+1)%blocks(i,1)%matrix(kk,jj)
                            enddo
                            random%RandomVectorRR(level+2)%blocks(i,1)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    !$omp end parallel do
                enddo
            endif
        enddo
        
        k=0
        do i=1, num_blocks
            mm=size(butterfly_block_randomized(1)%butterflyU(i)%matrix,1)
            !$omp parallel do default(shared) private(ii,jj)
            do ii=1, mm
                do jj=1, num_vectors
                    random%RandomVectorRR(level_butterfly+2)%blocks(i,1)%matrix(ii,jj)=RandomVectors_InOutput(3)%vector(ii+k,jj)
                enddo
            enddo
            !$omp end parallel do
            k=k+mm
        enddo       
        
        !deallocate (random%RandomVectorRR)
                    
    elseif (chara=='T') then
    
        num_blocks=2**level_butterfly
        
        allocate (random%RandomVectorLL(0:level_butterfly+2))
        allocate (random%RandomVectorLL(0)%blocks(num_blocks,1))
        random%RandomVectorLL(0)%num_row=num_blocks
        random%RandomVectorLL(0)%num_col=1
        
        k=0
        do i=1, num_blocks
            mm=size(butterfly_block_randomized(1)%butterflyU(i)%matrix,1)
            allocate (random%RandomVectorLL(0)%blocks(i,1)%matrix(mm,num_vectors))
            !$omp parallel do default(shared) private(ii,jj)
            do ii=1, mm
                do jj=1, num_vectors
                    random%RandomVectorLL(0)%blocks(i,1)%matrix(ii,jj)=RandomVectors_InOutput(4)%vector(ii+k,jj)
                enddo
            enddo
            !$omp end parallel do
            k=k+mm
        enddo 
        
        do level=0, level_butterfly
            if (level==0) then
                num_groupm=num_blocks
                allocate (random%RandomVectorLL(1)%blocks(num_groupm,1))
                random%RandomVectorLL(1)%num_row=num_groupm
                random%RandomVectorLL(1)%num_col=1
                do i=1, num_groupm
                    rank=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,2)
                    mm=size(butterfly_block_randomized(1)%ButterflyU(i)%matrix,1)
                    allocate (random%RandomVectorLL(1)%blocks(i,1)%matrix(rank,num_vectors))
                    !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do ii=1, rank
                        do jj=1, num_vectors
                            ctemp=0
                            do kk=1, mm
                                ctemp=ctemp+butterfly_block_randomized(1)%ButterflyU(i)%matrix(kk,ii)*random%RandomVectorLL(0)%blocks(i,1)%matrix(kk,jj)
                            enddo
                            random%RandomVectorLL(1)%blocks(i,1)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    !$omp end parallel do
                enddo  

            else
                num_groupm=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_row
                num_groupn=butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%num_col
                if (num_groupm/=1) then
                    allocate (random%RandomVectorLL(level+1)%blocks(int(num_groupm/2),num_groupn))
                    random%RandomVectorLL(level+1)%num_row=int(num_groupm/2)
                    random%RandomVectorLL(level+1)%num_col=num_groupn                 
                    do j=1, num_groupn
                        index_j=int((j+1)/2)
                        do i=1, num_groupm, 2
                            index_i=int((i+1)/2)
                            mm1=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,1)
                            mm2=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix,1)
                            nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix,2)
                            allocate (random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(nn,num_vectors))
                            !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                            do jj=1, nn
                                do ii=1, num_vectors
                                    ctemp=0
                                    do kk=1, mm1
                                        ctemp=ctemp+random%RandomVectorLL(level)%blocks(i,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i,j)%matrix(kk,jj)
                                    enddo
                                    do kk=1, mm2
                                        ctemp=ctemp+random%RandomVectorLL(level)%blocks(i+1,index_j)%matrix(kk,ii)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(i+1,j)%matrix(kk,jj)
                                    enddo
                                    random%RandomVectorLL(level+1)%blocks(index_i,j)%matrix(jj,ii)=ctemp
                                enddo
                            enddo
                            !$omp end parallel do
                        enddo
                    enddo
                else
                    allocate (random%RandomVectorLL(level+1)%blocks(1,num_groupn))
                    random%RandomVectorLL(level+1)%num_row=1
                    random%RandomVectorLL(level+1)%num_col=num_groupn
                    do j=1, num_groupn
                        index_j=int((j+1)/2)
                        nn=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix,2)
                        mm=size(butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix,1)
                        allocate (random%RandomVectorLL(level+1)%blocks(1,j)%matrix(nn,num_vectors))
                        !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                        do ii=1, nn
                            do jj=1, num_vectors
                                ctemp=0                           
                                do kk=1, mm
                                    ctemp=ctemp+random%RandomVectorLL(level)%blocks(1,index_j)%matrix(kk,jj)*butterfly_block_randomized(1)%ButterflyKerl(level_butterfly-level+1)%blocks(1,j)%matrix(kk,ii)
                                enddo
                                random%RandomVectorLL(level+1)%blocks(1,j)%matrix(ii,jj)=ctemp
                            enddo
                        enddo
                        !$omp end parallel do
                    enddo
                endif
            endif
            if (level==level_butterfly) then
                allocate (random%RandomVectorLL(level+2)%blocks(1,num_blocks))
                random%RandomVectorLL(level+2)%num_row=1
                random%RandomVectorLL(level+2)%num_col=num_blocks
                do j=1, num_blocks
                    nn=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,1)
                    rank=size(butterfly_block_randomized(1)%ButterflyV(j)%matrix,2)
                    allocate (random%RandomVectorLL(level+2)%blocks(1,j)%matrix(nn,num_vectors))
                    !$omp parallel do default(shared) private(ii,jj,kk,ctemp)
                    do ii=1, nn
                        do jj=1, num_vectors
                            ctemp=0
                            do kk=1, rank
                                ctemp=ctemp+random%RandomVectorLL(level+1)%blocks(1,j)%matrix(kk,jj)*butterfly_block_randomized(1)%ButterflyV(j)%matrix(ii,kk)
                            enddo
                            random%RandomVectorLL(level+2)%blocks(1,j)%matrix(ii,jj)=ctemp
                        enddo
                    enddo
                    !$omp end parallel do
                enddo
            endif
        enddo
        
        k=0
        do i=1, num_blocks
            nn=size(butterfly_block_randomized(1)%butterflyV(i)%matrix,1)
            !$omp parallel do default(shared) private(ii,jj)
            do ii=1, nn
                do jj=1, num_vectors
                    random%RandomVectorLL(level_butterfly+2)%blocks(1,i)%matrix(ii,jj)=RandomVectors_InOutput(6)%vector(ii+k,jj)
                enddo
            enddo
            !$omp end parallel do
            k=k+nn
        enddo 
    
    endif
    
    return
    
end subroutine butterfly_block_MVP_inlitialize_randomized 


subroutine check_results(blocks3,chara,blocks1,blocks2)

    use MODULE_FILE
    implicit none
    
    integer blocks1, blocks2, blocks3, mm, nn, mn
    integer i, ii, j, jj, k, kk, group_m, group_n, header_m, header_n
    complex(kind=8) ctemp1, ctemp2, ctemp3, ctemp4
    real*8 rtemp
    character chara
    
    !write(*,*) 'Butterfly addition multiplication test: block', blocks3
    
    group_m=matrices_block(blocks3,0)%col_group
    group_n=matrices_block(blocks3,0)%row_group
    header_m=basis_group(group_m)%head
    header_n=basis_group(group_n)%head
    mm=basis_group(group_m)%tail-header_m+1
    nn=basis_group(group_n)%tail-header_n+1
    group_n=matrices_block(blocks1,0)%row_group   
    header_n=basis_group(group_n)%head
    mn=basis_group(group_n)%tail-header_n+1
    
    do k=1, 10
         call random_number(rtemp)
         ii=int(rtemp*mm)+1
         call random_number(rtemp)
         jj=int(rtemp*nn)+1
         call Butterfly_value(ii,jj,matrices_block(blocks3,0),ctemp3)
         ctemp4=0
         !$omp parallel do default(shared) private(kk,ctemp1,ctemp2) reduction(+:ctemp4)
         do kk=1, mn
             call Butterfly_value(ii,kk,matrices_block(blocks1,0),ctemp1)
             call Butterfly_value(jj,kk,matrices_block(blocks2,0),ctemp2)
             ctemp4=ctemp4+ctemp1*ctemp2
         enddo
         !$omp end parallel do
         if(chara=='+') then
             ctemp3=ctemp3+ctemp4
         else
             ctemp3=ctemp3-ctemp4
         endif
         ctemp1=ctemp3
         call Butterfly_value_randomized(ii,jj,ctemp2)
         write(*,*) blocks3, ii, jj, abs(ctemp1-ctemp2)/abs(ctemp1), abs(ctemp1-ctemp2)/abs(ctemp2)
         pause
     enddo
    
    return

end subroutine check_results




subroutine Initialize_Bplus_FromInput(Bplus)
	use misc
    use MODULE_FILE
	! use lapack95
	! use blas95
    implicit none
    
    integer level_c,rowblock
	integer i,j,k,level,num_blocks,blocks3,num_row,num_col,ii,jj,kk,level_butterfly, mm, nn
    integer dimension_rank, dimension_m, dimension_n, blocks, groupm, groupn,tmpi,tmpj
    real*8 a,b,c,d
    complex (kind=8) ctemp
	complex (kind=8), allocatable::matrixtemp1(:,:),UU(:,:),VV(:,:)
	real*8, allocatable:: Singular(:)
	integer mn_min,index_i,index_j,blocks_idx
	type(matrixblock)::block
	type(blockplus)::Bplus
	integer seed_myid(2)
	integer time(8)
	integer ll,bb
	integer:: level_BP,levelm,groupm_start,Nboundall	
	
	
	allocate(Bplus_randomized(1))
	
	Bplus_randomized(1)%level = Bplus%level
	Bplus_randomized(1)%col_group = Bplus%col_group
	Bplus_randomized(1)%row_group = Bplus%row_group
	Bplus_randomized(1)%Lplus = Bplus%Lplus
	Bplus_randomized(1)%boundary = Bplus%boundary
	
	allocate(Bplus_randomized(1)%LL(LplusMax))
	

	! Bplus_randomized(1)%LL(1)%Nbound = 1
	! allocate(Bplus_randomized(1)%LL(1)%matrices_block(1))
	! Bplus_randomized(1)%LL(1)%matrices_block(1)%level = Bplus_randomized(1)%level
	! Bplus_randomized(1)%LL(1)%matrices_block(1)%col_group = Bplus_randomized(1)%col_group
	! Bplus_randomized(1)%LL(1)%matrices_block(1)%row_group = Bplus_randomized(1)%row_group			
	! Bplus_randomized(1)%LL(1)%matrices_block(1)%style = Bplus%LL(1)%matrices_block(1)%style
	allocate(Bplus_randomized(1)%LL(1)%boundary_map(1))
	Bplus_randomized(1)%LL(1)%boundary_map(1) = Bplus%LL(1)%boundary_map(1)
	
	do ll=1,LplusMax
	Bplus_randomized(1)%LL(ll)%Nbound = 0
	end do	
	
	do ll=1,LplusMax-1
		if(Bplus%LL(ll)%Nbound>0)then

			Bplus_randomized(1)%LL(ll)%rankmax = Bplus%LL(ll)%rankmax
			Bplus_randomized(1)%LL(ll)%Nbound = Bplus%LL(ll)%Nbound
			allocate(Bplus_randomized(1)%LL(ll)%matrices_block(Bplus_randomized(1)%LL(ll)%Nbound))
			
			do bb =1,Bplus_randomized(1)%LL(ll)%Nbound
				Bplus_randomized(1)%LL(ll)%matrices_block(bb)%row_group = Bplus%LL(ll)%matrices_block(bb)%row_group
				Bplus_randomized(1)%LL(ll)%matrices_block(bb)%col_group = Bplus%LL(ll)%matrices_block(bb)%col_group
				Bplus_randomized(1)%LL(ll)%matrices_block(bb)%style = Bplus%LL(ll)%matrices_block(bb)%style
				Bplus_randomized(1)%LL(ll)%matrices_block(bb)%level = Bplus%LL(ll)%matrices_block(bb)%level
			end do
			
			
			if(Bplus%LL(ll+1)%Nbound==0)then		
				Bplus_randomized(1)%LL(ll+1)%Nbound=0
			else 
				level_butterfly = int((Maxlevel_for_blocks - Bplus%LL(ll)%matrices_block(1)%level)/2)*2 
				! level_butterfly = 0 !!! only lowrank																			   
				level_BP = Bplus%level
				levelm = ceiling_safe(dble(level_butterfly)/2d0)						
				groupm_start=Bplus%LL(ll)%matrices_block(1)%row_group*2**levelm		
				Nboundall = 2**(Bplus%LL(ll)%matrices_block(1)%level+levelm-level_BP)				
				
				
				allocate(Bplus_randomized(1)%LL(ll+1)%boundary_map(Nboundall))
				! write(*,*)shape(Bplus%LL(ll+1)%boundary_map),shape(Bplus_randomized(1)%LL(ll+1)%boundary_map),'didi',ll
				Bplus_randomized(1)%LL(ll+1)%boundary_map = Bplus%LL(ll+1)%boundary_map
			end if
		
		
		else 
			exit
		end if

	end do
	
    return

end subroutine Initialize_Bplus_FromInput

 

end module Utilites_randomized
