!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! module_hydro_utils.f90 --- 
!!!!
!! subroutine make_boundary(idim)
!! subroutine constoprim(u,q,c)
!! subroutine eos(rho,eint,p,c)
!! subroutine trace(q,dq,c,qxm,qxp,dtdx)
!! subroutine slope(q,dq)
!! subroutine riemann(qleft,qright,qgdnv, &
!!            & rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
!!            & rstar,ustar,pstar,cstar,sgnm,spin,spout, &
!!            & ushock,frac,scr,delp,pold,ind,ind2)
!! subroutine cmpflx(qgdnv,flux)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module hydro_utils

contains

subroutine make_boundary(idim)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  use mladen ! communicate_boundaries
  implicit none

  ! Dummy arguments
  integer(kind=prec_int), intent(in) :: idim
  ! Local variables
  integer(kind=prec_int) :: ivar,i,i0,j,j0
  real(kind=prec_real)   :: sign
!!$ integer(kind=prec_int) :: ijet
!!$ real(kind=prec_real) :: djet,ujet,pjet



  if(idim==1)then

    call communicate_boundaries(idim)
    if(leftofme==wall) call makewall(1) !make left wall
    if (rightofme==wall) call makewall(2) !make right wall
    
  else

    call communicate_boundaries(idim) 
    if (belowme==wall) call makewall(4) !make lower wall
    if (aboveme==wall) call makewall(3) !make upper wall

    

!!$        djet=1.0
!!$        ujet=300.
!!$        pjet=1.0
!!$        ijet=imax-20 
!!$        do ivar=1,nvar
!!$           do j=1,2           
!!$              do i=ijet,imax-2
!!$                 uold(i,j,1)=djet
!!$                 uold(i,j,2)=0.
!!$                 uold(i,j,3)=djet*ujet
!!$                 uold(i,j,4)=pjet/(gamma-1)+0.5*djet*ujet**2
!!$              end do
!!$           end do
!!$        end do

  end if
end subroutine make_boundary


subroutine constoprim(u,q,c)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real), dimension(:,:), intent(in)   :: u
  real(kind=prec_real), dimension(:,:), intent(out)  :: q
  real(kind=prec_real), dimension(:)  , intent(out)  :: c
  ! Local variables
  integer(kind=prec_int) :: i,IN,ijmax,ijmin
  real(kind=prec_real)   :: eken
  real(kind=prec_real), dimension(1:size(c)) :: e

  ! ::: .....::::: convert to non-conservation form and compute
  ! ::: .....::::: pressure via equation of state
  ijmin = 1
  ijmax=size(c)
  do i = ijmin, ijmax
     q(i,ID) = max(u(i,ID),smallr)
     q(i,IU) = u(i,IU)/q(i,ID)
     q(i,IV) = u(i,IV)/q(i,ID)
     eken = half*(q(i,IU)**2+q(i,IV)**2)
     q(i,IP) = u(i,IP)/q(i,ID) - eken     
  end do

  if (nvar > 4) then
     do IN = 5, nvar
        do i = ijmin, ijmax
           q(i,IN) = u(i,IN)/q(i,ID)
        end do
     end do
  end if

  do i = ijmin, ijmax
     e(i)=q(i,IP)
  end do

  call eos(q(1:ijmax,ID),e,q(1:ijmax,IP),c(1:ijmax))

end subroutine constoprim


subroutine eos(rho,eint,p,c)
! equation of state
! reads in density, initial energy;
! gives out: pressure, speed of sound.
! The speed of sound shouldn't be larger than your cell size 
! => that's why we're computing the next timestep.
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real), dimension(:), intent(in)  :: rho,eint
  real(kind=prec_real), dimension(:), intent(out) :: p,c
  ! Local variables
  integer(kind=prec_int) :: k
  real(kind=prec_real)   :: smallp

  smallp = smallc**2/gamma
  do k = 1, size(rho)
     p(k) = (gamma - one)*rho(k)*eint(k)
     p(k) = max(p(k),rho(k)*smallp)
     c(k) = sqrt(gamma*p(k)/rho(k))
  end do
