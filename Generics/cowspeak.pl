:- module(
  cowspeak,
  [
    cowsay/1, % +Text:oneof([atom,list(atom)])
    cowsay/2, % +Text:oneof([atom,list(atom)])
              % -Cow:atom
    cowsay_web/2, % +Text:atom
                  % -Markup:list
    cowspeak/1, % +Text:oneof([atom,list(atom)])
    speech/1 % +Text:oneof([atom,list(atom)])
  ]
).

/** <module> Cowspeak

A funny cow for communicating with the user.

Based on the old cowsay by Tony Monroe,
in combination with the open source speech synthesizer eSpeak.

@author Wouter Beek
@see http://en.wikipedia.org/wiki/Cowsay pointers to cowsay resources.
@see http://espeak.sourceforge.net/ home of eSpeak.
@version 2012/09-2012/10, 2013/05
*/

:- use_module(generics(atom_ext)).
:- use_module(library(debug)).
:- use_module(library(process)).

:- debug(cowspeak).



%! cowsay(+Text:oneof([atom,list(atom)])) is det.
% Sends the given text in a cowified format to user output.

cowsay(Text):-
  cowsay(Text, Cow),
  format(user_output, '~w', [Cow]),
  speech(Text).

%! cowsay(+Text:oneof([atom,list(atom)]), -Cow:atom) is det.
% Turns the given text into a cowified message, displaying the given
% text in the cow's speech bubble.
%
% Meet the cow:
% ==
%    ^__^
%    (oo)|_____
%    (__)|     )/|/
%      ||----w |
%     ||       ||
% ==
%
% @arg Text Either an atomic text message or a list of atomic lines
%        constituting a message.
% @arg Cow An atomic representing of both the cow and the text message.
% @tbd Split lines by words (in whitespace). Add this to module ATOM_EXT.

cowsay(Atom, Cow):-
  atomic(Atom),
  !,
  cowsay([Atom], Cow).
cowsay(Atoms, Cow):-
  % Split the given atoms to fit nicely into the speech bubble.
  max_line(MaxLength),
  findall(
    Line,
    (
      member(Atom, Atoms),
      split_atom_exclusive(Atom, '\n', Lines1),
      member(Line1, Lines1),
      split_atom_length(Line1, MaxLength, Lines2),
      member(Line, Lines2)
    ),
    Lines
  ),

  % Establish the width of the speech bubble.
  maplist(atom_length, Lines, Lengths),
  max_list(Lengths, LongestLength),

  % Draw the speech bubble.
  repeating_atom('-', LongestLength, Dashes),
  findall(
    NewLine,
    (
      member(Line, Lines),
      atom_length(Line, Length),
      NumberOfSpaces is MaxLength - Length,
      repeating_atom(' ', NumberOfSpaces, Spaces),
      atomic_list_concat(['| ', Line, Spaces, ' |'], NewLine)
    ),
    NewLines
  ),
  atomic_list_concat(NewLines, '\n', NewText),
  format(atom(Bubble), '/-~w-\\\n~w\n\\-~w-/\n', [Dashes, NewText, Dashes]),

  % Draw the cow!
  atomic_list_concat(
    [
      Bubble,
      '  |\n',
      '  |\n',
      '  |\n',
      '  |  ^__^\n',
      '   - (oo)______\n',
      '     (__)      )/|/\n',
      '       ||----w||\n',
      '      ||       ||'
    ],
    Cow
  ).

%! cowsay_web(+Text:atom, -Markup:list) is det.

cowsay_web(
  Text,
  [element(title, [], ['Cow says'])]/[element(pre, [], [CowText])]
):-
  speech(Text),
  cowsay(Text, CowText).

%! cowspeak(+Text:oneof([atom,list(atom)])) is det.
% Combines cowsay/1 and speech/1.
% Both predicates do their own list-to-atom or atom-to-list conversions.

cowspeak(Text):-
  cowsay(Text),
  speech(Text).

max_line(76).

%! speech(+Text:oneof([atom,list(atom)])) is det.
% Turns the given text into speech and plays this speech shound.
%
% @arg Text An atomic text message.
% @tbd Add speech for Windows, e.g. using Mary TTS.

speech(Lines):-
  is_list(Lines),
  !,
  maplist(speech, Lines).
speech(Line):-
  atomic(Line),
  process_create(path(espeak), [Line], []),
  !.
speech(_):-
  debug(
    cowspeak,
    'The cow\'s speech cannot be played on the current OS.',
    []
  ).
