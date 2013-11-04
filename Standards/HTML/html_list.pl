:- module(
  html_list,
  [
    html_link_list//2, % +ListOptions:list(nvpair)
                       % +Parent:atom
    html_list//3, % +ListOptions:list(nvpair)
                  % +ListItemOptions:list(nvpair)
                  % +Items:list(list(dsl))
    html_module_list//1 % +ListOptions:list(nvpair)
  ]
).

/** <module> HTML list

Support for generating HTML lists.

@author Wouter Beek
@version 2013/10-2013/11
*/

:- use_module(library(http/http_path)).
:- use_module(library(http/html_write)).
:- use_module(library(option)).
:- use_module(server(web_console)).



%! html_link_list(+ListOptions:list(nvpair), +Parent:atom)// is det.
% Generates an HTML list for all URL paths that have an HTTP handler
% and that reside under the given parent path.

html_link_list(L_O1, Parent) -->
  {
    findall(
      li(a(href=Link3,Name)),
      (
        http:location(Name, ParentSpec1, _Priority),
        ParentSpec1 =.. [Parent,_],
        ParentSpec2 =.. [Parent,'.'],
        http_absolute_location(ParentSpec2, Link1, []),
        atomic_list_concat([Link1,Name], Link2),
        file_name_extension(Link2, html, Link3)
      ),
      ListItems
    )
  },
  html_list(L_O1, ListItems).

%! html_list(
%!   +ListOptions:list(nvpair),
%!   +ListItemOptions:list(nvpair),
%!   +ListItems:list(compound)
%! )// is det.
% Generates an HTML list containing the given list items.
%
% The following list options are supported:
%   * =|ordered(Ordered:boolean)|=
%     Whether an order =ol= or unordered =ul= HTML list is used.
%
% @param ListOptions A list of name-value pairs,
%        representing options of the HTML list element.
% @param ListItemOptions A list of name-value pairs,
%        representing options of the HTML list items.
% @param ListItems A list of compound terms that are DCG rules
%        in the HTML DSL, used for generating individual list items.

html_list(L_O1, LI_O1, Items) -->
  {
    findall(
      li(LI_O1, Entry),
      member(Entry, Items),
      ListItems
    )
  },
  html_list(L_O1, ListItems).

%! html_list(+ListOptions:list(nvpair), +ListItems:list(compound))// is det.
% Generates an HTML list containing the given list items.
% This is an internal predicate that is used by other in order to share code.
%
% The following options are supported:
%   * =|ordered(Ordered:boolean)|=
%     Whether an order =ol= or unordered =ul= HTML list is used.
%
% @param ListOptions A list of name-value pairs,
%        representing options of the HTML list element.
% @param ListItems A list of compound terms that are DCG rules
%        in the HTML DSL, used for generating individual list items.

html_list(L_O1, ListItems) -->
  {select_option(ordered(Ordered), L_O1, L_O2, false)},
  (
    {Ordered == false}
  ->
    html(ul(L_O2, ListItems))
  ;
    {Ordered == true}
  ->
    html(ol(L_O2, ListItems))
  ).

%! html_module_list(+ListOptions:list(nvpair))// is det.
% Generates an HTML list of the currently registered Web modules.
%
% The following options are supported:
%   * =|ordered(Ordered:boolean)|=
%     Whether an order =ol= or unordered =ul= HTML list is used.
%
% @param ListOptions A list of name-value pairs,
%        representing options of the HTML list element.

html_module_list(L_O1) -->
  {
    findall(
      li(a(href=Link,ExternalName)),
      (
        registered_module(InternalName, ExternalName),
        http_absolute_location(root(InternalName), Link, [])
      ),
      ListItems
    )
  },
  html_list(L_O1, ListItems).

