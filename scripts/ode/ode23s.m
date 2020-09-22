########################################################################
##
## Copyright (C) 2006-2020 The Octave Project Developers
##
## See the file COPYRIGHT.md in the top-level directory of this
## distribution or <https://octave.org/copyright/>.
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.
##
########################################################################

## -*- texinfo -*-
## @deftypefn  {} {[@var{t}, @var{y}] =} ode23s (@var{fun}, @var{trange}, @var{init})
## @deftypefnx {} {[@var{t}, @var{y}] =} ode23s (@var{fun}, @var{trange}, @var{init}, @var{ode_opt})
## @deftypefnx {} {[@var{t}, @var{y}] =} ode23s (@dots{}, @var{par1}, @var{par2}, @dots{})
## @deftypefnx {} {[@var{t}, @var{y}, @var{te}, @var{ye}, @var{ie}] =} ode23s (@dots{})
## @deftypefnx {} {@var{solution} =} ode23s (@dots{})
##
## Solve a set of stiff Ordinary Differential Equations (stiff ODEs) with a
## @nospell{Rosenbrock} method of order (2,3).
##
## @var{fun} is a function handle, inline function, or string containing the
## name of the function that defines the ODE: @code{M y' = f(t,y)}.  The
## function must accept two inputs where the first is time @var{t} and the
## second is a column vector of unknowns @var{y}.  @var{M} is a constant mass
## matrix, non-singular and possibly sparse.  Set the field @qcode{"Mass"} in
## @var{odeopts} using @var{odeset} to specify a mass matrix.
##
## @var{trange} specifies the time interval over which the ODE will be
## evaluated.  Typically, it is a two-element vector specifying the initial
## and final times (@code{[tinit, tfinal]}).  If there are more than two
## elements then the solution will also be evaluated at these intermediate
## time instances using an interpolation procedure of the same order as the
## one of the solver.
##
## By default, @code{ode23s} uses an adaptive timestep with the
## @code{integrate_adaptive} algorithm.  The tolerance for the timestep
## computation may be changed by using the options @qcode{"RelTol"} and
## @qcode{"AbsTol"}.
##
## @var{init} contains the initial value for the unknowns.  If it is a row
## vector then the solution @var{y} will be a matrix in which each column is
## the solution for the corresponding initial value in @var{init}.
##
## The optional fourth argument @var{ode_opt} specifies non-default options to
## the ODE solver.  It is a structure generated by @code{odeset}.
## @code{ode23s} will ignore the following options: @qcode{"BDF"},
## @qcode{"InitialSlope"}, @qcode{"MassSingular"}, @qcode{"MStateDependence"},
## @qcode{"MvPattern"}, @qcode{"MaxOrder"}, @qcode{"Non-negative"}.
##
## The function typically returns two outputs.  Variable @var{t} is a
## column vector and contains the times where the solution was found.  The
## output @var{y} is a matrix in which each column refers to a different
## unknown of the problem and each row corresponds to a time in @var{t}.  If
## @var{trange} specifies intermediate time steps, only those will be returned.
##
## The output can also be returned as a structure @var{solution} which has a
## field @var{x} containing a row vector of times where the solution was
## evaluated and a field @var{y} containing the solution matrix such that each
## column corresponds to a time in @var{x}.  Use
## @w{@code{fieldnames (@var{solution})}} to see the other fields and
## additional information returned.
##
## If using the @qcode{"Events"} option then three additional outputs may be
## returned.  @var{te} holds the time when an Event function returned a zero.
## @var{ye} holds the value of the solution at time @var{te}.  @var{ie}
## contains an index indicating which Event function was triggered in the case
## of multiple Event functions.
##
## Example: Solve the stiff @nospell{Van der Pol} equation
##
## @example
## @group
## f = @@(@var{t},@var{y}) [@var{y}(2); 1000*(1 - @var{y}(1)^2) * @var{y}(2) - @var{y}(1)];
## opt = odeset ('Mass', [1 0; 0 1], 'MaxStep', 1e-1);
## [vt, vy] = ode23s (f, [0 2000], [2 0], opt);
## @end group
## @end example
## @seealso{odeset, daspk, dassl}
## @end deftypefn

