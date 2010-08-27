! $Id$
!
!  This module contains FFT wrapper subroutines.
!
module Fourier
!
  use Cdata
  use Cparam
  use Messages, only: fatal_error
  use Mpicomm, only: transp
  use Sub, only: keep_compiler_quiet
!
  implicit none
!
  include 'fourier.h'
!
  interface fourier_transform_other
    module procedure fourier_transform_other_1
    module procedure fourier_transform_other_2
  endinterface
!
  interface fft_xy_parallel
    module procedure fft_xy_parallel_2D
    module procedure fft_xy_parallel_3D
    module procedure fft_xy_parallel_4D
  endinterface
!
  contains
!
!***********************************************************************
    subroutine fourier_transform(a_re,a_im,linv)
!
!  Subroutine to do fourier transform
!  The routine overwrites the input data
!
!  22-oct-02/axel+tarek: adapted from transform
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      if (nprocx>1) &
          call fatal_error ('fourier_transform', 'must have nprocx=1', lroot)
!
      if (present(linv)) then
        if (linv) &
            call fatal_error ('fourier_transform', 'only implemented for forwards transform', lroot)
      endif
!
      if (lroot .and. ip<10) print*,'transform_i: doing three FFTs'
      call fft(a_re,a_im, nx*ny*nz, nx, nx,-1)
      call transp(a_re,'y')
      call transp(a_im,'y')
      call fft(a_re,a_im, nx*ny*nz, nx, nx,-1)
      call transp(a_re,'z')
      call transp(a_im,'z')
      call fft(a_re,a_im, nx*ny*nz, nx, nx,-1)
!
!  Normalize
!
      a_re=a_re/nwgrid
      a_im=a_im/nwgrid
      if (lroot .and. ip<10) print*,'transform_i: fft has finished'
!
    endsubroutine fourier_transform
