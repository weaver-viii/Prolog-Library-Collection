% PLC load file.

user:prolog_file_type(html, 'text/html'    ).
user:prolog_file_type(md,   'text/markdown').
user:prolog_file_type(txt,  'text/plain'   ).

:- initialization(load_plc).

% The load file for the Prolog Generics Collection.
% This assumes that the search path =project= is already defined
% by the parent project (PGC is a library).

load_plc:-
  set_project,
  
  % Check SWI-Prolog version.
  use_remote_module(pl(pl_version)),
gtrace,
  check_pl_version,

  % Set data subdirectory.
  use_remote_module(pl(pl_clas)),
gtrace,
  process_options,

  % Start logging.
  use_remote_module(generics(logging)),
gtrace,
  start_log.


% If there is no outer project, then PGC is the project.

set_project:-
  current_predicate(project/2), !.
set_project:-
  assert(user:project('PGC', 'Prolog Generics Collection')).

