:- module(
  http11,
  [
    'content-type'//1,   % -Mime:dict
    'field-name'//1,     % -Name:string
    'header-field'//1,   % -Header:pair
    http_parse_header/3, % +Key, +Val, -Term
    'media-type'//1,     % -MT
    method//1,           % -Method:string
    'OWS'//0,
    'rfc850-date'//1     % -Date:dict
  ]
).

/** <module> HTTP 1.1: Hypertext Transfer Protocol (HTTP/1.1)

# Common mistakes

## Access-Control-Allow-Credentials

Value `*' i.o. `true'.

```http
Access-Control-Allow-Credentials: *
```


## ETag

No double quotes (`DQUOTE') surrounding the opaque identifier.

```http
ETag: e90ec0728cc9d1a7dd2c917923275fb9
```


## Expires

Timezone other than `"GMT"'.

```http
Expires: Sat, 26 Dec 2015 010:30:29 UTC
```

The numer zero i.o. a date-time value.

```http
Expires: 0
```


## Last-modified

Timezone other than `"GMT"'.

```http
Last-Modified: Sat, 26 Dec 2015 010:30:29 UTC
```


## Link

The query component of an URI cannot contain unescaped angular brackets.

```http
Link: <http://el.dbpedia.org/data/Linux.rdf>; rel="alternate"; type="application/rdf+xml"; title="Structured Descriptor Document (RDF/XML format)", <http://el.dbpedia.org/data/Linux.n3>; rel="alternate"; type="text/n3"; title="Structured Descriptor Document (N3/Turtle format)", <http://el.dbpedia.org/data/Linux.json>; rel="alternate"; type="application/json"; title="Structured Descriptor Document (RDF/JSON format)", <http://el.dbpedia.org/data/Linux.atom>; rel="alternate"; type="application/atom+xml"; title="OData (Atom+Feed format)", <http://el.dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fel.dbpedia.org&query=DESCRIBE+<http://el.dbpedia.org/resource/Linux>&format=text%2Fcsv>; rel="alternate"; type="text/csv"; title="Structured Descriptor Document (CSV format)", <http://el.dbpedia.org/data/Linux.ntriples>; rel="alternate"; type="text/plain"; title="Structured Descriptor Document (N-Triples format)", <http://el.dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fel.dbpedia.org&query=DESCRIBE+<http://el.dbpedia.org/resource/Linux>&output=application/microdata+json>; rel="alternate"; type="application/microdata+json"; title="Structured Descriptor Document (Microdata/JSON format)", <http://el.dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fel.dbpedia.org&query=DESCRIBE+<http://el.dbpedia.org/resource/Linux>&output=text/html>; rel="alternate"; type="text/html"; title="Structured Descriptor Document (Microdata/HTML format)", <http://el.dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fel.dbpedia.org&query=DESCRIBE+<http://el.dbpedia.org/resource/Linux>&output=application/ld+json>; rel="alternate"; type="application/ld+json"; title="Structured Descriptor Document (JSON-LD format)", <http://el.dbpedia.org/resource/Linux>; rel="http://xmlns.com/foaf/0.1/primaryTopic", <http://el.dbpedia.org/resource/Linux>; rev="describedby", <http://mementoarchive.lanl.gov/dbpedia/timegate/http://el.dbpedia.org/page/Linux>; rel="timegate"
```

## Location

Lowercase hexadecimal digits in percent encoded characters of URIs
(disallowed by RFC 3986).

```http
Location: https://login2.gnoss.com/obtenerCookie.aspx?UQ5IKlMXioK1tiCnK0oh7y%2fPdqTnyAdHPDV0j1Ox5tEdM14pGmhdaSTZhT3hezOjI4lDAwx%2fOghE%2fLJk7Ce%2ff%2ft%2bsC%2bywTcFPSXaYZhh2Wg9q5mWlDWDvLHMReIWmqWzGhnxNpc4DnbUDjewEMV5vfTVzKD%2bx3gMLq9vZvV%2fL8aIAQOcWkSRam0OyOCkc2KV2zUx24WqdUo9oS5od1ILHDmDwYJxq7WwRgFnHP73WfYJuQJNhwolaTkH7%2blbmx7V4K7bF12Van5ArXjz6umEpg%3d%3d
```


## Server

No linear white space (`LWS') between product and comment.

```http
Server: Jetty(8.1.1.v20120215)
```


## Set-Cookie

Omitting the requires space (`SP') between the separator (`;')
and the cookie parameter.

```http
set-cookie: NSC_tfep-83+63+5+220-91=ffffffff516a73d445525d5f4f58455e445a4a423660;path=/;httponly
```


## Via

Via components must consist of two parts ('protocol' and 'by')
that must be separated by white space (`RWS').

```http
Via: mt-s6, fs4
```


## X-Frame-Options

A valid value that appears multiple times.
(RFC 7034 does not allow comma-separated values.)

```http
X-Frame-Options: SAMEORIGIN, SAMEORIGIN
```

---

@author Wouter Beek
@compat RFC 7230
@compat RFC 7231
@compat RFC 7232
@compat RFC 7233
@compat RFC 7234
@compat RFC 7235
@see https://tools.ietf.org/html/rfc7230
@see https://tools.ietf.org/html/rfc7231
@see https://tools.ietf.org/html/rfc7232
@see https://tools.ietf.org/html/rfc7233
@see https://tools.ietf.org/html/rfc7234
@see https://tools.ietf.org/html/rfc7235
@version 2015/11-2016/03, 2016/07, 2016/09, 2016/11
*/

:- use_module(library(apply)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dcg/rfc2234), [
     'ALPHA'//1,  % ?C
     'CHAR'//1,   % ?C
     'CR'//0,
     'CRLF'//0,
     'CTL'//0,
     'CTL'//1,    % ?C
     'DIGIT'//1,  % ?Weight:nonneg
     'DIGIT'//2,  % ?Weight:nonneg, ?C
     'DQUOTE'//0,
     'HEXDIG'//1, % ?Weight:nonneg
     'HTAB'//0,
     'HTAB'//1,   % ?C
     'LF'//0,
     'OCTET'//1,  % ?C
     'SP'//0,
     'SP'//1,     % ?C
     'VCHAR'//1   % ?C
   ]).
:- use_module(library(dict_ext)).
:- use_module(library(http/cors)).
:- use_module(library(http/csp2)).
:- use_module(library(http/dcg_http)).
:- use_module(library(http/rfc5988)).
:- use_module(library(http/rfc6265)).
:- use_module(library(http/rfc6266)).
:- use_module(library(http/rfc6797)).
:- use_module(library(http/rfc7034)).
:- use_module(library(lists)).
:- use_module(library(ltag/rfc4647), [
     'language-range'//1 % -LRange:list(string)
   ]).
:- use_module(library(ltag/rfc5646), [
     'Language-Tag'//1 as 'language-tag' % -LTag:dict
   ]).
:- use_module(library(mail/rfc5322), [
     mailbox//1 % -Pair:pair(string)
   ]).
:- use_module(library(pair_ext)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(sgml)).
:- use_module(library(uri/rfc3986), [
     'absolute-URI'//1,     % -AbsoluteUri:dict
     fragment//1,           % -Fragment:string
     host//1 as 'uri-host', % -Host:dict
     port//1,               % -Port:nonneg
     query//1,              % -Query:string
     'relative-part'//1,    % -RelativeUri:dict
     'URI-reference'//1     % -UriReference:dict
   ]).

