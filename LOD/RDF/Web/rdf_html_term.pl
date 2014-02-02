:- module(
  rdf_html_term,
  [
    rdf_graph//1, % +Graph:atom
    rdf_html_term//1, % +Term
    rdf_html_term//2 % +Graph:atom
                     % +Term
  ]
).

/** <module> RDF HTML

HTML generation of RDF content.

@author Wouter Beek
@version 2014/01-2014/02
*/

:- use_module(generics(typecheck)).
:- use_module(generics(uri_ext)).
:- use_module(library(error)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_path)).
:- use_module(library(semweb/rdf_db)).
:- use_module(xml(xml_namespace)).



% TERM %

rdf_html_term(RDF_Term) -->
  rdf_html_term(_, RDF_Term).

% Graph.
rdf_html_term(_, Graph) -->
  {
    atom(Graph),
    rdf_graph(Graph)
  }, !,
  rdf_graph(Graph).
% Blank node.
rdf_html_term(_, RDF_Term) -->
  {rdf_is_bnode(RDF_Term)}, !,
  rdf_blank_node(RDF_Term).
% Literal.
rdf_html_term(Graph, RDF_Term) -->
  {rdf_is_literal(RDF_Term)}, !,
  rdf_literal(Graph, RDF_Term).
% IRI.
rdf_html_term(Graph, RDF_Term) -->
  rdf_iri(Graph, RDF_Term).
% Prolog term.
rdf_html_term(_, PL_Term) -->
  html(span(class='prolog-term', PL_Term)).



% GRAPH %

rdf_graph(Graph) -->
  {
    http_absolute_location(root(rdf_tabular), Location1, []),
    uri_query_add(Location1, graph, Graph, Location2)
  },
  html(span(class='rdf-graph', a(href=Location2, Graph))).



% BLANK NODE %

rdf_blank_node(BNode) -->
  {
    atom(BNode),
    atom_prefix(BNode, '__'), !,
    http_absolute_location(root(rdf_tabular), Location1, []),
    uri_query_add(Location1, term, BNode, Location2)
  },
  html(div(class='blank-node', a(href=Location2, BNode))).



% LITERAL %

rdf_language_tag(Language) -->
  html(span(class='language-tag', atom(Language))).

rdf_literal(_, Type) -->
  rdf_plain_literal(Type).
rdf_literal(Graph, Type) -->
  rdf_typed_literal(Graph, Type).

rdf_plain_literal(literal(lang(Language,Value))) -->
  html(
    span(class='plain-literal', [
      \rdf_simple_literal(Value),
      '@',
      \rdf_language_tag(Language)
    ])
  ).
rdf_plain_literal(literal(Value)) -->
  {atom(Value)},
  html(span(class='plain-literal', \rdf_simple_literal(Value))).

rdf_simple_literal(Value) -->
  html(span(class='simple-literal', ['"',Value,'"'])).

rdf_typed_literal(Graph, literal(type(Datatype,Value))) -->
  html(
    span(class='typed-literal', [
      '"',
      Value,
      '"^^',
      \rdf_iri(Graph, Datatype)
    ])
  ).



% IRI %

% E-mail.
rdf_iri(_, IRI1) -->
  {
    uri_components(IRI1, uri_components(Scheme, _, IRI2, _, _)),
    Scheme == mailto
  }, !,
  html(span(class='e-mail', a(href=IRI1, IRI2))).
% Image.
rdf_iri(_, IRI) -->
  {is_image_url(IRI)}, !,
  html(span(class='image', a(href=IRI, img(src=IRI, [])))).
% IRI.
rdf_iri(Graph, IRI1) -->
  {rdf_global_id(IRI2, IRI1)},
  (
    {IRI2 = Prefix:Postfix}
  ->
    {
      (
        xml_current_namespace(Prefix, _), !
      ;
        existence_error('XML namespace',Prefix)
      ),
      http_absolute_location(root(rdf_tabular), Location1, []),
      uri_query_add(Location1, term, IRI1, Location2),
      (
        var(Graph)
      ->
        Location3 = Location2
      ;
        uri_query_add(Location2, graph, Graph, Location3)
      )
    },
    html(
      span(class='iri', [
        a(href=Location3, [
          span(class=prefix, Prefix),
          ':',
          span(class=postfix, Postfix)
        ]),
        ' ',
        a(href=IRI1, 'X')
      ])
    )
  ;
    {is_of_type(iri, IRI1)}
  ->
    html(span(class='iri', a(href=IRI1, IRI1)))
  ).



% TABLE %
