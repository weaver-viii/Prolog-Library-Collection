:- module(
  rdf_randomize_iris,
  [
    rdf_randomize_iris/1 % +Graph:atom
  ]
).

/** <module> RDF randomize IRIs

@author Wouter Beek
@version 2014/01
*/

:- use_module(dcg(dcg_cardinal)).
:- use_module(dcg(dcg_generic)).
:- use_module(dcg(dcg_multi)).
:- use_module(generics(meta_ext)).
:- use_module(library(apply)).
:- use_module(library(random)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(uri)).
:- use_module(rdf(rdf_term)).



rdf_randomize_iris(Graph):-
  rdf_graph(Graph),
  setoff(
    IRI1-IRI2,
    (
      rdf_iri(Graph, IRI1),
      once(randomize_iri(IRI1, IRI2))
    ),
    Dict
  ),
  findall(
    S-P-O,
    rdf(S, P, O, Graph),
    Triples
  ),
  maplist(randomize_triple(Graph, Dict), Triples).

random_number -->
  {random_between(0, 9, X)},
  integer(X).

randomize_iri(IRI1, IRI2):-
  uri_components(IRI1, uri_components(Scheme, Authority, _, _, _)),
  dcg_with_output_to(atom(Path1), dcg_multi(random_number, 10)),
  atomic_concat('/', Path1, Path2),
  uri_components(IRI2, uri_components(Scheme, Authority, Path2, _, _)).

randomize_triple(Graph, Dict, S1-P1-O1):-
  rdf_retractall(S1, P1, O1, Graph),
  maplist(iri_lookup(Dict), [S1,P1,O1], [S2,P2,O2]),
  rdf_assert(S2, P2, O2, Graph).

iri_lookup(Dict, X, Y):-
  memberchk(X-Y, Dict), !.
iri_lookup(_, X, X).

