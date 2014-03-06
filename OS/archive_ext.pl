:- module(
  archive_ext,
  [
    extract_archive/2, % +FromFile:atom
                       % -Conversions:list(oneof([gunzipped,untarred,unzipped]))
    is_archive/1 % +File:atom
  ]
).

/** <module> Archive extensions

Extensions to the support for archived files.

@author Wouter Beek
@version 2013/12-2014/02
*/

:- use_module(generics(db_ext)).
:- use_module(library(filesex)).
:- use_module(library(process)).
:- use_module(os(mime_type)).

% application/x-bzip2
% .bz,.bz2,.tbz,.tbz2
:- mime_register_type(application, 'x-bzip2', bz2).
:- db_add_novel(user:prolog_file_type(bz, archive)).
:- db_add_novel(user:prolog_file_type(bz, bunzip2)).
:- db_add_novel(user:prolog_file_type(bz2, archive)).
:- db_add_novel(user:prolog_file_type(bz2, bunzip2)).
:- db_add_novel(user:prolog_file_type(tbz, archive)).
:- db_add_novel(user:prolog_file_type(tbz, bunzip2)).
:- db_add_novel(user:prolog_file_type(tbz2, archive)).
:- db_add_novel(user:prolog_file_type(tbz2, bunzip2)).
% application/x-gzip
% .gz
:- mime_register_type(application, 'x-gzip', gz).
:- db_add_novel(user:prolog_file_type(gz, archive)).
:- db_add_novel(user:prolog_file_type(gz, gunzip)).
% application/x-rar-compressed
% .rar
:- mime_register_type(application, 'x-rar-compressed', rar).
:- db_add_novel(user:prolog_file_type(rar, archive)).
:- db_add_novel(user:prolog_file_type(rar, rar)).
% application/x-tar
% .tar
% .tgz
:- mime_register_type(application, 'x-tar', tar).
:- db_add_novel(user:prolog_file_type(tar, archive)).
:- db_add_novel(user:prolog_file_type(tar, tar)).
% application/zip
% .zip
:- mime_register_type(application, 'zip', zip).
:- db_add_novel(user:prolog_file_type(zip, archive)).
:- db_add_novel(user:prolog_file_type(zip, zip)).



%! extract_archive(
%!   +FromFile:atom,
%!   -Conversions:list(oneof([gunzipped,untarred,unzipped]))
%! ) is det.

extract_archive(FromFile1, Conversions):-
  file_name_extension(_, tgz, FromFile1), !,
  file_alternative(FromFile1, _, _, '.tar.gz', FromFile2),
  rename_file(FromFile1, FromFile2),
  extract_archive(FromFile2, Conversions).
:- db_add_novel(user:prolog_file_type(tgz, archive)).
extract_archive(FromFile, [Conversion|Conversions]):-
  file_name_extension(Base, Ext, FromFile),
  prolog_file_type(Ext, archive), !,
  extract_archive(Ext, FromFile, Conversion),
  extract_archive(Base, Conversions).
extract_archive(_, []).


%! extract_archive(
%!   +Extension:oneof([bz2,gz,tgz,zip]),
%!   +FromFile:atom,
%!   -Conversion:oneof([gunzipped,untarred,unzipped])
%! ) is semidet.

extract_archive(Extension, File, gunzipped):-
  prolog_file_type(Extension, bunzip2), !,
  process_create(path(bunzip2), ['-f',file(File)], []).
extract_archive(Extension, File, gunzipped):-
  prolog_file_type(Extension, gunzip), !,
  process_create(path(gunzip), ['-f',file(File)], []).
extract_archive(Extension, File, untarred):-
  prolog_file_type(Extension, tar), !,
  directory_file_path(Directory, _, File),
  atomic_list_concat(['--directory',Directory], '=', C),
  process_create(path(tar), [xvf,file(File),C], []),
  delete_file(File).
extract_archive(Extension, File, unzipped):-
  prolog_file_type(Extension, zip), !,
  directory_file_path(Directory, _, File),
  process_create(path(unzip), [file(File),'-fo','-d',file(Directory)], []),
  delete_file(File).


%! is_archive(+File:atom) is semidet.

is_archive(File):-
  file_name_extension(_, Ext, File),
  prolog_file_type(Ext, archive), !.

