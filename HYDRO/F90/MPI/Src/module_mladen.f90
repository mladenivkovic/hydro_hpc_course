!!! MODULE MLADEN
!subroutine writetoscreen
!subroutine makedir
!subroutine communicate_boundaries_x
!subroutine makewall
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



!#####################################
!#####################################
!#####################################
!#####################################


subroutine writeruninfo()
! writes infos of the run to file. Needed to make movies properly.
    use hydro_parameters
    implicit none
    
    if (myid==1) then
        open(10, file='hydro_output/hydro_runinfo.txt', form='formatted')
        write(10, '(A1, 3A8)') "#", "nx", "ny", "nproc"
        write(10, '(x, 3I8)') nx, ny, nproc
        close(10)
    end if


end subroutine writeruninfo





!#####################################
!#####################################
!#####################################
!#####################################



subroutine communicate_boundaries_x()
    use hydro_commons
    use hydro_parameters
    use mpi
    implicit none

    integer :: x, y, z, code
    integer, dimension(MPI_STATUS_SIZE) :: status

    !domain start=imin+2
    !domain end=imax-2

 
    ! WARNING! MYID = RANK + 1 !!!!!
    ! send cells right of domain, receive ghost cells that go into
    ! end of domain
    if (myid /= nproc) then 
        call MPI_SENDRECV(uold(imax-3:imax-2,jmin:jmax,1:nvar), 2*(ny+4)*nvar, MPI_DOUBLE_PRECISION, myid, 100, uold(imax-1:imax,jmin:jmax,1:nvar), 2*(ny+4)*nvar, MPI_DOUBLE_PRECISION, myid, 200, MPI_COMM_WORLD, status, code)
    end if


    ! send cells left of domain, receive ghost cells that go into
    ! start of domain
    if (myid /= 1) then
        call MPI_SENDRECV(uold(imin+2:imin+3,jmin:jmax,1:nvar), 2*(ny+4)*nvar, MPI_DOUBLE_PRECISION, myid-2, 200, uold(imin:imin+1,jmin:jmax,1:nvar), 2*(ny+4)*nvar, MPI_DOUBLE_PRECISION, myid-2, 100, MPI_COMM_WORLD, status, code)
    end if


end subroutine communicate_boundaries_x


!#####################################
!#####################################
!#####################################
!#####################################




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