end subroutine eos


subroutine trace(q,dq,c,qxm,qxp,dtdx)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real), intent(in) :: dtdx
  real(kind=prec_real), dimension(:,:), intent(in)  :: q
  real(kind=prec_real), dimension(:,:), intent(out) :: dq,qxm,qxp 
  real(kind=prec_real), dimension(:),   intent(in)  :: c 
  ! Local variables
  integer(kind=prec_int) :: i,IN,ijmin,ijmax
  real(kind=prec_real)   :: cc,csq,r,u,v,p,a
  real(kind=prec_real)   :: dr,du,dv,dp,da
  real(kind=prec_real)   :: alpham,alphap,alpha0r,alpha0v
  real(kind=prec_real)   :: spminus,spplus,spzero
  real(kind=prec_real)   :: apright,amright,azrright,azv1right,acmpright
  real(kind=prec_real)   :: apleft,amleft,azrleft,azv1left,acmpleft
  real(kind=prec_real)   :: zerol,zeror,project

  ijmin = 1
  ijmax = size(c)


  ! compute slopes
  dq = zero
  if (iorder .ne. 1) then
     call slope(q,dq)
  endif

  if(scheme=='muscl')then ! MUSCL-Hancock method
     zerol=-100./dtdx
     zeror=+100./dtdx
     project=one
  endif
  if(scheme=='plmde')then ! standard PLMDE
     zerol=zero
     zeror=zero
     project=one  
  endif
  if(scheme=='collela')then ! Collela's method
     zerol=zero
     zeror=zero
     project=zero
  endif

  do i = ijmin+1, ijmax-1
     
     cc = c(i)
     csq = cc**2
     r = q(i,ID)
     u = q(i,IU)
     v = q(i,IV)
     p = q(i,IP)
     
     dr = dq(i,ID)
     du = dq(i,IU)
     dv = dq(i,IV)
     dp = dq(i,IP)
     
     alpham  = half*(dp/(r*cc) - du)*r/cc
     alphap  = half*(dp/(r*cc) + du)*r/cc
     alpha0r = dr - dp/csq
     alpha0v = dv
     
     ! Right state
     spminus = (u-cc)*dtdx+one
     spplus  = (u+cc)*dtdx+one
     spzero  =  u    *dtdx+one
     if((u-cc)>=zeror)spminus=project
     if((u+cc)>=zeror)spplus =project
     if( u    >=zeror)spzero =project
     apright   = -half*spplus *alphap
     amright   = -half*spminus*alpham
     azrright  = -half*spzero *alpha0r
     azv1right = -half*spzero *alpha0v     
     qxp(i,ID) = r + (apright + amright + azrright)
     qxp(i,IU) = u + (apright - amright           )*cc/r
     qxp(i,IV) = v + (azv1right                   )
     qxp(i,IP) = p + (apright + amright           )*csq
     
     ! Left state
     spminus = (u-cc)*dtdx-one
     spplus  = (u+cc)*dtdx-one
     spzero  =  u    *dtdx-one
     if((u-cc)<=zerol)spminus=-project
     if((u+cc)<=zerol)spplus =-project
     if( u    <=zerol)spzero =-project
     apleft   = -half*spplus *alphap
     amleft   = -half*spminus*alpham
     azrleft  = -half*spzero *alpha0r
     azv1left = -half*spzero *alpha0v
     qxm(i,ID) = r + (apleft + amleft + azrleft)
     qxm(i,IU) = u + (apleft - amleft          )*cc/r
     qxm(i,IV) = v + (azv1left                 )
     qxm(i,IP) = p + (apleft + amleft          )*csq
     
  end do

  if (nvar>4)then
     do IN = 5, nvar
        do i = ijmin+1, ijmax-1
           
           u  =  q(i,IU)
           a  =  q(i,IN)
           da = dq(i,IN)
           ! Right state
           spzero = u*dtdx+one
           if(u>=zeror)spzero=project
           acmpright = -half*spzero*da
           qxp(i,IN) = a + acmpright
           ! Left state
           spzero = u*dtdx-one
           if(u<=zerol)spzero=-project
           acmpleft = -half*spzero*da
           qxm(i,IN) = a + acmpleft
           
        end do
     end do
  end if
