:- module(
  web_console,
  [
    push/1, % +DOM:list
    push/2, % +Type:oneof([console_output,status_pane])
            % +DOM:list
    push/4 % +Type:oneof([console_output,status_pane])
           % +DTD_Name:atom
           % +StyleName:atom
           % +DOM:list
  ]
).

/** <module> Web console

A simple Web console interface.

@author Wouter Beek
@version 2012/10, 2013/02-2013/06, 2013/11
*/

:- use_module(generics(db_ext)).
:- use_module(generics(list_ext)).
:- use_module(generics(meta_ext)).
:- use_module(html(html_form)).
:- use_module(http(http)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_head)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_server_files)).
:- use_module(library(lists)).
:- use_module(library(settings)).
:- use_module(os(datetime_ext)).
:- use_module(server(app_ui)).
:- use_module(server(error_web)).
:- use_module(server(web_commands)).
:- use_module(server(web_modules)).
:- use_module(sparql(sparql_web)).

% /css
:- db_add_novel(http:location(css, root(css), [])).
:- db_add_novel(user:file_search_path(css, server(css))).
:- http_handler(css(.), serve_files_in_directory(css), [prefix]).
:- html_resource(css('web_console.css'), []).
:- html_resource(css('console_output.css'), [requires(css('web_console.css'))]).
:- html_resource(css('status_pane.css'), [requires(css('web_console.css'))]).

% /js
:- db_add_novel(http:location(js, root(js), [])).
:- db_add_novel(user:file_search_path(js, server(js))).
:- http_handler(js(.), serve_files_in_directory(js), [prefix]).
:- html_resource(js('web_console.js'), []).
:- html_resource(js('console_output.js'), [requires(js('web_console.js'))]).
:- html_resource(js('status_pane.js'), [requires(js('web_console.js'))]).

% HTTP handlers for the Wallace server.
:- http_handler(root(console), web_console, [priority(1)]).
:- http_handler(root(console_output), console_output, []).
:- http_handler(root(status_pane), status_pane, []).

%! content_queue(
%!   ?Type:oneof([console_output,status_pane]),
%!   ?DTD_Name:atom,
%!   ?StyleName:atom,
%!   ?DOM:list
%! ) is nondet.
% This is used to push content for the Web front-end.

:- dynamic(content_queue/4).

%! history_command(+Time:float, +Command:atom) is nondet.

:- dynamic(history_command/2).

%! history_push(
%!   ?Type:oneof([console_output,status_pane]),
%!   ?DateTime,
%!   ?DTD_Name:atom,
%!   ?StyleName:atom,
%!   ?DOM:list
%! ) is nondet.

:- dynamic(history_push/5).

:- setting(
  history_length,
  nonneg,
  5,
  'The number of previously issued Web commands that are shown in the UI.'
).

:- initialization(web_module_add('Web Console', web_console, console)).



%! command_input// is det.
% The input field for the Web console.

command_input -->
  html(input([maxlength=55,name=web_command,size=55,type=text,value=''])).

%! console_input// is det.
% Returns the markup for the web-based console.
% This can be inserted in (X)HTML web pages.
%
% @param Markup A list of compound terms representing (X)HTML markup.

console_input -->
  {
    findall(
      Command,
      history_command(_Time, Command),
      Commands
    ),
    setting(history_length, HistoryLength),
    first(Commands, HistoryLength, History_),
    atomic_list_concat(History_, '\n', History),
    http_absolute_location(root(console), URL, [])
  },
  html(
    div(id=console_input,
      \submission_form(
        URL,
        [
          \history(History, HistoryLength),
          br([]),
          \command_input,
          \submit_button,
          \html_requires(css('console_input.css'))
        ]
      )
    )
  ).

console_output -->
  html([
    div(id=console_output, []),
    \html_requires(css('console_output.css')),
    \html_requires(js('console_output.js'))
  ]).

console_output(_Request):-
  retract(content_queue(console_output, DTD_Name, Style_Name, DOM)), !,
  serve_xml(DTD_Name, Style_Name, DOM).
