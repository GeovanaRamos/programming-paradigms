#!/usr/bin/env swipl

% ENCODE
% converte pra ascii - OK
% de ascii para binario - OK
% junta os binarios em grupos de 6 - OK
% converte os grupos de 6 para o index - OK
% pega o base64 do index - OK
% sinal = ao final

:- initialization(main, main).
:- use_module(library(clpfd)).


main :-
    % Read file
    open('texto.txt', read, Str),
    read_stream_to_codes(Str,Codes), % [23,12,13]
    close(Str),

    codes_to_bin(Codes, Binary), % % [[0,1,..,N],[1,0,..,N],..] N=8

    flatten(Binary, FlattenBinary), % [0,1,..,1,0,..]
    
    % check if is divisible by 6 to part, otherwise fill with zeros
    length(FlattenBinary, L),
    append_zeros_2(FlattenBinary, L, BinaryFilled),

    part(BinaryFilled, 6, BinaryGroups), % [[0,1,..,N],[1,0,..,N],..] N=6

    bin_to_index(BinaryGroups, IndexList),    
    index_to_base64(IndexList, Base64),
    atomic_list_concat(Base64, Base64Concat),
    
    writeln(Base64Concat).


% Convert ASCII list to Binary list
codes_to_bin([], _) :- !.
codes_to_bin([H|[]], [NewH|[]]) :- binary_number(Bin, H), length(Bin, L), append_zeros(Bin, L, NewH).
codes_to_bin([H|T], [NewH|NewT]) :- 
    binary_number(Bin, H),
    length(Bin, L),
    append_zeros(Bin, L, NewH),
    codes_to_bin(T, NewT).


% Convert decimal number to binary number and vice-versa
binary_number(Bin, N) :-
    binary_number(Bin, 0, N).
binary_number([], N, N).
binary_number([Bit|Bits], Acc, N) :-
    Bit in 0..1,
    Acc1 #= Acc*2 + Bit,
    binary_number(Bits, Acc1, N).


% Add zeros to binary number START, if there are less than 8 digits
append_zeros(B, 8, NewH) :- NewH = B.
append_zeros(B, L, NewH) :-
    append([0], B, Concat),
    NewL is L+1,
    append_zeros(Concat, NewL, NewH).


% Add zeros to binary list END, if length is not divisible by 6
append_zeros_2(B, L, NewB) :- L mod 6 =:= 0, B = NewB.
append_zeros_2(B, L, NewH) :-
    append(B, [0], Concat),
    NewL is L+1,
    append_zeros_2(Concat, NewL, NewH).

% Part list into lists of N numbers
part([], _, []).
part(L, N, [DL|DLTail]) :-
   length(DL, N),
   append(DL, LTail, L),
   part(LTail, N, DLTail).

% Converts list of binary lists into list of indexes
bin_to_index([], _) :- !.
bin_to_index([H|[]], [NewH|[]]) :- binary_number(H, NewH).
bin_to_index([H|T], [NewH|NewT]) :- 
    binary_number(H, NewH),
    bin_to_index(T, NewT).


index_to_base64([], _) :- !.
index_to_base64([H|[]], [NewH|[]]) :- base64_char(H, NewH).
index_to_base64([H|T], [NewH|NewT]) :- 
    base64_char(H, NewH),
    index_to_base64(T, NewT).


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