:- module(
  oaei,
  [
    oaei_check_alignment/2, % +ReferenceAlignments:list(pair(iri))
                            % +RawAlignments:list(pair(iri))
    oaei_file_to_alignments/2 % +File:atom
                              % -AlignmentPairs:list(pair(iri))
  ]
).

/** <module> OAEI

### OAEI

The Ontology Alignment Evaluation Initiative (OAEI) is a coordinated
international initiative, which organizes the evaluation of the increasing
number of ontology matching systems. The main goal of OAEI is to compare
systems and algorithms on the same basis and to allow anyone to draw
conclusions about the best matching strategies.

### Instance matching

The instance matching track aims at evaluating the performance of different matching
tools on the task of matching RDF individuals which originate from different sources
but describe the same real-world entity. Data interlinking is known under many names
according to various research communities: equivalence mining, record linkage, object
consolidation and coreference resolution to mention the most used ones. In each case,
these terms are used for the task of finding equivalent entities in or across data sets [14].
As the quantity of data sets published on the Web of data dramatically increases, the
need for tools helping to interlink resources becomes more critical. It is particularly
important to maximize the automation of the interlinking process in order to be able to
follow this expansion.

#### Sandbox

The dataset used for the Sandbox task has been automatically generated by extracting
data from Freebase, an open knowledge base that contains information about 11 million
real objects including movies, books, TV shows, celebrities, locations, companies and
more. Data has been extracted in JSON through the Freebase JAVA API. Sandox
is a collection of OWL files consisting of 31 concepts, 36 object properties, 13 data
properties and 375 individuals divided into 10 test cases. In order to provide simple
matching challenges mainly conceived for systems in their initial developing phase,
we limited the way data are transformed from the original Abox to the test cases. In
particular, we introduced only changes in data format (misspelling, errors in text, etc.).

#### IIMB

The IIMB task is focused on two main goals:
    1. to provide an evaluation data set for various kinds of data transformations, including
       value transformations, structural transformations and logical transformations;
    2. to cover a wide spectrum of possible techniques and tools.

ISLab Instance Matching Benchmark (IIMB), that has been generated using the
SWING tool. Participants were requested to find the correct correspondences
among individuals of the first knowledge base and individuals of the other
one. An important task here is that some of the transformations require
automatic reasoning for finding the expected alignments.

IIMB is composed of a set of test cases, each one represented by a set of
instances, i.e., an OWL ABox, built from an initial data set of real linked
data extracted from the Web. Then, the ABox is automatically modified in
several ways by generating a set of new ABoxes, called test cases. Each test
case is produced by transforming the individual descriptions in the
reference ABox in new individual descriptions that are inserted in the test
case at hand. The goal of transforming the original individuals is twofold:
on one side, we provide a simulated situation where data referring to the
same objects are provided in different data sources; on the other side, we
generate different data sets with a variable level of data quality and
complexity. IIMB provides transformation techniques supporting modifications
of data property values, modifications of number and type of properties used
for the individual description, and modifications of the individuals
classification. The first kind of transformations is called *|data value
transformation|* and it aims at simulating the fact that data expressing the
same real object in different data sources may be different because of data
errors or because of the usage of different conventional patterns for data
representation. The second kind of transformations is called *|data structure
transformation|* and it aims at simulating the fact that the same real object
may be described using different properties/attributes in different data
sources. Finally, the third kind of transformations, called *|data semantic
transformation|*, simulates the fact that the same real object may be
classified in different ways in different data sources.

The 2012 edition has been created by exploiting the same OWL source used
for the Sandbox task. The main difference is that we introduced in IIMB
a large set of data transformations. In particular, test cases from 0 to
20 contain changes in data format (misspelling, errors in text, etc);
test cases 21 to 40 contain changes in structure (properties missing,
RDF triples changed); 41 to 60 contain logical changes (class membership
changed, logical errors); finally, test cases 61 to 80 contain a mix of
the previous.

Mismatch types:
    * Data value transformations
    * Data structure transformation
    * Data semantic transformation

@author Wouter Beek
@version 2013/04-2013/05, 2013/08-2013/09
*/

