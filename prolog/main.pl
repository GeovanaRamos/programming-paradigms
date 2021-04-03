#!/usr/bin/env swipl

% ENCODE
% converte pra ascii - OK
% de ascii para binario - OK
% acrescenta zeros a esquerda, se necessario - OK
% junta os binarios em grupos de 6
% converte os grupos de 6 para o index
% pega o base64 do index

:- initialization(main, main).


main :-
    % Read file
    open('texto.txt', read, Str),
    read_stream_to_codes(Str,Codes),
    close(Str),

    codes_to_bin(Codes, Binary),

    % Group binary list into groups of 6 binary digits   
    atomic_list_concat(Binary, BinaryConcat), % join all digits into one string
    atom_number(BinaryConcat, BinaryConcatNumber), % convert to one big integer
    number_codes(BinaryConcatNumber,X), % convert to list of ascii digits
    maplist(plus(48),BinaryList,X), % convert ascii to int digits
    
    % check if is divisible by 6 to part, otherwise fill with zeros
    atom_length(BinaryList, L),
    append_zeros_2(BinaryList, L, BinaryFilled),

    part(BinaryFilled, 6, BinaryGroups),

    
    writeln(BinaryGroups).


% Convert ASCII list to Binary list
codes_to_bin([], _) :- !.
codes_to_bin([H|[]], [NewH|[]]) :- dec_to_bin(H, B), atom_length(B, L), append_zeros(B, L, NewH).
codes_to_bin([H|T], [NewH|NewT]) :- 
    dec_to_bin(H, B),
    atom_length(B, L),
    append_zeros(B, L, NewH),
    codes_to_bin(T, NewT).


% Convert decimal number to binary number
dec_to_bin(0,'0').
dec_to_bin(1,'1').
dec_to_bin(N,B):- 
    N>1,
    X is N mod 2,
    Y is N//2,
    dec_to_bin(Y,B1),
    atom_concat(B1, X, B).


% Add zeros to binary number, if there are less than 8 digits
append_zeros(B, 8, NewH) :- NewH = B.
append_zeros(B, 7, NewH) :- atom_concat(0, B, NewH).
append_zeros(B, L, NewH) :-
    atom_concat(0, B, Concat),
    NewL is L+1,
    append_zeros(Concat, NewL, NewH).


% Add zeros to binary list, if length is not divisible by 6
append_zeros_2(B, L, NewB) :- L mod 6 =:= 0, B = NewB.
append_zeros_2(B, L, NewH) :-
    append(B, [0], Concat),
    NewL is L+1,
    append_zeros_2(Concat, NewL, NewH).

part([], _, []).
part(L, N, [DL|DLTail]) :-
   length(DL, N),
   append(DL, LTail, L),
   part(LTail, N, DLTail).


