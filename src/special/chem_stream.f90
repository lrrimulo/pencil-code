! $Id: chem_stream.f90,v 1.27 2008-05-13 15:44:29 nbabkovs Exp $
!
!  This module incorporates all the modules used for Natalia's
!  neutron star -- disk coupling simulations (referred to as nstar)
!
!  This sample modules solves a special set of problems related
!  to computing the accretion through a thin disk onto a rigid surface
!  and the spreading of accreted material along the neutron star's surface.
!  One-dimensional problems along the disc and perpendicular to it
!  can also be considered.
!

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lspecial = .true.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
!***************************************************************

!-------------------------------------------------------------------
!
! HOW TO USE THIS FILE
! --------------------
!
! The rest of this file may be used as a template for your own
! special module.  Lines which are double commented are intended
! as examples of code.  Simply fill out the prototypes for the
! features you want to use.
!
! Save the file with a meaningful name, eg. geo_kws.f90 and place
! it in the $PENCIL_HOME/src/special directory.  This path has
! been created to allow users ot optionally check their contributions
! in to the Pencil-Code CVS repository.  This may be useful if you
! are working on/using the additional physics with somebodyelse or
! may require some assistance from one of the main Pencil-Code team.
!
! To use your additional physics code edit the Makefile.local in
! the src directory under the run directory in which you wish to
! use your additional physics.  Add a line with all the module
! selections to say something like:
!
!    SPECIAL=special/chem_stream
!
! Where nstar it replaced by the filename of your new module
! upto and not including the .f90
!
!--------------------------------------------------------------------

module Special

  use Cparam
  use Cdata
  use Messages
  use Sub, only: keep_compiler_quiet
!  use Density, only: rho_up
  use EquationOfState


  implicit none

  include '../special.h'

  ! input parameters
  logical :: lmass_source_NS=.false.
  logical :: leffective_gravity=.false.

  character (len=labellen) :: initstream='default'

  real, dimension (mx,my,mz,3) :: divtau=0.
  real, dimension (mx,my,mz) :: pres=0., mmu1=0.
  logical :: ldivtau=.false.
  real :: test, H_max
  real :: Rgas, Rgas_unit_sys=1.

  real :: rho_init=1., T_init=1., Y1_init=1., Y2_init=1., Y3_init=1., ux_init=0.

  integer :: index_H2=0, index_O2=0, index_H2O=0, index_N2=0
  real :: x1_front=-0.2,x2_front=0.2
  real :: init_TT1=400.,init_TT2=2400.,init_lnTT1=6.,init_p2=1e6
! Keep some over used pencils
!

! start parameters
  namelist /chem_stream_init_pars/ &
   initstream,rho_init, T_init, Y1_init, Y2_init, Y3_init, H_max, ux_init, &
   index_H2, index_O2, index_H2O, index_N2,x1_front,x2_front,init_TT1,init_TT2,init_lnTT1, init_p2
! run parameters
  namelist /chem_stream_run_pars/ &
   test
!!
!! Declare any index variables necessary for main or
!!
!!   integer :: iSPECIAL_VARIABLE_INDEX=0
!
!! other variables (needs to be consistent with reset list below)
!
  integer :: idiag_dtcrad=0
  integer :: idiag_dtchi=0
!
  contains

!***********************************************************************
    subroutine register_special()
!
!  Configure pre-initialised (i.e. before parameter read) variables
!  which should be know to be able to evaluate
!
!
!  6-oct-03/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState
      use Mpicomm
!
      logical, save :: first=.true.
!
! A quick sanity check
!
      if (.not. first) call stop_it('register_special called twice')
      first = .false.

!!
!! MUST SET lspecial = .true. to enable use of special hooks in the Pencil-Code
!!   THIS IS NOW DONE IN THE HEADER ABOVE
!
!
!
!!
!! Set any required f-array indexes to the next available slot
!!
!!
!      iSPECIAL_VARIABLE_INDEX = nvar+1             ! index to access entropy
!      nvar = nvar+1
!
!      iSPECIAL_AUXILIARY_VARIABLE_INDEX = naux+1             ! index to access entropy
!      naux = naux+1
!
!
!  identify CVS version information (if checked in to a CVS repository!)
!  CVS should automatically update everything between $Id: chem_stream.f90,v 1.27 2008-05-13 15:44:29 nbabkovs Exp $
!  when the file in committed to a CVS repository.
!
      if (lroot) call cvs_id( &
           "$Id: chem_stream.f90,v 1.27 2008-05-13 15:44:29 nbabkovs Exp $")
!
!
!  Perform some sanity checks (may be meaningless if certain things haven't
!  been configured in a custom module but they do no harm)
!
      if (naux > maux) then
        if (lroot) write(0,*) 'naux = ', naux, ', maux = ', maux
        call stop_it('register_special: naux > maux')
      endif
!
      if (nvar > mvar) then
        if (lroot) write(0,*) 'nvar = ', nvar, ', mvar = ', mvar
        call stop_it('register_special: nvar > mvar')
      endif
!
    endsubroutine register_special
!***********************************************************************
    subroutine initialize_special(f)
!
!  called by run.f90 after reading parameters, but before the time loop
!
!  06-oct-03/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState

!
      real, dimension (mx,my,mz,mvar+maux) :: f
!!
!!  Initialize any module variables which are parameter dependent
!!
    if (unit_system == 'cgs') then
         Rgas_unit_sys = k_B_cgs/m_u_cgs
         Rgas=Rgas_unit_sys*unit_temperature/unit_velocity**2
       endif


!
!  Make sure initialization (somehow) works with eos_ionization.f90
!
      if (gamma == impossible) then
        gamma  = 1
        gamma1 = 0.
        gamma11 = 1.
      endif
!
      if(NO_WARN) print*,f  !(keep compiler quiet)
!
    endsubroutine initialize_special
!***********************************************************************
    subroutine init_special(f,xx,yy,zz)
