## Copyright (C) 2006 David Bateman <dbateman@free.fr>
##
## This file is part of Octave.
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, write to the Free
## Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
## 02110-1301, USA.

## -*- texinfo -*-
## @deftypefn {Function File} {} acotd (@var{x})
## Compute the inverse cotangent of an angle in degrees.
## @seealso{atan, tand}
## @end deftypefn

function y = acotd (x)
  if (nargin != 1)
    print_usage ();
  endif
  y = atand (1 ./ x);
endfunction

%!error(acotd())
%!error(acotd(1,2))
%!assert(acotd(0:10:90),180./pi.*acot(0:10:90),-10*eps)
