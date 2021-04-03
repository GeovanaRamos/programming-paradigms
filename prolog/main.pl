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
    open('texto.txt', read, Str),
    read_stream_to_codes(Str,Codes),
    codes_to_bin(Codes, Binary),
    close(Str),
    writeln(Binary).


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