:- use_module(generics(db_ext)).
:- use_module(generics(meta_ext)).
:- use_module(library(aggregate)).
:- use_module(library(debug)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(library(uri)).
:- use_module(math(statistics)).
:- use_module(os(file_ext)).
:- use_module(rdf(rdf_datatype)).
:- use_module(rdf(rdf_graph_name)).
:- use_module(rdf(rdf_lit_read)).
:- use_module(rdf(rdf_read)).
:- use_module(rdf(rdf_serial)).
:- use_module(xml(xml_namespace)).

% Register the namespaces.
:- xml_register_namespace(
  align,
  'http://knowledgeweb.semanticweb.org/heterogeneity/alignment#'
).

% Assert the used file types.
:- db_add_novel(user:prolog_file_type(owl, owl)).

% Assert the file search paths.
:- db_add_novel(user:file_search_path(alignment2, data(alignment2))).
:- db_add_novel(user:file_search_path(mapping2, alignment2(alignment))).
:- db_add_novel(user:file_search_path(ontology2, alignment2(ontology))).
:- db_add_novel(user:file_search_path(reference2, alignment2(reference))).

:- debug(oaei).



%! oaei_alignment_pair(?Graph:atom, ?From:uri, ?To:uri) is nondet.

oaei_alignment_pair(G, From, To):-
  rdf(BNode, align:entity1, From, G),
  rdf(BNode, align:entity2, To, G),
  once((
    rdf_literal(BNode, align:relation, '=', G),
    rdf_datatype(BNode, align:measure, xsd:float, 1.0, G)
  ;
    debug(oaei, 'Non-standard alignment was read from graph ~w.', G)
  )).

%! oaei_check_alignment(
%!   +ReferenceAlignments:list(pair),
%!   +RawAlignments:list(pair)
%! ) is det.
% Tests the quality of a raw alignment relative to the given reference.

oaei_check_alignment(ReferenceAlignments, RawAlignments):-
  t1_error(ReferenceAlignments, RawAlignments, FalsePositives),
  t2_error(ReferenceAlignments, RawAlignments, FalseNegatives),
  ord_intersect(ReferenceAlignments, RawAlignments, X),
  length(X, Overlap),
  % Write the results to user output.
  format(
    user_output,
    '\t~w\t~w\t~w\n',
    [Overlap, FalsePositives, FalseNegatives]
  ),
  flush_output(user_output).

oaei_file_to_alignments(F, A_Pairs):-
  setup_call_cleanup(
    (
      file_name(F, _Dir, G1, _Ext),
      % Make sure the graph name is unique.
      rdf_new_graph(G1, G2, 'Tmp graph (call-cleanup)'),
      rdf_load2(F, [graph(G2)])
    ),
    oaei_file_to_alignments_(G2, A_Pairs),
    rdf_unload_graph(G2)
  ).
oaei_file_to_alignments_(G, A_Pairs):-
  % Retrieve all alignment pairs.
  findall(
    X-Y,
    oaei_alignment_pair(G, X, Y),
    A_Pairs
  ),

  % DEB: Number of alignment pairs.
  length(A_Pairs, L1),
  debug(
    oaei,
    'Graph ~w contains ~w alignment pairs.',
    [G,L1]
  ).



% TMP %

oaei_graph(G):-
  nonvar_det(oaei_graph0(G)).
oaei_graph0(G):-
  rdf_graph(G),
  once((
    rdfs_individual_of(Alignment, align:'Alignment'),
    rdf(Alignment, _P, _O, G)
  )).

%! oaei_ontologies(+Graph:atom, -File1:atom, -File2:atom) is det.
% Returns the files in which the linked ontologies are stored.

oaei_ontologies(G, File1, File2):-
  oaei_ontology(G, File1),
  oaei_ontology(G, File2),
  File1 \== File2, !.

%! oaei_ontology(+Graph:atom, -File:atom) is nondet.
% Returns an ontology file used in the given alignment graph.

oaei_ontology(G, File):-
  rdf_literal(Ontology, align:location, URI, G),
  rdfs_individual_of(Ontology, align:'Ontology'),
  uri_components(
    URI,
    uri_components(_Scheme, _Authority, Path, _Search, _Fragment)
  ),
  file_base_name(Path, Base),
  absolute_file_name(ontology2(Base), File, [access(read)]).

