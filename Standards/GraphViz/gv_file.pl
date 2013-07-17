:- module(
  gv_file,
  [
    convert_gv/4, % +FromFile
                  % +Method:onef([dot,sfdp])
                  % +ToFileType:oneof([jpeg,pdf,svg,xdot])
                  % ?ToFile:atom
    convert_tree_to_gv/5, % +Options:list(nvpair)
                          % +Tree:compound
                          % +Method:onef([dot,sfdp])
                          % +ToFileType:oneof([jpeg,pdf,svg,xdot])
                          % ?ToFile:atom
    gv_to_svg/3 % +FromFile:stream
                % +Method:onef([dot,sfdp])
                % -SVG:list
  ]
).

/** <module> GV_FILE

@author Wouter Beek
@version 2011-2013/07
*/

:- use_module(generics(codes_ext)).
:- use_module(generics(db_ext)).
:- use_module(generics(exception_handling)).
:- use_module(generics(print_ext)).
:- use_module(gv(gv_dcg)).
:- use_module(library(process)).
:- use_module(os(file_ext)).
:- use_module(os(shell_ext)).
:- use_module(svg(svg)).

:- db_add_novel(user:prolog_file_type(dot,  graphviz       )).
:- db_add_novel(user:prolog_file_type(jpeg, jpeg           )).
:- db_add_novel(user:prolog_file_type(jpeg, graphviz_output)).
:- db_add_novel(user:prolog_file_type(jpg,  jpeg           )).
:- db_add_novel(user:prolog_file_type(jpg,  graphviz_output)).
:- db_add_novel(user:prolog_file_type(pdf,  pdf            )).
:- db_add_novel(user:prolog_file_type(pdf,  graphviz_output)).
:- db_add_novel(user:prolog_file_type(png,  graphviz_output)).
:- db_add_novel(user:prolog_file_type(svg,  graphviz_output)).
:- db_add_novel(user:prolog_file_type(svg,  svg            )).
:- db_add_novel(user:prolog_file_type(xdot, graphviz_output)).
:- db_add_novel(user:prolog_file_type(xdot, xdot           )).



%! convert_gv(
%!   +FromFile,
%!   +Method:oneof([dot,sfdp]),
%!   +ToFileType:oneof([jpeg,pdf,svg,xdot]),
%!   ?ToFile:atom
%! ) is det.
% Converts a GraphViz DOT file to an image file, using a specific
% visualization method.
%
% @arg FromFile
% @arg Method
% @arg ToFileType
% @arg ToFile

convert_gv(FromFile, Method, ToFileType, ToFile):-
  % Type checks.
  access_file(FromFile, read),
  must_be(oneof([dot,sfdp]), Method),
  prolog_file_type(ToExtension, ToFileType),
  prolog_file_type(ToExtension, graphviz_output),

  % The output file is either given or created.
  (
    var(ToFile)
  ->
    absolute_file_name(
      personal(export),
      ToFile,
      [access(write), file_type(ToFileType)]
    )
  ;
    is_absolute_file_name(ToFile),
    % The given output file must match a certain file extension.
    file_name_extension(_, ToExtension, ToFile)
  ),
  % Now that we have the output file we can prevent the
  % file type / file extension translation predicates from bakctracking.
  !,

  % Run the GraphViz conversion command in the shell.
  format(atom(OutputType), '-T~w', [ToExtension]),
  process_create(
    path(Method),
    [OutputType, FromFile, '-o', ToFile],
    [process(PID)]
  ),
  process_wait(PID, exit(ShellStatus)),
  rethrow(
    shell_status(ShellStatus),
    error(shell_error(FormalMessage), context(_Predicate, ContextMessage)),
    error(
      shell_error(FormalMessage),
      context(graphviz:dot/3, ContextMessage)
    )
  ).

convert_tree_to_gv(O, Tree, Method, ToFileType, ToFile):-
  once(phrase(gv_tree(O, Tree), Codes)),
  absolute_file_name(project(tmp), FromFile, [access(write), file_type(dot)]),
  setup_call_cleanup(
    open(FromFile, write, Out),
    put_codes(Out, Codes),
    close(Out)
  ),
  convert_gv(FromFile, Method, ToFileType, ToFile).

gv_to_svg(FromFile, Method, SVG):-
  convert_gv(FromFile, Method, svg, ToFile),
  file_to_svg(ToFile, SVG),
  safe_delete_file(ToFile).