console_output(Request):-
  serve_nothing(Request).

user:head(dev_style, _Head) -->
  {project_name(Project)},
  html(head(title(Project))).

history(History, HistoryLength) -->
  html(textarea([cols=60,name=history,rows=HistoryLength], History)).

markup_mold(DTD_Name/StyleName/DOM, DTD_Name, StyleName, DOM):- !.
markup_mold(StyleName/DOM, html, StyleName, DOM):- !.
markup_mold(DOM, html, app_style, DOM):- !.

%! process_web_command(+Command:atom, -Markup:list) is det.
% This returns either the markup that results from the execution of =Command=,
% or it returns the markup for an error messahe that occured.

process_web_command(Command, Markup):-
  % Catch errors and display their error messages in the Web browser.
  catch_web(process_web_command_(Command), Markup).

% Lets see if we can figure out the predicate
% indicated by the command issued via the Web console interface.
process_web_command_(Command, Markup):-
  atom_to_term(Command, Compound, _Bindings),
  Compound =.. [Predicate1|Arguments1],
  atom_concat(Predicate1, '_web', Predicate2),
  functor(Compound, Predicate1, Arity),
  WebArity is Arity + 1,
  (
    web_module(_ExternalName, InternalName, _PathName),
    current_predicate(InternalName:Predicate2/WebArity)
  ->
    get_time(Time),
    % Assert to the beginning, so running a findall will automatically
    % retrieve the commands in the order in which they were given.
    asserta(history_command(Time, Command)),
    append(Arguments1, [Markup], Arguments2),
    Call =.. [Predicate2|Arguments2],
    (
      call(InternalName:Call)
    ->
      true
    ;
      fail_web(Markup)
    )
  ;
    throw(
      error(
        existence_error(predicate, Predicate1),
        context(
          web_console:process_web_command/2,
          'Unrecognized predicate entered in Web console.'
        )
      )
    )
  ).

%! push(+Markup:list) is det.
% @see Wrapper around push/2 that pushes markup to the console output.

push(Markup):-
  push(console_output, Markup).

%! push(+Type:oneof([console_output,status_pane]), +Markup:list) is det.

push(Type, Markup):-
  markup_mold(Markup, DTD_Name, StyleName, DOM),
  push(Type, DTD_Name, StyleName, DOM).

%! push(
%!   +Type:oneof([console_output,status_pane]),
%!   +DTD_Name:atom,
%!   +StyleName:atom,
%!   +Markup:list
%! ) is det.

push(Type, DTD_Name, StyleName, DOM):-
  % Assert the content for AJAX retrieval.
  assertz(content_queue(Type, DTD_Name, StyleName, DOM)),

  % Also store the content in the history.
  current_date_time(DateTime),
  assertz(history_push(Type, DateTime, DTD_Name, StyleName, DOM)).

status_pane(_Request):-
  retract(content_queue(status_pane, DTD_Name, Style_Name, DOM)), !,
  serve_xml(DTD_Name, Style_Name, DOM).
status_pane(Request):-
  serve_nothing(Request).

status_pane -->
  html([
    \html_requires(css('status_pane.css')),
    \html_requires(js('status_pane.js')),
    div(id=status_pane, [])
  ]).

web_console(Request):-
  http_parameters(Request, [
    web_command(Command, [default(no_command)]),
    web_input(Query, [default(no_input)])
  ]),
  (
    Command \== no_command
  ->
    process_web_command(Command, Markup),
    push(console_output, Markup)
  ;
    Query \== no_input
  ->
    sparql_output_web(Query, DOM),
    push(console_output, html, app_style, DOM)
  ;
    true
  ),
  reply_html_page(app_style, title('Web Console'), \web_console).

web_console -->
  html(
    body(onload('loadConsoleOutputFunctions(); loadStatusPaneFunctions();'), [
      \html_requires(css('web_console.css')),
      \console_input,
      \console_output,
      \status_pane
    ])
  ).