!
!  initialise special condition; called from start.f90
!  06-oct-2003/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState
      use Mpicomm
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
!
      intent(in) :: xx,yy,zz
      intent(inout) :: f

!!
      select case(initstream)
         case('stream')
            call stream_field(f,xx,yy)
         case('bomb')
            call bomb_field(f,xx,yy)
         case('flame_spd')
            call flame_spd(f,xx,x1_front,x2_front)
         case('flame_spd_invert')
            call flame_spd_invert(f,xx)
         case('flame_spd_invert2')
            call flame_spd_invert2(f,xx)
        case('stream_field')
            call stream_field(f,xx,yy)
         case('default')
          if(lroot) print*,'init_special: Default  setup'
     !     call density_init(f,xx,zz)
     !     call entropy_init(f,xx,zz)
     !     call velocity_init(f,zz)
        case default
          !
          !  Catch unknown values
          !
          if (lroot) print*,'init_special: No such value for initstream: ', trim(initstream)
          call stop_it("")
      endselect
!
      if(NO_WARN) print*,f,xx,yy,zz  !(keep compiler quiet)
!
    endsubroutine init_special
!***********************************************************************
    subroutine pencil_criteria_special()
!
!  All pencils that this special module depends on are specified here.
!
!  18-07-06/tony: coded
!
      use Cdata
!
!
!
    endsubroutine pencil_criteria_special
!***********************************************************************
    subroutine dspecial_dt(f,df,p)
!
!  calculate right hand side of ONE OR MORE extra coupled PDEs
!  along the 'current' Pencil, i.e. f(l1:l2,m,n) where
!  m,n are global variables looped over in equ.f90
!
!  Due to the multi-step Runge Kutta timestepping used one MUST always
!  add to the present contents of the df array.  NEVER reset it to zero.
!
!  several precalculated Pencils of information are passed if for
!  efficiency.
!
!   06-oct-03/tony: coded
!
      use Cdata
      use Mpicomm
      use Sub
      use Global
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p

!
      intent(in) :: f,p
      intent(inout) :: df
!
!  identify module and boundary conditions
!
      if (headtt.or.ldebug) print*,'dspecial_dt: SOLVE dSPECIAL_dt'
!!      if (headtt) call identify_bcs('ss',iss)
!
!!
!! SAMPLE DIAGNOSTIC IMPLEMENTATION
!!
      if(ldiagnos) then
        if (idiag_dtcrad/=0) &
          call max_mn_name(sqrt(advec_crad2)/cdt,idiag_dtcrad,l_dt=.true.)
        if (idiag_dtchi/=0) &
          call max_mn_name(diffus_chi/cdtv,idiag_dtchi,l_dt=.true.)
      endif

! Keep compiler quiet by ensuring every parameter is used
      if (NO_WARN) print*,f,df,p

    endsubroutine dspecial_dt
!***********************************************************************
    subroutine read_special_init_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat)) then
        read(unit,NML=chem_stream_init_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chem_stream_init_pars,ERR=99)
      endif

99    return
    endsubroutine read_special_init_pars
!***********************************************************************
    subroutine write_special_init_pars(unit)
      integer, intent(in) :: unit

      write(unit,NML=chem_stream_init_pars)

    endsubroutine write_special_init_pars
!***********************************************************************
    subroutine read_special_run_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat)) then
        read(unit,NML=chem_stream_run_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chem_stream_run_pars,ERR=99)
      endif

99    return
    endsubroutine read_special_run_pars
!***********************************************************************
    subroutine write_special_run_pars(unit)
      integer, intent(in) :: unit

      write(unit,NML=chem_stream_run_pars)

    endsubroutine write_special_run_pars
!***********************************************************************
    subroutine rprint_special(lreset,lwrite)
!
!  reads and registers print parameters relevant to special
!
!   06-oct-03/tony: coded
!
      use Sub
!
!  define diagnostics variable
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite

!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_dtcrad=0
        idiag_dtchi=0
      endif
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'dtcrad',idiag_dtcrad)
        call parse_name(iname,cname(iname),cform(iname),'dtchi',idiag_dtchi)
      enddo
!
!  write column where which magnetic variable is stored
      if (lwr) then
        write(3,*) 'i_dtcrad=',idiag_dtcrad
        write(3,*) 'i_dtchi=',idiag_dtchi
      endif
!
    endsubroutine rprint_special
!***********************************************************************
    subroutine calc_lspecial_pars(f)
!
!  dummy routine
!
!  15-jan-08/axel: coded
!
      use Sub, only: keep_compiler_quiet
!
      real, dimension (mx,my,mz,mfarray) :: f
      intent(inout) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_lspecial_pars
!***********************************************************************
    subroutine special_calc_density(f,df,p)
!
!   06-oct-03/tony: coded
!
      use Cdata
      ! use Viscosity
      use EquationOfState

      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      real, dimension (mx) :: rho_prf
      type (pencil_case), intent(in) :: p
!
! Keep compiler quiet by ensuring every parameter is used
!
      if (NO_WARN) print*,df,p
!
    endsubroutine special_calc_density
!***********************************************************************
    subroutine special_calc_hydro(f,df,p)
!
!
!   16-jul-06/natalia: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
      integer :: i
!
!      do i=1,3
!        divtau(l1:l2,m,n,i)=p%fvisc(:,i)*p%rho(:)
!      enddo

        pres(l1:l2,m,n)=p%pp(:)!/p%mu1(:)
        mmu1(l1:l2,m,n)=p%mu1(:)


     !    print*,'Natalia',p%pp(l1+1), p%fvisc(l1+1,1),mmu1(l1+1,4,4)
      ldivtau=.true.



    endsubroutine special_calc_hydro
!***********************************************************************
    subroutine special_calc_magnetic(f,df,p)
!
!
!   06-oct-03/tony: coded
!
      use Cdata

      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

