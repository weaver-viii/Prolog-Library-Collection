:- module(
  json_to_rdf,
  [
    json_to_rdf/4 % +Graph:atom
                  % +Module:atom
                  % +JSON:compound
                  % -Individual:iri
  ]
).

/** <module> JSON to RDF

Automated JSON to RDF conversion.

This requires a Prolog module whose name is also registered as
 the XML namespace that is used for the RDF vocabulary.

@author Wouter Beek
@version 2014/01-2014/02
*/

:- use_module(dcg(dcg_ascii)).
:- use_module(dcg(dcg_cardinal)).
:- use_module(dcg(dcg_content)). % Meta-argument.
:- use_module(dcg(dcg_generic)).
:- use_module(dcg(dcg_replace)). % Meta-argument.
:- use_module(generics(atom_ext)).
:- use_module(generics(typecheck)).
:- use_module(generics(uri_ext)).
:- use_module(library(apply)).
:- use_module(library(debug)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).
:- use_module(library(pairs)).
:- use_module(library(semweb/rdf_db)).
:- use_module(rdf(rdf_build)).
:- use_module(rdf(rdf_datatype)).
:- use_module(rdf(rdf_image)).
:- use_module(rdf(rdf_lit_build)).
:- use_module(rdfs(rdfs_build)).
:- use_module(xml(xml_namespace)).
:- use_module(xsd(xsd)).



percent_encoding(space) -->
  percent_sign,
  integer(20).

arg_spec_match(Args, ArgSpecs, Length):-
  maplist(arg_to_name, Args, Names1),
  maplist(arg_spec_to_name, ArgSpecs, Names2),
  ord_intersection(Names1, Names2, Shared),
  length(Shared, Length).
arg_spec_to_name(Name-_-_, Name).
arg_to_name(Name=_, Name).


%! create_resource(
%!   +Graph:atom,
%!   +Module:atom,
%!   +Legend:atom,
%!   ?Id:atom,
%!   -Individual:iri
%! ) is det.
% @arg Graph
% @arg Module The atomic name of a Prolog module containing
%      legend declarations and the name of a registered XML namespace.
% @arg Legend The atomic name of the legend.
%      This is used to construct the IRI that denotes the RDFS class.
% @arg Id If the id is not instantiated, then the individual is
%      denoted by a blank node; otherwise it is denoted by an IRI.
% @arg Individual

create_resource(Graph, Module, Legend, Id, Individual):-
  once(dcg_phrase(capitalize, Legend, ClassName)),
  rdf_global_id(Module:ClassName, Class),
  rdfs_assert_class(Class, Graph),
  (
    var(Id)
  ->
    rdf_bnode(Individual)
  ;
    atomic_list_concat([ClassName,Id], '/', IndividualName),
    rdf_global_id(ckan:IndividualName, Individual)
  ),
  rdf_assert_individual(Individual, Class, Graph).


%! json_name_to_rdf_predicate_term(
%!   +Module:atom,
%!   +Name:atom,
%!   -Predicate:iri
%! ) is det.
% Construct the RDF predicate term based on (1) the XML namespace
% (which is identical to the Prolog module that declares the legend)
% and (2) the JSON name.

json_name_to_rdf_predicate_term(Module, Name, Predicate):-
  rdf_global_id(Module:Name, Predicate).


%! json_to_rdf(
%!   +Graph:atom
%!   +Module:atom
%!   +JSON:compound
%!   -Individual:iri
%! ) is det.
% Automated conversion from JSON to RDF,
%  based on registered legends.
%
% # Conversion table
%
% | *JSON*     | *Prolog*      | * RDF*        |
% | Term       | Compound term | Resource      |
% | Array      | List          |               |
% | String     | Atom          | `xsd:string`  |
% |            | Atom          | Resource      |
% | Number     | Number        | `xsd:float`   |
% |            |               | `xsd:integer` |
% | `false`    | `@(false)`    | `xsd:boolean` |
% | `true`     | `@(true)`     | `xsd:boolean` |
% | `null`     | `@(null)`     | skip          |
%
% # Argument descriptions
%
% @arg Graph The atomic name of the RDF graph in which results are asserted.
% @arg LegendModule The atomic name of the Prolog module that contains
%      the legens to which JSON terms have to conform.
% @arg JSON A compound term representing a JSON term.
%      This will be converted to RDF.
% @arg Individual An IRI denoting the RDF version of the JSON term.

% A list of JSON terms.
json_to_rdf(Graph, Module, JSONs, Individuals):-
  is_list(JSONs), !,
  findall(
    Individual,
    (
      member(JSON, JSONs),
      json_to_rdf(Graph, Module, JSON, Individual)
    ),
    Individuals
  ).
% A single JSON term.
json_to_rdf(Graph, Module, JSON, Individual):-
  % Namespace.
  (
    xml_current_namespace(Module, _), !
  ;
    atomic_list_concat(['http://www.wouterbeek.com/',Module,'#'], '', URL),
    xml_register_namespace(Module, URL)
  ),
  json_object_to_rdf(Graph, Module, JSON, Individual).