end subroutine trace


subroutine slope(q,dq)
  use hydro_commons
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real), dimension(:,:), intent(in)  :: q
  real(kind=prec_real), dimension(1:size(q,1),1:nvar), intent(out) :: dq
  ! Local arrays
  integer(kind=prec_int) :: i,n,ijmin,ijmax
  real(kind=prec_real)   :: dsgn,dlim,dcen,dlft,drgt,slop

  ijmin = 1
  ijmax = size(q,1)
  do n = 1, nvar
     do i = ijmin+1, ijmax-1        
        dlft = slope_type*(q(i  ,n) - q(i-1,n))
        drgt = slope_type*(q(i+1,n) - q(i  ,n))
        dcen = half*(dlft+drgt)/slope_type
        dsgn = sign(one, dcen)
        slop = min(abs(dlft),abs(drgt))
        dlim = slop
        if((dlft*drgt)<=zero)dlim=zero
        dq(i,n) = dsgn*min(dlim,abs(dcen))
     end do
  end do  
end subroutine slope


subroutine riemann(qleft,qright,qgdnv, &
                   rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
                   rstar,ustar,pstar,cstar,sgnm,spin,spout, &
                   ushock,frac,scr,delp,pold,ind,ind2)
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real),dimension(:,:), intent(in)  :: qleft,qright
  real(kind=prec_real),dimension(:,:), intent(out) :: qgdnv
  real(kind=prec_real),dimension(:),   intent(out) :: rl,ul,pl,cl,wl
  real(kind=prec_real),dimension(:),   intent(out) :: rr,ur,pr,cr,wr
  real(kind=prec_real),dimension(:),   intent(out) :: ro,uo,po,co,wo
  real(kind=prec_real),dimension(:),   intent(out) :: rstar,ustar,pstar,cstar
  real(kind=prec_real),dimension(:),   intent(out) :: sgnm,spin,spout,ushock
  real(kind=prec_real),dimension(:),   intent(out) :: frac,scr,delp,pold  
  integer(kind=prec_int),dimension(:), intent(out) :: ind,ind2
  ! Local variables
  real(kind=prec_real)   :: smallp,gamma6,ql,qr,usr,usl,wwl,wwr,smallpp
  integer(kind=prec_int) :: i,j,in,n,iter,n_new,nface

  ! Constants
  nface=size(rl)
  smallp = smallc**2/gamma
  smallpp = smallr*smallp
  gamma6 = (gamma+one)/(two*gamma)

  ! Pressure, density and velocity
  do i=1,nface
     rl(i)=MAX(qleft (i,ID),smallr)
     ul(i)=    qleft (i,IU)
     pl(i)=MAX(qleft (i,IP),rl(i)*smallp)
     rr(i)=MAX(qright(i,ID),smallr)
     ur(i)=    qright(i,IU)
     pr(i)=MAX(qright(i,IP),rr(i)*smallp)
  end do

  ! Lagrangian sound speed
  do i=1,nface
     cl(i) = gamma*pl(i)*rl(i)
     cr(i) = gamma*pr(i)*rr(i)
  end do

  ! First guess
  wl = sqrt(cl); wr = sqrt(cr)
  pstar = ((wr*pl+wl*pr)+wl*wr*(ul-ur))/(wl+wr)
  pstar = MAX(pstar,0.d0)
  pold = pstar
  n = nface
  do i = 1,n
     ind(i)=i
  end do

  ! Newton-Raphson iterations to find pstar at the required accuracy
  do iter = 1,niter_riemann 
     do i=1,n
        wwl=sqrt(cl(ind(i))*(one+gamma6*(pold(i)-pl(ind(i)))/pl(ind(i))))
        wwr=sqrt(cr(ind(i))*(one+gamma6*(pold(i)-pr(ind(i)))/pr(ind(i))))
        ql=two*wwl**3/(wwl**2+cl(ind(i)))
        qr=two*wwr**3/(wwr**2+cr(ind(i)))
        usl=ul(ind(i))-(pold(i)-pl(ind(i)))/wwl
        usr=ur(ind(i))+(pold(i)-pr(ind(i)))/wwr
        delp(i)=MAX(qr*ql/(qr+ql)*(usl-usr),-pold(i))
     end do
     do i=1,n
        pold(i)=pold(i)+delp(i)
     end do
     ! Convergence indicator
     do i=1,n 
        uo(i)=ABS(delp(i)/(pold(i)+smallpp))
     end do
     n_new=0
     do i=1,n
        if(uo(i)>1.d-06)then
           n_new=n_new+1
           ind2(n_new)=ind (i)
           po  (n_new)=pold(i)
        end if
     end do
     j=n_new
     do i=1,n
        if(uo(i)<=1.d-06)then
           n_new=n_new+1
           ind2(n_new)=ind (i)
           po  (n_new)=pold(i)
        end if
     end do
     ind (1:n)=ind2(1:n)
     pold(1:n)=po  (1:n)
     n=j
  end do

  do i=1,nface
     pstar(ind(i))=pold(i)
  end do
  do i=1,nface
     wl(i) = sqrt(cl(i)*(one+gamma6*(pstar(i)-pl(i))/pl(i)))
     wr(i) = sqrt(cr(i)*(one+gamma6*(pstar(i)-pr(i))/pr(i)))
  end do
  do i=1,nface
     ustar(i) = half*(ul(i) + (pl(i)-pstar(i))/wl(i) + &
          &           ur(i) - (pr(i)-pstar(i))/wr(i) )
  end do
  do i=1,nface
     sgnm(i) = sign(one,ustar(i))
  end do
  do i=1,nface
     if(sgnm(i)==one)then
        ro(i) = rl(i)
        uo(i) = ul(i)
        po(i) = pl(i)
        wo(i) = wl(i)
     else
        ro(i) = rr(i)
        uo(i) = ur(i)
        po(i) = pr(i)
        wo(i) = wr(i)
     end if
  end do
  do i=1,nface
     co(i) = max(smallc,sqrt(abs(gamma*po(i)/ro(i))))
  end do
  do i=1,nface
     rstar(i) = ro(i)/(one+ro(i)*(po(i)-pstar(i))/wo(i)**2)
     rstar(i) = max(rstar(i),smallr)
  end do
  do i=1,nface
     cstar(i) = max(smallc,sqrt(abs(gamma*pstar(i)/rstar(i))))
  end do
  do i=1,nface
     spout (i) = co   (i)    - sgnm(i)*uo   (i)
     spin  (i) = cstar(i)    - sgnm(i)*ustar(i)
     ushock(i) = wo(i)/ro(i) - sgnm(i)*uo   (i)
  end do
  do i=1,nface
     if(pstar(i)>=po(i))then
        spin (i) = ushock(i)
        spout(i) = ushock(i)
     end if
  end do
  do i=1,nface
     scr(i) = MAX(spout(i)-spin(i),smallc+ABS(spout(i)+spin(i)))
  end do
  do i=1,nface
     frac(i) = (one + (spout(i) + spin(i))/scr(i))*half
     frac(i) = max(zero,min(one,frac(i)))
  end do
  do i=1,nface
     qgdnv(i,ID) = frac(i)*rstar(i) + (one - frac(i))*ro(i)
     qgdnv(i,IU) = frac(i)*ustar(i) + (one - frac(i))*uo(i)
     qgdnv(i,IP) = frac(i)*pstar(i) + (one - frac(i))*po(i)
  end do
  do i=1,nface
     if(spout(i)<zero)then
        qgdnv(i,ID) = ro(i)
        qgdnv(i,IU) = uo(i)
        qgdnv(i,IP) = po(i)
     end if
  end do
  do i=1,nface
     if(spin(i)>zero)then
        qgdnv(i,ID) = rstar(i)
        qgdnv(i,IU) = ustar(i)
        qgdnv(i,IP) = pstar(i)
     end if
  end do

  ! transverse velocity
  do i=1,nface
     if(sgnm(i)==one)then
        qgdnv(i,IV) = qleft (i,IV)
     else
        qgdnv(i,IV) = qright(i,IV)
     end if
  end do

  ! other passive variables
  if (nvar > 4) then
     do in = 4,nvar
        do i=1,nface
           if(sgnm(i)==one)then
              qgdnv(i,in) = qleft (i,in)
           else
              qgdnv(i,in) = qright(i,in)
           end if
        end do
     end do
  end if

