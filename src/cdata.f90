module Cdata

!!! Global variables

  Use Cparam

  real, dimension (mx) :: x
  real, dimension (my) :: y
  real, dimension (mz) :: z
  real, dimension (nx) :: x_mn,y_mn,z_mn,r_mn
!  real, dimension (nx) :: rmn
!
  real, parameter :: pi=3.14159265358979323844,epsi=5*epsilon(1.)
  real :: t,dt,dx,dy,dz,dxmin,dxmax
  real :: dsnap,dvid,dforce,dtmin
  real :: tinit,tdamp,dampu,dampuext,rdamp,wdamp
  real :: cs0,rho0,cs20,gamma,gamma1,force,relhel,cs2top
  real :: DD,nu,cmu,cnu2,cdiffrho
  real :: hcond0,hcond1,hcond2,whcond,mpoly0,mpoly1,mpoly2
  real :: t_diag,dtu,dtv
  real :: rmean,rrms,rmax,urms,umax,u2max,divurms,divumax,divu2max
  real :: orms,omax,o2max,ourms,oumax
  real :: UUmax,cdt,cdtv,x0,y0,z0,Lx,Ly,Lz
  real :: z1,z2,ztop
  real :: gravz,ss0,grads0      ! (1/c_p)ds/dz
  real :: urand,cheat,wheat,cool,wcool,Fheat

  integer, dimension (2) :: seed
  integer :: nvar,iuu,iux,iuy,iuz,ilnrho,ient,iaa,iax,iay,iaz
  integer :: iperx,ipery,iperz
  integer :: nt,it1,isave,itorder
  integer :: it,ix,iy,iz
  integer :: ivisc,iforce=0,isothtop
  integer :: m,n
!
!  in this section are all the things related to printing
!
  integer :: nname
  integer :: ilabel_max=-1,ilabel_sum=1
  integer, parameter :: mname=100,mname_extra=2
  integer, dimension (mname) :: itype_name
  real, dimension (mname) :: fname
  character (len=30) :: cname(mname),cform(mname),cform_extra(mname_extra)

  logical :: lmpicomm=.false., lentropy=.false., lmagnetic=.false.
  logical :: lforcing=.false.
  logical :: lgrav=.false., lgravz=.false., lgravr=.false.
  logical :: lout,headt,headtt,ldt,lfirst,ldiagnos
  logical :: lroot=.true.
  logical :: lfirstpoint

  character (len=80) :: form1
  character (len=2*bclen+1), dimension(mvar) :: bcx,bcy,bcz
  character (len=bclen), dimension(mvar) :: bcx1,bcx2,bcy1,bcy2,bcz1,bcz2
  character (len=12) :: directory

endmodule Cdata
