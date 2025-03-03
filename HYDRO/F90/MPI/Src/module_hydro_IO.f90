!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! module_hydro_IO.f90 --- 
!!!!
!! subroutine read_params
!! subroutine output 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module hydro_IO

contains

subroutine read_params
  use hydro_parameters !contains MPI vars
  use mladen
  use mpi
  implicit none

  ! Local variables
  integer(kind=prec_int) :: narg,iargc
  character(LEN=80) :: infile
  character(LEN=80) :: message

  ! Namelists
  namelist/run/nstepmax,tend,noutput,on_output
  namelist/mesh/nx,ny,dx,boundary_left,boundary_right,boundary_down,boundary_up, &
                idimbloc,jdimbloc
  namelist/hydro/gamma,courant_factor,smallr,smallc,niter_riemann, &
                 iorder,scheme,slope_type

  narg = iargc()
  IF(narg .NE. 1)THEN
     print*, ' You should type: a.out input.nml'
     print*, ' File input.nml should contain a parameter namelist'
     STOP
  END IF
  CALL getarg(1,infile)
  open(1,file=infile)
  read(1,NML=run)
  read(1,NML=mesh)
  read(1,NML=hydro)
  close(1)
  

  !! INITIATE MPI
  call MPI_INIT(exitcode)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, exitcode)
  call MPI_COMM_RANK(MPI_COMM_WORLD, myid, exitcode)
  myid = myid+1

if (on_output) then
  call writetoscreen('#################################')
  call writetoscreen('######      HYDRO CODE     ######')
  call writetoscreen('#################################')

  !other init stuff
  call makedir('hydro_output')
  call MPI_BARRIER(MPI_COMM_WORLD, exitcode)
  ! so that no file will start writing into a directory that doesn't exist yet
end if

end subroutine read_params


subroutine output
  use hydro_commons
  use hydro_parameters
  use mladen
  implicit none

  ! Local variables
  character(LEN=80) :: filename
  character(LEN=5)  :: char,charpe
  integer(kind=prec_int) :: nout
  character(len=100) :: message

  nout=nstep/noutput
  call title(nout,char)
  call title(myid,charpe)
  filename='hydro_output/output_'//TRIM(char)//'.'//TRIM(charpe)
  open(10,file=filename,form='unformatted')
  rewind(10)
  !write(*, *) 'Outputting array of size=',imax-imin-3,jmax-jmin-3,nvar
  call writetoscreen("Writing output.")
  write(10)real(t,kind=prec_output),real(gamma,kind=prec_output)
  write(10) imax-imin-3,jmax-jmin-3,nvar,nstep
  write(10)real(uold(imin+2:imax-2,jmin+2:jmax-2,1:nvar),kind=prec_output)
  close(10)

contains

subroutine title(n,nchar)
  use hydro_precision
  implicit none

  integer(kind=prec_int), intent(in) :: n
  character(LEN=5), intent(out) :: nchar
  character(LEN=1) :: nchar1
  character(LEN=2) :: nchar2
  character(LEN=3) :: nchar3
  character(LEN=4) :: nchar4
  character(LEN=5) :: nchar5

  if(n.ge.10000)then
     write(nchar5,'(i5)') n
     nchar = nchar5
  elseif(n.ge.1000)then
     write(nchar4,'(i4)') n
     nchar = '0'//nchar4
  elseif(n.ge.100)then
     write(nchar3,'(i3)') n
     nchar = '00'//nchar3
  elseif(n.ge.10)then
     write(nchar2,'(i2)') n
     nchar = '000'//nchar2
  else
     write(nchar1,'(i1)') n
     nchar = '0000'//nchar1
  endif
end subroutine title

end subroutine output

end module hydro_IO