end subroutine riemann


subroutine cmpflx(qgdnv,flux)
  use hydro_parameters
  use hydro_const
  implicit none

  ! Dummy arguments
  real(kind=prec_real), dimension(:,:), intent(in)  :: qgdnv
  real(kind=prec_real), dimension(:,:), intent(out) :: flux
  ! Local variables
  integer(kind=prec_int) :: i,IN,nface
  real(kind=prec_real)   :: entho,etot,ekin

  nface=size(flux,1)
  entho=one/(gamma-one)

  ! Compute fluxes
  do i=1,nface

     ! Mass density
     flux(i,ID) = qgdnv(i,ID)*qgdnv(i,IU)

     ! Normal momentum
     flux(i,IU) = flux(i,ID)*qgdnv(i,IU)+qgdnv(i,IP)

     ! Transverse momentum 1
     flux(i,IV) = flux(i,ID)*qgdnv(i,IV)

     ! Total energy
     ekin = half*qgdnv(i,ID)*(qgdnv(i,IU)**2+qgdnv(i,IV)**2)
     etot = qgdnv(i,IP)*entho + ekin
     flux(i,IP) = qgdnv(i,IU)*(etot+qgdnv(i,IP))

     ! Other advected quantities
     if (nvar>4) then
        do IN = 5, nvar
           flux(i,IN) = flux(i,ID)*qgdnv(i,IN)
        end do
     end if

  end do
