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
  implicit none

  ! Local variables
  integer(kind=prec_int) :: i,j
  integer(kind=prec_int) :: domainwidth_x

  allocate(imin_global(1:nproc), imax_global(1:nproc), jmin_global(1:nproc), jmax_global(1:nproc))

  
  domainwidth_x = nx/nproc

  do i = 1, nproc
    imax_global(i) = domainwidth_x * i + 4
    imin_global(i) = 1 + domainwidth_x * (i-1)
    jmin_global(i) = 1
    jmax_global(i) = ny + 4
  end do

  if(mod(nx, nproc) /= 0) then
    do i = 0, mod(nx, nproc)-1
      imax_global(nproc - i) = imax_global(nproc - i) + mod(nx, nproc) - i
      imin_global(nproc - i) = imin_global(nproc - i) + mod(nx, nproc) - 1 - i
    end do
  end if
  

  imin=imin_global(myid)
  imax=imax_global(myid)
  jmin=jmin_global(myid)
  jmax=jmax_global(myid)
  nx = imax - imin -4 + 1
  ny = jmax - jmin -4 + 1
  
  if (myid == 1) write(*, '(A, 10I4)') "imax_global ", imax_global
  if (myid == 1) write(*, '(A, 10I4)') "imin_global ", imin_global
  if (myid == 1) write(*, '(A, 10I4)') "nx, ny ",nx, ny

  allocate(uold(imin:imax,jmin:jmax,1:nvar))
  !allocate(uold(1:nx+4, 1:ny+4, 1:nvar))
  
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
  uold(imin+2,jmin+2,IP)=1./dx/dx

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

  allocate(q(1:nx,1:IP),e(1:nx),c(1:nx))
  !allocate( q(imin:imax, 1:IP), e(imin:imax), c(imin:imax))
  do j=jmin+2,jmax-2
     do i=1, nx
        q(i,ID) = max(uold(i+1+imin,j,ID),smallr) ! take the bigger of the two -> so that the density doesn't surpass a minimal value "smallr"
        q(i,IU) = uold(i+1+imin,j,IU)/q(i,ID) !calculate velocities: rho*v/rho
        q(i,IV) = uold(i+1+imin,j,IV)/q(i,ID)
        eken = half*(q(i,IU)**2+q(i,IV)**2) ! calcualte kinetic energy
        q(i,IP) = uold(i+1+imin,j,IP)/q(i,ID) - eken
        e(i)=q(i,IP)
     end do

     call eos(q(1:nx,ID),e,q(1:nx,IP),c)
     ! calculate pressure and speed of sound with equation of state.
     ! then calculate the time step according to the speed of sound
     ! so that the maximal movement is not larger than one cell.

     cournox=max(cournox,maxval(c(1:nx)+abs(q(1:nx,IU))))
     cournoy=max(cournoy,maxval(c(1:nx)+abs(q(1:nx,IV))))
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
     call allocate_work_space(imin,imax,nx+1)

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
           do i=1,nx+1
              qleft (i,in)=qxm(i+imin,in)
              qright(i,in)=qxp(i+1+imin,in)
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
        do i=3, nx + 1
           uold(i+imin-1,j,ID)=u(i+imin-1,ID)+(flux(i-2,ID)-flux(i-1,ID))*dtdx
           uold(i+imin-1,j,IU)=u(i+imin-1,IU)+(flux(i-2,IU)-flux(i-1,IU))*dtdx
           uold(i+imin-1,j,IV)=u(i+imin-1,IV)+(flux(i-2,IV)-flux(i-1,IV))*dtdx
           uold(i+imin-1,j,IP)=u(i+imin-1,IP)+(flux(i-2,IP)-flux(i-1,IP))*dtdx
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
     call allocate_work_space(jmin,jmax,ny+1)

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
           do j = 1, ny+1
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

  subroutine allocate_work_space(ii1,ii2,ngrid)
    implicit none

    ! Dummy arguments
    integer(kind=prec_int), intent(in) :: ii1,ii2,ngrid

    allocate(u  (ii1:ii2,1:nvar))
    allocate(q  (ii1:ii2,1:nvar))
    allocate(dq (ii1:ii2,1:nvar))
    allocate(qxm(ii1:ii2,1:nvar))
    allocate(qxp(ii1:ii2,1:nvar))
    allocate(c  (ii1:ii2))
    allocate(qleft (1:ngrid,1:nvar))
    allocate(qright(1:ngrid,1:nvar))
    allocate(qgdnv (1:ngrid,1:nvar))
    allocate(flux  (1:ngrid,1:nvar))
    allocate(rl    (1:ngrid), ul   (1:ngrid), pl   (1:ngrid), cl    (1:ngrid))
    allocate(rr    (1:ngrid), ur   (1:ngrid), pr   (1:ngrid), cr    (1:ngrid))
    allocate(ro    (1:ngrid), uo   (1:ngrid), po   (1:ngrid), co    (1:ngrid))
    allocate(rstar (1:ngrid), ustar(1:ngrid), pstar(1:ngrid), cstar (1:ngrid))
    allocate(wl    (1:ngrid), wr   (1:ngrid), wo   (1:ngrid))
    allocate(sgnm  (1:ngrid), spin (1:ngrid), spout(1:ngrid), ushock(1:ngrid))
    allocate(frac  (1:ngrid), scr  (1:ngrid), delp (1:ngrid), pold  (1:ngrid))
    allocate(ind   (1:ngrid), ind2 (1:ngrid))
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