!!
!!  SAMPLE IMPLEMENTATION
!!     (remember one must ALWAYS add to df)
!!
!!
!!  df(l1:l2,m,n,iux) = df(l1:l2,m,n,iux) + SOME NEW TERM
!!  df(l1:l2,m,n,iuy) = df(l1:l2,m,n,iuy) + SOME NEW TERM
!!  df(l1:l2,m,n,iuz) = df(l1:l2,m,n,iuz) + SOME NEW TERM
!!
!!

! Keep compiler quiet by ensuring every parameter is used
      if (NO_WARN) print*,df,p

    endsubroutine special_calc_magnetic
!!***********************************************************************
    subroutine special_calc_entropy(f,df,p)
!

      use Cdata

      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p


! Keep compiler quiet by ensuring every parameter is used
      if (NO_WARN) print*,df,p

    endsubroutine special_calc_entropy
!***********************************************************************
    subroutine special_boundconds(f,bc)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-oct-03/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      type (boundary_condition) :: bc
!
      select case (bc%bcname)
         case ('stm')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_stream_x(f,-1, bc)
         case (iBC_X_BOT)
           call bc_stream_x(f,-1, bc)
         case (iBC_Y_TOP)
           call bc_stream_y(f,-1, bc)
         case (iBC_Y_BOT)
           call bc_stream_y(f,-1, bc)
         case (iBC_Z_TOP)
           call bc_stream_z(f,-1, bc)
         case (iBC_Z_BOT)
           call bc_stream_z(f,-1, bc)
         endselect
         bc%done=.true.
         case ('wal')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_gpress_wall(f,-1, bc)
         case (iBC_X_BOT)
           call bc_gpress_wall(f,-1, bc)
         endselect
         bc%done=.true.
         case ('inp')
         select case (bc%location)
         case (iBC_X_TOP)
           call spec_input(f,-1, bc)
         case (iBC_X_BOT)
           call spec_input(f,-1, bc)
         endselect
         bc%done=.true.
         case ('eql')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_equil_x(f,-1, bc)
         case (iBC_X_BOT)
           call bc_equil_x(f,-1, bc)
         case (iBC_Y_TOP)
           call bc_equil_y(f,-1, bc)
         case (iBC_Y_BOT)
           call bc_equil_y(f,-1, bc)
         endselect
         bc%done=.true.
         case ('HAi')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_HstreamAir_x(f,-1, bc)
         case (iBC_X_BOT)
           call bc_HstreamAir_x(f,-1, bc)
         endselect
         bc%done=.true.
         case ('sim')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_simple_x(f,-1, bc)
         case (iBC_X_BOT)
           call bc_simple_x(f,-1, bc)
         endselect
         bc%done=.true.
      endselect

      if (NO_WARN) print*,f(1,1,1,1),bc%bcname
!
    endsubroutine special_boundconds
!***********************************************************************
!
!  PRIVATE UTITLITY ROUTINES
!
!***********************************************************************
!********************************************************************
   subroutine density_init(f,xx,zz)
!
! Natalia
! Initialization of density 
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, zz

    endsubroutine density_init
!***************************************************************

    subroutine entropy_init(f,xx,zz)

      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, zz

      endsubroutine entropy_init
!***********************************************************************

      subroutine velocity_init(f,zz)
     !Natalia
     !Initialization of velocity 

      use Cdata

      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: zz

    endsubroutine  velocity_init
!***********************************************************************
!   INITIAL CONDITIONS
!
!***********************************************************************
   subroutine bomb_field(f,xx,yy)
!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy
      integer :: k,j,i

     do k=1,mx 

      if (abs(x(k))<0.2) then
       f(k,:,:,ilnrho)=log(rho_init)! &
         ! +log(1.1)*((0.2-abs(x(k)))/0.2)**2
        f(k,:,:,ilnTT)=log(T_init)+log(2.)*((0.2-abs(x(k)))/0.2)**2
      else
        f(k,:,:,ilnrho)=log(rho_init)
        f(k,:,:,ilnTT)=log(T_init)
      endif

     enddo

     
       !  -(xx(:,:,:)/(0.5*Lxyz(1)))**2
     f(l1:mx,:,:,ichemspec(nchemspec))=Y3_init
     f(:,:,:,iux)=ux_init


   endsubroutine bomb_field
!**************************************************************************
  subroutine stream_field(f,xx,yy)
!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy
      integer :: k,j,i
     
      real :: p2_front=10.13e5
      real :: Rgas=83144726.8870299

      real :: TT1_front=400., TT2_front=2400.
  

      do k=1,mx 
        if (x(k)<x1_front) then
          f(k,:,:,ilnTT)=log(TT1_front)
        endif
        if (x(k)>x2_front) then
          f(k,:,:,ilnTT)=log(TT2_front)
        endif
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,ilnTT)=log((x(k)-x1_front)/(x2_front-x1_front) &
               *(TT2_front-TT1_front)+TT1_front)
        endif

      enddo

      do k=1,mx
        f(k,:,:,ilnrho)=log(p2_front)-log(Rgas)-f(k,:,:,ilnTT)-log(2.)
      enddo


     f(:,:,:,ichemspec(nchemspec))=1.
     f(:,:,:,iux)=ux_init


   endsubroutine stream_field
!**************************************************************************
 subroutine flame_spd(f,xx,x1_front,x2_front)
