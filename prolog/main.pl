#!/usr/bin/env swipl

% ENCODE
% converte pra ascii - OK
% de ascii para binario - OK
% junta os binarios em grupos de 6 - OK
% converte os grupos de 6 para o index 
% pega o base64 do index

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
    
    writeln(IndexList).


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