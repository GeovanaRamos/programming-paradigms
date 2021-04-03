#!/usr/bin/env swipl

% converte pra ascii - OK
% de ascii para binario - OK
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

codes_to_bin([], _) :- !.
codes_to_bin([H|[]], [NewH|[]]) :- dec_to_bin(H, NewH).
codes_to_bin([H|T], [NewH|NewT]) :- 
    dec_to_bin(H, NewH),  
    codes_to_bin(T, NewT).


dec_to_bin(0,'0').
dec_to_bin(1,'1').
dec_to_bin(N,B):- 
    N>1,
    X is N mod 2,
    Y is N//2,
    dec_to_bin(Y,B1),
    atom_concat(B1, X, B).
