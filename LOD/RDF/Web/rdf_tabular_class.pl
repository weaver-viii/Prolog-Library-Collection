:- module(
  rdf_tabular_class,
  [
    rdf_tabular_class//2, % ?Graph:atom
                          % +Class:iri
    rdf_tabular_classes//1 % +Graph:atom
  ]
).

/** <module> RDF HTML graph table

Generates HTML tables for overviews of RDFS classes.

@author Wouter Beek
@version 2014/01-2014/03
*/

:- use_module(dcg(dcg_content)).
:- use_module(generics(meta_ext)).
:- use_module(generics(list_ext)).
:- use_module(html(pl_term_html)).
:- use_module(library(http/html_write)).
:- use_module(library(lists)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(rdf(rdf_name)).
:- use_module(rdf_term(rdf_term)).
:- use_module(rdf_web(rdf_html_table)).
:- use_module(rdf_web(rdf_term_html)).



rdf_tabular_class(G, Class1) -->
  {
    rdf_global_id(Class1, Class2),
    setoff(
      [Instance],
      (
        rdfs_individual_of(Instance, Class2),
        rdf_subject(Instance, G)
      ),
      Instances1
    ),
    length(Instances1, L),
    list_truncate(Instances1, 50, Instances2)
  },
  html([
    p([
      \rdf_term_html(Class2, G),
      ' is an RDF class with ',
      \pl_term_html(L),
      ' instances.'
    ]),
    \rdf_html_table(
      [graph(G),header_row(true)],
      html(['Instances of ',\rdf_term_in_graph_html(Class2, G),'.']),
      [['Instance']|Instances2]
    )
  ]).


rdf_tabular_classes(G) -->
  {
    setoff(
      Class,
      (
        rdfs_individual_of(Class, rdfs:'Class'),
        rdf_term(Class, G)
      ),
      Classes
    ),
    findall(
      NumberOfIndividuals-Class,
      (
        member(Class, Classes),
        aggregate_all(
          count,
          rdfs_individual_of(_, Class),
          NumberOfIndividuals
        )
      ),
      Pairs1
    ),
    keysort(Pairs1, Pairs2),
    reverse(Pairs2, Pairs3),
    findall(
      [Class,NumberOfIndividuals],
      member(NumberOfIndividuals-Class, Pairs3),
      Rows
    )
  },
  rdf_html_table(
    [graph(G),header_row(true)],
    html(['Overview of classes in RDF graph ',\rdf_graph_html(G),'.']),
    [['Class','Members']|Rows]
  ).

