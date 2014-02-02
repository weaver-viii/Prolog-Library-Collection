:- module(
  rdf_html_table,
  [
    rdf_html_table//3, % ?Graph:atom
                       % :Caption
                       % +Rows:list(list(ground))
    rdf_html_table//4 % ?Graph:atom
                      % :Caption
                      % +HeaderRow:list(ground)
                      % +Rows:list(list(ground))
  ]
).

/** <module> RDF HTML table

Generates HTML tables with RDF content.

@author Wouter Beek
@version 2014/01-2014/02
*/

:- use_module(html(html_table)).
:- use_module(library(http/html_write)).
:- use_module(library(lists)).
:- use_module(rdf_web(rdf_html_term)).



%! rdf_html_table(?Graph:atom, :Caption, +Rows:list(list(ground)))// is det.
%! rdf_html_table(
%!   +Graph:atom,
%!   :Caption,
%!   +HeaderRow:list(ground),
%!   +Rows:list(list(ground))
%! )// is det.
% If `Rows` are of the form `[P,O,G]` or `[S,P,O,G]`,
%  the header row is set automatically.
% Otherwise the header row has to be given explicitly.

:- meta_predicate(rdf_html_table(?,//,+,?,?)).
rdf_html_table(_, _, []) --> !, [].
rdf_html_table(Graph, Caption, [H|T]) -->
  {
    same_length(H, HeaderRow),
    append(_, HeaderRow, ['Subject','Predicate','Object','Graph'])
  },
  rdf_html_table(Graph, Caption, HeaderRow, [H|T]).

:- meta_predicate(rdf_html_table(?,//,+,+,?,?)).
% Do not fail for empty data lists.
rdf_html_table(_, _, _, []) --> !, [].
rdf_html_table(Graph, Caption, HeaderRow, Rows) -->
  html(
    \html_table(
      [header(true),indexed(true)],
      Caption,
      rdf_html_term(Graph),
      [HeaderRow|Rows]
    )
  ).
