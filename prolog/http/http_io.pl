:- module(
  http_io,
  [
    http_delete/1,               % +Iri
    http_delete/2,               % +Iri, :Goal_3
    http_delete/3,               % +Iri, :Goal_3, +Opts
    http_get/1,                  % +Iri
    http_get/2,                  % +Iri, :Goal_3
    http_get/3,                  % +Iri, :Goal_3, +Opts
    http_head/1,                 % +Iri
    http_head/2,                 % +Iri, +Opts
    http_header/3,               % +Key, +Path, -Val
    http_is_scheme/1,            % ?Scheme
    http_options/1,              % +Iri
    http_options/2,              % +Iri, +Opts
    http_post/2,                 % +Iri, +Data
    http_post/3,                 % +Iri, +Data, :Goal_3
    http_post/4,                 % +Iri, +Data, :Goal_3, +Opts
    http_put/2,                  % +Iri, +Data
    http_put/3,                  % +Iri, +Data, :Goal_3
    http_put/4,                  % +Iri, +Data, :Goal_3, +Opts
    http_retry_until_success/1,  % :Goal_0
    http_retry_until_success/2,  % :Goal_0, +Timeout
    http_status_is_auth_error/1, % +Status
    http_status_is_error/1,      % +Status
    http_status_is_redirect/1,   % +Status
    http_status_label/2,         % +Status, -Lbl
    http_status_must_be/2,       % +Status, +MustBe
    http_throw_bad_request/1     % :Goal_0
  ]
).

/** <module> HTTP I/O

This module extends the functionality of open_any/5 in module
iostream.

The following additional options are supported:

  * compression(+oneof([deflate,gzip,none])) Whether or not
  compression is used on the opened stream.  Default is `none`.

  * max_redirects(+positive_integer) The maximum number of redirects
  that is followed when opening a stream over HTTP.  Default is 5.

  * max_retries(+positive_integer) The maximum number of retries that
  is performed when opening a stream over HTTP.  A retry is made
  whenever a 4xx- or 5xx-range HTTP status code is returned.  Default
  is 1.

  * metadata(-dict)

  * parse_headers(+boolean) Whether HTTP headers are parsed according
  to HTTP 1.1 grammars.  Default is `false`.

The following debug flags are used:

  * http(error)

  * http(headers)

  * io

@author Wouter Beek
@version 2016/07-2016/09, 2016/11
*/

