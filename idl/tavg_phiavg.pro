;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   tavg_phiavg.pro   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;;  Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
;;;  Date:   16-Apr-2004
;;;
;;;  Description:
;;;   Time-average azimuthal averages in a given range.
;;;  Usage:
;;;   avg = tavg_phiavg()                ; average all PHIAVG files in
;;;                                      ; directory data/averages
;;;   avg = tavg_phiavg(DIR='data/avg2') ; average all PHIAVG files in
;;;                                      ; directorydata/avg2
;;;   avg = tavg_phiavg([2,10])          ; average PHIAVG1 to PHIAVG10
;;;   avg = tavg_phiavg([10.,35.])       ; average from time 10. to 35.

; ---------------------------------------------------------------------- ;

pro struct_mul, struc, fact, labels
;; Multiply all slots of structure STRUC indicated in LABELS with FACTOR.
;; Looks like we can only do this usign the execute function.
  cmd = ''
  for j=0,n_elements(labels)-1 do begin
    struc_l = 'struc.'+strtrim(labels[j],2)
    cmd = cmd + struc_l+'=fact*'+struc_l+' & '
  endfor
  if (execute(cmd) ne 1) then $
      message, 'STRUCT_MUL: Couldn''t execute "'+cmd+'"'
end

; ---------------------------------------------------------------------- ;

pro struct_add, struc1, struc2, labels
;; For all slots indicated in LABELS, add struc2 to struc1. 
;; Looks like we can only do this usign the execute function.
  cmd = ''
  for j=0,n_elements(labels)-1 do begin
    struc1_l = 'struc1.'+strtrim(labels[j],2)
    struc2_l = 'struc2.'+strtrim(labels[j],2)
    cmd = cmd + struc1_l+'='+struc1_l+'+'+struc2_l+' & '
  endfor
  if (execute(cmd) ne 1) then $
      message, 'STRUCT_MUL: Couldn''t execute "'+cmd+'"'
end

; ---------------------------------------------------------------------- ;

function tavg_phiavg, range, DIR=avgdir, QUIET=quiet

  datatopdir = 'data'
  default, avgdir, datatopdir+'/averages'
  default, quiet, 0

  ;; default range to include all averages
  spawn, 'cd ' + avgdir + '; ls PHIAVG* | sort -n -k1.7', res, /SH
  if (all(res eq '')) then message, "Found no PHIAVG[0-9]+ files in "+avgdir
  ;
  nums = strmid(res,6)
  default, range, minmax(long(nums))

  s = size(range)
  type = s[s[0]+1]
  if (type eq 2 or type eq 3) then begin ; integer or long
    range = [0,0] + range
    trange = [-1,1]*!values.d_infinity
  endif else if ((type eq 4) or (type eq 5)) then begin
    trange = range
    range = minmax(long(nums))
  endif

  first = 1
  count = 0.
  for i=range[0],range[1] do begin
    phiavgfile = 'PHIAVG'+strtrim(i,2)

    file = avgdir+'/'+phiavgfile

    if (any(findfile(file) ne '')) then begin
      avg_i = read_phiavg(avgdir+'/'+phiavgfile)
      if ((avg_i.t ge trange[0]) and (avg_i.t le trange[1])) then begin
        if (not quiet) then print, phiavgfile, ': t='+strtrim(avg_i.t,2)
        if (first) then begin
          avg = avg_i           ; copy first struct (for grid, etc.)
          struct_mul, avg, 0., avg.labels ; zero out content
          first = 0
        endif
        ;; Sum up and count
        struct_add, avg, avg_i, avg.labels
        count = count+1.
      endif else begin
        if (not quiet) then begin
          print, phiavgfile + ': t='+strtrim(avg_i.t,2) + ' not in trange = [' $
            + strtrim(trange[0],2) + ', ' + strtrim(trange[1],2) + ']'
        endif
      endelse

    endif else begin

      message, /INFO, 'No such file: ' + file

    endelse

  endfor

  if (count gt 0) then begin
    struct_mul, avg, 1./count, avg.labels ; normalize
  endif else begin
    message, /INFO, 'No data read -- all averages set to zero'
  endelse

  return, avg

end
; End of file tavg_phiavg.pro
