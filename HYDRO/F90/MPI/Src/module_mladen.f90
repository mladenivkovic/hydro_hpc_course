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

    real(kind=prec_real), dimension(1:2, jmin:jmax, 1:nvar) :: ghostcells_send_left, ghostcells_send_right, cells_receive_left, cells_receive_right
    integer :: x, y, z, code, doublesize
    integer, dimension(MPI_STATUS_SIZE) :: status
    character(len=1) :: filename
!    write(*, *) " Entered communicate_boundaries. myid ", myid
    ghostcells_send_left = 0 
    ghostcells_send_right = 0
    cells_receive_left = 0
    cells_receive_right = 0
    
    !domain start=imin+2
    !domain end=imax-2


    do x = 1, 2
        do y = jmin, jmax
            do z = 1, nvar
                !copy all ghost cells left of the domain
                if (myid /= 1) ghostcells_send_left(x,y, z) = uold(imin + x, y, z)
                !copy all ghost cells right of the domain
                if (myid /= nproc) ghostcells_send_right(x,y, z) = uold(imax - 2 + x,y, z)
            end do
        end do
    end do
    
!write(*, *) "  ghost arrays assigned. myid ", myid


    !send ghostcells_send_left (ghost cells left of domain), receive cells of the domain that are left

    call MPI_SIZEOF(1.d0, doublesize, exitcode)
    ! WARNING! MYID = RANK + 1 !!!!!
    if (myid /= 1) then 
        call MPI_SENDRECV(ghostcells_send_left(1:2, jmin:jmax, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid-2, 100, cells_receive_left(1:2, jmin:jmax, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid-2, 200, MPI_COMM_WORLD, status, code)
    end if


    if (myid /= nproc) then
        call MPI_SENDRECV(ghostcells_send_right(1:2, jmin:jmax, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid, 200, cells_receive_right(1:2, jmin:jmax, 1:nvar), 2*ny*nvar, MPI_DOUBLE_PRECISION, myid, 100, MPI_COMM_WORLD, status, code)
    end if



    ! sum up new cells with old cells
!write(*, *) "    summing up communicated stuff. myid ", myid
    do x = 1, 2
        do y = jmin, jmax
            do z = 1, nvar
                uold(imin + 2 - 1 + x, y, z) = uold(imin + 2 - 1 + x, y, z) + cells_receive_left(x,y,z)
                uold(imax -2 + 1 - x, y, z) = uold(imax-2+1-x, y, z) + cells_receive_right(3-x,y, z)
            end do
        end do
    end do



end subroutine communicate_boundaries_x


end module mladen
