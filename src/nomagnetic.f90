! $Id: nomagnetic.f90,v 1.11 2002-06-04 08:12:02 brandenb Exp $

module Magnetic

  use Cparam

  implicit none

  integer :: dummy              ! We cannot define empty namelists
  namelist /magnetic_init_pars/ dummy
  namelist /magnetic_run_pars/  dummy

  ! run parameters
  real :: va2=0.

  ! other variables (needs to be consistent with reset list below)
  integer :: i_b2m=0,i_bm2=0,i_j2m=0,i_jm2=0,i_abm=0,i_jbm=0

  contains

!***********************************************************************
    subroutine register_aa()
!
!  Initialise variables which should know that we solve for the vector
!  potential: iaa, etc; increase nvar accordingly
!  3-may-2002/wolf: dummy routine
!
      use Cdata
      use Mpicomm
      use Sub
!
      logical, save :: first=.true.
!
      if (.not. first) call stop_it('register_aa called twice')
      first = .false.
!
      lmagnetic = .false.
!
!  identify version number
!
      if (lroot) call cvs_id( &
           "$RCSfile: nomagnetic.f90,v $", &
           "$Revision: 1.11 $", &
           "$Date: 2002-06-04 08:12:02 $")
!
    endsubroutine register_aa
!***********************************************************************
    subroutine init_aa(f,xx,yy,zz)
!
!  initialise magnetic field; called from start.f90
!  3-may-2002/wolf: dummy routine
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar) :: f
      real, dimension (mx,my,mz)      :: xx,yy,zz
!
      if(ip==0) print*,xx,yy,zz !(keep compiler quiet)
    endsubroutine init_aa
!***********************************************************************
    subroutine daa_dt(f,df,uu,rho1,TT1)
!
!  magnetic field evolution
!  3-may-2002/wolf: dummy routine
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar) :: f,df
      real, dimension (nx,3) :: uu
      real, dimension (nx) :: rho1,TT1,cs2
!
      if(ip==0) print*,f,df,uu,rho1,TT1 !(keep compiler quiet)
    endsubroutine daa_dt
!***********************************************************************
    subroutine rprint_magnetic(lreset)
!
!  reads and registers print parameters relevant for magnetic fields
!  dummy routine
!   3-may-02/axel: coded
!
      use Cdata
!
      logical :: lreset
!
!  write column where which magnetic variable is stored
!  idl needs this even if everything is zero
!
      open(3,file='tmp/magnetic.pro')
      write(3,*) 'i_abm=',i_abm
      write(3,*) 'i_jbm=',i_jbm
      write(3,*) 'i_b2m=',i_b2m
      write(3,*) 'i_bm2=',i_bm2
      write(3,*) 'i_j2m=',i_j2m
      write(3,*) 'i_jm2=',i_jm2
      write(3,*) 'nname=',nname
      write(3,*) 'iaa=',iaa
      write(3,*) 'iax=',iax
      write(3,*) 'iay=',iay
      write(3,*) 'iaz=',iaz
      close(3)
!
    endsubroutine rprint_magnetic
!***********************************************************************

endmodule Magnetic