!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy, mu1
      integer :: k,j,i

      real :: x1_front,x2_front
      real :: rho1_front=1e-3, rho2_front=10./3.*1e-3
      real :: TT1_front=2000., TT2_front
      real :: p2_front=10.13e5
      real :: Rgas=83144726.8870299
      real :: mH,mC,mN,mO,mAr,mHe
      real :: YH2,YO2,YN2
      integer :: i_H2, i_O2, i_H2O, i_N2
      
      TT2_front=exp(6.)

      mH=1.00794
      mC=12.0107
      mN=14.00674
      mO=15.9994
      mAr=39.948
      mHe=4.0026
      !     
      ! Initialize some indexes
      !
      if (index_H2==0) &
           call fatal_error('flame_spd','set index for H2 in start.in')
      if (index_O2==0) &
           call fatal_error('flame_spd','set index for O2 in start.in')
      if (index_H2O==0)&
           call fatal_error('flame_spd','set index for H2O in start.in')
      if (index_N2==0) &
           call fatal_error('flame_spd','set index for N2 in start.in')
      i_H2=ichemspec(index_H2)
      i_O2=ichemspec(index_O2)
      i_N2=ichemspec(index_N2)
      i_H2O=ichemspec(index_H2O)
      !      
      !
      !
      f(l1,:,:,i_O2)=(f(l2,:,:,i_O2)/32.-f(l2,:,:,i_H2)/4.)*32. 
      f(l2,:,:,iux)=ux_init
      !
      do k=1,mx 
        if (x(k)<x1_front) then
          f(k,:,:,ilnTT)=log(TT1_front)
        endif
        if (x(k)>x2_front) then
          f(k,:,:,ilnTT)=log(TT2_front)
        endif
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,ilnTT)=log((x(k)-x1_front)/(x2_front-x1_front) &
               *(TT2_front-TT1_front)+TT1_front)
        endif
        !
        if (x(k)<x2_front) then
          f(k,:,:,i_H2O)=f(l2,:,:,i_H2)/2.*18. &
               *(exp(f(k,:,:,ilnTT))-TT2_front) &
               /(TT1_front-TT2_front)
          f(k,:,:,i_H2)=f(l2,:,:,i_H2) &
               *(exp(f(k,:,:,ilnTT))-TT1_front) &
               /(TT2_front-TT1_front)          
        endif
        !
        if (x(k)<x1_front) then
          f(k,:,:,i_O2)=f(l1,:,:,i_O2)
        endif
        !
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,i_O2)=(x(k)-x1_front)/(x2_front-x1_front) &
               *(f(l2,:,:,i_O2)-f(l1,:,:,i_O2))+f(l1,:,:,i_O2)
        endif
        !
        mu1(k,:,:)=f(k,:,:,i_H2)/(2.*mH)+f(k,:,:,i_O2)/(2.*mO) &
             +f(k,:,:,i_H2O)/(2.*mH+mO)+f(k,:,:,i_N2)/(2.*mN)
      enddo
      !
      !
      !
      do k=1,mx
        f(k,:,:,ilnrho)=log(p2_front)-log(Rgas)-f(k,:,:,ilnTT)-log(mu1(k,:,:))
      enddo
      !
 !     f(l1,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(l1,:,:,ilnrho))
      !
      do k=1,mx
!        f(k,:,:,iux)=(f(l1,:,:,iux)-ux_init) &
!             *(exp(f(k,:,:,ilnTT))-TT2_front)/(TT1_front-TT2_front)&
!             +ux_init        
      f(k,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(k,:,:,ilnrho))
      enddo
      !
   endsubroutine flame_spd
!**************************************************************************
subroutine flame_spd_invert(f,xx)

!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy, mu1
      integer :: k,j,i

      real :: x1_front=-0.2,x2_front=0.2
      real :: rho1_front=1e-3, rho2_front=10./3.*1e-3
      real :: TT1_front, TT2_front!=2400.
      real :: p2_front!=10.13e5
      real :: Rgas=83144726.8870299
      real :: mH,mC,mN,mO,mAr,mHe
      real :: YH2,YO2,YN2
      integer :: i_H2, i_O2, i_H2O, i_N2
      

      TT1_front=exp(init_lnTT1)
      TT2_front=init_TT2
      p2_front=init_p2

      mH=1.00794
      mC=12.0107
      mN=14.00674
      mO=15.9994
      mAr=39.948
      mHe=4.0026
      !     
      ! Initialize some indexes
      !
      if (index_H2==0) &
           call fatal_error('flame_spd','set index for H2 in start.in')
      if (index_O2==0) &
           call fatal_error('flame_spd','set index for O2 in start.in')
      if (index_H2O==0)&
           call fatal_error('flame_spd','set index for H2O in start.in')
      if (index_N2==0) &
           call fatal_error('flame_spd','set index for N2 in start.in')
      i_H2=ichemspec(index_H2)
      i_O2=ichemspec(index_O2)
      i_N2=ichemspec(index_N2)
      i_H2O=ichemspec(index_H2O)
      !      
      !
      !
      f(l2,:,:,i_O2)=(f(l1,:,:,i_O2)/32.-f(l1,:,:,i_H2)/4.)*32. 
      f(l1,:,:,iux)=ux_init
      !
      do k=1,mx 
        if (x(k)<x1_front) then
          f(k,:,:,ilnTT)=log(TT1_front)
        endif
        if (x(k)>x2_front) then
          f(k,:,:,ilnTT)=log(TT2_front)
        endif
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,ilnTT)=log((x(k)-x1_front)/(x2_front-x1_front) &
               *(TT2_front-TT1_front)+TT1_front)
        endif
        !
        if (x(k)>x1_front) then
          f(k,:,:,i_H2O)=f(l1,:,:,i_H2)/2.*18. &
               *(exp(f(k,:,:,ilnTT))-TT1_front) &
               /(TT2_front-TT1_front)
          f(k,:,:,i_H2)=f(l1,:,:,i_H2) &
               *(exp(f(k,:,:,ilnTT))-TT2_front) &
               /(TT1_front-TT2_front)          
        endif
        !
        if (x(k)>x2_front) then
          f(k,:,:,i_O2)=f(l2,:,:,i_O2)
        endif
        !
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,i_O2)=(x(k)-x2_front)/(x1_front-x2_front) &
               *(f(l1,:,:,i_O2)-f(l2,:,:,i_O2))+f(l2,:,:,i_O2)
        endif
        !
        mu1(k,:,:)=f(k,:,:,i_H2)/(2.*mH)+f(k,:,:,i_O2)/(2.*mO) &
             +f(k,:,:,i_H2O)/(2.*mH+mO)+f(k,:,:,i_N2)/(2.*mN)
      enddo
      !
      !
      !
      do k=1,mx
        f(k,:,:,ilnrho)=log(p2_front)-log(Rgas)-f(k,:,:,ilnTT)-log(mu1(k,:,:))
      enddo
      !
 !     f(l1,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(l1,:,:,ilnrho))
      !
      do k=1,mx
