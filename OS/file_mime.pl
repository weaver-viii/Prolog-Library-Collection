:- module(
  file_mime,
  [
    file_mime/2, % +File:atom
                 % -MIME:atom
    mime_dir/3 % +FromDirectory:atom
               % +ToDirectory:atom
               % -AP_Status:compound
  ]
).

/** <module> File mime

Returns the MIME of a given file.

@author Wouter Beek
@version 2014/01
*/

:- use_module(dcg(dcg_cardinal)).
:- use_module(dcg(dcg_content)).
:- use_module(dcg(dcg_generic)).
:- use_module(library(debug)).
:- use_module(library(filesex)).
:- use_module(library(lists)).
:- use_module(library(pure_input)).
:- use_module(os(dir_ext)).



/*DEB
:- use_module(os(io_ext)).
file_mime(File, Mime):-
  file_to_atom(File, Atom),
  atom_codes(Atom, Codes),
  phrase(file_mime(Mime), Codes), !.
*/
file_mime(File, _):-
  \+ access_file(File, read), !,
  debug(file_mime, 'Cannot read from file ~w.', [File]),
  fail.
file_mime(File, MIME):-
  phrase_from_file(file_mime(MIME), File), !.
file_mime(File, MIME):-
  gtrace, %DEB
  file_mime(File, MIME).


%! mime_dir(
%!   +FromDirectory:atom,
%!   +ToDirectory:atom,
%!   -AP_Status:compound
%! ) is det.

mime_dir(FromDir, ToDir, ap(status(succeed),properties(OfFiles))):-
  directory_files([], FromDir, FromFiles),
  findall(
    of_file(FromFile,[nvpair('MIME',mime(MIME))]),
    (
      member(FromFile, FromFiles),
      file_mime(FromFile, MIME)
    ),
    OfFiles
  ),
  forall(
    member(FromFile, FromFiles),
    copy_file(FromFile, ToDir)
  ).


file_mime('application/x-turtle') -->
  ci_string(`@prefix`), !,
  dcg_done.
file_mime('text/html') -->
  `<!`, ci_string(`DOCTYPE`), blanks,
  ci_string(`HTML`), !,
  dcg_done.
file_mime(Mime) -->
  blanks,
  (xml_declaration(_) ; ""), blanks,
  (xml_comment ; ""), blanks,
  xml_something(Mime),
  dcg_done.

xml_comment -->
  `<!--`,
  dcg_until([end_mode(inclusive)], test, _),
  blanks_to_nl.
test -->
  `-->`.

%! xml_declaration(?Version:float)// .
% The XML specification also permits an XML declaration at
%  the top of the document with the XML version and possibly
%  the XML content encoding. This is optional but recommended.

xml_declaration(Version) -->
  `<?`, ci_string(`XML`), whites,
  (xml_version(Version), whites ; ""),
  (xml_encoding, whites ; ""),
  `?>`, blanks_to_nl.

xml_doctype('application/rdf+xml') -->
  `<!`, ci_string(`DOCTYPE`), blanks, `rdf:RDF`, !,
  dcg_done.

xml_encoding -->
  `encoding=`,
  quoted(utf8).

utf8 -->
  ci_string(`UTF`), `-8`.

xml_something('application/rdf+xml') -->
  `<rdf:RDF`, !,
  dcg_done.
xml_something(MIME) -->
  xml_doctype(MIME).
xml_something('text/xml') -->
  dcg_done.

xml_version(Version) -->
  `version=`,
  quoted(float(Version)).