end subroutine cmpflx


subroutine riemann_newalg_f90(qleft,qright,qgdnv, &
                   rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
                   rstar,ustar,pstar,cstar,sgnm,spin,spout, &
                   ushock,frac,scr,delp,pold,ind)
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real),dimension(:,:), intent(in)  :: qleft,qright
  real(kind=prec_real),dimension(:,:), intent(out) :: qgdnv
  real(kind=prec_real),dimension(:),   intent(out) :: rl,ul,pl,cl,wl
  real(kind=prec_real),dimension(:),   intent(out) :: rr,ur,pr,cr,wr
  real(kind=prec_real),dimension(:),   intent(out) :: ro,uo,po,co,wo
  real(kind=prec_real),dimension(:),   intent(out) :: rstar,ustar,pstar,cstar
  real(kind=prec_real),dimension(:),   intent(out) :: sgnm,spin,spout,ushock
  real(kind=prec_real),dimension(:),   intent(out) :: frac,scr,delp,pold  
  integer(kind=prec_int),dimension(:), intent(out) :: ind
  ! Local variables
  real(kind=prec_real)   :: smallp,gamma6,ql,qr,usr,usl,wwl,wwr,smallpp
  integer(kind=prec_int) :: i,j,in,n,iter,n_new,nface

  ! Constants
  nface=size(rl)
  smallp = smallc**2/gamma
  smallpp = smallr*smallp
  gamma6 = (gamma+one)/(two*gamma)

  ! Pressure, density and velocity
  rl(1:nface)=MAX(qleft (1:nface,ID),smallr)
  ul(1:nface)=    qleft (1:nface,IU)
  pl(1:nface)=MAX(qleft (1:nface,IP),rl(1:nface)*smallp)
  rr(1:nface)=MAX(qright(1:nface,ID),smallr)
  ur(1:nface)=    qright(1:nface,IU)
  pr(1:nface)=MAX(qright(1:nface,IP),rr(1:nface)*smallp)
  ! Lagrangian sound speed
  cl(1:nface) = gamma*pl(1:nface)*rl(1:nface)
  cr(1:nface) = gamma*pr(1:nface)*rr(1:nface)
  ! First guess
  wl(1:nface) = sqrt(cl(1:nface))
  wr(1:nface) = sqrt(cr(1:nface))
  pstar(1:nface) = ((wr(1:nface)*pl(1:nface)+wl(1:nface)*pr(1:nface))+ &
                   wl(1:nface)*wr(1:nface)*(ul(1:nface)-ur(1:nface)))/(wl(1:nface)+wr(1:nface))
  pstar(1:nface) = MAX(pstar(1:nface),0.d0)
  pold(1:nface) = pstar(1:nface)
  ind(1:nface) = 1
  ! Newton-Raphson iterations to find pstar at the required accuracy
  do iter = 1,niter_riemann 
     do i=1,nface
        if (ind(i)==1) then
           wwl=sqrt(cl(i)*(one+gamma6*(pold(i)-pl(i))/pl(i)))
           wwr=sqrt(cr(i)*(one+gamma6*(pold(i)-pr(i))/pr(i)))
           ql=two*wwl**3/(wwl**2+cl(i))
           qr=two*wwr**3/(wwr**2+cr(i))
           usl=ul(i)-(pold(i)-pl(i))/wwl
           usr=ur(i)+(pold(i)-pr(i))/wwr
           delp(i)=MAX(qr*ql/(qr+ql)*(usl-usr),-pold(i))
           pold(i)=pold(i)+delp(i)
           ! Convergence indicator
           uo(i)=ABS(delp(i)/(pold(i)+smallpp))
           if (uo(i)<=1.d-06) ind(i)=0
        end if
     end do
  end do
  pstar(1:nface)=pold(1:nface)
  wl(1:nface) = sqrt(cl(1:nface)*(one+gamma6*(pstar(1:nface)-pl(1:nface))/pl(1:nface)))
  wr(1:nface) = sqrt(cr(1:nface)*(one+gamma6*(pstar(1:nface)-pr(1:nface))/pr(1:nface)))
  ustar(1:nface) = half*(ul(1:nface) + (pl(1:nface)-pstar(1:nface))/wl(1:nface) + &
       &           ur(1:nface) - (pr(1:nface)-pstar(1:nface))/wr(1:nface) )
  sgnm(1:nface) = sign(one,ustar(1:nface))
  where(sgnm(1:nface)==one)
     ro(1:nface) = rl(1:nface)
     uo(1:nface) = ul(1:nface)
     po(1:nface) = pl(1:nface)
     wo(1:nface) = wl(1:nface)
  elsewhere
     ro(1:nface) = rr(1:nface)
     uo(1:nface) = ur(1:nface)
     po(1:nface) = pr(1:nface)
     wo(1:nface) = wr(1:nface)
  end where
  co(1:nface) = max(smallc,sqrt(abs(gamma*po(1:nface)/ro(1:nface))))
  rstar(1:nface) = ro(1:nface)/(one+ro(1:nface)*(po(1:nface)-pstar(1:nface))/wo(1:nface)**2)
  rstar(1:nface) = max(rstar(1:nface),smallr)
  cstar(1:nface) = max(smallc,sqrt(abs(gamma*pstar(1:nface)/rstar(1:nface))))
  spout (1:nface) = co   (1:nface)    - sgnm(1:nface)*uo   (1:nface)
  spin  (1:nface) = cstar(1:nface)    - sgnm(1:nface)*ustar(1:nface)
  ushock(1:nface) = wo(1:nface)/ro(1:nface) - sgnm(1:nface)*uo   (1:nface)
  where(pstar(1:nface)>=po(1:nface))
     spin (1:nface) = ushock(1:nface)
     spout(1:nface) = ushock(1:nface)
  end where
  scr(1:nface) = MAX(spout(1:nface)-spin(1:nface),smallc+ABS(spout(1:nface)+spin(1:nface)))
  frac(1:nface) = (one + (spout(1:nface) + spin(1:nface))/scr(1:nface))*half
  frac(1:nface) = max(zero,min(one,frac(1:nface)))
  qgdnv(1:nface,ID) = frac(1:nface)*rstar(1:nface) + (one - frac(1:nface))*ro(1:nface)
  qgdnv(1:nface,IU) = frac(1:nface)*ustar(1:nface) + (one - frac(1:nface))*uo(1:nface)
  qgdnv(1:nface,IP) = frac(1:nface)*pstar(1:nface) + (one - frac(1:nface))*po(1:nface)
  where(spout(1:nface)<zero)
     qgdnv(1:nface,ID) = ro(1:nface)
     qgdnv(1:nface,IU) = uo(1:nface)
     qgdnv(1:nface,IP) = po(1:nface)
  end where
  where(spin(1:nface)>zero)
     qgdnv(1:nface,ID) = rstar(1:nface)
     qgdnv(1:nface,IU) = ustar(1:nface)
     qgdnv(1:nface,IP) = pstar(1:nface)
  end where
  ! transverse velocity
  where(sgnm(1:nface)==one)
     qgdnv(1:nface,IV) = qleft (1:nface,IV)
  elsewhere
     qgdnv(1:nface,IV) = qright(1:nface,IV)
  end where

  ! other passive variables
  if (nvar > 4) then
     do in = 4,nvar
        do i=1,nface
           if(sgnm(i)==one)then
              qgdnv(i,in) = qleft (i,in)
           else
              qgdnv(i,in) = qright(i,in)
           end if
        end do
     end do
  end if
  