!        f(k,:,:,iux)=(f(l1,:,:,iux)-ux_init) &
!             *(exp(f(k,:,:,ilnTT))-TT2_front)/(TT1_front-TT2_front)&
!             +ux_init        
      f(k,:,:,iux)=ux_init*exp(f(l1,:,:,ilnrho))/exp(f(k,:,:,ilnrho))
      enddo
      !
   endsubroutine flame_spd_invert
!**************************************************************************
subroutine flame_spd_invert2(f,xx)
!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy, mu1
      integer :: k,j,i

      real :: x1_front=-0.2, x2_front=0.2
      real :: TT1_front, TT2_front=1200.
      real :: p2_front=10.13e5
      real :: Rgas=83144726.8870299
      real :: mH,mC,mN,mO,mAr,mHe
      real :: YH2,YO2,YN2
      

      TT1_front=exp(6.)

        mH=1.00794
        mC=12.0107
        mN=14.00674
        mO=15.9994
        mAr=39.948
        mHe=4.0026

     if (index_H2==0) call fatal_error('flame_spd','set index for H2 in start.in')
     if (index_O2==0)  call fatal_error('flame_spd','set index for O2 in start.in')
     if (index_H2O==0)  call fatal_error('flame_spd','set index for H2O in start.in')
     if (index_N2==0)  call fatal_error('flame_spd','set index for N2 in start.in')


  !   f(l1,:,:,ichemspec(index_O2))=(f(l2,:,:,ichemspec(index_O2))/32.-f(l2,:,:,ichemspec(index_H2))/4.)*32. 

     f(l1,:,:,iux)=ux_init

     do k=1,mx 
      if (x(k)<x1_front) then
        f(k,:,:,ilnTT)=log(TT1_front)
 !       f(k,:,:,ilnrho)=log(1e-3)
      endif
      if (x(k)>x2_front) then
        f(k,:,:,ilnTT)=log(TT2_front)
  !      f(k,:,:,ilnrho)=log(1e-3*10./3.)
      endif
      if (x(k)>x1_front .and. x(k)<x2_front) then
        f(k,:,:,ilnTT)=log((x(k)-x1_front)/(x2_front-x1_front) &
          *(TT2_front-TT1_front)+TT1_front)
      endif

    
    !  if (x(k)<x2_front) then
    !   f(k,:,:,ichemspec(index_H2O))=f(l2,:,:,ichemspec(index_H2))/2.*18. &
    !         *(exp(f(k,:,:,ilnTT))-TT2_front) &
    !        /(TT1_front-TT2_front)
    !   f(k,:,:,ichemspec(index_H2))=f(l2,:,:,ichemspec(index_H2)) &
    !        *(exp(f(k,:,:,ilnTT))-TT1_front) &
    !         /(TT2_front-TT1_front)

    !  endif

  !    if (x(k)<x1_front) then
  !     f(k,:,:,ichemspec(index_O2))=f(l1,:,:,ichemspec(index_O2))
  !    endif

   !   if (x(k)>x1_front .and. x(k)<x2_front) then
   !     f(k,:,:,ichemspec(index_O2))=(x(k)-x1_front)/(x2_front-x1_front) &
   !       *(f(l2,:,:,ichemspec(index_O2))-f(l1,:,:,ichemspec(index_O2)))+f(l1,:,:,ichemspec(index_O2))
   !   endif

     mu1(k,:,:)=f(k,:,:,ichemspec(index_H2))/(2.*mH)+f(k,:,:,ichemspec(index_O2))/(2.*mO) &
           +f(k,:,:,ichemspec(index_H2O))/(2.*mH+mO)+f(k,:,:,ichemspec(index_N2))/(2.*mN)

    enddo

    do k=1,mx
     f(k,:,:,ilnrho)=log(p2_front)-log(Rgas)-f(k,:,:,ilnTT)-log(mu1(k,:,:))
    enddo

     f(l1,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(l1,:,:,ilnrho))

    do k=1,mx
      f(k,:,:,iux)=(f(l1,:,:,iux)-ux_init) &
           *(exp(f(k,:,:,ilnTT))-TT2_front)/(TT1_front-TT2_front)&
           +ux_init

    enddo
   endsubroutine flame_spd_invert2
