!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! main.f90 --- 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

program hydro_main
  use hydro_commons
  use hydro_parameters
  use hydro_IO
  use hydro_principal
  use mladen
  implicit none

  real(kind=prec_real)   :: dt, tps_elapsed, tps_cpu, t_deb, t_fin
  integer(kind=prec_int) :: nbp_init, nbp_final, nbp_max, freq_p,i,j

  ! Initialize clock counter
  ! system_clock and cpu_time are itrinistic fortran subroutines.
  call system_clock(count_rate=freq_p, count_max=nbp_max) 
  call system_clock(nbp_init)
  call cpu_time(t_deb)

  ! Read run parameters
  call read_params ! is in module_hydro_IO.f90

  ! Call my own subroutine
  call writetoscreen('It works!')


  ! Initialize hydro grid
  call init_hydro ! from module_hydro_principal.f90

  print *
  print *,' Starting time integration, nx = ',nx,' ny = ',ny  
  print *

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
     endif

     ! Directional splitting
     if(MOD(nstep,2)==0)then
        call godunov(1,dt) !module_hydro_principal.f90
        call godunov(2,dt)
     else
        call godunov(2,dt)
        call godunov(1,dt)
     end if

     nstep=nstep+1
     t=t+dt
     write(*,'("step=",I6," t=",1pe10.3," dt=",1pe10.3)')nstep,t,dt

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
  print *
  print *,'Temps CPU (s.)     : ',tps_cpu
  print *,'Temps elapsed (s.) : ',tps_elapsed
  print *
  
end program hydro_main
