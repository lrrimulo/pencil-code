! $Id: nograv.f90,v 1.6 2002-06-04 08:12:02 brandenb Exp $

module Gravity

!
!  Dummy model: no gravity
!

  use Cparam

  implicit none

  integer :: dummy              ! We cannot define empty namelists
  namelist /grav_init_pars/ dummy
  namelist /grav_run_pars/  dummy

  contains

!***********************************************************************
    subroutine register_grav()
!
!  initialise gravity flags
!
!  9-jan-02/wolf: coded
! 28-mar-02/axel: adapted from grav_z
!
      use Cdata
      use Mpicomm
      use Sub
!
      logical, save :: first=.true.
!
      if (.not. first) call stop_it('register_grav called twice')
      first = .false.
!
!  identify version number (generated automatically by CVS)
!
      if (lroot) call cvs_id( &
           "$RCSfile: nograv.f90,v $", &
           "$Revision: 1.6 $", &
           "$Date: 2002-06-04 08:12:02 $")
!
      lgrav = .false.
      lgravz = .false.
      lgravr = .false.
!
    endsubroutine register_grav
!***********************************************************************
    subroutine init_grav(f,xx,yy,zz)
!
!  initialise gravity; called from start.f90
!   9-jan-02/wolf: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
!
! Not doing anything (this might change if we decide to store gg)
!
      if(ip==0) print*,f,xx,yy,zz !(keep compiler quiet)
    endsubroutine init_grav
!***********************************************************************
    subroutine duu_dt_grav(f,df)
!
!  add nothing to duu/dt
!
! 28-mar-02/axel: adapted from grav_z
!
      use Cdata
!      use Mpicomm
      use Sub
      use Slices
!
      real, dimension (mx,my,mz,mvar) :: f,df
!
      if(ip==0) print*,f,df  !(keep compiler quiet)
    endsubroutine duu_dt_grav
!***********************************************************************
    subroutine potential(xmn,ymn,zmn,rmn, pot)
!
!  gravity potential
!  28-mar-02/axel: adapted from grav_z
!
      use Cdata, only: nx,lroot
!
      real, dimension (nx,1,1) :: xmn,rmn, pot
      real :: ymn,zmn
!
      if (lroot) print*,'potential: should not have been called'
      pot = 0.
!
      if(ip==0) print*,xmn,ymn,zmn,rmn
    endsubroutine potential
!***********************************************************************

endmodule Gravity
