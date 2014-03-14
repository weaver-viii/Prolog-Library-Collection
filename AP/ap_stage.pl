:- module(
  ap_stage,
  [
    ap_stages/2 % +AP:iri
                % +AP_Stages:list(compound)
  ]
).

/** <module> Auto-process stages

Runs stages in an automated process.

# Options for AP stages

The following options can be added to AP stages:
  * =|args(+PostfixedArguments:list)|=
  * =|between(+Low:integer, +High:integer)|=
  * =|from(+Directory:atom,+Base:atom,+FileType:atom)|=
  * =|name(+Name:atom)|=
    The name of the stage.
    This is e.g. used as the column label in tabular overviews of APs.
  * =|to(+Base:atom,+FileType:atom)|=

@author Wouter Beek
@tbd Add support for option =|finished(+Finished:boolean)|=,
     allowing previously finished stages to be skipped.
@version 2013/10-2014/03
*/

:- use_module(ap(ap_db)).
:- use_module(ap(ap_dir)).
:- use_module(generics(error_ext)).
:- use_module(library(debug)).
:- use_module(library(semweb/rdfs)).
:- use_module(os(datetime_ext)).
:- use_module(rdf(rdf_container)).
:- use_module(rdf(rdf_datatype)).
:- use_module(rdf(rdf_build)).
:- use_module(xml(xml_namespace)).

:- xml_register_namespace(ap, 'http://www.wouterbeek.com/ap.owl#').



%! ap_stages(+AP:iri, +AP_Stages:list(compound)) is det.

ap_stages(AP, AP_Stages):-
  create_initial_stage(AP, AP_Stage),
  ap_stages0(AP_Stage, AP_Stages).

ap_stages0(_, []):- !.
ap_stages0(AP_Stage1, [Mod:ap_stage(O1,Goal)|T]):-
  catch(
    (
      ap_stage_begin(O1, AP_Stage1),
      ap_stage(O1, AP_Stage1, Mod:Goal),
      ap_stage_end(AP_Stage1),
      (T == [], ! ; create_next_stage(AP_Stage1, AP_Stage2)),
      ap_stages0(AP_Stage2, T)
    ),
    Error,
    ap_catcher(AP_Stage1, Error, T)
  ).

ap_stage_begin(O1, AP_Stage):-
  option(name(Name), O1),
  rdf_assert_datatype(AP_Stage, ap:name, xsd:string, Name, ap),

  % DEB
  current_date_time(DateTime),
  debug(ap, '  Starting AP Stage ~w at ~w.', [Name,DateTime]).

ap_catcher(AP_Stage, Error, AP_Stages):-
  rdf_assert_individual(AP_Stage, ap:'Error', ap),
  rdf_assert_datatype(AP_Stage, ap:status, xsd:string, error, ap),
  with_output_to(atom(Atom), write_canonical_catch(Error)),
  rdf_assert_datatype(AP_Stage, ap:error, xsd:string, Atom, ap),
  never_reached(AP_Stage, AP_Stages).

never_reached(_, []):- !.
never_reached(AP_Stage1, [_:ap_stage(O1,_)|T]):-
  create_next_stage(AP_Stage1, AP_Stage2),
  rdf_assert_individual(AP_Stage2, ap:'NeverReached', ap),
  ap_stage_begin(O1, AP_Stage2),
  rdf_assert_datatype(AP_Stage2, ap:status, xsd:string, never_reached, ap),
  never_reached(AP_Stage2, T).


%! ap_stage(+Options:list(nvpair), +AP_Stage:iri, :Goal) is det.
% `Goal` receives the from and to files as arguments.
%
% The following options are supported:
%   * =|args(+Arguments:list)|=
%     Additional, goal-specific arguments.
%     Default: the empty list.
%   * =|stat_lag(+Interval:positive_interval)|=
%     The lag between statistics updates in seconds.
%     Default: =10=.
%   * =|to(?ToFile:atom,?ToFileType:atom)|=
%     Identifies the output from a script stage.
%     The directory is not included since this is fixed to
%     the process' output directory.
% `ToDirectory` is the atomic name of the directory where
%  the results are stored.

:- meta_predicate(ap_stage(+,+,:)).
ap_stage(O1, AP_Stage, Goal):-
  is_initial_stage(AP_Stage), !,
  once(rdf_collection_member(AP_Stage, AP, ap)),
  ap_directory(AP, write, input, ToDir),
  ap_stage_dirs(O1, AP_Stage, _NoFromDir, ToDir, Goal).
ap_stage(O1, AP_Stage, Goal):-
  ap_stage_from_directory(O1, AP_Stage, FromDir),
  ap_stage_to_directory(O1, AP_Stage, ToDir),
  ap_stage_dirs(O1, AP_Stage, FromDir, ToDir, Goal).

is_initial_stage(AP_Stage):-
  rdf_datatype(AP_Stage, ap:stage, xsd:integer, -1, ap).


