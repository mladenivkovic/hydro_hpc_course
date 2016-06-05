!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! main.f90 --- 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

program hydro_main
  use hydro_commons
  use hydro_parameters ! contains MPI vars
  use hydro_IO
  use hydro_principal
  use mladen ! writetoscreen
  use mpi
  implicit none

  real(kind=prec_real)   :: dt, dt_sync, tps_elapsed, tps_cpu, t_deb, t_fin
  integer(kind=prec_int) :: nbp_init, nbp_final, nbp_max, freq_p,i,j
  character(len=100) :: message, c




  ! Initialize clock counter
  ! system_clock and cpu_time are itrinistic fortran subroutines.
  call system_clock(count_rate=freq_p, count_max=nbp_max) 
  call system_clock(nbp_init)
  call cpu_time(t_deb)

  ! Read run parameters
  call read_params ! is in module_hydro_IO.f90, initialise MPI

  ! Initialize hydro grid
  call init_hydro ! from module_hydro_principal.f90


  call writetoscreen(' ')
  if (myid==1) write(*, *) 'Starting time integration, nx = ',nx,' ny = ',ny  
  ! Main time loop
  do while (t < tend .and. nstep < nstepmax)

     ! Output results
     if( on_output .and. MOD(nstep,noutput)==0)then
        call output ! module_hydro_IO.f90
     end if

     ! Compute new time-step
     if(MOD(nstep,2)==0)then
        call cmpdt(dt) ! module_hydro_principal.f90
        if(nstep==0)dt=dt/2.
        call MPI_ALLREDUCE(dt, dt_sync, 1, MPI_DOUBLE_PRECISION, MPI_MIN, MPI_COMM_WORLD, exitcode )
     endif

     ! Directional splitting
     if(MOD(nstep,2)==0)then
        call godunov(1,dt_sync) !module_hydro_principal.f90
        call godunov(2,dt_sync)
     else
        call godunov(2,dt_sync)
        call godunov(1,dt_sync)
     end if

     nstep=nstep+1
     t=t+dt_sync
     if (myid==1) write(*, '(" step= ",I6,"   t= ",1pe10.3,"   dt=",1pe10.3)') nstep,t,dt_sync

  end do

  ! Final output
  if (on_output) call output ! module_hydro_IO.f90


  ! Timing
  call cpu_time(t_fin)
  call system_clock(nbp_final)
  tps_cpu=t_fin-t_deb
  if (nbp_final>nbp_init) then
     tps_elapsed=real(nbp_final-nbp_init)/real(freq_p)
  else
     tps_elapsed=real(nbp_final-nbp_init+nbp_max)/real(freq_p) 
  endif  
  
  if (myid==1) then
    write(*, '(A,F18.14)') 'CPU time (s.)     : ',tps_cpu 
    write(*, '(A,F18.14)') 'Time elapsed (s.) : ',tps_elapsed
  end if
  call MPI_FINALIZE(exitcode)
end program hydro_main
