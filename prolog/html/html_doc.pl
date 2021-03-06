:- module(
  html_doc,
  [
    media_type_table//1, % +Mod
    param_table//1       % +Mod
  ]
).

/** <module> HTML documentation

@author Wouter Beek
@version 2016/08-2016/09
*/

:- use_module(library(html/html_ext)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(option)).

:- multifile
    http_param/1,
    media_type/1.



%! media_type_table(+Mod)// is det.

media_type_table(Mod) -->
  {findall(MT, Mod:media_type(MT), MTs)},
  table(
    \media_type_header_row,
    \html_maplist(media_type_data_row, MTs)
  ).


media_type_header_row -->
  table_header_row(["Format","Media Type"]).


media_type_data_row(Type/Subtype) -->
  {
    media_type_label(Type/Subtype, Lbl),
    format(string(MT), "~a/~a", [Type,Subtype])
  },
  table_data_row([Lbl,code(MT)]).


media_type_label(application/json, "JSON").
media_type_label(application/'ld+json', "JSON-LD 1.0").
media_type_label(application/'n-triples', "N-Triples 1.1").
media_type_label(application/'n-quads', "N-Quads 1.1").
media_type_label(application/'vnd.geo+json', "GeoJSON").
media_type_label(text/html, "HTML 5").



%! param_table(+Mod)// is det.

param_table(Mod) -->
  {
    findall(
      Key-Spec,
      (
        Mod:http_param(Key),
        http:http_param(Mod, Key, Spec)
      ),
      Pairs
    )
  },
  table(
    \param_header_row,
    \html_maplist(param_data_row, Pairs)
  ).


param_data_row(Key-Spec) -->
  html(
    tr([
      td(\param_key(Key)),
      td(\param_type(Spec)),
      td(\param_required(Spec)),
      td(\param_default(Spec)),
      td(\param_desc(Spec))
    ])
  ).


param_header_row -->
  table_header_row(["Parameter","Type","Required","Default","Description"]).


param_key(Key) -->
  html(code(Key)).


% between(Low,High)
param_type(Spec) -->
  {memberchk(between(Low,High), Spec)}, !,
  {format(string(Lbl), "~D ≤ n ≤ ~D", [Low,High])},
  html(Lbl).
% boolean
param_type(Spec) -->
  {memberchk(boolean, Spec)}, !,
  html("boolean").
% float
param_type(Spec) -->
  {memberchk(float, Spec)}, !,
  html("float").
% positive integer
param_type(Spec) -->
  {memberchk(positive_integer, Spec)}, !,
  html("n ≥ 1").
% q_iri
param_type(Spec) -->
  {memberchk(q_iri, Spec)}, !,
  html("RDF IRI").
% q_literal
param_type(Spec) -->
  {memberchk(q_literal, Spec)}, !,
  html("RDF literal").
% q_term
param_type(Spec) -->
  {memberchk(q_term, Spec)}, !,
  html("RDF term").
% string
param_type(Spec) -->
  {memberchk(string, Spec)}, !,
  html("String").


param_required(Spec) -->
  {
    option(optional(Bool), Spec, false),
    param_bool_lbl(Bool, Lbl)
  },
  html(Lbl).


param_bool_lbl(true, "No").
param_bool_lbl(false, "Yes").


param_default(Spec) -->
  {option(default(Val), Spec, "")},
  html(Val).


param_desc(Spec) -->
  {option(description(Desc), Spec, "")},
  html(Desc).