!**************************************************************************
!**************************************************************************
subroutine flame_spd_2D(f,xx,x1_front,x2_front)
!
! Natalia
! Initialization of chem. species  in a case of the stream
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx, yy, mu1
      integer :: k,j,i

      real :: x1_front,x2_front
      real :: rho1_front=1e-3, rho2_front=10./3.*1e-3
      real :: TT1_front=2400., TT2_front=400.
      real :: p2_front=10.13e5
      real :: Rgas=83144726.8870299
      real :: mH,mC,mN,mO,mAr,mHe
      real :: YH2,YO2,YN2
      integer :: i_H2, i_O2, i_H2O, i_N2
      
      mH=1.00794
      mC=12.0107
      mN=14.00674
      mO=15.9994
      mAr=39.948
      mHe=4.0026
      !     
      ! Initialize some indexes
      !
      if (index_H2==0) &
           call fatal_error('flame_spd','set index for H2 in start.in')
      if (index_O2==0) &
           call fatal_error('flame_spd','set index for O2 in start.in')
      if (index_H2O==0)&
           call fatal_error('flame_spd','set index for H2O in start.in')
      if (index_N2==0) &
           call fatal_error('flame_spd','set index for N2 in start.in')
      i_H2=ichemspec(index_H2)
      i_O2=ichemspec(index_O2)
      i_N2=ichemspec(index_N2)
      i_H2O=ichemspec(index_H2O)
      !      
      !
      !
      f(l1,:,:,i_O2)=(f(l2,:,:,i_O2)/32.-f(l2,:,:,i_H2)/4.)*32. 
      f(l2,:,:,iux)=ux_init
      !
      do k=1,mx 
        if (x(k)<x1_front) then
          f(k,:,:,ilnTT)=log(TT1_front)
        endif
        if (x(k)>x2_front) then
          f(k,:,:,ilnTT)=log(TT2_front)
        endif
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,ilnTT)=log((x(k)-x1_front)/(x2_front-x1_front) &
               *(TT2_front-TT1_front)+TT1_front)
        endif
        !
        if (x(k)<x2_front) then
          f(k,:,:,i_H2O)=f(l2,:,:,i_H2)/2.*18. &
               *(exp(f(k,:,:,ilnTT))-TT2_front) &
               /(TT1_front-TT2_front)
          f(k,:,:,i_H2)=f(l2,:,:,i_H2) &
               *(exp(f(k,:,:,ilnTT))-TT1_front) &
               /(TT2_front-TT1_front)          
        endif
        !
        if (x(k)<x1_front) then
          f(k,:,:,i_O2)=f(l1,:,:,i_O2)
        endif
        !
        if (x(k)>x1_front .and. x(k)<x2_front) then
          f(k,:,:,i_O2)=(x(k)-x1_front)/(x2_front-x1_front) &
               *(f(l2,:,:,i_O2)-f(l1,:,:,i_O2))+f(l1,:,:,i_O2)
        endif
        !
        mu1(k,:,:)=f(k,:,:,i_H2)/(2.*mH)+f(k,:,:,i_O2)/(2.*mO) &
             +f(k,:,:,i_H2O)/(2.*mH+mO)+f(k,:,:,i_N2)/(2.*mN)
      enddo
      !
      !
      !
      do k=1,mx
        f(k,:,:,ilnrho)=log(p2_front)-log(Rgas)-f(k,:,:,ilnTT)-log(mu1(k,:,:))
      enddo
      !
 !     f(l1,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(l1,:,:,ilnrho))
      !
      do k=1,mx
!        f(k,:,:,iux)=(f(l1,:,:,iux)-ux_init) &
!             *(exp(f(k,:,:,ilnTT))-TT2_front)/(TT1_front-TT2_front)&
!             +ux_init        
      f(k,:,:,iux)=ux_init*exp(f(l2,:,:,ilnrho))/exp(f(k,:,:,ilnrho))
      enddo
      !
   endsubroutine flame_spd_2D
