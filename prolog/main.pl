#!/usr/bin/env swipl

:- initialization(main, main).
:- use_module(library(clpfd)).

main(ArgsList):-
    
    set_prolog_flag(encoding, iso_latin_1),

    parse_arguments(ArgsList, I, W, Mode, Filename),
    read_input(Filename, Codes, Mode),
    call_encode_or_decode(I, W, Mode, Codes).


% Get value for each parameter
parse_arguments([], _, _, _, _) :- !.
parse_arguments(['--help'|_], _, _, _, _) :- help(), halt(0).
parse_arguments(['--version'|_], _, _, _, _) :- version(), halt(0).
parse_arguments(['--decode'|ArgList], I, W, Mode, Filename) :- 
    Mode=1,
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments(['-d'|ArgList], I, W, Mode, Filename) :- 
    Mode=1,
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments(['--wrap'|ArgList], I, W, Mode, Filename) :- 
    ( [Val|T] = ArgList ->
        W=Val,
        parse_arguments(T, I, W, Mode, Filename)
    ;
        writeln('base64: option requires an argument -- \'w\'\nTry \'base64 --help\' for more information.'),
        halt(0)
    ).
parse_arguments(['-w'|ArgList], I, W, Mode, Filename) :- 
    ( [Val|T] = ArgList ->
        W=Val,
        parse_arguments(T, I, W, Mode, Filename)
    ;
        writeln('base64: option requires an argument -- \'w\'\nTry \'base64 --help\' for more information.'),
        halt(0)
    ).
parse_arguments(['--ignore-garbage'|ArgList], I, W, Mode, Filename) :-  
    I=1, 
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments(['-i'|ArgList], I, W, Mode, Filename) :-  
    I=1, 
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments([Arg|_], _, _, _, _) :- 
    string_chars(Arg, Chars),
    [Fchar|Tail] = Chars,
    Fchar = '-',
    [Schar|_] = Tail,
    Schar = '-',
    write('base64: unrecognized option \''),
    write(Arg),
    writeln('\'\nTry \'base64 --help\' for more information.'),
    halt(0).
parse_arguments([Arg|_], _, _, _, _) :- 
    string_chars(Arg, Chars),
    [Fchar|_] = Chars,
    Fchar = '-',
    write('base64: invalid option \''),
    write(Arg),
    writeln('\'\nTry \'base64 --help\' for more information.'),
    halt(0).
parse_arguments([Arg|ArgList], I, W, Mode, Filename) :- 
    Filename=Arg,
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments(_, _, _, _, Filename) :- 
    write('base64: extra operand \''),
    write(Filename),
    writeln('\'\nTry \'base64 --help\' for more information.'),
    halt(0).

% Help message command
help :-
    open('../help.txt', read, Str),
    read_stream_to_codes(Str, X), 
    writef("%s", [X]), writeln('').

% Version message command
version :-
    open('../version.txt', read, Str),
    read_stream_to_codes(Str, X), 
    writef("%s", [X]), writeln('').


% Read file or stdin
read_input(Filename, Codes, _) :- 
    atom(Filename),
    ( exists_file(Filename) ->
        open(Filename, read, Stream),
        read_stream_to_codes(Stream,Codes), % [23,12,13]
        close(Stream)
    ;
        write('base64: '),
        write(Filename),
        writeln(': No such file or directory'),
        halt(0)
    ).
read_input(_, Codes, 0) :-
    current_input(Input),
    read_line_to_codes(Input, InputCodes), 
    close(Input),
    append(InputCodes, [10], Codes).
read_input(_, Codes, 1) :-
    current_input(Input),
    read_line_to_codes(Input, Codes), 
    close(Input).


% Decide each mode to call
call_encode_or_decode(_, W, 0, Codes) :- atom(W), encode(W, Codes).
call_encode_or_decode(_, _, 0, Codes) :- encode('76', Codes).
call_encode_or_decode(I, _, 1, Codes) :- number(I), decode(1, Codes).
call_encode_or_decode(_, _, 1, Codes) :- decode(0, Codes).
call_encode_or_decode(_, _, 1, _) :- writeln('base64: invalid input').


