:- module(
  cache_it,
  [
    cache_it/3, % +Graph:atom
                % :Predicate
                % +Resource:iri
    cache_it/5 % +Graph:atom
               % :Predicate
               % +Resource:iri
               % -Resources:ordset(iri)
               % -Propositions:ordset(list(or([bnode,iri,literal])))
  ]
).

/** <module> Cache it

Generic predicate for caching RDF results.

Possible instantiations for `Predicate` are SPARQL_cache/4 and LOD_cache/4.

@author Wouter Beek
@version 2014/01
*/

:- use_module(generics(typecheck)).
:- use_module(library(apply)).
:- use_module(library(debug)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(uri)).
:- use_module(os(file_ext)).
:- use_module(rdf_web(rdf_table)).
:- use_module('SPARQL'('SPARQL_db')).

:- meta_predicate(cache_it(+,3,+)).
:- meta_predicate(cache_it(+,3,+,-,-)).
:- meta_predicate(cache_it(+,+,3,+,+,-,+,-)).

:- debug(cache_it).



%! cache_it(
%!   +Graph:atom,
%!   :Predicate,
%!   +Resource:or([bnode,iri,literal])
%! ) is det.

cache_it(Graph, Pred, Resource):-
  cache_it(Graph, Pred, Resource, _, Propositions),
  maplist(assert_proposition(Graph), Propositions).

assert_proposition(Graph, [S,P,O]):-
  rdf_assert(S, P, O, Graph).


%! cache_it(
%!   +Graph:atom,
%!   :Predicate,
%!   +Resource:or([bnode,iri,literal]),
%!   -Resources:ordset(or([bnode,iri,literal])),
%!   -Propositions:ordset(list(or([bnode,iri,literal])))
%! ) is det.

cache_it(_, _, [], [], []):- !.
cache_it(G, Pred, [H|T], Resources, Propositions):- !,
  cache_it('depth-first', G, Pred, [H|T], [H], Resources, [], Propositions),
  % DEB
  findall(
    [S,P,O,none],
    member([S,P,O], Propositions),
    Quadruples
  ),
  rdf_store_table(Quadruples).
cache_it(G, Pred, Resource, Resources, Propositions):-
  cache_it(G, Pred, [Resource], Resources, Propositions).


%! cache_it(
%!   +Mode:oneof(['breadth-first','depth-first']),
%!   +Graph:atom,
%!   :Predicate,
%!   +QueryTargets:list(or([bnode,iri,literal])),
%!   +ResourceHistory:ordset(or([bnode,iri,literal])),
%!   -Resources:ordset(or([bnode,iri,literal])),
%!   +PropositionHistory:ordset(list(or([bnode,iri,literal]))),
%!   -Propositions:ordset(list(or([bnode,iri,literal])))
%! ) is det.

% Base case.
cache_it(_, _, _, [], VSol, VSol, PropsSol, PropsSol):- !.
% Recursive case.
cache_it(Mode, G, Pred, [H1|T1], Vs1, VSol, Props1, PropsSol):-
  message('Resource ~w', [H1]),
  call(Pred, H1, Neighbors, NeighborProps), !,

  % Filter on propositions that are included in results.
  exclude(old_proposition(G), NeighborProps, NewProps),

  % Filter on resources that have to be visited.
  exclude(old_neighbor(Vs1, NewProps), Neighbors, NewNeighbors),

  % Update results: resources.
  ord_union(Vs1, NewNeighbors, Vs2),
  maplist(length, [NewNeighbors,Vs2], [NumberOfNewNeighbors,NumberOfVs2]),
  message(
    '~d resources added (~d in total)',
    [NumberOfNewNeighbors,NumberOfVs2]
  ),

  % Update results: propositions.
  ord_union(Props1, NewProps, Props2),
  maplist(length, [NewProps,Props2], [NumberOfNewProps,NumberOfProps2]),
  message(
    '~d propositions added (~d in total)',
    [NumberOfNewProps,NumberOfProps2]
  ),

  % Update resources that have to be visited.
  % Support breadth-first and depth-first modes.
  (
    Mode == 'breadth-first'
  ->
    append(T1, NewNeighbors, T2)
  ;
    Mode == 'depth-first'
  ->
    append(NewNeighbors, T1, T2)
  ),
  length(T2, NumberOfT2),
  message('~d remaining', [NumberOfT2]),

  % Recurse.
  cache_it(Mode, G, Pred, T2, Vs2, VSol, Props2, PropsSol).
% The show must go on!
cache_it(Mode, G, Pred, [H|T], Vs, VSol, Props, PropsSol):-
  message('[FAILED] ~w', [H]),
  cache_it(Mode, G, Pred, T, Vs, VSol, Props, PropsSol).

message(Format, Args):-
  debug(cache_it, Format, Args),
  format(user_output, Format, Args),
  nl(user_output),
  flush_output(user_output).

old_neighbor(Vs1, _, Element):-
  memberchk(Element, Vs1), !.
old_neighbor(_, NewProps, Element):-
  member(
    [_,'http://dbpedia.org/ontology/wikiPageExternalLink',Element],
    NewProps
  ), !.

old_proposition(G, [S,P,O]):-
  rdf(S, P, O, G), !.
old_proposition(G, [S,P,O]):-
  rdf_predicate_property(P, symmetric(true)),
  rdf(O, P, S, G), !.

