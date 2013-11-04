:- module(
  web_console,
  [
    clear_web/1, % -Markup:list
    console_input//0, % -Markup:list
    deregister_module/1, % +Module:atom
    documentation_web/1, % -Markup:list
    help_web/1, % -Markup:list
    input_ui/1, % -Markup:list
    %messages_web/1, % -Markup:list
    register_module/2, % +InternalName:atom
                       % +ExternalName:atom
    registered_module/2, % ?InternalName:atom
                         % ?ExternalName:atom
    registered_modules/1, % -Pairs:list(pair(atom,atom))
    registered_modules_web/1, % -Markup:list
    web_console/2 % +Command:atom
                  % -Markup:list
  ]
).

/** <module> Web console

The Web-based console for the debug server's Web page.

@author Wouter Beek
@version 2012/10, 2013/02-2013/06, 2013/11
*/

:- use_module(generics(db_ext)).
:- use_module(generics(list_ext)).
:- use_module(generics(meta_ext)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_head)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_server_files)).
:- use_module(library(pairs)).
:- use_module(server(error_web)).

:- dynamic history/2.

% ! registered_module(?InternalName:atom, ?ExternalName:atom) is nondet.
% Modules that are currently registered with the web console.
% Only web modules can be sensibly registered, since the web console
% looks for =|_web|=-predicates exclusively. Web modules must be
% registered before their web methods can be accessed from the web
% console.
%
% @param InternalName The atomic name of a Prolog module.
%        intended for internal use.
% @param ExternalName The atomic name of a Prolog module for
%        intended for human consumption.

:- dynamic registered_module/2.

% /css
:- db_add_novel(http:location(css, root(css), [])).
:- assert(user:file_search_path(css, server(css))).
:- http_handler(css(.), serve_files_in_directory(css), [prefix]).
:- html_resource(css('console_input.css'), [requires(css('dev_server.css'))]).



%! clear_web(-Markup:list) is det.
% Clears the output region of the PraSem Web interface.

clear_web([]).

%! command_input// is det.
% The input field for the Web console.

command_input -->
  html(input(
    [maxlength=200, name=web_command, size=62, type=text, value=''])).

%! console_input// is det.
% Returns the markup for the web-based console.
% This can be inserted in (X)HTML web pages.
%
% @param Markup A list of compound terms representing (X)HTML markup.

console_input -->
  {
    findall(
      Command,
      history(_Time, Command),
      Commands
    ),
    history_length(HistoryLength),
    first(Commands, HistoryLength, History_),
    atomic_list_concat(History_, '\n', History),
    http_absolute_location(dev_server(.), URL, [])
  },
  html([
    div(id(console_input), [
      form([
        action=URL,
        enctype='application/x-www-form-urlencoded',
        method=post
      ], [
        \history(History, HistoryLength),
        br([]),
        \command_input,
        \submit_button,
        \html_requires(css('console_input.css'))
      ])
    ])
  ]).

%! deregister_module(+Module:atom) is det.
% Deregisters the given module. This means that the =|_web|=-predicates
% of this module will no longer be accessible from the web console.

deregister_module(Module):-
  registered_module(Module, _Name1), !,
  retractall(registered_module(Module, _Name2)).
% Fails silently.
deregister_module(_Module).

%! documentation_web(-Markup:list) is det.
% Opens a client browser for the documentation server (plDoc).

documentation_web([element(p, [], ['Documentation was opened.'])]):-
  doc_browser.

fail_web([element(h1, [], ['False'])]).

help_web([element(ul, [], ModuleItems)]):-
  setoff(
    element(li, [], [
      element(p, [],
        [element(b, [], [Module]), ':', element(ol, [], PredicateItems)])]),
    (
      registered_module(_InternalName, Module),
      module_property(Module, exports(WebPredicates)),
      setoff(
        element(li, [], [Label]),
        (
          member(WebPredicate/WebArity, WebPredicates),
          atom_concat(Predicate, '_web', WebPredicate),
          DisplayArity is WebArity - 1,
          format(atom(Label), '~w/~w', [Predicate, DisplayArity])
        ),
        PredicateItems
      )
    ),
    ModuleItems
  ).

history(History, HistoryLength) -->
  html(
    textarea(
      [cols=80,name=history,onclick='clickme(\'aap\')',rows=HistoryLength],
      History
    )
  ).

history_length(5).

%! input_ui(-Markup:list) is det.
% HTML markup for an input form.

