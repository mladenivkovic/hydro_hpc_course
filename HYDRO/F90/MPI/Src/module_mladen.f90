! #### module_mladen.f90
! subroutine writetoscreen              11
! subroutine makedir                    29
! subroutine communicate_boundaries     46
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


subroutine communicate_boundaries(id, nextid, sendbuf, recvbuf)
    ! nextid = 1 for sending right values as left boundaries,
    ! nextid = -1 for sending left values as right boundaries
    use hydro_commons ! uold, imin, imax...
    use hydro_parameters ! MPI vars
    use mpi
    implicit none
    integer, intent(in) :: id, nextid
    real(kind=prec_real), dimension(1:2, jmin:jmax, 1:nvar), intent(in) :: sendbuf
    real(kind=prec_real), dimension(1:2, jmin:jmax, 1:nvar), intent(out) :: recvbuf

    integer, dimension( MPI_STATUS_SIZE):: mpi_status_mladen
    integer :: proc_id, tag=100

    if (myid == id .or. myid == id + nextid) then
        proc_id = id -1 ! since myid = myid+1

        call MPI_RECV(recvbuf, 1, type_subarray, proc_id, tag, MPI_COMM_WORLD, exitcode)
        call MPI_SEND(sendbuf, 1, type_subarray, proc_id+nextid, tag, MPI_COMM_WORLD, exitcode)

        !call MPI_SENDRECV(sendbuf, 2*jmax*nvar, MPI_DOUBLE_PRECISION, proc_id+nextid, tag, recvbuf, 2*jmax*nvar, type_subarray, tag, MPI_COMM_WORLD, mpi_status_mladen, exitcode)

        ! communicator type_subarray is built with subroutine
        ! build_communicator.
        ! It is called in init_hydro in module_hydro_principal.f90.
        !call MPI_SENDRECV(sendbuf, 1, type_subarray, proc_id+nextid, tag, recvbuf, 1, type_subarray, tag, MPI_COMM_WORLD, mpi_status_mladen, exitcode)

    end if


end subroutine communicate_boundaries





subroutine build_communicator() ! called in subroutine hydro_init in module_hydro_principal

    use hydro_commons ! uold, imin, imax...
    use hydro_parameters ! MPI vars
    use mpi
    implicit none

    !integer, dimension( MPI_STATUS_SIZE):: status
    integer, dimension(3) :: shape_array, shape_subarray, start_coord
    integer, dimension(3) :: start_coord_righttoleft, start_coord_lefttoright
    integer, parameter :: tag = 100
    integer :: proc_id

    shape_array(:) = (/2, jmax, nvar /)
    shape_subarray(:) = (/2, jmax, nvar /) ! von jeder Zeile 2 Spalten
    !start_coord_lefttoright(:) = (/imax-4, 0, 0/)
    !start_coord_righttoleft(:) = (/2, 0, 0/)
    start_coord(:) = (/0, 0, 0 /)
    !!! ATTENTION!!!!
    ! the start_coord(:) array contains the indexes that MPI_TYPE_CREATE_SUBARRAY
    ! needs. BUT: Fortran usually starts with index 1, this MPI subroutine 
    ! starts with index 0 !!!!

    !call MPI_TYPE_CREATE_SUBARRAY(3, shape_array, shape_subarray, start_coord_righttoleft, MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, type_subarray_sendrighttoleft, exitcode)
    !call MPI_TYPE_COMMIT(type_subarray_sendrighttoleft, exitcode)

    !call MPI_TYPE_CREATE_SUBARRAY(3, shape_array, shape_subarray, start_coord_righttoleft, MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, type_subarray_sendlefttoright, exitcode)
    !call MPI_TYPE_COMMIT(type_subarray_sendlefttoright, exitcode)
    
    call MPI_TYPE_CREATE_SUBARRAY(3, shape_array, shape_subarray, start_coord_righttoleft, MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, type_subarray, exitcode)
    call MPI_TYPE_COMMIT(type_subarray, exitcode)
    
    call writetoscreen(' Communicator built.')
end subroutine build_communicator
end module mladen