:- meta_predicate
    'field-content'(3, -, ?, ?).





%! accept(-AcceptVals:list(compound))// is det.
%
% ```abnf
% Accept = #( media-range [ accept-params ] )
% ```

accept(L) -->
  '*#'(accept_value0, Pairs),
  {desc_pairs_values(Pairs, L)}.


accept_value0(Weight-accept_value(MT,Exts)) -->
  'media-range'(MT),
  ('accept-params'(Weight, Exts) -> "" ; {Exts = [], Weight = 1.0}).



%! 'accept-charset'(-Charsets:list(atom))// is det.
%
% ```abnf
% Accept-Charset = 1#( ( charset | "*" ) [ weight ] )
% ```

'accept-charset'(L) -->
  +#(accept_charset_value0, Pairs),
  {desc_pairs_values(Pairs, L)}.


accept_charset_value0(Weight-Charset) -->
  ("*" -> "" ; charset(Charset)),
  optional_weight(Weight).



%! 'accept-encoding'(-AcceptEncs:list(string))// is det.
%
% ```abnf
% Accept-Encoding = #( codings [ weight ] )
% ```

'accept-encoding'(L) -->
  '*#'(accept_encoding_value0, Pairs),
  {desc_pairs_values(Pairs, L)}.


accept_encoding_value0(Weight-Enc) -->
  codings(Enc),
  optional_weight(Weight).



%! 'accept-ext'(-Ext:or([atom,pair(atom)]))// is det.
%
% ```abnf
% accept-ext = OWS ";" OWS token [ "=" ( token | quoted-string ) ]
% ```

'accept-ext'(Ext) -->
  'OWS', ";", 'OWS',
  token(Key),
  (   "="
  ->  (token(Val), ! ; 'quoted-string'(Val)),
      {Ext = Key-Val}
  ;   {Ext = Key}
  ).



%! 'accept-language'(-AcceptLangs:list(dict))// is det.
%
% ```abnf
% Accept-Language = 1#( language-range [ weight ] )
% ```

'accept-language'(L) -->
  +#(accept_language_value, Pairs),
  {desc_pairs_values(Pairs, L)}.


accept_language_value(Weight-LRange) -->
  'language-range'(LRange),
  optional_weight(Weight).



%! 'accept-params'(-Weight, -Exts)// is det.
%
% ```abnf
% accept-params = weight *( accept-ext )
% ```

'accept-params'(Weight, Exts) -->
  weight(Weight),
  *('accept-ext', Exts).



%! 'accept-ranges'(-AcceptRanges:list(dict))// is det.
%
% ```abnf
% Accept-Ranges = acceptable-ranges
% ```

'accept-ranges'(L) --> 'acceptable-ranges'(L).



%! 'acceptable-ranges'(-AcceptableRanges:list(dict))// is det.
%
% ```abnf
% acceptable-ranges = 1#range-unit | "none"
% ```