input_ui([
  element(form, [
    action=URI,
    enctype='application/x-www-form-urlencoded',
    method=post
  ], [
    element(textarea,
      [cols=100, name=web_input, rows=40, type=text, value=''],
      ['']),
    element(button,
      [name=submit, type=submit, value='Submit'],
      ['Submit'])])]
):-
  http_absolute_location(dev_server(.), URI, []).

maximum_number_of_messages(100).

/*messages_web(Markup):-
  maximum_number_of_messages(MaximumNumberOfMessages),
  findall(
    [element(h1,[],[DateTime])|DOM],
    history(status_pane, DateTime, _DTD_Name, _StyleName, DOM),
    DOMs
  ),
  reverse(DOMs, RDOMs),
  length(RDOMs, NumberOfMessages),
  (
    NumberOfMessages == 0
  ->
    DisplayedDOMs = [[element(p,[],['There are no messages.'])]]
  ;
    NumberOfMessages =< MaximumNumberOfMessages
  ->
    DisplayedDOMs = RDOMs
  ;
    length(DisplayedDOMs, MaximumNumberOfMessages),
    append(DisplayedDOMs, _, RDOMs)
  ),
  append(DisplayedDOMs, Markup).*/

%! register_module(+Module:atom, +Name:atom) is det.
% Registers the given module for the web console.
% If the module is a web module, i.e. contains =|_web|=-predicates,
% then these can now be accessed from the web console.
%
% @param Module The atomic name of a module that is used internally.
% @param Name A human-readable name for the module.
%        This is displayed in the Web application.

% The module is already registered, do nothing.
register_module(Module, _Name1):-
  registered_module(Module, _Name2), !.
% Register the module.
register_module(Module, Name):-
  % The module must already be loaded.
  current_module(Module),
  assert(registered_module(Module, Name)).

registered_module(web_console, 'Console').

%! registered_modules(-Pairs:list(pair(atom,atom))) is det.
% Returns all modules that are currently registered with the web console.
%
% @param Pairs A list of pairs of atomic modules name.
%	 The first is the internal name, the second is the external
%	 name.

registered_modules(Pairs):-
  findall(
    Module-Name,
    registered_module(Module, Name),
    Pairs
  ).

registered_modules_web(
  [
    element(
      table,
      [border=1, summary='The currently registered modules.'],
      [
        element(caption, [], ['The currently registered modules.'])
      |
        Rows
      ]
    )
  ]
):-
  registered_modules(Pairs),
  pairs_values(Pairs, Modules),
  findall(
    element(tr, [], [element(td, [], [Module])]),
    member(Module, Modules),
    Rows
  ).

%! request_web(+Request:list, -Markup:list) is det.
% Returns a table markup element representing the header of
% the given request.
%
% @param Request A compound term representing an HTTP header.
% @param Markup A compound term encoding an (X)HTML table.

request_web(
  Request,
  [
    element(
      table,
      [border=1, summary='This table shows an HTTP header.'],
      [
        element(caption, [], ['An HTTP header'])
      |
        Rows
      ]
    )
  ]
):-
  findall(
    element(tr, [], [element(td, [], [AName]), element(td, [], [AValue])]),
    (
      member(NameValuePair, Request),
      NameValuePair =.. [Name, Value],
      maplist(term_to_atom, [Name, Value], [AName, AValue])
    ),
    Rows
  ).

submit_button -->
  html(button([name=submit, type=submit, value='Submit'], 'Submit')).

%! web_console(+Command:atom, -Markup:list) is det.
% This returns either the markup that results from the execution of =Command=,
% or it returns the markup for an error messahe that occured.

web_console(Command, Markup):-
  % Catch errors and display their error messages in the Web browser.
  catch_web(web_console_(Command), Markup).

% Lets see if we can figure out the predicate
% indicated by the command issued via the Web console interface.
web_console_(Command, Markup):-
  atom_to_term(Command, Compound, _Bindings),
  Compound =.. [Predicate1|Arguments1],
  atom_concat(Predicate1, '_web', Predicate2),
  functor(Compound, Predicate1, Arity),
  WebArity is Arity + 1,
  (
    registered_module(Module, _ExternalName),
    current_predicate(Module:Predicate2/WebArity)
  ->
    get_time(Time),
    % Assert to the beginning, so running a findall will automatically
    % retrieve the commands in the order in which they were given.
    asserta(history(Time, Command)),
    append(Arguments1, [Markup], Arguments2),
    Call =.. [Predicate2|Arguments2],
    (
      call(Module:Call)
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
          web_console:web_console/4,
          'Unrecognized predicate entered in Web console.'
        )
      )
    )
  ).

