!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! module_hydro_principal.f90 --- 
!!!!
!! subroutine init_hydro
!! subroutine cmpdt(dt)
!! subroutine godunov(idim,dt)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module hydro_principal

contains

subroutine init_hydro
  use hydro_commons
  use hydro_const
  use hydro_parameters
  use mladen
  use mpi
  implicit none

  ! Local variables
  integer(kind=prec_int) :: i,j
  integer(kind=prec_int) :: domainwidth_x, domainwidth_y

  !get best value for processors in x and y direction
  call distribute_processors(nproc_x, nproc_y) !module_mladen
  call writeruninfo() !module_mladen

  !get processor map /get neighbours
  call create_procmap()

  !do i = 1, nproc
    !if (myid==i) then
    !write(*, *) "Myid", myid
    !write(*, *) "leftofme", leftofme, "rightofme", rightofme
    !write(*, *) "above me", aboveme, "below me", belowme
    !write(*, *)
    !end if
    !call MPI_BARRIER(MPI_COMM_WORLD, exitcode)
  !end do

  allocate(imin_global(1:nproc_x), imax_global(1:nproc_x), jmin_global(1:nproc_y), jmax_global(1:nproc_y))

  !distribute processors optimally  along the domain: 
  ! Assigning indices imin, imax, jmin, jmax to all processors.
  ! First get "mean domain width" by division, then fill up
  ! unassigned cells to processors starting with the last one.
  domainwidth_x = nx/nproc_x
  domainwidth_y = ny/nproc_y

  do i=1, nproc_x
      imax_global(i) = domainwidth_x * i + 4
      imin_global(i) = 1 + domainwidth_x * (i-1)
  end do

  do j=1, nproc_y
    jmin_global(j) =1 + domainwidth_y*(j-1)
    jmax_global(j) =domainwidth_y*j + 4
  end do

! if there is rest of the division, distribute 1 row of cells per processor starting with the last processor row resp. column
  if(mod(nx, nproc_x) /= 0) then
    do i = 0, mod(nx, nproc_x)-1
      imax_global(nproc_x - i) = imax_global(nproc_x - i) + mod(nx, nproc_x) - i
      imin_global(nproc_x - i) = imin_global(nproc_x - i) + mod(nx, nproc_x) - 1 - i
    end do
  end if

  if(mod(ny, nproc_y) /= 0) then
    do i = 0, mod(nx, nproc_y)-1
      jmax_global(nproc_y - i) = jmax_global(nproc_y - i) + mod(nx, nproc_y) - i
      jmin_global(nproc_y - i) = jmin_global(nproc_y - i) + mod(nx, nproc_y) - 1 - i
    end do
  end if

  do i=1, nproc_x
    do j=1, nproc_y
      if(myid==i+(j-1)*nproc_x) then
        imin=imin_global(i)
        imax=imax_global(i)
        jmin=jmin_global(j)
        jmax=jmax_global(j)
      end if
    end do
  end do


  !write(*, *) "id", myid, "w", width, totalwidth, "h", height, totalheight
  !allocate(uold(1:nx+4, 1:ny+4, 1:nvar))

  allocate(uold(imin:imax, jmin:jmax, 1:nvar))

  ! Initial conditions in grid interior
  ! Warning: conservative variables U = (rho, rhou, rhov, E)
  ! rho: density
  ! rhov: density * velocity_v
  ! rhou: density * velocity_u
  ! E: Energy (temperature, pressure...)


!!$  ! Jet
!!$  do j=jmin+2,jmax-2
!!$     do i=imin+2,imax-2
!!$        uold(i,j,ID)=1.0
!!$        uold(i,j,IU)=0.0
!!$        uold(i,j,IV)=0.0
!!$        uold(i,j,IP)=1.0/(gamma-1.0)
!!$     end do
!!$  end do

  ! Wind tunnel with point explosion
  ! Initiating array uold except the border 
  do j=jmin+2,jmax-2
     do i=imin+2,imax-2
        uold(i,j,ID)=1.0
        uold(i,j,IU)=0.0
        uold(i,j,IV)=0.0
        uold(i,j,IP)=1.d-5
     end do
  end do



  ! initiating primary "bang"
  if (myid==1) uold(imin+2,jmin+2,IP)=1./dx/dx



!!$  ! 1D Sod test
!!$  do j=jmin+2,jmax-2
!!$     do i=imin+2,imax/2
!!$        uold(i,j,ID)=1.0
!!$        uold(i,j,IU)=0.0
!!$        uold(i,j,IV)=0.0
!!$        uold(i,j,IP)=1.0/(gamma-1.0)
!!$     end do
!!$     do i=imax/2+1,imax-2
!!$        uold(i,j,ID)=0.125
!!$        uold(i,j,IU)=0.0
!!$        uold(i,j,IV)=0.0
!!$        uold(i,j,IP)=0.1/(gamma-1.0)
!!$     end do
!!$  end do