end subroutine riemann_newalg_f90


subroutine riemann_newalg_bigloop(qleft,qright,qgdnv, &
                   rl,ul,pl,cl,wl,rr,ur,pr,cr,wr,ro,uo,po,co,wo, &
                   rstar,ustar,pstar,cstar,sgnm,spin,spout, &
                   ushock,frac,scr,delp,pold,ind)
  use hydro_const
  use hydro_parameters
  implicit none

  ! Dummy arguments
  real(kind=prec_real),dimension(:,:), intent(in)  :: qleft,qright
  real(kind=prec_real),dimension(:,:), intent(out) :: qgdnv
  real(kind=prec_real),dimension(:),   intent(out) :: rl,ul,pl,cl,wl
  real(kind=prec_real),dimension(:),   intent(out) :: rr,ur,pr,cr,wr
  real(kind=prec_real),dimension(:),   intent(out) :: ro,uo,po,co,wo
  real(kind=prec_real),dimension(:),   intent(out) :: rstar,ustar,pstar,cstar
  real(kind=prec_real),dimension(:),   intent(out) :: sgnm,spin,spout,ushock
  real(kind=prec_real),dimension(:),   intent(out) :: frac,scr,delp,pold  
  integer(kind=prec_int),dimension(:), intent(out) :: ind
  ! Local variables
  real(kind=prec_real)   :: smallp,gamma6,ql,qr,usr,usl,wwl,wwr,smallpp
  integer(kind=prec_int) :: i,j,in,n,iter,n_new,nface

  ! Constants
  nface=size(rl)
  smallp = smallc**2/gamma
  smallpp = smallr*smallp
  gamma6 = (gamma+one)/(two*gamma)

  ! Pressure, density and velocity
  do i=1,nface
     rl(i)=MAX(qleft (i,ID),smallr)
     ul(i)=    qleft (i,IU)
     pl(i)=MAX(qleft (i,IP),rl(i)*smallp)
     rr(i)=MAX(qright(i,ID),smallr)
     ur(i)=    qright(i,IU)
     pr(i)=MAX(qright(i,IP),rr(i)*smallp)
     ! Lagrangian sound speed
     cl(i) = gamma*pl(i)*rl(i)
     cr(i) = gamma*pr(i)*rr(i)
     ! First guess
     wl(i) = sqrt(cl(i))
     wr(i) = sqrt(cr(i))
     pstar(i) = ((wr(i)*pl(i)+wl(i)*pr(i))+wl(i)*wr(i)*(ul(i)-ur(i)))/(wl(i)+wr(i))
     pstar(i) = MAX(pstar(i),0.d0)
     pold(i) = pstar(i)
     ind(i) = 1
     ! Newton-Raphson iterations to find pstar at the required accuracy
     do iter = 1,niter_riemann 
        if (ind(i)==1) then
           wwl=sqrt(cl(i)*(one+gamma6*(pold(i)-pl(i))/pl(i)))
           wwr=sqrt(cr(i)*(one+gamma6*(pold(i)-pr(i))/pr(i)))
           ql=two*wwl**3/(wwl**2+cl(i))
           qr=two*wwr**3/(wwr**2+cr(i))
           usl=ul(i)-(pold(i)-pl(i))/wwl
           usr=ur(i)+(pold(i)-pr(i))/wwr
           delp(i)=MAX(qr*ql/(qr+ql)*(usl-usr),-pold(i))
           pold(i)=pold(i)+delp(i)
           ! Convergence indicator
           uo(i)=ABS(delp(i)/(pold(i)+smallpp))
           if (uo(i)<=1.d-06) ind(i)=0
        end if
     end do
     pstar(i)=pold(i)
     wl(i) = sqrt(cl(i)*(one+gamma6*(pstar(i)-pl(i))/pl(i)))
     wr(i) = sqrt(cr(i)*(one+gamma6*(pstar(i)-pr(i))/pr(i)))
     ustar(i) = half*(ul(i) + (pl(i)-pstar(i))/wl(i) + ur(i) - (pr(i)-pstar(i))/wr(i) )
     sgnm(i) = sign(one,ustar(i))
     if(sgnm(i)==one)then
        ro(i) = rl(i)
        uo(i) = ul(i)
        po(i) = pl(i)
        wo(i) = wl(i)
     else
        ro(i) = rr(i)
        uo(i) = ur(i)
        po(i) = pr(i)
        wo(i) = wr(i)
     end if
     co(i) = max(smallc,sqrt(abs(gamma*po(i)/ro(i))))
     rstar(i) = ro(i)/(one+ro(i)*(po(i)-pstar(i))/wo(i)**2)
     rstar(i) = max(rstar(i),smallr)
     cstar(i) = max(smallc,sqrt(abs(gamma*pstar(i)/rstar(i))))
     spout (i) = co   (i)    - sgnm(i)*uo   (i)
     spin  (i) = cstar(i)    - sgnm(i)*ustar(i)
     ushock(i) = wo(i)/ro(i) - sgnm(i)*uo   (i)
     if(pstar(i)>=po(i))then
        spin (i) = ushock(i)
        spout(i) = ushock(i)
     end if
     scr(i) = MAX(spout(i)-spin(i),smallc+ABS(spout(i)+spin(i)))
     frac(i) = (one + (spout(i) + spin(i))/scr(i))*half
     frac(i) = max(zero,min(one,frac(i)))
     qgdnv(i,ID) = frac(i)*rstar(i) + (one - frac(i))*ro(i)
     qgdnv(i,IU) = frac(i)*ustar(i) + (one - frac(i))*uo(i)
     qgdnv(i,IP) = frac(i)*pstar(i) + (one - frac(i))*po(i)
     if (spout(i)<zero) then
        qgdnv(i,ID) = ro(i)
        qgdnv(i,IU) = uo(i)
        qgdnv(i,IP) = po(i)
     end if
     if (spin(i)>zero) then
        qgdnv(i,ID) = rstar(i)
        qgdnv(i,IU) = ustar(i)
        qgdnv(i,IP) = pstar(i)
     end if
     ! transverse velocity
     if (sgnm(i)==one) then
        qgdnv(i,IV) = qleft (i,IV)
     else
        qgdnv(i,IV) = qright(i,IV)
     end if
  end do

  ! other passive variables
  if (nvar > 4) then
     do in = 4,nvar
        do i=1,nface
           if(sgnm(i)==one)then
              qgdnv(i,in) = qleft (i,in)
           else
              qgdnv(i,in) = qright(i,in)
           end if
        end do
     end do
  end if

end subroutine riemann_newalg_bigloop

end module hydro_utils
