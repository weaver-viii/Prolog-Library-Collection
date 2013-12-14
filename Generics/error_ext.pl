:- module(
  error_ext,
  [
    idle_error/1, % +Reason
    rethrow/3 % :Goal
              % +Catcher
              % +Exception
  ]
).
:- reexport(
  library(error),
  [
    domain_error/2, % +Domain
                    % +Term
    existence_error/2, % +Type
                       % +Term
    instantiation_error/1,	% +Term
    permission_error/3, % +Action
                        % +Type
                        % +Term
    representation_error/1,	% +Reason
    syntax_error/1, % +Culprit
    type_error/2 % +Type
                 % +Term
  ]
).

/** <module> Error extensions

Exception handling predicates.

@author Wouter Beek
@version 2013/01, 2013/12
*/

:- meta_predicate rethrow(0,+,+).



idle_error(Format-Args):- !,
  format(atom(Reason), Format, Args),
  idle_error(Reason).
idle_error(Reason):-
  throw(error(idle_error(Reason), _)).

%! retrhow(:Goal, +Catcher, +Exception) is det.
% Catches an exception that is thrown lower in the stack, and reappropriates
% it for a new exception, to be caught by another method higher in the stack.
% This is used to provide more detailed ('higher-level') information for
% more generic ('lower-level') exceptions.
%
% Example: =convert_to_jpeg= catches the exception thrown by
% =convert_to_anything= and adds the more specific information that it is a
% conversion to *jpeg* that causes the exception, reusing a generic exception
% for convesions.
%
% @param Goal
% @param Catcher
% @param Exception

rethrow(Goal, Catcher, Exception):-
  catch(Goal, Catcher, throw(Exception)).
