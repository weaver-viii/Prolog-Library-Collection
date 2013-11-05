:- module(
  web_ui,
  [
    category//1, % +Category:atom
    clear_button//1, % +Fields:list(atom)
    http_button//3, % +Name:atom
                    % +Method:oneof(['DELETE','GET','POST'])
                    % +Event:atom
    location//1 % +Location:atom
  ]
).

/** <module> SWAPP Web UI

Generics for SWAPP Web UI.

@author Torbjörn Lager
@author Jan Wielemaker
@author Wouter Beek
@see This code was originally taken from SWAPP:
     http://www.swi-prolog.org/git/contrib/SWAPP.git
@version 2009, 2013/10-2013/11
*/

:- use_module(dcg(dcg_generic)).
:- use_module(generics(db_ext)).
:- use_module(library(http/html_head)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/js_write)).

% /css
:- http_handler(root(css), serve_files_in_directory(server(css)), [prefix]).

% /img
:- http_handler(root(img), serve_files_in_directory(server(img)), [prefix]).

% /js
:- http_handler(root(js), serve_files_in_directory(server(js)), [prefix]).

%:- html_resource(css('blueish.css'), []).
%:- html_resource(css('framelike.css'), []).
%:- html_resource(css('user_interface.css'), []).
%:- html_resource(js('event-min.js'), []).
%:- html_resource(js('connection_core-min.js'), []).
%:- html_resource(js('json-min.js'), []).
%:- html_resource(js('jsonbrowser.js'), []).
%:- html_resource(js('utils.js'), []).
%:- html_resource(js('yahoo-min.js'), []).



category(C1) -->
  {upcase_atom(C1, C2)},
  html(tr(td(valign=bottom, p(class=c1,C2)))).

%! clear_button(+Fields:list(atom))// is det.

clear_button(Fields) -->
  {dcg_phrase(js_call(clearFields(Fields)), OnClickEvent)},
  html(
    input([
      class=button,
      onclick=OnClickEvent,
      style='float:right;',
      type=button,
      value='Clear'
    ])
  ).

%! http_button(
%!   +Name:atom,
%!   +Method:oneof(['DELETE','GET','POST']),
%!   +Event:atom
%! )// is det.

http_button(Name, Method, Event) -->
  html(
    input([
      class=button,
      id=Name,
      name=Name,
      onclick=Event,
      type=button,
      value=Method
    ])
  ).

location(Location) -->
  html(
    tr(
      td([align=center,valign=bottom],
        span(style='font-family:monospace;font-size:20px;', Location)
      )
    )
  ).

menu -->
  {http_absolute_location(img('api_explorer.png'), RelativeURI, [])},
  html(
    tr(
      td([
        a([href='home',target='_top'],
          img([style='border:0;float:left;',src=RelativeURI])
        ),
        span(
          style=
              'float:right;\c
               font-family:verdana;\c
               font-size:10px;\c
               font-weight:bold;',
          [
            a([href=login,target='_top'],'Login'),
            ' | ',
            a([href=admin,target='_top'],'Admin'),
            ' | ',
            a([href=rdf_db,target='_top'],'RDF DB'),
            ' | ',
            a([href=session_db,target='_top'],'Session DB'),
            ' | ',
            a([href=session_eq,target='_top'],'Session EQ'),
            ' | ',
            a([href=help,target=display],'Help')
          ]
        )
      ])
    )
  ).

user:head(framelike_style, Head) -->
  html(
    head([
      title('APP - Admin API Explorer'),
      %\html_requires(css('blueish.css')),
      %\html_requires(css('framelike.css')),
      %\html_requires(css('user_interface.css')),
      %\html_requires(js('event-min.js')),
      %\html_requires(js('connection_core-min.js')),
      %\html_requires(js('json-min.js')),
      %\html_requires(js('jsonbrowser.js')),
      %\html_requires(js('utils.js')),
      %\html_requires(js('yahoo-min.js')),
      Head
    ])
  ).
