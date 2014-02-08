:- module(
  ap_dir,
  [
    ap_clean/1, % +AP:iri
    ap_dir/4, % +AP:iri
              % +Mode:oneof([read,write])
              % +Subdir:atom
              % -AbsoluteDir:atom
    ap_dirs/2, % +AP:iri
               % -Directories:list(atom)
    ap_last_stage_dir/2, % +AP:iri
                         % -LastStageDirectory:atom
    ap_stage_dir/3, % +AP_Stage:iri
                    % +Mode:oneof([read,write])
                    % -AbsoluteDir:atom
    ap_stage_name/2 % +StageNumber:nonneg
                    % -StageName:atom
  ]
).

/** <module> Auto-processing directories

Directory management for running automated processes.

@author Wouter Beek
@version 2013/11, 2014/01-2014/02
*/

:- use_module(generics(atom_ext)).
:- use_module(generics(typecheck)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(semweb/rdfs)).
:- use_module(os(dir_ext)).
:- use_module(rdf(rdf_container)).
:- use_module(rdf(rdf_datatype)).
:- use_module(xml(xml_namespace)).

:- xml_register_namespace(ap, 'http://www.wouterbeek.com/ap.owl#').



%! ap_clean(+AP:iri) is det.
% This is run after results have been saved to the `Output` directory.

ap_clean(AP):-
  ap_dirs(AP, StageDirs),
  maplist(delete_directory([include_self(true),safe(true)]), StageDirs).


%! ap_dir(
%!   +AP:iri,
%!   +Mode:oneof([read,write]),
%!   +Subdir:atom,
%!   -AbsoluteDir:atom
%! ) is det.

ap_dir(AP, Mode, Subdir1, AbsoluteDir):-
  rdfs_individual_of(AP, ap:'AP'), !,
  rdf_datatype(AP, ap:alias, xsd:string, Alias, ap),

  to_atom(Subdir1, Subdir2),
  Spec =.. [Alias,Subdir2],
  (
    absolute_file_name(
      Spec,
      AbsoluteDir,
      [access(Mode),file_errors(fail),file_type(directory)]
    ), !
  ;
    Mode = write,
    % If the AP subdirectory is not found and the mode is `write`,
    % then we create it.
    create_nested_directory(Spec, AbsoluteDir)
  ).


%! ap_dirs(+AP:iri, -StageDirectories:list(atom)) is det.

ap_dirs(AP, Dirs):-
  ap_dirs(AP, 1, Dirs).

ap_dirs(AP, Stage1, [H|T]):-
  ap_stage_name(Stage1, Stage1Name),
  ap_dir(AP, read, Stage1Name, H), !,
  Stage2 is Stage1 + 1,
  ap_dirs(AP, Stage2, T).
ap_dirs(_, _, []).


%! ap_last_stage_dir(+AP:iri, -LastStageDirectory:atom) is semidet.
% Returns the last stage directory, if it exists.

ap_last_stage_dir(AP, LastStageDir):-
  ap_dirs(AP, StageDirs),
  StageDirs \== [],
  last(StageDirs, LastStageDir).


ap_stage_dir(AP_Stage, Mode, AbsoluteDir):-
  rdfs_individual_of(AP_Stage, ap:'AP-Stage'), !,
  rdf_collection_member(AP_Stage, AP, ap),
  rdf_datatype(AP_Stage, ap:stage, xsd:integer, StageNum, ap),
  ap_stage_name(StageNum, StageName),
  ap_dir(AP, Mode, StageName, AbsoluteDir).


%! ap_stage_name(+StageNumber:integer, -StageName:atom) is det.
% Returns the stage name that corresponds to the given indicator.
%
% @arg StageIndicator One of the following:
%   * `0` is converted to name `input`.
%   * Positive integers `N` are converted to names `stage_N`.
%   * Other names are unchanged.
% @arg StageName An atomic name.

ap_stage_name(0, input):- !.
ap_stage_name(StageNum, StageName):-
  must_be(positive_integer, StageNum), !,
  format(atom(StageName), 'stage~w', [StageNum]).
ap_stage_name(StageName, StageName).

