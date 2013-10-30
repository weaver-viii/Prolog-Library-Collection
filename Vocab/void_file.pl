:- module(
  void_file,
  [
    void_load_library/2, % +File:atom
                         % +Graph:atom
    void_save_library/2 % +Graph:atom
                        % ?File:atom
  ]
).

/** <module> VoID file handling

Support for the Vocabulary of Interlinked Datasets (VoID).

VoID is an RDF Schema vocabulary for expressing metadata about RDF datasets.
It is intended as a bridge between the publishers and users of RDF data,
with applications ranging from data discovery to cataloging and archiving
of datasets.

VoID is a W3C Interest Group Note as of 2011/03/03.

VoiD covers four areas of metadata:
  * *|General metadata|* following the Dublin Core model.
  * *|Access metadata|* describes how RDF data can be accessed
  *  using various protocols.
  * *|Structural metadata|* describes the structure and schema of datasets
    and is useful for tasks such as querying and data integration.
  * *|Description of links between datasets|* are helpful
    for understanding how multiple datasets are related.

@author WouterBeek
@compat http://www.w3.org/TR/void/
@version 2013/03-2013/05, 2013/09-2013/10
*/

:- use_module(generics(thread_ext)).
:- use_module(library(debug)).
:- use_module(library(filesex)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(rdf(rdf_serial)).
:- use_module(vocab(void_stat)).
:- use_module(xml(xml_namespace)).

:- xml_register_namespace(void, 'http://rdfs.org/ns/void#').

%! dataset(
%!   ?VoID_Graph:atom,
%!   ?Dataset:iri,
%!   ?DatasetFile:atom,
%!   ?DatasetGraph:atom
%! ) is nondet.
% These assertions make it easy to read/write from/to the description of
% a dataset in the VoID graph based on information that is in the dataset
% graph.
%
% Keeping the file names makes it easy to store the VoID graph to
% a package that includes all the relevant files.

:- dynamic(dataset/4).

:- debug(void_file).



%! void_init is det.
% Loads the VoID vocabulary.

void_init:-
  rdf_new_graph(void_schema, G),
  absolute_file_name(vocab('VoID'), F, [access(read),file_type(turtle)]),
  rdf_load2(F, [file_type(turtle),graph(G)]).

%! void_load_dataset(
%!   +DescriptionFile:atom,
%!   +DescriptionGraph:atom,
%!   +Dataset:iri
%! ) is det.
% @param DescriptionFile The atomic name of the file that contains the
%        dataset description.
% @param DescriptionGraph The atomic name of the RDF graph that contains
%        the description.
% @param Dataset An IRI denoting a dataset.

void_load_dataset(DD_F, DD_G, DS):-
  % Every dataset must have a set datadump property.
  once(rdf(DS, void:dataDump, Dump)),

  % @tbd Extend this to other cases: absolute files, generic relative files,
  %      Web locations.
  directory_file_path(DD_Dir, _, DD_F),
  absolute_file_name(Dump, DS_F, [access(read),relative_to(DD_Dir)]),

  % The RDF graph name into which the sataset is loaded is derived from
  % its IRI.
  rdf_global_id(_Ns:DS_G, DS),

  rdf_load2(DS_F, [graph(DS_G)]),

  % Update the internally stored relations between VoID graphs and
  % dataset graphs.
  assert(dataset(DD_G, DS, DS_F, DS_G)).

%! void_load_library(+File:atom, +Graph:atom) is det.
% Loads a VoID file and all the datasets defined in it.
% Also calculates VoID statistics for all datasets and asserts those to
% the VoID file.
%
% @param File The atomic name of an absolute file path of a VoID file.
% @param Graph The atomic name of the VoID graph.

% The RDF graph already exists.
void_load_library(_F, G):-
  rdf_graph(G), !,
  debug(
    void_file,
    'Cannot load VoID file since RDF graph ~w already exists.',
    [G]
  ).
void_load_library(F, G):-
  % Make sure the VoID file exists and is readable.
  access_file(F, read),
  nonvar(G),

  % Clear the internal database.
  retractall(dataset(G, _, _, _)),

  % Make sure the VoID vocabulary is loaded.
  void_init,

  % Load the VoID file into an RDF graph with the given name.
  rdf_load2(F, [graph(G)]),
  debug(void_file, 'VoID file ~w loaded into graph ~w.', [F,G]),

  % All datasets are loaded in multiple threads.
  forall_thread(
    (
      % This includes VoID linksets, according to the VoID vocabulary.
      rdfs_individual_of(DS, void:'Dataset'),
      format(atom(Msg), 'Loading dataset ~w.', [DS])
    ),
    void_load_dataset(F, G, DS),
    void_file,
    Msg
  ).

%! void_save_library(+Graph:atom, ?File:atom) is det.
% @tbd Add meta-data updates.

void_save_library(G, F):-
  % First save all datasets that are described in the given VoID graph.
  forall_thread(
    (
      dataset(G, _DS, DS_F, DS_G),
      format(atom(Msg), 'Saving graph ~w.', [DS_G])
    ),
    rdf_save2(DS_F, [format(turtle),graph(DS_G)]),
    void_file,
    Msg
  ),
  % Then save the VoID graph itself.
  rdf_save2(F, [format(turtle),graph(G)]).

void_update_library(G):-
  forall_thread(
    (
      dataset(G, DS, _DS_F, DS_G),
      format(atom(Msg), 'Updating dataset ~w', [DS])
    ),
    (
      void_assert_modified(G, DS),
      void_assert_statistics(G, DS, DS_G)
    ),
    void_file,
    Msg
  ).