!***********************************************************************
    subroutine fourier_transform_xz(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x- and z-directions
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_xz', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xz)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_xz
!***********************************************************************
    subroutine fourier_transform_xy(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x- and y-directions
!
      real, dimension(nx,ny) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_xy', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_xy
!***********************************************************************
    subroutine fourier_transform_shear_xy(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x- and y-directions
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_xy_shear', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_shear_xy
!***********************************************************************
    subroutine fourier_transform_xy_xy(a_re,a_im,linv,lneed_im)
!
!  Subroutine to do Fourier transform in the x- and y-directions
!
      real, dimension(nx,ny), intent(inout) :: a_re,a_im
      logical, optional, intent(in) :: linv,lneed_im
!
      call fatal_error('fourier_transform_xy_xy', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
      call keep_compiler_quiet(present(lneed_im))
!
    endsubroutine fourier_transform_xy_xy
!***********************************************************************
    subroutine fourier_transform_y_y(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform of a 1-D array under MPI.
!
      real, dimension(ny) :: a_re, a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_y_y', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_y)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_y_y
!***********************************************************************
    subroutine fourier_transform_xy_xy_other(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x- and y-directions
!
      real, dimension(nx,ny) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_xy_xy_other', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_xy_xy_other
!***********************************************************************
    subroutine fourier_transform_x(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x-direction.
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_x', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_x)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_x
!***********************************************************************
    subroutine fourier_transform_y(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in the x-direction.
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_y', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_y)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_y
!***********************************************************************
    subroutine fourier_transform_shear(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform in shearing coordinates.
!
      real, dimension(nx,ny,nz) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_shear', &
          'this sub is not available in fourier_fft.f90!', lroot)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_shear
!***********************************************************************
    subroutine fourier_transform_other_1(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform on a 1-D array of arbitrary size.
!
      real, dimension(:) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_other_1', &
          'this sub is not available in fourier_fft.f90!', lroot)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_other_1
!***********************************************************************
    subroutine fourier_transform_other_2(a_re,a_im,linv)
!
!  Subroutine to do Fourier transform of a 2-D array of arbitrary size.
!
      real, dimension(:,:) :: a_re,a_im
      logical, optional :: linv
!
      call fatal_error('fourier_transform_other_2', &
          'this sub is not available in fourier_fft.f90!', lroot)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
!
    endsubroutine fourier_transform_other_2
!***********************************************************************
    subroutine fourier_shift_yz_y(a_re,shift_y)
!
!  Performs a periodic shift in the y-direction of an entire y-z plane by
!  the amount shift_y.
!
!  02-oct-07/anders: dummy
!
      real, dimension (ny,nz) :: a_re
      real :: shift_y
!
      call fatal_error('fourier_shift_yz_y', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_yz)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(shift_y)
!
    endsubroutine fourier_shift_yz_y
!***********************************************************************
    subroutine fourier_shift_y(a_re,shift_y)
!
!  Performs a periodic shift in the y-direction by the amount shift_y.
!
!  04-oct-07/anders: dummy
!
      real, dimension (nx,ny,nz) :: a_re
      real, dimension (nx) :: shift_y
!
      call fatal_error('fourier_shif_y', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_y)
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(shift_y)
!
    endsubroutine fourier_shift_y
!***********************************************************************
    subroutine fourier_transform_real_1(a,na,ifirst_fft,wsavex_temp,linv)
!
!   3-jul-08/dhruba: dummy routine
!
      real, dimension(na) :: a
      integer, intent(in) :: na,ifirst_fft
      logical, optional :: linv
      real, dimension(2*na+15),optional :: wsavex_temp
!
      call fatal_error('fourier_transform_real', &
          'this sub is not available in fourier_fft.f90!', lroot)
!
      call keep_compiler_quiet(a)
      call keep_compiler_quiet(na)
      call keep_compiler_quiet(ifirst_fft)
      call keep_compiler_quiet(present(linv))
      call keep_compiler_quiet(present(wsavex_temp))
!
    endsubroutine fourier_transform_real_1
!***********************************************************************
    subroutine fft_xy_parallel_2D(a_re,a_im,linv,lneed_im)
!
!  Subroutine to do FFT of distributed 2D data in the x- and y-direction.
!
      real, dimension (nx,ny), intent(inout) :: a_re, a_im
      logical, optional, intent(in) :: linv, lneed_im
!
      call fatal_error('fft_xy_parallel_2D', &
          'this sub is not available in fourier_fft.f90!')
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
      call keep_compiler_quiet(present(lneed_im))
!
    endsubroutine fft_xy_parallel_2D
!***********************************************************************
    subroutine fft_xy_parallel_3D(a_re,a_im,linv,lneed_im)
!
!  Subroutine to do FFT of distributed 3D data in the x- and y-direction.
!
      real, dimension (:,:,:), intent(inout) :: a_re, a_im
      logical, optional, intent(in) :: linv, lneed_im
!
      call fatal_error('fft_xy_parallel_3D', &
          'this sub is not available in fourier_fft.f90!')
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
      call keep_compiler_quiet(present(lneed_im))
!
    endsubroutine fft_xy_parallel_3D
!***********************************************************************
    subroutine fft_xy_parallel_4D(a_re,a_im,linv,lneed_im)
!
!  Subroutine to do FFT of distributed 4D data in the x- and y-direction.
!
      real, dimension (:,:,:,:), intent(inout) :: a_re, a_im
      logical, optional, intent(in) :: linv, lneed_im
!
      call fatal_error('fft_xy_parallel_4D', &
          'this sub is not available in fourier_fft.f90!')
!
      call keep_compiler_quiet(a_re)
      call keep_compiler_quiet(a_im)
      call keep_compiler_quiet(present(linv))
      call keep_compiler_quiet(present(lneed_im))
!
    endsubroutine fft_xy_parallel_4D
!***********************************************************************
    subroutine vect_pot_extrapol_z_parallel(in,out,factor)
!
!  Subroutine to do a z-extrapolation of a vector potential using
!  'factor' as a multiplication factor to the Fourier coefficients.
!
      real, dimension(:,:,:), intent(in) :: in
      real, dimension(:,:,:,:), intent(out) :: out
      real, dimension(:,:,:), intent(in) :: factor
!
      call fatal_error('vect_pot_extrapol_z_parallel', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(in)
      call keep_compiler_quiet(out)
      call keep_compiler_quiet(factor)
!
    endsubroutine vect_pot_extrapol_z_parallel
!***********************************************************************
    subroutine field_extrapol_z_parallel(in,out,factor)
!
!  Subroutine to do a z-extrapolation of a fields z-component using
!  'factor' as a multiplication factor to the Fourier coefficients.
!
      real, dimension(:,:), intent(in) :: in
      real, dimension(:,:,:,:), intent(out) :: out
      real, dimension(:,:,:), intent(in) :: factor
!
      call fatal_error('field_extrapol_z_parallel', &
          'this sub is not available in fourier_fft.f90!', lfirst_proc_xy)
!
      call keep_compiler_quiet(in)
      call keep_compiler_quiet(out)
      call keep_compiler_quiet(factor)
!
    endsubroutine field_extrapol_z_parallel
!***********************************************************************
endmodule Fourier
