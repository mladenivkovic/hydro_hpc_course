!!! MODULE MLADEN
!subroutine writetoscreen
!subroutine makedir
!subroutine communicate_boundaries
!
!
!
module mladen


contains 

subroutine writetoscreen(message)
    use hydro_parameters, only: myid
    implicit none
    character(len=*), intent(in), optional :: message
    
    if(myid==1) then
        if(present(message)) then
            if (len(message) /= 0) then
                write(6, '(A)') message
            end if
        else
            write(6, '(A)') "You left no specific message."
        end if

    end if
end subroutine writetoscreen


!#####################################
!#####################################
!#####################################
!#####################################




subroutine makedir(dirname)
!create a directory.
    use hydro_parameters, only: myid
    implicit none
    character(len=*), intent(in) :: dirname
    character(30) :: cmnd

    if (myid==1) then

        cmnd = 'mkdir -p '//TRIM(dirname)
        call system(cmnd)
        call writetoscreen(' Created output directory '//TRIM(dirname))

    end if
end subroutine makedir




subroutine communicate_boundaries_x()
    use hydro_commons
    use hydro_parameters
    use mpi
    implicit none

    real(kind=prec_real), dimension(1:2, jmin+2:jmax-2, 1:nvar) :: ghostcells_left, ghostcells_right, cells_receive_start, cells_receive_end, cells_send_start, cells_send_end
    integer :: x, y, z, code
    integer, dimension(MPI_STATUS_SIZE) :: status
    character(len=10000) :: filename
!    write(*, *) " Entered communicate_boundaries. myid ", myid
    ghostcells_left = 0 
    ghostcells_right = 0
    cells_receive_start = 0
    cells_receive_end = 0
    cells_send_start=0
    cells_send_end=0
    !domain start=imin+2
    !domain end=imax-2

    !if(myid==1) write(*, *) "PRINTING UOLD 1"
    do x = 0, 1
        do y = jmin+2, jmax-2
            do z = 1, nvar
                !copy all ghost cells left of the domain
                !if (myid /= 1) ghostcells_left(x+1,y,z) = uold(imin+x,y,z)
                
                !copy all cells at the start of the domain
                if (myid /= 1) cells_send_start(x+1,y,z)=uold(imin+2+x,y,z)

                !copy all ghost cells right of the domain
                !if (myid /= nproc) ghostcells_right(x+1,y,z) = uold(imax-1+x,y,z)

                if (myid /= nproc) cells_send_end(x+1,y,z)=uold(imax-3+x,y,z)
     !           if (myid == 1) write(*, *) uold(imax-1+x,y,z)
            end do
        end do
    end do
      
    !if(myid==2) then
    !write(*, *) "PRINTING UOLD 2"
    !do x = 0, 1
    !    do y = jmin+2, jmax-2
    !        do z = 1, nvar
    !            write(*, *) uold(imin+x,y,z)
    !        end do
    !    end do
    !end do  
    !end if
!write(*, *) "  ghost arrays assigned. myid ", myid



    ! WARNING! MYID = RANK + 1 !!!!!
    ! send cells right of domain, receive ghost cells that go into
    ! end of domain
    if (myid /= nproc) then 
        call MPI_SENDRECV(uold(imax-3,1,1), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid, 100, uold/imax-1, 1, 1), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid, 200, MPI_COMM_WORLD, status, code)
    end if


    ! send cells left of domain, receive ghost cells that go into
    ! start of domain
    if (myid /= 1) then
        call MPI_SENDRECV(cells_send_start(1:2, jmin+2:jmax-2, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid-2, 200, ghostcells_left(1:2, jmin+2:jmax-2, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid-2, 100, MPI_COMM_WORLD, status, code)
    end if


    ! sum up new cells with old cells
!write(*, *) "    summing up communicated stuff. myid ", myid
    do x = 0, 1
        do y = jmin+2, jmax-2
            do z = 1, nvar
                !uold(imin+2+x,y,z) = uold(imin+2+x,y,z) + cells_receive_start(x+1,y,z)
                !uold(imax-3+x,y,z) = uold(imax-3+x,y,z) + cells_receive_end(x+1,y, z)
                uold(imin+x,y,z) = ghostcells_left(x+1,y,z)
                uold(imax-1+x,y,z) = ghostcells_right(x+1,y, z)
            end do
        end do
    end do



end subroutine communicate_boundaries_x


subroutine reset_boundaries(boundary)
    ! 1: left
    ! 2: right
    ! 3: upper
    ! 4: lower
    use hydro_parameters
    use hydro_commons
    use hydro_const
    implicit none
    integer, intent(in) :: boundary
    integer :: i, j

  ! initiate ghost cells as 0 

if (boundary == 4) then
! lower boundary
  do j=jmin, jmin+1
    do i=imin+2, imax-2
      uold(i,j,ID)=0.0
      uold(i,j,IU)=0.0
      uold(i,j,IV)=0.0
      uold(i,j,IP)=0.0
    end do
  end do

else if (boundary==3) then
  ! upper boundary
  do j=jmax-1, jmax
    do i=imin+2, imax-2
      uold(i,j,ID)=0.0
      uold(i,j,IU)=0.0
      uold(i,j,IV)=0.0
      uold(i,j,IP)=0.0
    end do
  end do

else if (boundary==2) then
  !right boundary
  do j=jmin+2, jmax-2
    do i=imax-1, imax
      uold(i,j,ID)=0.0
      uold(i,j,IU)=0.0
      uold(i,j,IV)=0.0
      uold(i,j,IP)=0.0
    end do
  end do

else if(boundary==1) then
  !left boundary
  do j=jmin, jmin+1
    do i=imin, imin+1
      uold(i,j,ID)=0.0
      uold(i,j,IU)=0.0
      uold(i,j,IV)=0.0
      uold(i,j,IP)=0.0
    end do
  end do

end if





end subroutine reset_boundaries



subroutine makewall(boundary)
! 1: left
! 2: right

    use hydro_parameters
    use hydro_commons
    use hydro_const
    implicit none
    integer, intent(in) :: boundary
    integer :: i, j, ivar, sign

! make left wall
if (boundary==1) then

    do ivar=1,nvar
        do i=1,2
            sign=1.0
            if (ivar==IU)sign=-1.0
            do j=jmin+2, jmax-2
                uold(i+imin-1, j, ivar)=uold(5-i+imin-1, j, ivar)*sign
            end do
        end do
    end do
end if


!make right wall
if (boundary==2) then

    do ivar=1, nvar
        do i=1,2
            sign=1.0
            if(ivar==IU)sign=-1.0
            do j=jmin+2, jmax-2
                uold(imax-2+i,j, ivar)=uold(imax-1-i,j,ivar)*sign
            end do
        end do
    end do
end if

end subroutine makewall
end module mladen