json_object_to_rdf(Graph, Module, JSON, Individual):-
  JSON = json(Args0),

  % Find the legend to which this JSON term conforms.
  sort(Args0, Args),
  findall(
    Length-Legend,
    (
      Module:legend(Legend, _, ArgSpecs),
      arg_spec_match(Args, ArgSpecs, Length)
    ),
    Pairs1
  ),
  keysort(Pairs1, Pairs2),
  pairs_values(Pairs2, Legends),
  debug(json_to_rdf, 'Legend order found: ~w.', [Legends]),
  last(Legends, Legend),

  json_object_to_rdf(Graph, Module, Legend, json(Args), Individual).


% Now we have a legend based on which we do the conversion.
json_object_to_rdf(Graph, Module, Legend, json(Args1), Individual):-
  Module:legend(Legend, PrimaryKey, Spec),

  (nonvar(PrimaryKey) -> memberchk(PrimaryKey=Id, Args1) ; true),

  % Class and individual.
  create_resource(Graph, Module, Legend, Id, Individual),

  % Propositions.
  maplist(json_pair_to_rdf(Graph, Module, Individual, Spec), Args1).


%! json_pair_to_rdf(
%!   +Graph:atom,
%!   +Module:atom,
%!   +Individual:iri,
%!   +ArgumentSpecification:compound,
%!   +JSON:pair(atom,term)
%! ) is det.
% Make sure a property with the given name exists.
% Also retrieve the type the value should adhere to.

json_pair_to_rdf(Graph, Module, Individual, Spec, Name=Value):-
  memberchk(Name-Type-_, Spec),
  json_pair_to_rdf(Graph, Module, Individual, Name, Type, Value), !.
% DEB
json_pair_to_rdf(Graph, Module, Individual, Spec, Name=Value):-
  gtrace, %DEB
  json_pair_to_rdf(Graph, Module, Individual, Spec, Name=Value).

% The value must match at least one of the given types.
json_pair_to_rdf(Graph, Module, Individual, Name, or(Types), Value):-
  % Notice the choicepoint.
  member(Type, Types),
  json_pair_to_rdf(Graph, Module, Individual, Name, Type, Value), !.
% We do not have an RDF equivalent for the JSON null value,
% so we do not assert pairs with a null value in RDF.
json_pair_to_rdf(_, _, _, _, _, Value):-
  Value = @(null), !.
% We do not believe that empty values -- i.e. the empty atom --
% are very usefull, so we do not assert pairs with this value.
json_pair_to_rdf(_, _, _, _, _, ''):- !.
% We have a specific type that is always skipped, appropriately called `skip`.
json_pair_to_rdf(_, _, _, _, skip, _):- !.
% There are two ways to realize legend types / create resources:
% 1. JSON terms (always).
json_pair_to_rdf(Graph, Module, Individual1, Name, Legend/_, Value):-
  Value = json(_), !,
  json_object_to_rdf(Graph, Module, Legend, Value, Individual2),
  json_name_to_rdf_predicate_term(Module, Name, Predicate),
  rdf_assert(Individual1, Predicate, Individual2, Graph).
% There are two ways to realize legend types / create resources:
% 2. JSON strings (sometimes).
json_pair_to_rdf(Graph, Module, Individual1, Name, Legend/_, Value):-
  atom(Value), !,
  create_resource(Graph, Module, Legend, Value, Individual2),
  json_name_to_rdf_predicate_term(Module, Name, Predicate),
  rdf_assert(Individual1, Predicate, Individual2, Graph).
% A JSON object occurs for which the legend it not yet known.
json_pair_to_rdf(Graph, Module, Individual1, Name, Type, Value):-
  Type \= _/_, Value = json(_), !,
  json_object_to_rdf(Graph, Module, Value, Individual2),
  json_name_to_rdf_predicate_term(Module, Name, Predicate),
  rdf_assert(Individual1, Predicate, Individual2, Graph).
% List.
json_pair_to_rdf(Graph, Module, Individual, Name, list(Type), Values):-
  is_list(Values), !,
  maplist(json_pair_to_rdf(Graph, Module, Individual, Name, Type), Values).
% JSON string that is asserted as an XSD string.
json_pair_to_rdf(Graph, Module, Individual, Name, Type, Value1):-
  json_name_to_rdf_predicate_term(Module, Name, Predicate),
  % Convert the JSON value to an RDF object term.
  % This is where we validate that the value is of the required type.
  json_value_to_rdf(Type, Value1, Datatype, Value2),
  rdf_assert_datatype(Individual, Predicate, Datatype, Value2, Graph).


% The value is already in XSD format: recognize that this is the case.
json_value_to_rdf(Type, Value1, Datatype, Value2):-
  atom(Value1),
  xsd_datatype(Type, Datatype),
  rdf_datatype(Datatype, Value1, Value2), !.
% The value is not yet in XSD format, but could be converted using
% the supported mappings.
json_value_to_rdf(Type, Value, Datatype, Value):-
  xsd_datatype(Type, Datatype), !,
  xsd_canonicalMap(Datatype, Value, _).

