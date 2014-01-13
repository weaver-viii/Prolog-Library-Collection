:- module(
  rdf_describe_web,
  [
    rdf_describe_web/2, % +Resource:atom
                        % -DOM:list
    rdf_table/4 % +Subject:or([bnode,iri])
                % +Predicate:iri
                % +Object:or([bnode,iri,literal])
                % +Graph:atom
  ]
).

/** <module> RDF describe Web

Generates Web pages that describe a resource.

:- use_module(rdf_web(rdf_describe_web)).

@author Wouter Beek
@tbd Add blank node map.
@tbd Add namespace legend.
@tbd Add local/remote distinction.
@tbd Include images.
@version 2013/12-2014/01
*/

:- use_module(generics(meta_ext)).
:- use_module(generics(uri_ext)).
:- use_module(html(html_table)).
:- use_module(http_headers(rfc2616_accept_language)).
:- use_module(library(apply)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(library(www_browser)).
:- use_module(rdf(rdf_name)).
:- use_module(rdf(rdf_read)).
:- use_module(rdf_web(rdf_web)).
:- use_module(server(web_modules)).

:- rdf_meta(rdf_table(r,r,r,+)).

:- initialization(web_module_add('RDF DESCRIBE', rdf_describe_web, rdf_desc)).

:- http_handler(root(rdf_desc), rdf_describe, []).

%! rdf_table(?Time:positive_integer, ?Quadruples:list(list)) is nondet.

:- dynamic(rdf_table/2).



%! rdf_describe(+Request:list) is det.
% Example:
% ~~~{.url}
% http://localhost:5000/rdf_desc?resource=dbpedia:Monkey
% ~~~

rdf_describe(Request):-
  memberchk(search(Search), Request),
  memberchk(resource=R1, Search), !,
  rdf_web_argument(R1, R2),
  reply_html_page(app_style, \rdf_describe_head(R1), \rdf_describe_body(R2)).
rdf_describe(_Request):-
  findall(
    Time-Quadruples,
    rdf_table(Time, Quadruples),
    Pairs1
  ),
  keysort(Pairs1, Pairs2),
  reverse(Pairs2, Pairs3),
  rdf_describe_(Pairs3).
rdf_describe_([]):- !,
  reply_html_page(app_style, title('No RDF to tablify'), \show_categories).
rdf_describe_([Time1-Quadruples|_]):-
  format_time(atom(Time2), '%FT%T%:z', Time1),
  format(atom(Caption), 'RDF Table at ~w', [Time2]),
  reply_html_page(
    app_style,
    title(['RDF Table - ',Time2]),
    \html_table(
      [
        caption(Caption),
        cell_dcg(dcg_rdf_term_name),
        header(true),
        indexed(true)
      ],
      [['Subject','Predicate','Object','Graph']|Quadruples]
    )
  ).

rdf_describe_body(R) -->
  {
    setoff(
      [P2,O2],
      (
        rdf(R, P1, O1),
        maplist(rdf_term_name([]), [P1,O1], [P2,O2])
      ),
      PO_Pairs
    ),
    format(atom(Caption), 'Triples describing resource ~w.', [R])
  },
  html([
    \html_table(
      [caption(Caption),header(true),indexed(true)],
      [['Predicate','Object']|PO_Pairs]
    ),
    \show_categories
  ]).

show_categories -->
  show_categories([ckan:'Organization',ckan:'Package',ckan:'User']).

show_categories([]) --> [].
show_categories([Category1|Categories]) -->
  {
    rdf_global_id(Category1, Category2),
    with_output_to(atom(CategoryName), rdf_term_name(Category2)),
    format(atom(Caption), 'Instances of ~w.', [CategoryName]),
    setoff(
      [Instance],
      rdfs_individual_of(Instance, Category2),
      Instances
    )
  },
  html(
    \html_table(
      [
        caption(Caption),
        cell_dcg(rdf_linked_term),
        header(true),
        indexed(true)
      ],
      [['Instance']|Instances]
    )
  ),
  show_categories(Categories).

rdf_linked_term(Resource) -->
  {
    phrase(dcg_rdf_term_name(Resource), Codes),
    atom_codes(Name, Codes),
    http_absolute_location(root(rdf_desc), Location1, []),
    uri_query_add(Location1, resource, Name, Location2)
  },
  html(a(href=Location2, Name)).

rdf_describe_head(R) -->
  html(title(['Description of resource denoted by ', R])).

%! rdf_describe_web(+Resource:atom, -DOM:list) is det.

rdf_describe_web(S1, DOM):-
  rdf_web_argument(S1, S2),
  findall(
    [P,O],
    rdf(S2, P, O),
    PO_Pairs
  ),
  format(
    atom(Caption),
    'Description of the resource denoted by ~w.',
    [S2]
  ),
  html_table(
    [caption(Caption),header(true),indexed(true)],
    [['Predicate','Object']|PO_Pairs],
    DOM
  ).

rdf_table(S, P, O, G):-
  setoff(
    [S,P,O,G],
    rdf(S, P, O, G),
    Quadruples
  ),
  get_time(Time),
  assert(rdf_table(Time, Quadruples)),
  www_open_url('http://localhost:5000/rdf_desc').

