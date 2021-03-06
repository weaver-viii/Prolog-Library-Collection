:- module(
  call_ext,
  [
    call_det/1,          % :Goal_0
    call_det/2,          % :Goal_0, -IsDet
    call_n_sol/3,        % +N, :Select_1, :Goal_1
    call_n_times/2,      % +N, :Goal_0
    call_or_exception/1, % :Goal_0
    call_or_fail/1,      % :Goal_0
    call_timeout/2,      % +Time, :Goal_0
    concurrent_n_sols/3, % +N, :Select_1, :Goal_1
    forall/1,            % :Goal_0
    var_goal/1           % @Term
  ]
).

/** <module> Call extensions

@author Wouter Beek
@version 2016/04, 2016/07-2016/10
*/

:- use_module(library(lists)).
:- use_module(library(thread)).
:- use_module(library(time)).

:- meta_predicate
    call_det(0),
    call_det(0, -),
    call_n_sol(+, 1, 1),
    call_n_times(+, 0),
    call_or_exception(0),
    call_or_fail(0),
    call_timeout(+, 0),
    concurrent_n_sols(+, 1, 1),
    forall(0).





%! call_det(:Goal_0) is semidet.
%! call_det(:Goal_0, -IsDet) is det.

call_det(Goal_0) :-
  call_det(Goal_0, true).


call_det(Goal_0, Det) :-
  call(Goal_0),
  deterministic(Det).



%! call_n_sol(+N, :Select_1, :Goal_1) is det.

call_n_sol(N, Select_1, Goal_1) :-
  findnsols(N, X, call(Select_1, X), Xs),
  last(Xs, X),
  call(Goal_1, X).



%! call_n_times(+N, :Goal_0) is det.

call_n_times(N, Goal_0) :-
  forall(between(1, N, _), Goal_0).



%! call_or_exception(:Goal_0) is semidet.

call_or_exception(Goal_0) :-
  catch(Goal_0, E, true),
  (   var(E)
  ->  true
  ;   print_message(warning, E),
      fail
  ).



%! call_or_fail(:Goal_0) is semidet.

call_or_fail(Goal_0) :-
  catch(Goal_0, _, fail).



%! call_timeout(+Time, :Goal_0) is det.
%
% Time is a float, integer, or `inf`.

call_timeout(inf, Goal_0) :- !,
  call(Goal_0).
call_timeout(Time, Goal_0) :-
  call_with_time_limit(Time, Goal_0).



%! concurrent_n_sols(+N, :Select_1, :Goal_1) is det.

concurrent_n_sols(N, Select_1, Mod:Goal_1) :-
  findnsols(
    N,
    Mod:Goal_0,
    (
      call(Select_1, X),
      Goal_0 =.. [Goal_1,X]
    ),
    Goals
  ),
  concurrent(N, Goals, []).



%! forall(:Goal_0) is det.

forall(Goal_0) :-
  forall(Goal_0, true).



%! var_goal(@Term) is semidet.
%
% Succeeds for a variable or a module prefixes variable.

var_goal(X) :- var(X), !.
var_goal(_:X) :- var(X).
