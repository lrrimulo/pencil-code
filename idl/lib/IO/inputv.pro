FUNCTION inputv, file, DOUBLE=double, ONE=one, _EXTRA=extra
;; Read vector field from binary data file. If file does not exist,
;; return NaNs.
;; Keywords:
;;   DOUBLE  -- flag for double precision data
;;   ONE     -- if 1.0, use single precision, if 1.0D0, use double precision
;;              Use with start.pro's variable ONE like this:
;;                var=inputv('var.dat',ONE=ONE)
;; All other keywords (e.g. /SWAP_ENDIAN) are passed on to the OPENR
;; statement.
  common cdat,x,y,z,nx,ny,nz,nw,ntmax,date0,time0
  ;
  default, ONE, 1.0
  if (keyword_set(double)) then ONE=1.D0
  ;
  field=fltarr(nx,ny,nz,3)*ONE
  if ((findfile(file))[0] ne '') then begin
    close,1
    openr,1,file,/f77, _EXTRA=extra
    readu,1,field
    close,1
  endif else begin
    message,/informational,"No such file: '" + file + "'"
    field = field*!VALUES.F_NAN
  endelse
  ;
  return,field

END
