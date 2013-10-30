:- module(
  tms_web,
  [
    tms_node_web/2, % +NodeLabel:atom
                    % -SVG:list
    tms_web/1, % -DOM:list
    tms_web/2 % +TMS:atom
              % -SVG:list
  ]
).

/** <module> TMS web

@author Wouter Beek
@version 2013/10
*/

:- use_module(generics(meta_ext)).
:- use_module(gv(gv_file)).
:- use_module(html(html_table)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- use_module(library(semweb/rdf_db)).
:- use_module(server(dev_server)).
:- use_module(server(web_console)).
:- use_module(tms(tms)).
:- use_module(tms(tms_export)).
:- use_module(xml(xml_namespace)).

:- xml_register_namespace(tms, 'http://www.wouterbeek.com/tms.owl#').

:- initialization(start_dev_server).

:- register_module(tms_web).

http:location(tms_nav, dev_server(tms_nav), []).
:- http_handler(tms_nav(.), tms_nav, [prefix]).



%! tms_nav(+Request:list) is det.
% TMS graph navigation callback.

tms_nav(Request):-
  memberchk(path_info(NLocal), Request),
  rdf_global_id(doyle:NLocal, N),
  tms_node_web_(N, SVG),
  push(SVG).

%! tms_node_web(+NodeLabel:atom, -SVG:list) is det.

tms_node_web(NLabel, SVG):-
  tms_create_node_iri(NLabel, N),
  tms_node_web_(N, SVG).

tms_node_web_(N, SVG):-
  http_absolute_uri(tms_nav(.), BaseURL),
  tms_export_node([base_url(BaseURL),recursive(false)], N, GIF),
  graph_to_svg_dom([], GIF, dot, SVG).

%! tms_web(-DOM:list) is det.
% Returns a DOM description of the currently loaded TMS-es.

tms_web([HTML_Table]):-
  findall(
    [TMS,Type,NumberOfJs,NumberOfNs],
    (
      tms(Type, TMS),
      setoff(J, tms_justification(TMS, J), Js),
      length(Js, NumberOfJs),
      setoff(N, tms_node(TMS, N), Ns),
      length(Ns, NumberOfNs)
    ),
    Rows
  ),
  html_table(
    [
      caption('The currently loaded Truth Maintenance Systems.'),
      header(true),
      indexed(true)
    ],
    [['TMS','Type','#Justifications','#Nodes']|Rows],
    HTML_Table
  ).

%! tms_web(+TMS:atom, -SVG:list) is det.

tms_web(TMS, SVG):-
  http_absolute_uri(tms_nav(.), BaseURL),
  tms_export_graph([base_url(BaseURL)], TMS, GIF),
  graph_to_svg_dom([], GIF, sfdp, SVG).
