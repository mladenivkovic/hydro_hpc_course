!!! MODULE MLADEN
!subroutine writetoscreen
!subroutine makedir
!subroutine writeruninfo()
!subroutine communicate_boundaries()
!subroutine makewall
!subroutine distribute_processors(nproc_x, nproc_y)
!real function calculate_communications(proc_x, proc_y)
!subroutine create_procmap()

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
        write(10, '(A1, 5A8)') "#", "nx", "ny", "nproc", "nproc_x", "nproc_y"
        write(10, '(x, 5I8)') nx, ny, nproc, nproc_x, nproc_y
        close(10)

        write(*,*)
        write(*, *) "Runinfo:"
        write(*, '(5A8)') "nx", "ny", "nproc", "nproc_x", "nproc_y"
        write(*, '(5I8)') nx, ny, nproc, nproc_x, nproc_y
        write(*,*)

    end if


end subroutine writeruninfo





!#####################################
!#####################################
!#####################################
!#####################################



subroutine communicate_boundaries(idim)
    use hydro_commons
    use hydro_parameters
    use mpi
    implicit none
    integer, intent(in) :: idim
    integer, dimension(MPI_STATUS_SIZE) :: status

    !domain start=imin+2
    !domain end=imax-2

 
if(idim==1) then !communicate boundaries in x direction

    ! WARNING! MYID = RANK + 1 !!!!!
    ! send cells right of domain, receive ghost cells that go into
    ! end of domain
    if (rightofme/=wall) then 
        call MPI_SENDRECV(uold(imax-3:imax-2,jmin:jmax,1:nvar), 2*(jmax-jmin+1)*nvar, MPI_DOUBLE_PRECISION, rightofme-1, 100, uold(imax-1:imax,jmin:jmax,1:nvar), 2*(jmax-jmin+1)*nvar, MPI_DOUBLE_PRECISION, rightofme-1, 200, MPI_COMM_WORLD, status, exitcode)
    end if


    ! send cells left of domain, receive ghost cells that go into
    ! start of domain
    if (leftofme/=wall) then
        call MPI_SENDRECV(uold(imin+2:imin+3,jmin:jmax,1:nvar), 2*(jmax-jmin+1)*nvar, MPI_DOUBLE_PRECISION, leftofme-1, 200, uold(imin:imin+1,jmin:jmax,1:nvar), 2*(jmax-jmin+1)*nvar, MPI_DOUBLE_PRECISION, leftofme-1, 100, MPI_COMM_WORLD, status, exitcode)
    end if





else    !communicate boudaries in y direction





    ! send cells on top of the domain, receive ghost cells that go 
    ! into top of domain
    if (aboveme/=wall) then 
        call MPI_SENDRECV(uold(imin:imax,jmax-3:jmax-2,1:nvar), 2*(imax-imin+1)*nvar, MPI_DOUBLE_PRECISION, aboveme-1, 100, uold(imin:imax,jmax-1:jmax,1:nvar), 2*(imax-imin+1)*nvar, MPI_DOUBLE_PRECISION, aboveme-1, 200, MPI_COMM_WORLD, status, exitcode)
    end if


    ! send cells at bottom of domain, receive ghost cells that go into
    ! bottom of domain
    if (belowme/=wall) then
        call MPI_SENDRECV(uold(imin:imax,jmin+2:jmin+3,1:nvar), 2*(imax-imin+1)*nvar, MPI_DOUBLE_PRECISION, belowme-1, 200, uold(imin:imax,jmin:jmin+1,1:nvar), 2*(imax-imin+1)*nvar, MPI_DOUBLE_PRECISION, belowme-1, 100, MPI_COMM_WORLD, status, exitcode)
    end if





end if

end subroutine communicate_boundaries


!#####################################
!#####################################
!#####################################
!#####################################




subroutine makewall(boundary)
! 1: left
! 2: right
! 3: upper
! 4: lower

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
                uold(i+imin-1, j, ivar)=uold(imin+4-i, j, ivar)*sign
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



!make upper wall
if (boundary==3) then
    do ivar=1, nvar
        do j=1,2
            sign=1.0
            if(ivar==IV)sign=-1.0
            do i=imin+2, imax-2
                uold(i,jmax-2+j,ivar)=uold(i,jmax-1-j,ivar)*sign
            end do
        end do
    end do
end if


!make lower wall
if (boundary==4) then
    do ivar=1, nvar
        do j=1,2
            sign=1.0
            if(ivar==IV)sign=-1.0
            do i=imin+2, imax-2
                uold(i,jmin+j-1,ivar)=uold(i,jmin+4-i,ivar)*sign
            end do
        end do
    end do
end if
end subroutine makewall



!#####################################
!#####################################
!#####################################
!#####################################



subroutine distribute_processors(nproc_x, nproc_y)
    use hydro_parameters
    implicit none
    integer, intent(out) :: nproc_x, nproc_y
    real, dimension(:), allocatable:: calcarray
    integer, dimension(:,:), allocatable :: procarray
    integer :: i, ind
    real :: mintime

    

    allocate(procarray(1:nproc, 1:2),calcarray(1:nproc))
    calcarray=0.0
    procarray=0

    do i = 1, nproc
        if( mod(nproc, i) == 0) then
            procarray(i, 1) = i
            procarray(i, 2) = nproc/i
            calcarray(i) = calculate_communications(i, nproc/i)
        end if
    end do

    mintime=calcarray(1)
    ind=1
    do i=1, nproc
        if (calcarray(i) /= 0.0) then
            if (mintime > calcarray(i)) then
            mintime=calcarray(i)
            ind=i
            end if
        end if
    end do

    nproc_x=procarray(ind,1)
    nproc_y=procarray(ind,2)

end subroutine distribute_processors



!#####################################
!#####################################
!#####################################
!#####################################





real function calculate_communications(proc_x, proc_y)
    use hydro_parameters
    implicit none
    integer, intent(in) :: proc_x, proc_y
    real :: domainsize_x, domainsize_y
    real :: talking_time
    real :: waiting_time
    integer :: communications
    domainsize_x = nx/proc_x
    domainsize_y = ny/proc_y

    communications = 4*nproc-2*(proc_x+proc_y) ! The number of communications

    talking_time = real(communications)/2 * real_datasize / communication_speed * (domainsize_x + domainsize_y)*nvar

    waiting_time = communications*lattency

    calculate_communications=talking_time + waiting_time


end function calculate_communications






!#####################################
!#####################################
!#####################################
!#####################################


subroutine create_procmap()

    use hydro_parameters
    implicit none
    integer :: i, j




 do i=1, nproc_x
        if (myid==i) aboveme=wall ! create upper wall
        if (myid==nproc-i+1) belowme=wall !create lower wall
        do j=1, nproc_y

            if (myid==1+(j-1)*nproc_x) leftofme=wall !create left wall
            if (myid==nproc_x+(j-1)*nproc_x) rightofme=wall !create right wall

            !get neighbours above
            if (j /= 1) then
                if (myid==i+(j-1)*nproc_x) aboveme=i+(j-2)*nproc_x 
            end if

            !get neighbours below
            if (j/=nproc_y) then 
                if (myid==i+(j-1)*nproc_x) belowme=i+j*nproc_x 
            end if

            !get neighbours to the right 
            if (i/=nproc_x) then
                if(myid==i+(j-1)*nproc_x) rightofme=i+1+(j-1)*nproc_x
            end if

            !get neightbours to the left
            if (i/=1) then
                if (myid==i+(j-1)*nproc_x) leftofme=i-1+(j-1)*nproc_x
            end if
        end do
    end do


end subroutine create_procmap

end module mladen