!**************************************************************************
!**************************************************************************
!       BOUNDARY CONDITIONS
!*88888888888888888888888888888888888888888888888888888888888888888888888888
  subroutine bc_stream_x(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2, yy0

      yy0=3.

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


    if (bc%location==iBC_X_BOT) then
      ! bottom boundary

       if (vr==1) then
        do k=1,my
            if (abs(y(k)) .lt. yy0) then
              do i=0,nghost
                   f(l1-i,k,:,vr)=value1*(1.-(y(k)/yy0)**2); 
              enddo
            else
              do i=0,nghost;   f(l1-i,k,:,vr)=0.;  enddo
            !  do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
            endif
        
        enddo
       endif


       if (vr==5) then
         !  if (abs(y(k)) .lt. yy0) then
            do i=0,nghost;  f(l1-i,m1:my,:,vr)=log(value1);  enddo
         !  else
          !  do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
          !  do i=0,nghost; f(l1-i,:,:,vr)=f(l1,:,:,vr); enddo
          !   do i=0,nghost
          !      f(l1-i,:,:,vr)=0.5*(f(l1-i+1,:,:,vr)+f(l1-i-1,:,:,vr))
          !   enddo
          ! endif
       endif


       if (vr==4 ) then
         !  if (abs(y(k)) .lt. yy0) then
      !      do i=0,nghost;  f(l1-i,m1:my,:,vr)=log(value1);  enddo
         !  else
          !  do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
          !  do i=0,nghost; f(l1-i,:,:,vr)=f(l1,:,:,vr); enddo
          do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
          !   do i=0,nghost
          !      f(l1-i,:,:,vr)=0.5*(f(l1-i+1,:,:,vr)+f(l1-i-1,:,:,vr))
          !   enddo
          ! endif
       endif


       if (vr >= ichemspec(1)) then

         do i=0,nghost; 
          do k=1,my
             if (abs(y(k)) .lt. yy0) then
                if (vr < ichemspec(nchemspec))  f(l1-i,k,:,vr)=value1
                if (vr == ichemspec(nchemspec)) f(l1-i,k,:,vr)=value1*((l1-i)/(l1-0.))**4*0.
             else
              !  if (vr < ichemspec(nchemspec)) then
              !   f(l1-i,k,:,vr)=value1*0.
              !  endif 
              !  if (vr == ichemspec(nchemspec)) then
              !        f(l1-i,k,:,vr)=value1!*((l1-i)/(l1-0.))**4*0.

              ! do i=1,nghost
                 f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr)
              ! enddo
             !   f(l1-i,:,:,vr)=0.5*(f(l1-i+1,:,:,vr)+f(l1-i-1,:,:,vr))
               endif
            ! endif
          enddo
         enddo

       endif

      elseif (bc%location==iBC_X_TOP) then
      ! top boundary
        do i=1,nghost
        f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)+sgn*f(l2-i,:,:,vr); 
        enddo
      else
        print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_stream_x
 !******************************************************************** 
  subroutine bc_stream_y(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i, vr
      real :: value1, value2


      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


    if (bc%location==iBC_Y_BOT) then
      ! bottom boundary
        do i=1,nghost
         f(:,m2-i,:,vr)=f(:,m2,:,vr) 
      !   f(:,m2-i,:,vr)=2*f(:,m2,:,vr)+sgn*f(:,m2+i,:,vr); 
        enddo
      elseif (bc%location==iBC_Y_TOP) then
      ! top boundary
        do i=1,nghost
        f(:,m2+i,:,vr)=f(:,m2,:,vr)
       ! f(:,m2+i,:,vr)=2*f(:,m2,:,vr)+sgn*f(:,m2-i,:,vr);
        enddo
      else
        print*, "bc_BL_y: ", bc%location, " should be `top(", &
                        iBC_Y_TOP,")' or `bot(",iBC_Y_BOT,")'"
      endif
!
    endsubroutine bc_stream_y
 !********************************************************************
 subroutine bc_stream_z(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i, vr
      real :: value1, value2


      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


    if (bc%location==iBC_Z_BOT) then
      ! bottom boundary
        do i=1,nghost
         f(:,:,n2-i,vr)=f(:,:,n2,vr)!+2*f(:,m2,:,vr)*0.!+sgn*f(:,m2-i,:,vr); 
        enddo
      elseif (bc%location==iBC_Z_TOP) then
      ! top boundary
        do i=1,nghost
        f(:,:,n2+i,vr)=f(:,:,n2,vr)!+2*f(:,m2,:,vr)*0.!+sgn*f(:,m2+i,:,vr); 
        enddo
      else
        print*, "bc_BL_z: ", bc%location, " should be `top(", &
                        iBC_Z_TOP,")' or `bot(",iBC_Z_BOT,")'"
      endif
!
    endsubroutine bc_stream_z
 !********************************************************************
  subroutine bc_equil_x(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2

    if (bc%location==iBC_X_BOT) then
      ! bottom boundary

      if (vr==1) then
           do i=0,nghost
            f(l1-i,:,:,vr)=value1
           enddo 
      endif


      if (vr==4) then
           do i=0,nghost
            f(l1-i,:,:,4)=f(l1,:,:,4)
           enddo 
      endif

      if (vr==5) then
          do i=0,nghost
            f(l1-i,:,:,vr)=2.*f(l1,:,:,vr)-f(l1+i,:,:,vr)
          enddo 
      endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
             f(l1-i,:,:,vr)=2.*f(l1,:,:,vr)-f(l1+i,:,:,vr)
          enddo
       endif

      elseif (bc%location==iBC_X_TOP) then
      ! top boundary

      if (vr==1) then
           do i=0,nghost
            f(l2+i,:,:,vr)=value1
           enddo 
      endif


      if (vr==4) then
           do i=0,nghost
            f(l2+i,:,:,vr)=f(l2,:,:,vr)
           enddo 
      endif

      if (vr==5) then
          do i=0,nghost
            f(l2+i,:,:,vr)=2.*f(l2,:,:,vr)-f(l2-i,:,:,vr)
          enddo 
      endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
             f(l2+i,:,:,vr)=2.*f(l2,:,:,vr)-f(l2-i,:,:,vr)
          enddo
       endif

    !   do i=1,nghost
     !     f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)!+sgn*f(l2-i,:,:,vr);
     !   enddo


      else
        print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_equil_x
!***********************************************************************
 subroutine bc_equil_y(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2

    if (bc%location==iBC_Y_BOT) then
      ! bottom boundary

      if (vr==1) then
           do i=0,nghost
            f(:,m1-i,:,vr)=value1
           enddo 
      endif


      if (vr==4) then
           do i=0,nghost
            f(:,m1-i,:,vr)=f(:,m1,:,vr)
           enddo 
      endif

      if (vr==5) then
          do i=0,nghost
            f(:,m1-i,:,vr)=2.*f(:,m1,:,vr)-f(:,m1+i,:,vr)
          enddo 
      endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
             f(:,m1-i,:,vr)=2.*f(:,m1,:,vr)-f(:,m1+i,:,vr)
          enddo
       endif

      elseif (bc%location==iBC_Y_TOP) then
      ! top boundary

      if (vr==1) then
           do i=0,nghost
            f(:,m2+i,:,vr)=value1
           enddo 
      endif


      if (vr==4) then
           do i=0,nghost
            f(:,m2+i,:,vr)=f(:,m2,:,vr)
           enddo 
      endif

      if (vr==5) then
          do i=0,nghost
            f(:,m2+i,:,vr)=2.*f(:,m2,:,vr)-f(:,m2-i,:,vr)
          enddo 
      endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
             f(:,m2+i,:,vr)=2.*f(:,m2,:,vr)-f(:,m2-i,:,vr)
          enddo
       endif

    !   do i=1,nghost
     !     f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)!+sgn*f(l2-i,:,:,vr);
     !   enddo


      else
        print*, "bc_BL_y: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_equil_y
!**********************************************************************

  subroutine spec_input(f,sgn,bc)
   !
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2

        if (bc%location==iBC_X_BOT) then
      ! bottom boundary

        if (vr==1 ) then
          do i=0,nghost;   f(l1-i,:,:,vr)=value1;  enddo
        endif

         if (vr==5 ) then
          do i=0,nghost;   f(l1-i,:,:,vr)=log(value1);  enddo
     !      print*,log(value1)
        endif

        if (vr==4) then
          do i=0,nghost;   f(l1-i,:,:,vr)=f(l1,:,:,vr);  enddo
        endif

      !  if (vr==5 .or. vr==9) then
       if (vr >= ichemspec(1)) then
         if ( vr==9) then
           do i=0,nghost;   f(l1-i,:,:,vr)=value1;  enddo
        else
           do i=0,nghost;   f(l1-i,:,:,vr)=f(l1,:,:,vr);  enddo
        endif
       endif

        elseif (bc%location==iBC_X_TOP) then
      ! top boundary

        do i=1,nghost
          f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)!+sgn*f(l2-i,:,:,vr);
        enddo


        else
          print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
        endif
!
  endsubroutine spec_input
!***********************************************************************
 subroutine bc_gpress_wall(f,sgn,bc)
!
! Natalia
!
    use Cdata
    use Sub
    use Deriv
    use Mpicomm, only: stop_it
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (l1+2) :: pp
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2



    if (bc%location==iBC_X_BOT) then
      ! bottom boundary

       if (vr==1) then
              do i=0,nghost;   f(l1-i,:,:,vr)=value1;  enddo
       endif

 !     if (vr==4) then
 !          do i=0,nghost;  f(l1-i,:,:,vr)=log(value1);  enddo
 !     endif

      if (vr==5) then

       if (.not. ldivtau) then
           do i=0,nghost
            f(l1-i,:,:,4)=f(l1,:,:,4)
            f(l1-i,:,:,5)=f(l1,:,:,5)

           enddo 
       else
         do i=0,nghost;   f(l1-i,:,:,5)=log(value1); enddo 

         do i=0,nghost
           pres(l1-i,:,:)=pres(l1-i+1,:,:)-divtau(l1-i,:,:,1)*dx
         enddo

         do i=0,nghost
           f(l1-i,:,:,4)=log(pres(l1,:,:)/value1/mmu1(l1,:,:)/Rgas); 
         enddo 

       endif

     endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
           f(l1-i,:,:,vr)=2*f(l1-i+1,:,:,vr)-f(l1-i+2,:,:,vr)
          enddo
       endif

      elseif (bc%location==iBC_X_TOP) then

       if (vr==1) then
              do i=0,nghost;   f(l2+i,:,:,vr)=value1;  enddo
       endif

 !     if (vr==4) then
 !          do i=0,nghost;  f(l1-i,:,:,vr)=log(value1);  enddo
 !     endif

      if (vr==5) then

       if (.not. ldivtau) then
           do i=0,nghost
            f(l2+i,:,:,4)=f(l2,:,:,4)
            f(l2+i,:,:,5)=f(l2,:,:,5)
           enddo 
       else
         do i=0,nghost;   f(l2+i,:,:,5)=log(value1); enddo 

         do i=0,nghost
           pres(l2+i,:,:)=pres(l2+i-1,:,:)+divtau(l2+i,:,:,1)*dx
         enddo

         do i=0,nghost
           f(l2+i,:,:,4)=log(pres(l2,:,:)/value1/mmu1(l2,:,:)/Rgas); 
         enddo 


      endif

     endif

       if (vr >= ichemspec(1)) then
         do i=0,nghost; 
           f(l2+i,:,:,vr)=2*f(l2+i-1,:,:,vr)-f(l2+i-2,:,:,vr)
          enddo
       endif


      ! top boundary
      !  do i=1,nghost
      !    f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)!+sgn*f(l2-i,:,:,vr);
      !  enddo
      else
        print*, "bc_stream_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_gpress_wall
