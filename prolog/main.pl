#!/usr/bin/env swipl

% converte pra ascii
% de ascii para binario
% junta os binarios em grupos de 6
% converte os grupos de 6 para o index
% pega o base64 do index

:- initialization(main, main).


main :-
    open('texto.txt', read, Str),
    read_stream_to_codes(Str,Text),
    close(Str),
    write(Text), nl.