end subroutine init_hydro


subroutine cmpdt(dt)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  use hydro_utils
  implicit none

  ! Dummy arguments
  real(kind=prec_real), intent(out) :: dt  
  ! Local variables
  integer(kind=prec_int) :: i,j
  real(kind=prec_real)   :: cournox,cournoy,eken
  real(kind=prec_real),  dimension(:,:), allocatable   :: q
  real(kind=prec_real),  dimension(:)  , allocatable   :: e,c

  ! compute time step on grid interior
  cournox = zero
  cournoy = zero

  allocate(q(imin:imax,1:IP),e(imin:imax),c(imin:imax))
  !allocate( q(imin:imax, 1:IP), e(imin:imax), c(imin:imax))
  do j=jmin+2,jmax-2
     do i=imin, imax-4
        q(i,ID) = max(uold(i+2,j,ID),smallr) ! take the bigger of the two -> so that the density doesn't surpass a minimal value "smallr"
        q(i,IU) = uold(i+2,j,IU)/q(i,ID) !calculate velocities: rho*v/rho
        q(i,IV) = uold(i+2,j,IV)/q(i,ID)
        eken = half*(q(i,IU)**2+q(i,IV)**2) ! calcualte kinetic energy
        q(i,IP) = uold(i+2,j,IP)/q(i,ID) - eken
        e(i)=q(i,IP)
     end do

     call eos(q(imin:imax,ID),e,q(imin:imax,IP),c)
     ! calculate pressure and speed of sound with equation of state.
     ! then calculate the time step according to the speed of sound
     ! so that the maximal movement is not larger than one cell.

     cournox=max(cournox,maxval(c(imin:imax)+abs(q(imin:imax,IU))))
     cournoy=max(cournoy,maxval(c(imin:imax)+abs(q(imin:imax,IV))))
  end do

  deallocate(q,e,c)

  dt = courant_factor*dx/max(cournox,cournoy,smallc) 
  !compute the actual minimal timestep.
end subroutine cmpdt


subroutine godunov(idim,dt)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  use hydro_utils
  use hydro_work_space
  implicit none

  ! Dummy arguments
  integer(kind=prec_int), intent(in) :: idim !in which dimensin (x or y) x= 1, y = 2
  real(kind=prec_real),   intent(in) :: dt
  ! Local variables
  integer(kind=prec_int) :: i,j,in
  real(kind=prec_real)   :: dtdx
  ! constant
  dtdx=dt/dx

  ! Update boundary conditions
  call make_boundary(idim)

  if (idim==1)then
     ! Allocate work space for 1D sweeps
     call allocate_work_space(imin,imax)

     do j=jmin+2,jmax-2
        ! Gather conservative variables
        do i=imin,imax
           u(i,ID)=uold(i,j,ID)
           u(i,IU)=uold(i,j,IU)
           u(i,IV)=uold(i,j,IV)
           u(i,IP)=uold(i,j,IP)
        end do
        if(nvar>4)then
           do in = 5,nvar
              do i=imin,imax
                 u(i,in)=uold(i,j,in)
              end do
           end do
        end if

 
        ! Convert to primitive variables
        call constoprim(u,q,c)


        ! Characteristic tracing
        call trace(q,dq,c,qxm,qxp,dtdx)

        do in = 1,nvar
           do i=imin, imax-3
              qleft (i,in)=qxm(i+1,in)
              qright(i,in)=qxp(i+2,in)
           end do
        end do


        ! Solve Riemann problem at interfaces
        call riemann(qleft,qright,qgdnv, &
                     rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
                     rstar,ustar,pstar,cstar,sgnm,spin,spout, &
                     ushock,frac,scr,delp,pold,ind,ind2)

        ! Compute fluxes
        ! based of the results of riemann()
        call cmpflx(qgdnv,flux)
 
        ! Update conservative variables 
        do i=imin+2, imax-2
           uold(i,j,ID)=u(i,ID)+(flux(i-2,ID)-flux(i-1,ID))*dtdx
           uold(i,j,IU)=u(i,IU)+(flux(i-2,IU)-flux(i-1,IU))*dtdx
           uold(i,j,IV)=u(i,IV)+(flux(i-2,IV)-flux(i-1,IV))*dtdx
           uold(i,j,IP)=u(i,IP)+(flux(i-2,IP)-flux(i-1,IP))*dtdx
        end do
        if(nvar>4)then
           do in = 5,nvar
              do i=imin+2,imax-2
                 uold(i,j,in)=u(i,in)+(flux(i-2,in)-flux(i-1,in))*dtdx
              end do
           end do
        end if
     end do

     ! Deallocate work space
     call deallocate_work_space

  else

     ! Allocate work space for 1D sweeps
     call allocate_work_space(jmin,jmax)

     do i=imin+2,imax-2
        ! Gather conservative variables
        do j=jmin,jmax
           u(j,ID)=uold(i,j,ID)
           u(j,IU)=uold(i,j,IV)
           u(j,IV)=uold(i,j,IU)
           u(j,IP)=uold(i,j,IP)
        end do
        if(nvar>4)then
           do in = 5,nvar
              do j=jmin,jmax
                 u(j,in)=uold(i,j,in)
              end do
           end do
        end if

        ! Convert to primitive variables
        call constoprim(u,q,c)

        ! Characteristic tracing
        call trace(q,dq,c,qxm,qxp,dtdx)

        do in = 1, nvar
           do j = jmin, jmax-3
              qleft (j,in)=qxm(j+1,in)
              qright(j,in)=qxp(j+2,in)
           end do
        end do

        ! Solve Riemann problem at interfaces
        call riemann(qleft,qright,qgdnv, &
                     rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
                     rstar,ustar,pstar,cstar,sgnm,spin,spout, &
                     ushock,frac,scr,delp,pold,ind,ind2)

        ! Compute fluxes
        call cmpflx(qgdnv,flux)

        ! Update conservative variables 
        do j=jmin+2,jmax-2
           uold(i,j,ID)=u(j,ID)+(flux(j-2,ID)-flux(j-1,ID))*dtdx
           uold(i,j,IU)=u(j,IV)+(flux(j-2,IV)-flux(j-1,IV))*dtdx
           uold(i,j,IV)=u(j,IU)+(flux(j-2,IU)-flux(j-1,IU))*dtdx
           uold(i,j,IP)=u(j,IP)+(flux(j-2,IP)-flux(j-1,IP))*dtdx
        end do
        if(nvar>4)then
           do in = 5,nvar
              do j=jmin+2,jmax-2
                 uold(i,j,in)=u(j,in)+(flux(j-2,in)-flux(j-1,in))*dtdx
              end do
           end do
        end if

      end do

     ! Deallocate work space
     call deallocate_work_space
  end if