!***********************************************************************

 subroutine bc_HstreamAir_x(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2, yy0

      yy0=3.

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


    if (bc%location==iBC_X_BOT) then
      ! bottom boundary

       if (vr==1) then
        do k=1,my
            if (abs(y(k)) .lt. yy0) then
              do i=0,nghost
                   f(l1-i,k,:,vr)=value1*(1.-(y(k)/yy0)**2); 
              enddo
            else
              do i=0,nghost;   f(l1-i,k,:,vr)=0.;  enddo
            !  do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
            endif
        
        enddo
       endif


       if (vr==5 .or. vr==4 ) then
         !  if (abs(y(k)) .lt. yy0) then
            do i=0,nghost;  f(l1-i,m1:my,:,vr)=log(value1);  enddo
         !  else
          !  do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
          !  do i=0,nghost; f(l1-i,:,:,vr)=f(l1,:,:,vr); enddo
          !   do i=0,nghost
          !      f(l1-i,:,:,vr)=0.5*(f(l1-i+1,:,:,vr)+f(l1-i-1,:,:,vr))
          !   enddo
          ! endif
       endif

     !   if (vr==4 ) then
     !       do i=0,nghost; f(l1-i,:,:,vr)=f(l1,:,:,vr); enddo
     ! endif



       if (vr >= ichemspec(1)) then

         do i=0,nghost; 
          do k=1,my
             if (abs(y(k)) .lt. yy0) then
                if (vr == ichemspec(nchemspec))  f(l1-i,k,:,vr)=value1*0.
                if (vr < ichemspec(nchemspec)) f(l1-i,k,:,vr)=value1*((l1-i)/(l1-0.))**4*0.
             else
                if (vr < ichemspec(nchemspec)) then
                 f(l1-i,k,:,vr)=value1*0.
                endif 
                if (vr == ichemspec(nchemspec)) then
                      f(l1-i,k,:,vr)=value1*0.!*((l1-i)/(l1-0.))**4*0.
             !    f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr)
             !   f(l1-i,:,:,vr)=0.5*(f(l1-i+1,:,:,vr)+f(l1-i-1,:,:,vr))
               endif
             endif
          enddo
         enddo

       endif

      elseif (bc%location==iBC_X_TOP) then
      ! top boundary
        do i=1,nghost
        f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)+sgn*f(l2-i,:,:,vr); 
        enddo
      else
        print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_HstreamAir_x
 !******************************************************************** 
   subroutine bc_simple_x(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,vr
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


      if (bc%location==iBC_X_BOT) then
      ! bottom boundary 
       do i=0,nghost; f(l1-i,:,:,vr)=f(l1,:,:,vr); enddo

      elseif (bc%location==iBC_X_TOP) then
      ! top boundary
        do i=0,nghost
        f(l2+i,:,:,vr)=f(l2,:,:,vr)
        enddo
      else
        print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_simple_x
 !******************************************************************** 

    subroutine special_before_boundary(f)
!
!   Possibility to modify the f array before the boundaries are
!   communicated.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-jul-06/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
!
      if (NO_WARN) print*,f(1,1,1,1)
!
    endsubroutine special_before_boundary
!
!********************************************************************

!************        DO NOT DELETE THE FOLLOWING       **************
!********************************************************************
!**  This is an automatically generated include file that creates  **
!**  copies dummy routines from nospecial.f90 for any Special      **
!**  routines not implemented in this file                         **
!**                                                                **
    include '../special_dummies.inc'
!********************************************************************

endmodule Special