% Encode message
encode(W, Codes) :-

    codes_to_bin(Codes, Binary, 0), % % [[0,1,..,N],[1,0,..,N],..] N<=8
    pad_binary_list(Binary, BinaryList, 8), % [[0,1,..,N],[1,0,..,N],..] N=8

    flatten(BinaryList, FlattenBinary), % [0,1,..,1,0,..]
    
    % check if is divisible by 6 to part, otherwise fill with zeros
    length(FlattenBinary, L),
    append_zeros_end(FlattenBinary, L, BinaryFilled),

    part(BinaryFilled, 6, BinaryGroups), % [[0,1,..,N],[1,0,..,N],..] N=6

    bin_to_index(BinaryGroups, IndexList, 0), % [12, 32, 43] 
    index_to_base64(IndexList, Base64, 0), % [X, y, z]

    length(Codes, BaseLength),
    add_padding(BaseLength, Base64, NewBase64), % [X, y, z, =, =]

    atom_number(W, NewW),

    % Format output
    ( NewW>0 ->
        part(NewBase64, NewW, Concat),
        print_formatted_decode(Concat)
    ;
        atomic_list_concat(NewBase64, Base64Concat),
        writeln(Base64Concat)
    ).


% Pad with "="
add_padding(BaseLength, Base64, NewBase64) :- BaseLength mod 3 =:= 1, append(Base64, ['=', '='], NewBase64).
add_padding(BaseLength, Base64, NewBase64) :- BaseLength mod 3 =:= 2, append(Base64, ['='], NewBase64).
add_padding(_, Base64, NewBase64) :- NewBase64 = Base64.


% Print according to W parameter
print_char(C) :- atom(C), write(C).
print_char(_) :- !.

print_formatted_decode([]) :- !.
print_formatted_decode([H|[]]) :- maplist(print_char, H), writeln(''), !.
print_formatted_decode([H|T]) :- 
    string_chars(String, H),
    writeln(String),
    print_formatted_decode(T).


% Decode message
decode(I, Codes) :-
    
    delete(Codes, 61, NewCodes),
    ( I=0 ->
        NewNewCodes = NewCodes
    ;
        filter_codes(Codes, NewNewCodes)
    ),
    
    atom_codes(String, NewNewCodes), % TWFu
    string_chars(String, Chars), % [T,W,F,u]
    index_to_base64(IndexList, Chars, 1), % [19,22,5,46]

    bin_to_index(Binary, IndexList, 1), % [[0,1,..,N],[1,0,..,N],..] N<=6
    pad_binary_list(Binary, BinaryFilled, 6), % [[0,1,..,N],[1,0,..,N],..] N=6

    flatten(BinaryFilled, FlattenBinary), % [0,1,..,1,0,..]

    % check if is divisible by 8 to part, otherwise remove zeros
    length(FlattenBinary, L),
    remove_zeros_end(FlattenBinary, L, BinaryRemoved),

    part(BinaryRemoved, 8, BinaryGroups), % [[0,1,..,N],[1,0,..,N],..] N=8

    codes_to_bin(BinaryCodes, BinaryGroups, 1),
    atom_codes(Text, BinaryCodes),

    write(Text).


% Remove non valid chars
filter_codes([], _) :- !.
filter_codes([H|[]], [NewH|[]]) :- 
    (H>64,H<91), % A,B,C,D,...
    NewH = H.
filter_codes([H|[]], [NewH|[]]) :- 
    (H>96,H<123), % a,b,c,d,...
    NewH = H.
filter_codes([H|[]], [NewH|[]]) :- 
    (H>46,H<58), % /,1,2,3,4,...
    NewH = H.
filter_codes([H|[]], [NewH|[]]) :- 
    H=43, % +
    NewH = H.
filter_codes([_|[]], []) :- !.
filter_codes([H|T], [NewH|NewT]) :- 
    (H>64,H<91), % A,B,C,D,...
    NewH = H,
    filter_codes(T, NewT).
filter_codes([H|T], [NewH|NewT]) :- 
    (H>96,H<123), % a,b,c,d,...
    NewH = H,
    filter_codes(T, NewT).
filter_codes([H|T], [NewH|NewT]) :- 
    (H>46,H<58), % /,1,2,3,4,...
    NewH = H,
    filter_codes(T, NewT).
filter_codes([H|T], [NewH|NewT]) :- 
    H=43, % +
    NewH = H,
    filter_codes(T, NewT).
filter_codes([_|T], NewCodes) :- 
    filter_codes(T, NewCodes).


% Convert ASCII list to Binary list
codes_to_bin([], _, 0) :- !.
codes_to_bin(_, [], 1) :- !.
codes_to_bin([H|[]], [NewH|[]], _) :- binary_number(NewH, H).
codes_to_bin([H|T], [NewH|NewT], Order) :- 
    binary_number(NewH, H),
    codes_to_bin(T, NewT, Order).