contains

  subroutine allocate_work_space(ii1,ii2)
    implicit none

    ! Dummy arguments
    integer(kind=prec_int), intent(in) :: ii1,ii2

    allocate(u  (ii1:ii2,1:nvar))
    allocate(q  (ii1:ii2,1:nvar))
    allocate(dq (ii1:ii2,1:nvar))
    allocate(qxm(ii1:ii2,1:nvar))
    allocate(qxp(ii1:ii2,1:nvar))
    allocate(c  (ii1:ii2))
    allocate(qleft (ii1:ii2-3,1:nvar))
    allocate(qright(ii1:ii2-3,1:nvar))
    allocate(qgdnv (ii1:ii2-3,1:nvar))
    allocate(flux  (ii1:ii2-3,1:nvar))
    allocate(rl    (ii1:ii2-3), ul   (ii1:ii2-3), pl   (ii1:ii2-3), cl    (ii1:ii2-3))
    allocate(rr    (ii1:ii2-3), ur   (ii1:ii2-3), pr   (ii1:ii2-3), cr    (ii1:ii2-3))
    allocate(ro    (ii1:ii2-3), uo   (ii1:ii2-3), po   (ii1:ii2-3), co    (ii1:ii2-3))
    allocate(rstar (ii1:ii2-3), ustar(ii1:ii2-3), pstar(ii1:ii2-3), cstar (ii1:ii2-3))
    allocate(wl    (ii1:ii2-3), wr   (ii1:ii2-3), wo   (ii1:ii2-3))
    allocate(sgnm  (ii1:ii2-3), spin (ii1:ii2-3), spout(ii1:ii2-3), ushock(ii1:ii2-3))
    allocate(frac  (ii1:ii2-3), scr  (ii1:ii2-3), delp (ii1:ii2-3), pold  (ii1:ii2-3))
    allocate(ind   (ii1:ii2-3), ind2 (ii1:ii2-3))
  end subroutine allocate_work_space

  subroutine deallocate_work_space
    deallocate(u,q,dq,qxm,qxp,c,qleft,qright,qgdnv,flux)
    deallocate(rl,ul,pl,cl)
    deallocate(rr,ur,pr,cr)  
    deallocate(ro,uo,po,co)  
    deallocate(rstar,ustar,pstar,cstar)
    deallocate(wl,wr,wo)
    deallocate(sgnm,spin,spout,ushock)
    deallocate(frac,scr,delp,pold)
    deallocate(ind,ind2)    
  end subroutine deallocate_work_space

end subroutine godunov

end module hydro_principal