function varargout = ode23s (fun, trange, init, varargin)

  if (nargin < 3)
    print_usage ();
  endif

  solver = "ode23s";
  order = 2;

  if (nargin >= 4)
    if (! isstruct (varargin{1}))
      ## varargin{1:len} are parameters for fun
      odeopts = odeset ();
      funarguments = varargin;
    elseif (numel (varargin) > 1)
      ## varargin{1} is an ODE options structure opt
      odeopts = varargin{1};
      funarguments = {varargin{2:numel (varargin)}};
    else
      ## varargin{1} is an ODE options structure opt
      odeopts = varargin{1};
      funarguments = {};
    endif
  else  # nargin == 3
    odeopts = odeset ();
    funarguments = {};
  endif

  if (! isnumeric (trange) || ! isvector (trange))
    error ("Octave:invalid-input-arg",
           "ode23s: TRANGE must be a numeric vector");
  endif

  if (numel (trange) < 2)
    error ("Octave:invalid-input-arg",
           "ode23s: TRANGE must contain at least 2 elements");
  elseif (trange(2) == trange(1))
    error ("Octave:invalid-input-arg",
           "ode23s: invalid time span, TRANGE(1) == TRANGE(2)");
  else
    direction = sign (trange(2) - trange(1));
  endif
  trange = trange(:);

  if (! isnumeric (init) || ! isvector (init))
    error ("Octave:invalid-input-arg",
           "ode23s: INIT must be a numeric vector");
  endif
  init = init(:);

  if (ischar (fun))
    if (! exist (fun))
      error ("Octave:invalid-input-arg",
             ['ode23s: function "' fun '" not found']);
    endif
    fun = str2func (fun);
  endif
  if (! is_function_handle (fun))
    error ("Octave:invalid-input-arg",
           "ode23s: FUN must be a valid function handle");
  endif

  ## Start preprocessing, have a look which options are set in odeopts,
  ## check if an invalid or unused option is set.
  [defaults, classes, attributes] = odedefaults (numel (init),
                                                 trange(1), trange(end));

  persistent ode23s_ignore_options = ...
    {"BDF", "InitialSlope", "MassSingular", "MStateDependence", ...
     "MvPattern", "MaxOrder", "NonNegative"};

  defaults   = rmfield (defaults, ode23s_ignore_options);
  classes    = rmfield (classes, ode23s_ignore_options);
  attributes = rmfield (attributes, ode23s_ignore_options);

  odeopts = odemergeopts ("ode23s", odeopts, defaults, classes, attributes);

  odeopts.funarguments = funarguments;
  odeopts.direction    = direction;
  ## ode23s ignores "NonNegative" option, but integrate_adaptive needs it...
  odeopts.havenonnegative = false;

  if (isempty (odeopts.OutputFcn) && nargout == 0)
    odeopts.OutputFcn = @odeplot;
    odeopts.haveoutputfunction = true;
  else
    odeopts.haveoutputfunction = ! isempty (odeopts.OutputFcn);
  endif

  if (isempty (odeopts.InitialStep))
    odeopts.InitialStep = odeopts.direction * ...
                          starting_stepsize (order, fun, trange(1), init,
                                             odeopts.AbsTol, odeopts.RelTol,
                                             strcmpi (odeopts.NormControl,
                                                      "on"),
                                             odeopts.funarguments);
  endif

  if (! isempty (odeopts.Mass) && isnumeric (odeopts.Mass))
    havemasshandle = false;
    mass = odeopts.Mass;     # constant mass
  elseif (isa (odeopts.Mass, "function_handle"))
    havemasshandle = true;   # mass defined by a function handle
    odeopts.Mass = feval (odeopts.Mass, trange(1), init,
                          odeopts.funarguments{:});
  else  # no mass matrix - create a diag-matrix of ones for mass
    havemasshandle = false;
    odeopts.Mass = diag (ones (length (init), 1), 0);
  endif

  ## Starting the initialization of the core solver ode23s

  if (nargout == 1)
    ## Single output requires auto-selected intermediate times,
    ## which is obtained by NOT specifying specific solution times.
    trange = [trange(1); trange(end)];
    odeopts.Refine = [];  # disable Refine when single output requested
  elseif (numel (trange) > 2)
    odeopts.Refine = [];  # disable Refine when specific times requested
  endif

  solution = integrate_adaptive (@runge_kutta_23s, ...
                                 order, fun, trange, init, odeopts);

  ## Postprocessing, do whatever when terminating integration algorithm
  if (odeopts.haveoutputfunction)  # Cleanup plotter
    feval (odeopts.OutputFcn, [], [], "done", odeopts.funarguments{:});
  endif
  if (! isempty (odeopts.Events))   # Cleanup event function handling
    ode_event_handler (odeopts.Events, solution.t(end), ...
                       solution.x(end,:).', "done", odeopts.funarguments{:});
  endif

  ## Print additional information if option Stats is set
  if (strcmpi (odeopts.Stats, "on"))
    nsteps    = solution.cntloop;             # cntloop from 2..end
    nfailed   = solution.cntcycles - nsteps;  # cntcycl from 1..end
    nfevals   = 5 * solution.cntcycles;       # number of ode evaluations
    ndecomps  = nsteps;  # number of LU decompositions
    npds      = 0;  # number of partial derivatives
    nlinsols  = 3 * nsteps;  # no. of solutions of linear systems

    printf ("Number of successful steps: %d\n", nsteps);
    printf ("Number of failed attempts:  %d\n", nfailed);
    printf ("Number of function calls:   %d\n", nfevals);
  endif

  if (nargout == 2)
    varargout{1} = solution.t;      # Time stamps are first output argument
    varargout{2} = solution.x;      # Results are second output argument
  elseif (nargout == 1)
    varargout{1}.x = solution.t.';  # Time stamps saved in field x (row vector)
    varargout{1}.y = solution.x.';  # Results are saved in field y (row vector)
    varargout{1}.solver = solver;   # Solver name is saved in field solver
    if (! isempty (odeopts.Events))
      varargout{1}.xe = solution.event{3};  # Time info when an event occurred
      varargout{1}.ye = solution.event{4};  # Results when an event occurred
      varargout{1}.ie = solution.event{2};  # Index info which event occurred
    endif
    if (strcmpi (odeopts.Stats, "on"))
      varargout{1}.stats = struct ();
      varargout{1}.stats.nsteps   = nsteps;
      varargout{1}.stats.nfailed  = nfailed;
      varargout{1}.stats.nfevals  = nfevals;
      varargout{1}.stats.npds     = npds;
      varargout{1}.stats.ndecomps = ndecomps;
      varargout{1}.stats.nlinsols = nlinsols;
    endif
  elseif (nargout == 5)
    varargout = cell (1,5);
    varargout{1} = solution.t;
    varargout{2} = solution.x;
    if (! isempty (odeopts.Events))
      varargout{3} = solution.event{3};  # Time info when an event occurred
      varargout{4} = solution.event{4};  # Results when an event occurred
      varargout{5} = solution.event{2};  # Index info which event occurred
    endif
  endif

endfunction


%!demo
%! ## Demo function: stiff Van Der Pol equation
%! fun = @(t,y) [y(2); 10*(1-y(1)^2)*y(2)-y(1)];
%! ## Calling ode23s method
%! tic ()
%! [vt, vy] = ode23s (fun, [0 20], [2 0]);
%! toc ()
%! ## Plotting the result
%! plot(vt,vy(:,1),'-o');

%!demo
%! ## Demo function: stiff Van Der Pol equation
%! fun = @(t,y) [y(2); 10*(1-y(1)^2)*y(2)-y(1)];
%! ## Calling ode23s method
%! odeopts = odeset ("Jacobian", @(t,y) [0 1; -20*y(1)*y(2)-1, 10*(1-y(1)^2)],
%!                   "InitialStep", 1e-3)
%! tic ()
%! [vt, vy] = ode23s (fun, [0 20], [2 0], odeopts);
%! toc ()
%! ## Plotting the result
%! plot(vt,vy(:,1),'-o');

%!demo
%! ## Demo function: stiff Van Der Pol equation
%! fun = @(t,y) [y(2); 100*(1-y(1)^2)*y(2)-y(1)];
%! ## Calling ode23s method
%! odeopts = odeset ("InitialStep", 1e-4);
%! tic ()
%! [vt, vy] = ode23s (fun, [0 200], [2 0]);
%! toc ()
%! ## Plotting the result
%! plot(vt,vy(:,1),'-o');

%!demo
%! ## Demo function: stiff Van Der Pol equation
%! fun = @(t,y) [y(2); 100*(1-y(1)^2)*y(2)-y(1)];
%! ## Calling ode23s method
%! odeopts = odeset ("Jacobian", @(t,y) [0 1; -200*y(1)*y(2)-1, 100*(1-y(1)^2)],
%!                   "InitialStep", 1e-4);
%! tic ()
%! [vt, vy] = ode23s (fun, [0 200], [2 0], odeopts);
%! toc ()
%! ## Plotting the result
%! plot(vt,vy(:,1),'-o');

%!demo
%! ## Demonstrate convergence order for ode23s
%! tol = 1e-5 ./ 10.^[0:5];
%! for i = 1 : numel (tol)
%!   opt = odeset ("RelTol", tol(i), "AbsTol", realmin);
%!   [t, y] = ode23s (@(t, y) -y, [0, 1], 1, opt);
%!   h(i) = 1 / (numel (t) - 1);
%!   err(i) = norm (y .* exp (t) - 1, Inf);
%! endfor
%!
%! ## Estimate order visually
%! loglog (h, tol, "-ob",
%!         h, err, "-b",
%!         h, (h/h(end)) .^ 2 .* tol(end), "k--",
%!         h, (h/h(end)) .^ 3 .* tol(end), "k-");
%! axis tight
%! xlabel ("h");
%! ylabel ("err(h)");
%! title ("Convergence plot for ode23s");
%! legend ("imposed tolerance", "ode23s (relative) error",
%!         "order 2", "order 3", "location", "northwest");
%!
%! ## Estimate order numerically
%! p = diff (log (err)) ./ diff (log (h))

%!test
%! [vt, vy] = ode23s (@(t,y) t - y + 1, [0 10], [1]);
%! assert ([vt(end), vy(end)], [10, exp(-10) + 10], 1e-3);

%!test
%! opts = odeset ('Mass', 5, 'Jacobian', -5, 'JConstant', 'on');
%! [vt, vy] = ode23s (@(t,y) 5 * (t - y + 1), [0 10], [1], opts);
%! assert ([vt(end), vy(end)], [10, exp(-10) + 10], 1e-3);

## We are using the "Van der Pol" implementation for all tests that are done
## for this function.  For further tests we also define a reference solution
## (computed at high accuracy).
%!function ydot = fpol (t, y)  # The Van der Pol ODE
%!  ydot = [y(2); 10 * (1 - y(1)^2) * y(2) - y(1)];
%!endfunction
%!function ydot = jac (t, y)   # The Van der Pol ODE
%!  ydot = [0 1; -20 * y(1) * y(2) - 1, 10 * (1 - y(1)^2)];
%!endfunction
%!function ref = fref ()       # The computed reference sol
%!  ref = [1.8610687248524305  -0.0753216319179125];
%!endfunction
%!function [val, trm, dir] = feve (t, y, varargin)
%!  val = fpol (t, y, varargin);  # We use the derivatives
%!  trm = zeros (2,1);            # that's why component 2
%!  dir = ones (2,1);             # does not seem to be exact
%!endfunction
%!function [val, trm, dir] = fevn (t, y, varargin)
%!  val = fpol (t, y, varargin);  # We use the derivatives
%!  trm = ones (2,1);             # that's why component 2
%!  dir = ones (2,1);             # does not seem to be exact
%!endfunction
%!function mas = fmas (t, y, varargin)
%!  mas = [1, 0; 0, 1];           # Dummy mass matrix for tests
%!endfunction
%!function mas = fmsa (t, y, varargin)
%!  mas = sparse ([1, 0; 0, 1]);  # A sparse dummy matrix
%!endfunction
%!function out = fout (t, y, flag, varargin)
%!  out = false;
%!  if (strcmp (flag, "init"))
%!    if (! isequal (size (t), [2, 1]))
%!      error ('fout: step "init"');
%!    endif
%!  elseif (isempty (flag))
%!    if (! isequal (size (t), [1, 1]))
%!      error ('fout: step "calc"');
%!    endif
%!  elseif (strcmp (flag, "done"))
%!    if (! isempty (t))
%!      warning ('fout: step "done"');
%!    endif
%!  else
%!    error ("fout: invalid flag <%s>", flag);
%!  endif
%!endfunction
%!
%!test  # two output arguments
%! [t, y] = ode23s (@fpol, [0 2], [2 0]);
%! assert ([t(end), y(end,:)], [2, fref], 1e-3);
%!test  # anonymous function instead of real function
%! fvdp = @(t,y) [y(2); 10 * (1 - y(1)^2) * y(2) - y(1)];
%! [t, y] = ode23s (fvdp, [0 2], [2 0]);
%! assert ([t(end), y(end,:)], [2, fref], 1e-3);
%!test  # extra input arguments passed through
%! [t, y] = ode23s (@fpol, [0 2], [2 0], 12, 13, "KL");
%! assert ([t(end), y(end,:)], [2, fref], 1e-3);
%!test  # empty OdePkg structure *but* extra input arguments
%! opt = odeset;
%! [t, y] = ode23s (@fpol, [0 2], [2 0], opt, 12, 13, "KL");
%! assert ([t(end), y(end,:)], [2, fref], 1e-2);
%!test  # InitialStep option
%! opt = odeset ("InitialStep", 1e-8);
%! [t, y] = ode23s (@fpol, [0 0.2], [2 0], opt);
%! assert ([t(2)-t(1)], [1e-8], 1e-9);
%!test  # MaxStep option
%! opt = odeset ("MaxStep", 1e-3);
%! sol = ode23s (@fpol, [0 0.2], [2 0], opt);
%! assert ([sol.x(5)-sol.x(4)], [1e-3], 1e-4);
%!test  # AbsTol option
%! opt = odeset ("AbsTol", 1e-5);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # AbsTol and RelTol option
%! opt = odeset ("AbsTol", 1e-8, "RelTol", 1e-8);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # RelTol and NormControl option -- higher accuracy
%! opt = odeset ("RelTol", 1e-8, "NormControl", "on");
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-4);
%!test  # Details of OutputSel and Refine can't be tested
%! opt = odeset ("OutputFcn", @fout, "OutputSel", 1, "Refine", 5);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%!test  # Stats must add further elements in sol
%! opt = odeset ("Stats", "on");
%! stat_str = evalc ("sol = ode23s (@fpol, [0 2], [2 0], opt);");
%! assert (strncmp (stat_str, "Number of successful steps:", 27));
%! assert (isfield (sol, "stats"));
%! assert (isfield (sol.stats, "nsteps"));
%!test  # Events option add further elements in sol
%! opt = odeset ("Events", @feve);
%! sol = ode23s (@fpol, [0 10], [2 0], opt);
%! assert (isfield (sol, "ie"));
%! assert (sol.ie(1), 2);
%! assert (isfield (sol, "xe"));
%! assert (isfield (sol, "ye"));
%!test  # Mass option as function
%! opt = odeset ("Mass", @fmas);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # Mass option as matrix
%! opt = odeset ("Mass", eye (2,2));
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # Mass option as sparse matrix
%! opt = odeset ("Mass", sparse (eye (2,2)));
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # Mass option as function and sparse matrix
%! opt = odeset ("Mass", @fmsa);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!test  # Jacobian option as function
%! opt = odeset ('Jacobian', @jac);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!testif HAVE_UMFPACK  # Sparse Jacobian
%! jac = @(t, y) sparse ([0 1; -20*y(1)*y(2)-1, 10*(1-y(1)^2)]);
%! opt = odeset ('Jacobian', jac);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);
%!testif HAVE_UMFPACK  # Jpattern
%! S = sparse ([0 1; 1 1]);
%! opt = odeset ("Jpattern", S);
%! sol = ode23s (@fpol, [0 2], [2 0], opt);
%! assert ([sol.x(end); sol.y(:,end)], [2; fref'], 1e-3);

## Note: The following options have no effect on this solver
##       therefore it makes no sense to test them here:
##
## "BDF"
## "InitialSlope"
## "MassSingular"
## "MStateDependence"
## "MaxOrder"
## "MvPattern"
## "NonNegative"

%!test # Check that imaginary part of solution does not get inverted
%! sol = ode23s (@(x,y) 1, [0 1], 1i);
%! assert (imag (sol.y), ones (size (sol.y)))
%! [x, y] = ode23s (@(x,y) 1, [0 1], 1i);
%! assert (imag (y), ones (size (y)))

## Test input validation
%!error ode23s ()
%!error ode23s (1)
%!error ode23s (1,2)
%!error <TRANGE must be a numeric> ode23s (@fpol, {[0 25]}, [3 15 1])
%!error <TRANGE must be a .* vector> ode23s (@fpol, [0 25; 25 0], [3 15 1])
%!error <TRANGE must contain at least 2 elements> ode23s (@fpol, [1], [3 15 1])
%!error <invalid time span>  ode23s (@fpol, [1 1], [3 15 1])
%!error <INIT must be a numeric> ode23s (@fpol, [0 25], {[3 15 1]})
%!error <INIT must be a .* vector> ode23s (@fpol, [0 25], [3 15 1; 3 15 1])
%!error <FUN must be a valid function handle> ode23s (1, [0 25], [3 15 1])