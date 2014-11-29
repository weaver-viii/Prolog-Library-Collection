:- module(
  boolean_ext,
  [
    and/3,
    or/3,
    to_boolean/2 % +Value:oneof([0,1,@(false),@(true),false,'False',off,on,true,'True'])
                 % -Boolean:boolean
  ]
).

/** <module> Boolean extensions

Support for Boolean values.

@author Wouter Beek
@version 2014/03, 2014/11
*/



%! and(?X:boolean, ?Y:boolean, ?Z:boolean) is nondet.

and(false, false, false).
and(false, true,  false).
and(true,  false, false).
and(true,  true,  true ).



%! or(?X:boolean, ?Y:boolean, ?Z:boolean) is nondet.

or(false, false, false).
or(false, true,  true ).
or(true,  false, true ).
or(true,  true,  true ).



%! to_boolean(
%!   +Value:oneof([0,1,@(false),@(true),false,'False',off,on,true,'True']),
%!   -Boolean:boolean
%! ) is det.
% Maps values that are often associated with Boolean values to Boolean values.
%
% The following conversions are supported:
% | *Value*    | *|Boolean value|*   |
% | _false_    | _false_             |
% | _@(false)_ | _false_             |
% | _0_        | _false_             |
% | _off_      | _false_             |
% | _true_     | _true_              |
% | _@(true)_  | _true_              |
% | _1_        | _true_              |
% | _on_       | _true_              |

% Prolog native.
to_boolean(true,     true ).
to_boolean(false,    false).
% Prolog DSL for JSON.
to_boolean(@(true),  true ).
to_boolean(@(false), false).
% Integer boolean.
to_boolean(1,        true ).
to_boolean(0,        false).
% CKAN boolean.
to_boolean('True',   true ).
to_boolean('False',  false).
% Electric switch.
to_boolean(on,       true ).
to_boolean(off,      false).