:- use_module(library(apply)).
:- use_module(library(call_ext)).
:- use_module(library(date_time/date_time)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dcg/dcg_pl)).
:- use_module(library(debug_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(http/http_cookie)).     % HTTP cookie support
:- use_module(library(http/http_json)).       % JSON support
:- use_module(library(http/http_open)).       % HTTP support
:- use_module(library(http/http_ssl_plugin)). % HTTPS support
:- use_module(library(http/http11)).
:- use_module(library(iri/iri_ext)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(library(os/io)).
:- use_module(library(print_ext)).
:- use_module(library(settings)).
:- use_module(library(ssl)).                  % SSL support
:- use_module(library(time)).
:- use_module(library(uri)).
:- use_module(library(yall)).

:- meta_predicate
    http_delete(+, 3),
    http_delete(+, 3, +),
    http_get(+, 3),
    http_get(+, 3, +),
    http_post(+, +, 3),
    http_post(+, +, 3, +),
    http_put(+, +, 3),
    http_put(+, +, 3, +),
    http_retry_until_success(0),
    http_retry_until_success(0, +),
    http_throw_bad_request(0).

:- public
    ssl_verify/5.

ssl_verify(_SSL, _ProblemCertificate, _AllCertificates, _FirstCertificate, _Error).

:- setting(
     user_agent,
     string,
     "SWI-Prolog",
     "The HTTP User Agent."
   ).





%! http_delete(+Iri) is semidet.
%! http_delete(+Iri, :Goal_3) is semidet.
%! http_delete(+Iri, :Goal_3, +Opts) is semidet.

http_delete(Iri) :-
  http_delete(Iri, http_default_success).


http_delete(Iri, Goal_3) :-
  http_delete(Iri, Goal_3, []).


http_delete(Iri, Goal_3, Opts0) :-
  merge_options(Opts0, [method(delete)], Opts),
  call_on_stream(Iri, Goal_3, Opts).



%! http_get(+Iri) is det.
%! http_get(+Iri, :Goal_3) is det.
%! http_get(+Iri, :Goal_3, +Opts) is det.

http_get(Iri) :-
  http_get(Iri, http_default_success).


http_get(Iri, Goal_3) :-
  http_get(Iri, Goal_3, []).


http_get(Iri, Goal_3, Opts0) :-
  merge_options([method(get)], Opts0, Opts),
  call_on_stream(Iri, Goal_3, Opts).



%! http_head(+Iri) is semidet.
%! http_head(+Iri, +Opts) is semidet.

http_head(Iri) :-
  http_head(Iri, []).


http_head(Iri, Opts0) :-
  merge_options(Opts0, [method(head)], Opts),
  call_on_stream(Iri, _, Opts).



%! http_header(+Key, +Path, -Val) is nondet.

http_header(Key, Path, Val) :-
  http_get_dict(headers, Path, Headers),
  downcase_atom(Key, KeyNorm),
  get_dict(KeyNorm, Headers, Dicts),
  member(Dict, Dicts),
  dict_pairs(Dict, valid_http_header, Pairs),
  memberchk(value-Val, Pairs).



%! http_is_scheme(+Scheme) is semidet.

http_is_scheme(http).
http_is_scheme(https).



%! http_open_any(+Iri, -In, -Path, +Opts) is det.
%
% The following options are supported:
%
%   * max_redirects(+nonneg) Default is 5.
%
%   * max_retries(+nonneg) Default is 1.
%
%   * metadata(-list(dict)) Contains the following keys:
%
%     * headers(list(list(code)))
%
%     * iri(atom)
%
%     * status(between(100,599))
%
%     * time(float)
%
%     * version(dict) Contains the following keys:
%
%       * major(nonneg)
%
%       * minor(nonneg)

http_open_any(Iri, In, Path, Opts) :-
  option(max_redirects(MaxRedirect), Opts, 5),
  option(max_retries(MaxRetry), Opts, 1),
  State = _{
    max_redirects: MaxRedirect,
    max_retries: MaxRetry,
    redirects: 0,
    retries: 0,
    visited: []
  },
  http_open1(Iri, State, In, Path, Opts).


http_open1(Iri, State, In2, Path, Opts0) :-
  copy_term(Opts0, Opts1),
  setting(user_agent, UA),
  Opts2 = [
    authenticate(false),
    cert_verify_hook(cert_accept_any),
    header(location,Location),
    raw_headers(Lines),
    redirect(false),
    status_code(Status),
    user_agent(UA),
    version(Major-Minor)
  ],
  merge_options(Opts1, Opts2, Opts3),
  option(timeout(Time), Opts0, inf),
  call_timeout(
    Time,
    call_statistics(
      catch(http_open(Iri, In1, Opts3), E, true),
      walltime,
      TS
    )
  ),
  indent_debug(in, io, "R> ~a → ~w", [Iri,In1]),
  % @tbd Remove throw/1?
  (   var(E)
  ->  deb_http_headers(Lines),
      http_parse_headers(Lines, Groups),
      dict_pairs(Headers, Groups),
      %%%%stream_property(In1, position(Pos)),
      %%%%stream_position_data(byte_count, Pos, NumBytes),
      %%%%stream_position_data(char_count, Pos, NumChars),
      %%%%stream_position_data(line_count, Pos, NumLines),
      H = _{
        %%%%header_byte_count: NumBytes,
        %%%%header_char_count: NumChars,
        %%%%header_line_count: NumLines,
        headers: Headers,
        iri: Iri,
        status: Status,
        time: TS,
        version: _{major: Major, minor: Minor}
      },
      http_open2(Iri, State, Location, Lines, In1, [H|T], In2, Opts0)
  ;   throw(E)
  ),
  reverse([H|T], Path).


% Authentication error.
http_open2(Iri, State, _, Lines, In1, [H|T], In2, Opts) :-
  http_status_is_auth_error(H.status),
  http_open:parse_headers(Lines, Headers),
  http:authenticate_client(Iri, auth_reponse(Headers, Opts, AuthOpts)), !,
  close(In1),
  http_open1(Iri, State, In2, T, AuthOpts).
% Non-authentication error.
http_open2(Iri, State, _, _, In1, [H|T], In2, Opts) :-
  http_status_is_error(H.status), !,
  copy_stream_data(In1, user_error),
  dict_inc(retries, State),
  (   State.retries >= State.max_retries
  ->  In1 = In2,
      T = []
  ;   http_open1(Iri, State, In2, T, Opts)
  ).
% Redirect.
http_open2(Iri0, State, Location, _, In1, [H|T], In2, Opts) :-
  http_status_is_redirect(H.status), !,
  close(In1),
  uri_resolve(Location, Iri0, Iri),
  dict_prepend(visited, State, Iri),
  (   http_is_redirect_limit_exceeded(State)
  ->  http_throw_max_redirect_error(Iri, State.max_redirects)
  ;   http_is_redirect_loop(Iri, State)
  ->  http_throw_looping_redirect_error(Iri)
  ;   true
  ),
  http_open:redirect_options(Opts, RedirectOpts),
  http_open1(Iri, State, In2, T, RedirectOpts).
% Success.
http_open2(_, _, _, _, In, [_], In, _).



%! http_options(+Iri) is semidet.
%! http_options(+Iri, +Opts) is semidet.

http_options(Iri) :-
  http_options(Iri, []).


http_options(Iri, Opts0) :-
  merge_options(Opts0, [method(options)], Opts),
  call_on_stream(Iri, _, Opts).



%! http_post(+Iri, +Data:compound) is det.
%! http_post(+Iri, +Data:compound, :Goal_3) is det.
%! http_post(+Iri, +Data:compound, :Goal_3, +Opts) is det.

http_post(Iri, Data) :-
  http_post(Iri, Data, http_default_success).


http_post(Iri, Data, Goal_3) :-
  http_post(Iri, Data, Goal_3, []).


http_post(Iri, Data, Goal_3, Opts0) :-
  merge_options([method(post),post(Data)], Opts0, Opts),
  call_on_stream(Iri, Goal_3, Opts).



%! http_put(+Iri, +Data:compound) is det.
%! http_put(+Iri, +Data:compound, :Goal_3) is det.
%! http_put(+Iri, +Data:compound, :Goal_3, +Opts) is det.

http_put(Iri, Data) :-
  http_put(Iri, Data, http_default_success).


http_put(Iri, Data, Goal_3) :-
  http_put(Iri, Data, Goal_3, []).


http_put(Iri, Data, Goal_3, Opts0) :-
  merge_options([method(put),post(Data)], Opts0, Opts),
  call_on_stream(Iri, Goal_3, Opts).



%! http_retry_until_success(:Goal_0) is det.
%! http_retry_until_success(:Goal_0, +Timeout) is det.
%
% Retry Goal_0 that uses HTTP communication until the HTTP
% communication succeeds.
%
% Timeout is the number of seconds in between consecutive calls of
% Goal_0.  The default timeout is 10 seconds.

http_retry_until_success(Goal_0) :-
  http_retry_until_success(Goal_0, 10).


http_retry_until_success(Goal_0, Timeout) :-
  catch(Goal_0, E, true),
  (   % HTTP success status code
      var(E)
  ->  true
  ;   % HTTP error status code
      E = error(existence_error(_,[H|_]),_),
      http_get_dict(status, H, Status),
      (http_status_label(Status, Lbl) -> true ; Lbl = "No Label")
  ->  indent_debug(http(error), "Status: ~D (~s)", [Status,Lbl]),
      sleep(Timeout),
      http_retry_until_success(Goal_0)
  ;   % TCP error (Try Again)
      E = error(socket_error('Try Again'), _)
  ->  indent_debug(http(error), "TCP Try Again"),
      sleep(Timeout),
      http_retry_until_success(Goal_0)
  ).



%! http_status_is_auth_error(+Status) is semidet.

http_status_is_auth_error(401).



%! http_status_is_error(+Status) is semidet.

http_status_is_error(Status):-
  between(400, 599, Status).



%! http_status_is_redirect(+Status) is semidet.

http_status_is_redirect(Status) :-
  between(300, 399, Status).



%! http_status_label(+Code:between(100,599), -Lbl) is det.

http_status_label(Code, Lbl):-
  http_header:status_number_fact(Fact, Code),
  string_phrase(http_header:status_comment(Fact), Lbl).



%! http_status_must_be(+Status, +MustBe) is det.
%
% MustBe is a list of HTTP status codes.
%
% @throws `http_status(Status,MustBe)`

http_status_must_be(Status, MustBe) :-
  member(N, MustBe),
  Status =:= N, !.
http_status_must_be(Status, MustBe) :-
  throw(http_status(Status, MustBe)).



%! http_throw_bad_request(:Goal_0) is det.

http_throw_bad_request(Goal_0) :-
  catch(Goal_0, E, true),
  (   var(E)
  ->  true
  ;   message_to_string(E, Msg),
      Code = 400,
      http_status_label(Code, Lbl),
      format(string(Status), "~d (~s)", [Code,Lbl]),
      reply_json_dict(_{error: Msg, status: Status}, [status(Code)])
  ).





% HELPERS %

%! http_get_dict(+Key, +Path, -Val) is semidet.

http_get_dict(Key, Path, Val) :-
  member(Entry, Path),
  get_dict(Key, Entry, Val), !.



%! deb_http_headers(+Lines) is det.

deb_http_headers(Lines) :-
  debugging(http(headers)), !,
  maplist(deb_http_header, Lines).
deb_http_headers(_).


deb_http_header(Line) :-
  string_codes(Str, Line),
  msg_notification("~s~n", [Str]).



%! http_default_success(+In, +Path1, -Path2) is det.

http_default_success(In, L, L) :-
  maplist(print_dict, L),
  copy_stream_data(In, user_output).



%! http_error_msg(+Iri, +Status, +Lines, +In) is det.

http_error_msg(Iri, Status, Lines, In) :-
  maplist([Cs,Header]>>phrase('header-field'(Header), Cs), Lines, Headers),
  create_grouped_sorted_dict(Headers, http_headers, MetaHeaders),
  (http_status_label(Status, Lbl) -> true ; Lbl = "No Label"),
  dcg_with_output_to(string(Str1), pl_dict(MetaHeaders, _{indent: 2})),
  peek_string(In, 1000, Str2),
  msg_warning(
    "HTTP ERROR:~n  Response:~n    ~d (~a)~n  Final IRI:~n    ~a~n  Parsed headers:~n    ~s~n  Message content:~n    ~s~n",
    [Status,Lbl,Iri,Str1,Str2]
  ).



%! http_is_redirect_limit_exceeded(+State) is semidet.

http_is_redirect_limit_exceeded(State) :-
  State.max_redirects == inf, !,
  fail.
http_is_redirect_limit_exceeded(State) :-
  length(State.visited, Len),
  Len > State.max_redirects.



%! http_is_redirect_loop(+Iri, +State) is semidet.

http_is_redirect_loop(Iri, State) :-
  include(==(Iri), State.visited, L),
  length(L, Len),
  Len >= 2.



%! http_parse_headers(+Lines, -Groups) is det.

http_parse_headers(Lines, Groups) :-
  maplist(http_parse_header0, Lines, Pairs),
  keysort(Pairs, SortedPairs),
  group_pairs_by_key(SortedPairs, Groups).


http_parse_header0(Line, Key-Val) :-
  once(phrase('header-field'(Key-Val), Line)).
  %%%%phrase(http_parse_header_simplified(Key, Val), Line).


%%%%http_parse_header_simplified(Key, Val) -->
%%%%  http11:'field-name'(Key0),
%%%%  ":",
%%%%  http11:'OWS',
%%%%  rest(Val0),
%%%%  {
%%%%    atom_codes(Key, Key0),
%%%%    string_codes(Val, Val0)
%%%%  }.



%! http_throw_looping_redirect_error(+Iri) is det.

http_throw_looping_redirect_error(Iri) :-
  throw(
    error(
      permission_error(redirect, http, Iri),
      context(_, 'Redirection loop')
    )
  ).



%! http_throw_max_redirect_error(+Iri, +Max) is det.

http_throw_max_redirect_error(Iri, Max) :-
  format(atom(Comment), "max_redirect (~w) limit exceeded", [Max]),
  throw(
    error(
      permission_error(redirect, http, Iri),
      context(_, Comment)
    )
  ).