'acceptable-ranges'(L) -->
  (+#('range-unit', L) -> "" ; atom_ci(none) -> {L = []}).



%! age(-N)// is det.
%
% ```abnf
% Age = delta-seconds
% ```

age(N) --> 'delta-seconds'(N).



%! allow(-Methods:list(string))// is det.
%
% ```abnf
% Allow = #method
% ```

allow(L) --> '*#'(method, L).



%! 'asctime-date'(-DT)// is det.
%
% ```abnf
% asctime-date = day-name SP date3 SP time-of-day SP year
% ```

'asctime-date'(date_time(Y,Mo,D,H,Mi,S,0)) -->
  'day-name'(D),
  'SP',
  date3(Mo, D),
  'SP',
  'time-of-day'(H, Mi, S),
  'SP',
  year(Y).



%! 'auth-param'(-Pair)// is det.
%
% ```abnf
% auth-param = token BWS "=" BWS ( token | quoted-string )
% ```

'auth-param'(Key-Val) -->
  token(Key),
  'BWS', "=", 'BWS',
  (token(Val), ! ; 'quoted-string'(Val)).



%! 'auth-scheme'(-Scheme)// is det.
%
% ```abnf
% auth-scheme = token
% ```

'auth-scheme'(A) -->
  token(A).



%! authorization(-Credentials:dict)// is det.
%
% ```abnf
% Authorization = credentials
% ```

authorization(D) -->
  credentials(D).



%! 'BWS'// is det.
%
% ```abnf
% BWS = OWS   ; "bad" whitespace
% ```

'BWS' -->
  'OWS'.



%! 'byte-content-range'(-ByteContentRange:dict)// is det.
%
% ```abnf
% byte-content-range = bytes-unit SP ( byte-range-resp | unsatisfied-range )
% ```

'byte-content-range'(D2) -->
  'bytes-unit',
  'SP',
  ('byte-range-resp'(Range, Len), ! ; 'unsatisfied-range'(Range, Len)),
  {
    D1 = byte_content_range{range: Range, unit: "bytes"},
    (var(Len) -> D2 = D1 ; put_dict(length, D1, Len, D2))
  }.



%! 'byte-range'(-ByteRange:pair)// is det.
%
% ```abnf
% byte-range = first-byte-pos "-" last-byte-pos
% ```

'byte-range'(First-Last) -->
  'first-byte-pos'(First),
  "-",
  'last-byte-pos'(Last).



%! 'byte-range-resp'(-Range:pair, ?Len)// is det.
%
% ```abnf
% byte-range-resp = byte-range "/" ( complete-length | "*" )
% ```

'byte-range-resp'(Range, Len) -->
  'byte-range'(Range),
  "/",
  ("*" -> "" ; 'complete-length'(Len)).



%! 'byte-range-spec'(-ByteRangeSpec:dict)// is det.
%
% ```abnf
% byte-range-spec = first-byte-pos "-" [ last-byte-pos ]
% ```

'byte-range-spec'(First-Last) -->
  'first-byte-pos'(First),
  "-",
  ?('last-byte-pos'(Last)).



%! 'byte-ranges-specifier'(-ByteRangesSpecifier:dict)// is det.
%
% ```abnf
% byte-ranges-specifier = bytes-unit "=" byte-range-set
% ```

'byte-ranges-specifier'(
  byte_ranges_specifier{byte_range_set:Ranges,bytes_unit:"bytes"}
) -->
  'bytes-unit',
  "=",
  'byte-range-set'(Ranges).



%! 'byte-range-set'(-ByteRangeSet:list(dict))// is det.
%
% ```abnf
% byte-range-set  = 1#( byte-range-spec | suffix-byte-range-spec )
% ```

'byte-range-set'(L) -->
  +#(byte_range_set_part, L).

byte_range_set_part(D) --> 'byte-range-spec'(D).
byte_range_set_part(D) --> 'suffix-byte-range-spec'(D).



%! 'bytes-unit'// is det.
%
% ```abnf
% bytes-unit = "bytes"
% ```

'bytes-unit' -->
  atom_ci(bytes).



%! 'cache-control'(-Directives:list(dict))// is det.
%
% ```abnf
% Cache-Control = 1#cache-directive
% ```

'cache-control'(L) -->
  +#('cache-directive', L).



%! 'cache-directive'(-CacheDirective:dict)// is det.
%
% ```abnf
% cache-directive = token [ "=" ( token | quoted-string ) ]
% ```

'cache-directive'(Directive) -->
  token(Key),
  (   "="
  ->  (token(Val), ! ; 'quoted-string'(Val)),
      {Directive = Key-Val}
  ;   {Directive = Key}
  ).



%! challenge(-Challenge:dict)// is det.
%
% ```abnf
% challenge = auth-scheme [ 1*SP ( token68 | #auth-param ) ]
% ```

challenge(challenge{authority_scheme:AuthScheme,params:Params}) -->
  'auth-scheme'(AuthScheme),
  (   +('SP')
  ->  (   '*#'('auth-param', Pairs)
      ->  {dict_pairs(Params, Pairs)}
      ;   token68(S),
          {Params = [S]}
      )
  ;   {Params = []}
  ).



%! charset(-Charset)// is det.
%
% ```abnf
% charset = token
% ```

charset(A) -->
  token(A).



%! chunk(-Chunk:dict)// is det.
%
% ```abnf
% chunk = chunk-size [ chunk-ext ] CRLF chunk-data CRLF
% ```
%
% @bug It's a mistake to make chunk-ext optional when its also Kleene star.

chunk(chunk{chunk_data:Cs,chunk_extensions:Exts,chunk_size:Size}) -->
  'chunk-size'(Size),
  'chunk-ext'(Exts), 'CRLF',
  'chunk-data'(Cs), 'CRLF'.



%! 'chunk-data'(-Codes:list(code))// is det.
%
% ```abnf
% chunk-data = 1*OCTET ; a sequence of chunk-size octets
% ```

'chunk-data'(Cs) -->
  +('OCTET', Cs).



%! 'chunk-ext'(-Exts:list(or([atom,pair(atom)])))// is det.
%
% ```abnf
% chunk-ext = *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
% ```

'chunk-ext'(Exts) -->
  *(sep_chunk_ext, Exts).


sep_chunk_ext(Ext) -->
  ";",
  'chunk-ext-name'(Key),
  (   "="
  ->  'chunk-ext-val'(Val),
      {Ext = Key-Val}
  ;   {Ext = Key}
  ).



%! 'chunk-ext-name'(-Name)// is det.
%
% ```abnf
% chunk-ext-name = token
% ```

'chunk-ext-name'(A) -->
  token(A).



%! 'chunk-ext-val'(-Val)// is det.

'chunk-ext-val'(A) -->
  token(A), !.
'chunk-ext-val'(A) -->
  'quoted-string'(A).



%! 'chunk-size'(-Size:nonneg)// is det.
%
% ```abnf
% chunk-size = 1*HEXDIG
% ```

'chunk-size'(N) -->
  +('HEXDIG', Ds),
  {pos_sum(Ds, 16, N)}.



%! codings(-Enc)// is det.
%
% ```abnf
% codings = content-coding | "identity" | "*"
% ```

codings(A)        --> 'content-coding'(A).
codings(identity) --> atom_ci(identity).
codings(_)        --> "*".



%! comment(-Comment:string)// is det.
%
% ```abnf
% comment = "(" *( ctext | quoted-pair | comment ) ")"
% ```

comment(Str) --> dcg_string(comment_codes1, Str).


comment_codes1([0'(|T]) -->
  "(", comment_codes2(T0), ")",
  {append(T0, [0')], T)}.


comment_codes2([H|T]) --> ctext(H), !, comment_codes2(T).
comment_codes2([H|T]) --> 'quoted-pair'(H), !, comment_codes2(T).
comment_codes2(L)     --> comment_codes1(L), !.
comment_codes2([])    --> "".



%! 'complete-length'(-N:positive_integer)// is det.
%
% ```abnf
% complete-length = 1*DIGIT
% ```

'complete-length'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! connection(-ConnectionOpts:list(string))// is det.
%
% ```abnf
% 'Connection'(S) --> 1#(connection-option)
% ```

connection(L) -->
  +#('connection-option', L).



%! 'connection-option'(-ConnectionOpt)// .
%
% ```abnf
% connection-option = token
% ```

'connection-option'(A) -->
  token(A).



%! 'content-coding'(-ContentCoding)// is det.
%
% ```abnf
% content-coding = token
% ```

'content-coding'(A) -->
  token(A).



%! 'content-encoding'(-Encodings:list)// is det.
%
% ```abnf
% Content-Encoding = 1#content-coding
% ```

'content-encoding'(L) -->
  +#('content-coding', L).



%! 'content-language'(-LTags:list(dict))// .
%
% ```abnf
% Content-Language = 1#language-tag
% ```

'content-language'(L) -->
  +#('language-tag', L).



%! 'content-length'(-N)// is det.
%
% ```abnf
% Content-Length = 1*DIGIT
% ```

'content-length'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'content-location'(-Uri:dict)// is det.
%
% ```abnf
% Content-Location = absolute-URI | partial-URI
% ```

'content-location'(Uri) --> 'absolute-URI'(Uri).
'content-location'(Uri) --> 'partial-URI'(Uri).



%! 'content-range'(-ContentRange:dict)// is det.
%
% ```abnf
% Content-Range = byte-content-range | other-content-range
% ```

'content-range'(D) -->
  'byte-content-range'(D).
'content-range'(D) -->
  'other-content-range'(D).



%! 'content-type'(-MT)// is det.
%
% ```abnf
% Content-Type = media-type
% ```

'content-type'(MT) -->
  'media-type'(MT).



%! credentials(-Credentials:dict)// is det.
%
% ```abnf
% credentials = auth-scheme [ 1*SP ( token68 | #auth-param ) ]
% ```

credentials(_{authority_scheme:AuthScheme,params:Params}) -->
  'auth-scheme'(AuthScheme),
  (   +('SP')
  ->  (   token68(Str)
      ->  {Params = [Str]}
      ;   '*#'('auth-param', Pairs),
          {dict_pairs(Params, Pairs)}
      )
  ;   {Params = []}
  ).



%! ctext(?C)// is det.
%
% ```abnf
% ctext = HTAB | SP | %x21-27 | %x2A-5B | %x5D-7E | obs-text
% ```

ctext(C) --> 'HTAB'(C).
ctext(C) --> 'SP'(C).
ctext(C) --> [C], {(  between(0x21, 0x27, C), !
                  ;   between(0x2A, 0x5B, C), !
                  ;   between(0x5D, 0x7E, C)
                  )}.
ctext(C) --> 'obs-text'(C).



%! date(-DT)// is det.
%
% ```abnf
% Date = HTTP-date
% ```

date(DT) -->
  'HTTP-date'(DT).



%! date1(
%!   -Year:between(0,9999),
%!   -Month:between(1,12),
%!   -Day:between(0,99)
%! )// is det.
%
% ```abnf
% date1 = day SP month SP year   ; e.g., 02 Jun 1982
% ```

date1(Y, Mo, D) -->
  day(D),
  'SP',
  month(Mo),
  'SP',
  year(Y).



%! date2(
%!   -Year:between(0,9999),
%!   -Month:between(1,12),
%!   -Day:beween(0,99)
%! )// is det.
%
% ```abnf
% date2 = day "-" month "-" 2DIGIT   ; e.g., 02-Jun-82
% ```

date2(Y, Mo, D) -->
  day(D), "-",
  month(Mo), "-",
  #(2, 'DIGIT', Ds),
  {pos_sum(Ds, Y)}.



%! date3(-Month:between(1,12), -Day:between(0,99))// is det.
%
% ```abnf
% date3 = month SP ( 2DIGIT | ( SP 1DIGIT ))   ; e.g., Jun  2
% ```

date3(Mo, D) -->
  month(Mo), 'SP',
  (   #(2, 'DIGIT', Ds)
  ->  {pos_sum(Ds, D)}
  ;   'SP',
      #(1, 'DIGIT', D)
  ).



%! day(-Day:between(0,99))// is det.
%
% ```abnf
% day = 2DIGIT
% ```

day(D) -->
  #(2, 'DIGIT', Ds),
  {pos_sum(Ds, D)}.



%! 'day-name'(-Day:between(1,7))// is det.
%
% ```abnf
% day-name = %x4D.6F.6E   ; "Mon", case-sensitive
%          | %x54.75.65   ; "Tue", case-sensitive
%          | %x57.65.64   ; "Wed", case-sensitive
%          | %x54.68.75   ; "Thu", case-sensitive
%          | %x46.72.69   ; "Fri", case-sensitive
%          | %x53.61.74   ; "Sat", case-sensitive
%          | %x53.75.6E   ; "Sun", case-sensitive
% ```

'day-name'(1) --> atom_ci('Mon'), !.
'day-name'(2) --> atom_ci('Tue'), !.
'day-name'(3) --> atom_ci('Wed'), !.
'day-name'(4) --> atom_ci('Thu'), !.
'day-name'(5) --> atom_ci('Fri'), !.
'day-name'(6) --> atom_ci('Sat'), !.
'day-name'(7) --> atom_ci('Sun').



%! 'day-name-l'(-Day:between(1,7))// is det.
%
% ```abnf
% day-name-l = %x4D.6F.6E.64.61.79            ; "Monday", case-sensitive
%            | %x54.75.65.73.64.61.79         ; "Tuesday", case-sensitive
%            | %x57.65.64.6E.65.73.64.61.79   ; "Wednesday", case-sensitive
%            | %x54.68.75.72.73.64.61.79      ; "Thursday", case-sensitive
%            | %x46.72.69.64.61.79            ; "Friday", case-sensitive
%            | %x53.61.74.75.72.64.61.79      ; "Saturday", case-sensitive
%            | %x53.75.6E.64.61.79            ; "Sunday", case-sensitive
% ```

%! weekday(?Weekday:between(1,7))// .
%
% ```abnf
% weekday = "Monday" | "Tuesday" | "Wednesday"
%         | "Thursday" | "Friday" | "Saturday" | "Sunday"
% ```

'day-name-l'(1) --> atom_ci('Monday'), !.
'day-name-l'(2) --> atom_ci('Tuesday'), !.
'day-name-l'(3) --> atom_ci('Wednesday'), !.
'day-name-l'(4) --> atom_ci('Thursday'), !.
'day-name-l'(5) --> atom_ci('Friday'), !.
'day-name-l'(6) --> atom_ci('Saturday'), !.
'day-name-l'(7) --> atom_ci('Sunday').



%! 'delay-seconds'(-D)// is det.
%
% ```abnf
% delay-seconds = 1*DIGIT
% ```

'delay-seconds'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'delta-seconds'(-Delta:nonneg)// is det.
%
% ```abnf
% delta-seconds = 1*DIGIT
% ```

'delta-seconds'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'entity-tag'(-EntityTag:dict)// is det.
%
% ```abnf
% entity-tag = [ weak ] opaque-tag
% ```

'entity-tag'(entity_tag{opaque_tag: OTag, weak: Weak}) -->
  (weak -> {Weak = true} ; {Weak = false}),
  'opaque-tag'(OTag).



%! expires(-DT)// is det.
%
% ```abnf
% Expires = HTTP-date
% ```

expires(DT) -->
  'HTTP-date'(DT).



%! etag(-ETag:dict)// is det.
%
% Used for Web cache validation and optimistic concurrency control.
%
% ```abnf
% ETag = "ETag" ":" entity-tag
% ```

etag(D) --> 'entity-tag'(D).



%! etagc(?C)// .
%
% ```abnf
% etagc = %x21 | %x23-7E | obs-text   ; VCHAR except double quotes, plus obs-text
% ```

etagc(0x21) --> [0x21].
etagc(C)    --> [C], {between(0x23, 0x7E, C)}.
etagc(C)    --> 'obs-text'(C).



%! expect(-Expectation)// is det.
%
% ```abnf
% Expect = "100-continue"
% ```

expect('100-continue') -->
  atom_ci('100-continue').



%! 'extension-pragma'(-Ext:or([atom,pair(atom)]))// is det.
%
% ```abnf
% extension-pragma = token [ "=" ( token | quoted-string ) ]
% ```

'extension-pragma'(Ext) -->
  token(Key),
  (   "="
  ->  (token(Val), ! ; 'quoted-string'(Val)),
      {Ext = Key-Val}
  ;   {Ext = Key}
  ).



%! 'field-content'(:Key_3, -Val:dict)// .
%
% ```abnf
% field-content = field-vchar [ 1*( SP | HTAB ) field-vchar ]
% ```

'field-content'(Mod:Key_3, Dict) -->
  (   {current_predicate(Key_3/3)}
  ->  (   % Valid value.
          dcg_call(Mod:Key_3, Val),
          'OWS',
          % This should fail in case only /part/ of the HTTP header is parsed.
          eos
      ->  {Dict = valid_http_header{value: Val}}
      ;   % Empty value.
          phrase('obs-fold')
      ->  {Dict = empty_http_header{}}
      ;    % Buggy value.
          rest(Cs),
          {
            Dict = invalid_http_header{},
            debug(http(parse), "Buggy HTTP header ~a: ~s", [Key_3,Cs])
          }
      )
  ;   % Unknown unknown key.
      rest(Cs),
      {
        Dict = unknown_http_header{},
        (   known_unknown(Key_3)
        ->  true
        ;   debug(http(parse), "No parser for HTTP header ~a: ~s", [Key_3,Cs])
        )
      }
  ).
known_unknown('cf-ray').
known_unknown('fuseki-request-id').
known_unknown(servidor).
known_unknown('x-acre-source-url').
known_unknown('x-adblock-key').
known_unknown('x-backend').
known_unknown('x-cache').
known_unknown('x-cache-action').
known_unknown('x-cache-age').
known_unknown('x-cache-hits').
known_unknown('x-cache-lookup').
known_unknown('x-cache-operation').
known_unknown('x-cache-rule').
known_unknown('x-cacheable').
known_unknown('x-content-type-options'). % Has grammar.  Implemented.
known_unknown('x-dropbox-http-protocol').
known_unknown('x-dropbox-request-id').
known_unknown('x-drupal-cache').
known_unknown('x-ec-custom-error').
known_unknown('x-fastly-request-id').
known_unknown('x-generator').
known_unknown('x-github-request-id').
known_unknown('x-goog-generation').
known_unknown('x-goog-hash').
known_unknown('x-goog-meta-uploaded-by').
known_unknown('x-goog-metageneration').
known_unknown('x-goog-storage').
known_unknown('x-goog-storage-class').
known_unknown('x-goog-stored-content-encoding').
known_unknown('x-goog-stored-content-length').
known_unknown('x-http-host').
known_unknown('x-hosted-by').
known_unknown('x-metaweb-cost').
known_unknown('x-metaweb-tid').
known_unknown('x-pad').
known_unknown('x-pal-host').
known_unknown('x-pingback').
known_unknown('x-powered-by').
known_unknown('x-productontology-limit').
known_unknown('x-productontology-offset').
known_unknown('x-productontology-results').
known_unknown('x-purl').
known_unknown('x-robots-tag'). % Has grammar.  Implemented.
known_unknown('x-rack-cache').
known_unknown('x-request-id').
known_unknown('x-response-id').
known_unknown('x-runtime').
known_unknown('x-served-by').
known_unknown('x-served-from-cache').
known_unknown('x-sparql').
known_unknown('x-sparql-default-graph').
known_unknown('x-timer').
known_unknown('x-total-results').
known_unknown('x-ua-compatible').
known_unknown('x-uniprot-release').
known_unknown('x-varnish').
known_unknown('x-varnish-caching-rule-id').
known_unknown('x-varnish-header-set-id').
known_unknown('x-xss-protection'). % Has grammar.  Implemented.



%! 'field-name'(-Name)// is det.
%
% ```abnf
% field-name = token
% ```

'field-name'(LowerA) -->
  token(A),
  {downcase_atom(A, LowerA)}.



%! 'field-vchar'(?C)// .
%
% ```abnf
% field-vchar = VCHAR | obs-text
% ```

'field-vchar'(C) --> 'VCHAR'(C).
'field-vchar'(C) --> 'obs-text'(C).



%! 'field-value'(+Cs, +Key, -Val:dict)// is det.
%
% ```abnf
% field-value = *( field-content | 'obs-fold' )
% ```

'field-value'(Cs, Key, D2) :-
  phrase('field-content'(http11:Key, D1), Cs),
  string_codes(Raw, Cs),
  put_dict(raw, D1, Raw, D2).



%! 'first-byte-pos'(-Pos)// is det.
%
% ```abnf
% first-byte-pos = 1*DIGIT
% ```

'first-byte-pos'(Pos) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, Pos)}.



%! from(-Mailbox:dict)// is det.
%
% ```abnf
% From = mailbox
% ```

from(D) -->
  mailbox(D).



%! 'GMT'// is det.
%
% ```abnf
% GMT = %x47.4D.54   ; "GMT", case-sensitive
% ```

'GMT' -->
  atom_ci('GMT').



%! 'header-field'(-Header:pair)// is det.
%
% ```abnf
% header-field = field-name ":" OWS field-value OWS
% ```

'header-field'(Key-D) -->
  'field-name'(Key),
  ":", 'OWS',
  rest(Cs),
  {'field-value'(Cs, Key, D)}.



%! host(-Host:dict)// is det.
%
% ```abnf
% Host = uri-host [ ":" port ] ; Section 2.7.1
% ```

host(D2) -->
  'uri-host'(UriHost),
  {D1 = host{uri_host: UriHost}},
  (":" -> port(Port), {put_dict(port, D1, Port, D2)} ; {D2 = D1}).



%! hour(-Hour:between(0,99))// is det.
%
% ```abnf
% hour = 2DIGIT
% ```

hour(H) -->
  #(2, 'DIGIT', Ds),
  {pos_sum(Ds, H)}.



%! 'HTTP-date'(-DT)// is det.
%
% ```abnf
% HTTP-date = IMF-fixdate | obs-date
% ```

'HTTP-date'(DT) -->
  'IMF-fixdate'(DT).
'HTTP-date'(DT) -->
  'obs-date'(DT).



%! http_parse_header(+Key, +Val, -Term) is det.

http_parse_header(Key, Val, Term) :-
  Dcg_0 =.. [Key,Term],
  once(atom_phrase(Dcg_0, Val)).



%! 'if-match'(-IfMatch:list(dict))// is det.
%
% ```abnf
% If-Match = "*" | 1#entity-tag
% ```

'if-match'([]) -->
  "*", !.
'if-match'(L)  -->
  +#('entity-tag', L).



%! 'if-modified-since'(-DT)// is det.
%
% ```abnf
% If-Modified-Since = HTTP-date
% ```

'if-modified-since'(DT) -->
  'HTTP-date'(DT).



%! 'if-none-match'(-IfNoneMatch:list(dict))// is det.
%
% ```abnf
% If-None-Match = "*" | 1#entity-tag
% ```

'if-none-match'([]) -->
  "*", !.
'if-none-match'(L) -->
  +#('entity-tag', L).



%! 'if-range'(-Val:or([compound,dict]))// is det.
%
% ```abnf
% If-Range = entity-tag | HTTP-date
% ```

'if-range'(D) -->
  'entity-tag'(D), !.
'if-range'(DT) -->
  'HTTP-date'(DT).



%! 'if-unmodified-since'(-DT)// is det.
%
% ```abnf
% If-Unmodified-Since = HTTP-date
% ```

'if-unmodified-since'(DT) -->
  'HTTP-date'(DT).



%! 'IMF-fixdate'(-DT)// is det.
%
% ```abnf
% IMF-fixdate = day-name "," SP date1 SP time-of-day SP GMT
%             ; fixed length/zone/capitalization subset of the format
%             ; see Section 3.3 of [RFC5322]
% ```

'IMF-fixdate'(date_time(Y,Mo,D,H,Mi,S,0)) -->
  'day-name'(_DayInWeek),
  ",",
  'SP',
  date1(Y, Mo, D),
  'SP',
  'time-of-day'(H, Mi, S),
  'SP',
  'GMT'.



%! 'last-byte-pos'(-Position:nonneg)// is det.
%
% ```abnf
% last-byte-pos = 1*DIGIT
% ```

'last-byte-pos'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'last-chunk'(-Exts:list)// is det.
%
% ```abnf
% last-chunk = 1*("0") [ chunk-ext ] CRLF
% ```
%
% @bug It's a mistake to make chunk-ext optional when its also Kleene star.

'last-chunk'(Exts) -->
  +("0"),
  'chunk-ext'(Exts),
  'CRLF'.



%! 'last-modified'(-DT)// is det.
%
% ```abnf
% Last-Modified = HTTP-date
% ```

'last-modified'(DT) -->
  'HTTP-date'(DT).



%! location(-Uri:dict)// is det.
%
% ```abnf
% Location = URI-reference
% ```

location(D) -->
  'URI-reference'(D).



%! 'max-forwards'(-Max:nonneg)// is det.
%
% ```abnf
% Max-Forwards = 1*DIGIT
% ```

'max-forwards'(N) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'media-range'(-MT)// is det.
%
%	Type and/or Subtype is a variable if the specified value is `*`.
%
% ```abnf
% media-range = ( "*/*"
%               | ( type "/" "*" )
%               | ( type "/" subtype )
%               ) *( OWS ";" OWS parameter )
% ```

'media-range'(media_type(Type,Subtype,Params)) -->
  ("*" -> "/*" ; type(Type), "/", ("*" -> "" ; subtype(Subtype))),
  *(sep_parameter, Params).



%! 'media-type'(-MT)// is det.
%
% ```abnf
% media-type = type "/" subtype *( OWS ";" OWS parameter )
% ```

'media-type'(media_type(Type,Subtype,Params)) -->
  type(Type),
  "/",
  subtype(Subtype),
  (+(sep_parameter, Params) -> "" ; {Params = []}).

sep_parameter(Pair) -->
  'OWS',
  ";",
  'OWS',
  parameter(Pair).



%! 'message-body'(-Body:list(code))// is det.
%
% ```abnf
% message-body = *OCTET
% ```

'message-body'(Cs) -->
  *('OCTET', Cs).



%! method(-Method)// is det.
%
% ```abnf
% method = token
% ```
%
% The following methods are defined by HTTP 1.1:
%   - CONNECT
%   - DELETE
%   - GET
%   - HEAD
%   - OPTIONS
%   - POST
%   - PUT
%   - TRACE

method(A) -->
  token(A).



%! minute(-Minute:between(0,99))// is det.
%
% ```abnf
% minute = 2DIGIT
% ```

minute(Mi) -->
  #(2, 'DIGIT', Ds),
  {pos_sum(Ds, Mi)}.



%! month(-Month:between(1,12))// is det.
%
% ```abnf
% month = %x4A.61.6E ;   "Jan", case-sensitive
%       | %x46.65.62 ;   "Feb", case-sensitive
%       | %x4D.61.72 ;   "Mar", case-sensitive
%       | %x41.70.72 ;   "Apr", case-sensitive
%       | %x4D.61.79 ;   "May", case-sensitive
%       | %x4A.75.6E ;   "Jun", case-sensitive
%       | %x4A.75.6C ;   "Jul", case-sensitive
%       | %x41.75.67 ;   "Aug", case-sensitive
%       | %x53.65.70 ;   "Sep", case-sensitive
%       | %x4F.63.74 ;   "Oct", case-sensitive
%       | %x4E.6F.76 ;   "Nov", case-sensitive
%       | %x44.65.63 ;   "Dec", case-sensitive
% ```

month(1)  --> atom_ci('Jan'), !.
month(2)  --> atom_ci('Feb'), !.
month(3)  --> atom_ci('Mar'), !.
month(4)  --> atom_ci('Apr'), !.
month(5)  --> atom_ci('May'), !.
month(6)  --> atom_ci('Jun'), !.
month(7)  --> atom_ci('Jul'), !.
month(8)  --> atom_ci('Aug'), !.
month(9)  --> atom_ci('Sep'), !.
month(10) --> atom_ci('Oct'), !.
month(11) --> atom_ci('Nov'), !.
month(12) --> atom_ci('Dec').



%! 'obs-date'(-DT)// is det.
%
% ```abnf
% obs-date = rfc850-date | asctime-date
% ```

'obs-date'(DT) -->
  'rfc850-date'(DT), !.
'obs-date'(DT) -->
  'asctime-date'(DT).



%! 'obs-fold'// is det.
%
% ```abnf
% obs-fold = CRLF 1*( SP | HTAB )   ; obsolete line folding
% ```

'obs-fold' -->
  'CRLF',
  +(sp_or_htab).



%! 'obs-text'(?C)// is det.
%
% ```abnf
% obs-text = %x80-FF
% ```

'obs-text'(C) --> [C], {between(0x80, 0xFF, C)}.



%! 'opaque-tag'(-OpaqueTag)// .
%
% ```abnf
% opaque-tag = DQUOTE *etagc DQUOTE
% ```

'opaque-tag'(A) -->
  'DQUOTE',
  *(etagc, Cs),
  'DQUOTE',
  {atom_codes(A, Cs)}.



%! 'other-content-range'(-ContentRange:dict)// is det.
%
% ```abnf
% other-content-range = other-range-unit SP other-range-resp
% ```

'other-content-range'(_{range: Range, unit: Unit}) -->
  'other-range-unit'(Unit),
  'SP',
  'other-range-resp'(Range).



%! 'other-range-resp'(-A)// is det.
%
% ```abnf
% other-range-resp = *CHAR
% ```

'other-range-resp'(A) -->
  *('CHAR', Cs),
  {atom_codes(A, Cs)}.



%! 'other-range-set'(-RangeSet)// is det.
%
% ```abnf
% other-range-set = 1*VCHAR
% ```

'other-range-set'(A) -->
  +('VCHAR', Cs),
  {atom_codes(A, Cs)}.



%! 'other-range-unit'(-RangeUnit)// is det.
%
% ```abnf
% other-range-unit = token
% ```

'other-range-unit'(A) -->
  token(A).



%! 'other-ranges-specifier'(-RangeSpecifier:dict)// is det.
%
% ```abnf
% other-ranges-specifier = other-range-unit "=" other-range-set
% ```

'other-ranges-specifier'(
  _{other_range_unit: OtherRangeUnit, other_range_set: OtherRangeSet}
) -->
  'other-range-unit'(OtherRangeUnit),
  "=",
  'other-range-set'(OtherRangeSet).



%! 'OWS'// is det.
%
% ```abnf
% OWS = *( SP | HTAB )   ; optional whitespace
% ```

'OWS' -->
  *(sp_or_htab).



%! parameter(-Pair)// is det.
%
% ```abnf
% parameter = token "=" ( token | quoted-string )
% ```

parameter(Key-Val) -->
  token(Key),
  "=",
  (token(Val), ! ; 'quoted-string'(Val)).



%! 'partial-URI'(-PartialUri:dict)// is det.
%
% ```abnf
% partial-URI = relative-part [ "?" query ]
% ```

'partial-URI'(D2) -->
  'relative-part'(D1),
  ("?" -> query(Query), {put_dict(query, D1, Query, D2)} ; {D2 = D1}).



%! pragma(?Directives:list)// is det.
%
% ```abnf
% Pragma = 1#pragma-directive
% ```

pragma(L) -->
  +#('pragma-directive', L).



%! 'pragma-directive'(-Val)// is det.
%
% ```abnf
% pragma-directive = "no-cache" | extension-pragma
% ```

'pragma-directive'('no-cache') -->
  atom_ci('no-cache'), !.
'pragma-directive'(D) -->
  'extension-pragma'(D).



%! product(-Product:dict)// is det.
%
% ```abnf
% product = token ["/" product-version]
% ```

product(D2) -->
  token(Name),
  {D1 = product{name: Name}},
  (   "/"
  ->  'product-version'(Version),
      {put_dict(version, D1, Version, D2)}
  ;   {D2 = D1}
  ).



%! 'product-version'(-Version)// is det.
%
% ```abnf
% product-version = token
% ```

'product-version'(A) -->
  token(A).



%! 'proxy-authenticate'(-Challenges:list(dict))// is det.
%
% ```abnf
% Proxy-Authenticate = 1#challenge
% ```

'proxy-authenticate'(L) -->
  +#(challenge, L).



%! 'proxy-authorization'(-Credentials:dict)// is det.
%
% ```abnf
% Proxy-Authorization = credentials
% ```

'proxy-authorization'(D) -->
  credentials(D).



%! protocol(-Protocol:dict)// is det.
%
% ```abnf
% protocol = protocol-name ["/" protocol-version]
% ```

protocol(D2) -->
  'protocol-name'(Name),
  {D1 = protocol{name: Name}},
  (   "/"
  ->  'protocol-version'(Version),
      {put_dict(version, D1, Version, D2)}
  ;   {D2 = D1}
  ).



%! 'protocol-name'(-Name)// .
%
% ```abnf
% protocol-name = token
% ```

'protocol-name'(A) -->
  token(A).



%! 'protocol-version'(-Version)// .
%
% ```abnf
% protocol-version = token
% ```

'protocol-version'(A) -->
  token(A).



%! pseudonym(-Pseudonym)// .
%
% ```abnf
% pseudonym = token
% ```

pseudonym(A) -->
  token(A).



%! qdtext(?C)// is det.
%
% ```abnf
% qdtext = HTAB | SP | %x21 | %x23-5B | %x5D-7E | obs-text
% ```

qdtext(C)    --> 'HTAB'(C).
qdtext(C)    --> 'SP'(C).
qdtext(0x21) --> [0x21].
qdtext(C)    --> [C], {(between(0x23, 0x5B, C), ! ; between(0x5D, 0x7E, C))}.
qdtext(C)    --> 'obs-text'(C).



%! 'quoted-pair'(?C)// .
%
% ```abnf
% quoted-pair = "\" ( HTAB | SP | VCHAR | obs-text )
% ```

'quoted-pair'(C) -->
  "\\",
  ('HTAB'(C) ; 'SP'(C) ; 'VCHAR'(C) ; 'obs-text'(C)).



%! 'quoted-string'(-A)// is det.
%
% ```abnf
% quoted-string = DQUOTE *( qdtext | quoted-pair ) DQUOTE
% ```

'quoted-string'(A) -->
  'DQUOTE',
  *(quoted_string_code, Cs),
  'DQUOTE',
  {atom_codes(A, Cs)}.

quoted_string_code(C) --> qdtext(C).
quoted_string_code(C) --> 'quoted-pair'(C).



%! qvalue(-Val:between(0.0,1.0))// is det.
%
% ```abnf
% qvalue = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
% ```

qvalue(N)   -->
  "0",
  (   "."
  ->  'm*n'(0, 3, 'DIGIT', Ds),
      {pos_frac(Ds, N0), N is float(N0)}
  ;   {N = 0}
  ).
qvalue(1.0) -->
  "1",
  ("." -> 'm*n'(0, 3, "0") ; "").



%! range(-Range:dict)// is det.
%
% ```abnf
% Range = byte-ranges-specifier | other-ranges-specifier
% ```

range(D) -->
  'byte-ranges-specifier'(D).
range(D) -->
  'other-ranges-specifier'(D).



%! 'range-unit'(-A)// is det.
%
% ```abnf
% range-unit = bytes-unit | other-range-unit
% ```

'range-unit'(bytes) -->
  'bytes-unit', !.
'range-unit'(A)     -->
  'other-range-unit'(A).



%! rank(-Rank:between(0.0,1.0))// is det.
%
% ```abnf
% rank = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
% ```

rank(N)   -->
  "0",
  (   "."
  ->  'm*n'(0, 3, 'DIGIT', Ds),
      {
        pos_frac(Ds, N0),
        N is float(N0)
      }
  ;   {N = 0}
  ).
rank(1.0) -->
  "1",
  ("." -> 'm*n'(0, 3, "0") ; "").



%! 'received-by'(-Receiver:dict)// is det.
%
% ```abnf
% received-by = ( uri-host [ ":" port ] ) | pseudonym
% ```

'received-by'(receiver{uri_host: UriHost, port: Port}) -->
  'uri-host'(UriHost), !,
  (":" -> port(Port) ; {Port = 80}).
'received-by'(receiver{pseudonym: Pseudonym}) -->
  pseudonym(Pseudonym).



%! 'received-protocol'(-Protocol:dict)// is det.
%
% ```abnf
% received-protocol = [ protocol-name "/" ] protocol-version
% ```

'received-protocol'(D2) -->
  {D1 = protocol{version: Version}},
  ('protocol-name'(Name), "/" -> {put_dict(name, D1, Name, D2)} ; {D2 = D1}),
  'protocol-version'(Version).



%! referer(-Uri:dict)// is det.
%
% ```abnf
% Referer = absolute-URI | partial-URI
% ```

referer(D) -->
  'absolute-URI'(D).
referer(D) -->
  'partial-URI'(D).



%! 'retry-after'(-DT)// is det.
%
% ```abnf
% Retry-After = HTTP-date | delay-seconds
% ```

'retry-after'(DT) -->
  'HTTP-date'(DT).
'retry-after'(D) -->
  'delay-seconds'(D).



%! 'rfc850-date'(-DT)// is det.
%
% ```abnf
% rfc850-date  = day-name-l "," SP date2 SP time-of-day SP GMT
% ```

'rfc850-date'(date_time(Y,Mo,D,H,Mi,S,0)) -->
  'day-name-l'(D),
  ",",
  'SP',
  date2(Y, Mo, D),
  'SP',
  'time-of-day'(H, Mi, S),
  'SP',
  'GMT'.



%! 'RWS'// is det.
%
% ```abnf
% RWS = 1*( SP | HTAB )   ; required whitespace
% ```

'RWS' -->
  +(sp_or_htab).



%! second(-Second:between(0,99))// is det.
%
% ```abnf
% second = 2DIGIT
% ```
%
% @tbd Define an XSD for the range [0,99].

second(N) -->
  #(2, 'DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! server(-As)// is det.
%
% ```abnf
% Server = product *( RWS ( product | comment ) )
% ```

server([H|T]) -->
  product(H),
  *(sep_product_or_comment, T).



%! subtype(-Subtype)// is det.
%
% ```abnf
% subtype = token
% ```

subtype(A) -->
  token(A).



%! 'suffix-byte-range-spec'(-Len)// is det.
%
% ```abnf
% suffix-byte-range-spec = "-" suffix-length
% ```

'suffix-byte-range-spec'(Len) -->
  "-",
  'suffix-length'(Len).



%! 'suffix-length'(-Len)// is det.
%
% ```abnf
% suffix-length = 1*DIGIT
% ```

'suffix-length'(Len) -->
  +('DIGIT', Ds),
  {pos_sum(Ds, Len)}.



%! 't-codings'(-TCodings)// is det.
%
% ```abnf
% t-codings = "trailers" | ( transfer-coding [ t-ranking ] )
% ```

't-codings'(trailers) -->
  atom_ci(trailers).
't-codings'(D2) -->
  'transfer-coding'(TransferCoding),
  {D1 = tcoding{transfer_coding: TransferCoding}},
  ('t-ranking'(Rank) -> {put_dict('t-ranking', D1, Rank, D2)} ; {D2 = D1}).



%! 't-ranking'(-Rank:float)// is det.
%
% ```abnf
% t-ranking = OWS ";" OWS "q=" rank
% ```
%
% @tbd Define an XSD for the range [0.0,1.0].

't-ranking'(Rank) -->
  'OWS',
  ";",
  'OWS',
  atom_ci('q='),
  rank(Rank).



%! tchar(?C)// is det.
%
% ```abnf
% tchar = "!" | "#" | "$" | "%" | "&" | "'" | "*"
%       | "+" | "-" | "." | "^" | "_" | "`" | "|" | "~"
%       | DIGIT | ALPHA   ; any VCHAR, except delimiters
% ```

tchar(C)   --> 'ALPHA'(C).
tchar(C)   --> 'DIGIT'(_, C).
tchar(0'!) --> "!".
tchar(0'#) --> "#".
tchar(0'$) --> "$".
tchar(0'%) --> "%".
tchar(0'&) --> "&".
tchar(0'') --> "'".
tchar(0'*) --> "*".
tchar(0'+) --> "+".
tchar(0'-) --> "-".
tchar(0'.) --> ".".
tchar(0'^) --> "^".
tchar(0'_) --> "_".
tchar(0'`) --> "`".
tchar(0'|) --> "|".
tchar(0'~) --> "~".



%! te(-TCodings:list)// is det.
%
% ```abnf
% TE = #t-codings
% ```

te(L) -->
  '*#'('t-codings', L).



%! 'time-of-day'(-H, -Mi, -S)// is det.
%
% ```abnf
% time-of-day = hour ":" minute ":" second
%             ; 00:00:00 - 23:59:60 (leap second)
% ```

'time-of-day'(H, Mi, S) -->
  hour(H),
  ":",
  minute(Mi),
  ":",
  second(S).



%! token(-Token)// is det.
%
% ```abnf
% token = 1*tchar
% ```

token(A) -->
  +(tchar, Cs),
  {atom_codes(A, Cs)}.



%! token68(-Token)// is det.
%
% ```abnf
% token68 = 1*( ALPHA | DIGIT | "-" | "." | "_" | "~" | "+" | "/" ) *"="
% ```

token68(A) -->
  +(token68_code, Cs),
  {atom_codes(A, Cs)},
  *("=").

token68_code(C)   --> 'ALPHA'(C).
token68_code(C)   --> 'DIGIT'(_, C).
token68_code(0'-) --> "-".
token68_code(0'.) --> ".".
token68_code(0'_) --> "_".
token68_code(0'~) --> "~".
token68_code(0'+) --> "+".
token68_code(0'/) --> "/".



%! trailer(-Fields:list(string))// is det.
%
% ```abnf
% Trailer = 1#field-name
% ```

trailer(L) -->
  +#('field-name', L).



%! 'transfer-coding'(-TransferCoding)// is det.
%
% ```abnf
% transfer-coding = "chunked"
%                 | "compress"
%                 | "deflate"
%                 | "gzip"
%                 | transfer-extension
% ```

'transfer-coding'(chunked)  --> atom_ci(chunked), !.
'transfer-coding'(compress) --> atom_ci(compress), !.
'transfer-coding'(deflate)  --> atom_ci(deflate), !.
'transfer-coding'(gzip)     --> atom_ci(gzip), !.
'transfer-coding'(D)        --> 'transfer-extension'(D).



%! 'transfer-encoding'(-TransferCodings:list(dict))// is det.
%
% ```abnf
% Transfer-Encoding = 1#transfer-coding
% ```

'transfer-encoding'(L) -->
  +#('transfer-coding', L).



%! 'transfer-extension'(-TransferExt:dict)// is det.
%
% ```abnf
% transfer-extension = token *( OWS ";" OWS transfer-parameter )
% ```

'transfer-extension'('transfer-extension'{token: H, params: Params}) -->
  token(H),
  *(sep_transfer_parameter, Pairs),
  {dict_pairs(Params, Pairs)}.

sep_transfer_parameter(Pair) -->
  'OWS',
  ";",
  'OWS',
  'transfer-parameter'(Pair).



%! 'transfer-parameter'(-Param:pair)// is det.
%
% ```abnf
% transfer-parameter = token BWS "=" BWS ( token | quoted-string )
% ```

'transfer-parameter'(Key-Val) -->
  token(Key),
  'BWS',
  "=",
  'BWS',
  (token(Val), ! ; 'quoted-string'(Val)).



%! type(-Type)// .
%
% ```abnf
% type = token
% ```

type(A) -->
  token(A).



%! 'unsatisfied-range'(-Range:string, -Len)// is det.
%
% ```abnf
% unsatisfied-range = "*/" complete-length
% ```

'unsatisfied-range'(_-_, Len) -->
  "*/",
  'complete-length'(Len).



%! upgrade(-Protocols:list(dict))// is det.
%
% ```abnf
% upgrade = 1#protocol
% ```

upgrade(L) -->
  +#(protocol, L).



%! 'user-agent'(-UserAgent:list)// is det.
%
% ```abnf
% User-Agent = product *( RWS ( product | comment ) )
% ```

'user-agent'([H|T]) -->
  product(H),
  *(sep_product_or_comment, T).



%! vary(-FieldNames:list(dict))// is det.
%
% ```abnf
% Vary = "*" | 1#field-name
% ```

vary([]) -->
  "*", !.
vary(L) -->
  +#('field-name', L).



%! via(-Receiver:list(dict))// is det.
%
% ```abnf
% Via = 1#( received-protocol RWS received-by [ RWS comment ] )
% ```

via(L) -->
  '+#'(via_component, L).

via_component(D2) -->
  'received-protocol'(ReceivedProtocol),
  'RWS',
  'received-by'(ReceivedBy),
  {
    D1 = via_component{
	   received_protocol: ReceivedProtocol,
	   received_by: ReceivedBy
	 }
  },
  ('RWS' -> comment(Z), {D2 = D1.put(comment, Z)} ; {D2 = D1}).



%! 'warn-agent'(-Agent)// is det.
%
% ```abnf
% warn-agent = ( uri-host [ ":" port ] ) | pseudonym
%            ; the name or pseudonym of the server adding
%            ; the Warning header field, for use in debugging
%            ; a single "-" is recommended when agent unknown
% ```

'warn-agent'(D2) -->
  'uri-host'(UriHost),
  (":" -> port(Port), {D1 = _{port: Port}} ; {D1 = _{}}), !,
  {put_dict(uri_host, D1, UriHost, D2)}.
'warn-agent'(Pseudonym) -->
  pseudonym(Pseudonym).



%! 'warn-code'(-N:between(0,999))// is det.
%
% ```abnf
% warn-code = 3DIGIT
% ```

'warn-code'(N) -->
  #(3, 'DIGIT', Ds),
  {pos_sum(Ds, N)}.



%! 'warn-date'(-DT)// is det.
%
% ```abnf
% warn-date = DQUOTE HTTP-date DQUOTE
% ```

'warn-date'(DT) -->
  'DQUOTE',
  'HTTP-date'(DT),
  'DQUOTE'.



%! 'warn-text'(-A)// is det.
%
% ```abnf
% warn-text = quoted-string
% ```

'warn-text'(A) -->
  'quoted-string'(A).



%! warning(-Warnings:list(dict))// is det.
%
% ```abnf
% warning = 1#warning-value
% ```

warning(L) -->
  +#('warning-value', L).



%! 'warning-value'(-WarningVal:dict)// is det.
%
% ```abnf
% warning-value = warn-code SP warn-agent SP warn-text [ SP warn-date ]
% ```

'warning-value'(D2) -->
  'warn-code'(WarnCode),
  'SP',
  'warn-agent'(WarnAgent),
  'SP',
  'warn-text'(WarnText),
  {
    D1 = warning_value{
      warning_agent: WarnAgent,
      warning_code: WarnCode,
      warning_text: WarnText
    }
  },
  (   'SP'
  ->  'warn-date'(WarnDate),
      {put_dict(warning_date, D1, WarnDate, D2)}
  ;   {D2 = D1}
  ).



%! weak// is det.
%
% ```abnf
% weak = %x57.2F   ; "W/", case-sensitive
% ```

weak -->
  "W/".



%! weight(-Weight:between(0.0,1.0))// is det.
%
% ```abnf
% weight = OWS ";" OWS "q=" qvalue
% ```

weight(N) -->
  'OWS',
  ";",
  'OWS',
  atom_ci('q='),
  qvalue(N).



%! 'www-authenticate'(-Challenges:list(dict))// is det.
%
% ```abnf
% WWW-Authenticate = 1#challenge
% ```

'www-authenticate'(L) -->
  +#(challenge, L).



%! year(-Year:between(0,9999))// is det.
%
% ```
% year = 4DIGIT
% ```

year(Y) -->
  #(4, 'DIGIT', Ds),
  {pos_sum(Ds, Y)}.





% HELPERS %

%! header_field_eol(-Header)// is det.

header_field_eol(Header) -->
  'header-field'(Header),
  'CRLF'.



%! optional_weight(-Weight:between(0.0,1.0))// is det.

optional_weight(Weight) -->
  weight(Weight), !.
optional_weight(1.0).



%! sep_product_or_comment(-A)// is det.

sep_product_or_comment(A) -->
  'RWS',
  (product(A), ! ; comment(A)).



%! sp_or_htab// is nondet.

sp_or_htab --> 'SP'.
sp_or_htab --> 'HTAB'.