:- meta_predicate(ap_stage_dirs(+,+,+,+,:)).
% This stage has not been perfomed yet.
ap_stage_dirs(O1, AP_Stage, FromDir, ToDir, Goal):-
  % From directory or file.
  ap_stage_from_arg(O1, AP_Stage, FromDir, FromArg),

  % To directory or file.
  ap_stage_to_arg(O1, ToDir, ToArg),

  % Make sure the arguments option is present.
  option(args(Args), O1, []),

  (
    option(between(Low,High), O1)
  ->
    forall(
      between(Low, High, N),
      execute_goal(AP_Stage, Goal, [FromArg,ToArg,AP_Stage,N|Args])
    )
  ;
    execute_goal(AP_Stage, Goal, [FromArg,ToArg,AP_Stage|Args])
  ), !.
ap_stage_dirs(_, _, _, _, _).

ap_stage_end(AP_Stage):-
  add_succeed(AP_Stage),

  % DEB
  rdf_datatype(AP_Stage, ap:name, xsd:string, Name, ap),
  current_date_time(DateTime),
  debug(ap, '  Ended AP Stage ~w at ~w.', [Name,DateTime]).


%! ap_stage_from_arg(
%!   +Options:list(nvpair),
%!   +AP_Stage:iri,
%!   +FromDir:atom,
%!   -FromArg:atom
%! ) is det.

% Read the from file located in the previous stage directory.
ap_stage_from_arg(O1, _, FromDir, FromArg):-
  option(from(_,FromFileName,FromFileType), O1),
  nonvar(FromFileName),
  nonvar(FromFileType),
  absolute_file_name(
    FromFileName,
    FromArg,
    [
      access(read),
      file_errors(fail),
      file_type(FromFileType),
      relative_to(FromDir)
    ]
  ).
% Initialization of the input stage.
% No "from" directory.
ap_stage_from_arg(_, AP_Stage, _NoFromDir, _NoFromArg):-
  rdf_datatype(AP_Stage, ap:stage, xsd:integer, -1, ap), !.
% Read from the previous stage directory.
ap_stage_from_arg(_, _, FromDir, FromDir):-
  access_file(FromDir, read).


%! ap_stage_from_directory(
%!   +Options:list(nvpair),
%!   +AP_Stage:iri,
%!   -FromDirectory:atom
%! ) is det.
% Creates a directory in `Data` for the given stage number
% and adds it to the file search path.

% Use the directory that is specified as an option, if it exists.
ap_stage_from_directory(O1, AP_Stage, FromDir):-
  option(from(FromDirName,_,_), O1),
  nonvar(FromDirName), !,
  rdf_collection_member(AP_Stage, AP, ap),
  ap_directory(AP, write, FromDirName, FromDir).
ap_stage_from_directory(_, AP_Stage, StageDir):-
  ap_stage_directory(AP_Stage, write, StageDir).


%! ap_stage_to_arg(
%!   +Options:list(nvpair),
%!   +ToDirectory:atom,
%!   -ToArgument
%! ) is det.

ap_stage_to_arg(O1, ToDir, ToArg):-
  option(to(_,ToFileName,ToFileType), O1),
  nonvar(ToFileName),
  nonvar(ToFileType), !,

  % Write to the to file located in the next stage directory.
  absolute_file_name(
    ToFileName,
    ToArg,
    [
      access(write),
      file_errors(fail),
      file_type(ToFileType),
      relative_to(ToDir)
    ]
  ).
% Write to the next stage directory.
ap_stage_to_arg(_, ToDir, ToDir):-
  access_file(ToDir, write).


%! ap_stage_to_directory(
%!   +Options:list(nvpair),
%!   +AP_Stage:iri,
%!   -ToDirectory:atom
%! ) is det.
% Creates a directory in `Data` for the given stage number
% and adds it to the file search path.

% Specific directory specified as option.
ap_stage_to_directory(O1, _, ToDir3):-
  option(to(ToDir1,_,_), O1),
  nonvar(ToDir1), !,
  ToDir2 =.. [ToDir1,'.'],
  absolute_file_name(
    ToDir2,
    ToDir3,
    [access(write),file_errors(fail),file_type(directory)]
  ).
% The directory for the next stage.
ap_stage_to_directory(_, AP_Stage, ToDir):-
  rdf_datatype(AP_Stage, ap:stage, xsd:integer, StageNum1, ap),
  StageNum2 is StageNum1 + 1,
  ap_stage_directory_name(StageNum2, StageName),
  rdf_collection_member(AP_Stage, AP, ap),
  ap_directory(AP, write, StageName, ToDir).


:- meta_predicate(execute_goal(+,:,+)).
execute_goal(AP_Stage, Goal, Args):-
  setup_call_cleanup(
    get_time(Begin),
    apply(Goal, Args),
    (
      get_time(End),
      Delta is End - Begin,
      rdf_assert_datatype(
        AP_Stage,
        ap:duration,
        xsd:duration,
        duration(0,Delta),
        ap
      )
    )
  ).