% Iterate list of binary lists to pad zeros
pad_binary_list([], _, _) :- !.
pad_binary_list([H|[]], [NewH|[]], MaxLen) :- length(H, L), append_zeros_start(H, L, MaxLen, NewH).
pad_binary_list([H|T], [NewH|NewT], MaxLen) :- 
    length(H, L),
    append_zeros_start(H, L, MaxLen,  NewH),
    pad_binary_list(T, NewT, MaxLen).


% Convert decimal number to binary number and vice-versa
binary_number(Bin, N) :-
    binary_number(Bin, 0, N).
binary_number([], N, N).
binary_number([Bit|Bits], Acc, N) :-
    Bit in 0..1,
    Acc1 #= Acc*2 + Bit,
    binary_number(Bits, Acc1, N).


% Add zeros to binary number START, if there are less than MaxLen digits
append_zeros_start(B, CurrLen , MaxLen, B) :- CurrLen>=MaxLen.
append_zeros_start(B, CurrLen, MaxLen, NewB) :-
    append([0], B, Concat),
    NewCurrLen is CurrLen+1,
    append_zeros_start(Concat, NewCurrLen, MaxLen, NewB).


% Add zeros to binary number END, if length is not divisible by 6
append_zeros_end(B, L, B) :- L mod 6 =:= 0.
append_zeros_end(B, L, NewB) :-
    append(B, [0], Concat),
    NewL is L+1,
    append_zeros_end(Concat, NewL, NewB).

% Delete last element of a list
delete_last_element([_], []).
delete_last_element([Head, Next|Tail], [Head|NTail]):-
    delete_last_element([Next|Tail], NTail).

% Remove zeros from binary number END, if length is not divisible by 8
remove_zeros_end(B, L, B) :- L mod 8 =:= 0.
remove_zeros_end(B, L, NewB) :-
    delete_last_element(B, Removed),
    NewL is L-1,
    remove_zeros_end(Removed, NewL, NewB).

% Part list into lists of N numbers
part([], _, []).
part(L, N, [DL|DLTail]) :-
   length(DL, N),
   append(DL, LTail, L),
   part(LTail, N, DLTail).

% Converts list of binary lists into list of indexes
bin_to_index([], _, 0) :- !.
bin_to_index(_, [], 1) :- !.
bin_to_index([H|[]], [NewH|[]], _) :- binary_number(H, NewH).
bin_to_index([H|T], [NewH|NewT], Order) :- 
    binary_number(H, NewH),
    bin_to_index(T, NewT, Order).


index_to_base64([], _, 0) :- !.
index_to_base64(_, [], 1) :- !.
index_to_base64([H|[]], [NewH|[]], _) :- base64_char(H, NewH).
index_to_base64([H|T], [NewH|NewT], Order) :- 
    base64_char(H, NewH),
    index_to_base64(T, NewT, Order).


base64_char(00, 'A').
base64_char(01, 'B').
base64_char(02, 'C').
base64_char(03, 'D').
base64_char(04, 'E').
base64_char(05, 'F').
base64_char(06, 'G').
base64_char(07, 'H').
base64_char(08, 'I').
base64_char(09, 'J').
base64_char(10, 'K').
base64_char(11, 'L').
base64_char(12, 'M').
base64_char(13, 'N').
base64_char(14, 'O').
base64_char(15, 'P').
base64_char(16, 'Q').
base64_char(17, 'R').
base64_char(18, 'S').
base64_char(19, 'T').
base64_char(20, 'U').
base64_char(21, 'V').
base64_char(22, 'W').
base64_char(23, 'X').
base64_char(24, 'Y').
base64_char(25, 'Z').
base64_char(26, 'a').
base64_char(27, 'b').
base64_char(28, 'c').
base64_char(29, 'd').
base64_char(30, 'e').
base64_char(31, 'f').
base64_char(32, 'g').
base64_char(33, 'h').
base64_char(34, 'i').
base64_char(35, 'j').
base64_char(36, 'k').
base64_char(37, 'l').
base64_char(38, 'm').
base64_char(39, 'n').
base64_char(40, 'o').
base64_char(41, 'p').
base64_char(42, 'q').
base64_char(43, 'r').
base64_char(44, 's').
base64_char(45, 't').
base64_char(46, 'u').
base64_char(47, 'v').
base64_char(48, 'w').
base64_char(49, 'x').
base64_char(50, 'y').
base64_char(51, 'z').
base64_char(52, '0').
base64_char(53, '1').
base64_char(54, '2').
base64_char(55, '3').
base64_char(56, '4').
base64_char(57, '5').
base64_char(58, '6').
base64_char(59, '7').
base64_char(60, '8').
base64_char(61, '9').
base64_char(62, '+').
base64_char(63, '/').