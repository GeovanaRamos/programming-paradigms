#!/usr/bin/env swipl

:- initialization(main, main).
:- use_module(library(clpfd)).


main(ArgsList):-
    
    set_prolog_flag(encoding, iso_latin_1),

    parse_arguments(ArgsList, I, W, Mode, Filename),
    ( exists_file(Filename) ->
        call_encode_or_decode(I, W, Mode, Filename),
        halt(0)
    ;
        write('base64: '),
        write(Filename),
        writeln(': Arquivo ou diretório inexistente'),
        halt(0)
    ).


% Get value for each parameter
parse_arguments([], _, _, _, _) :- !.
parse_arguments(['--help'|_], _, _, _, _) :- help(), halt(0).
parse_arguments(['--version'|_], _, _, _, _) :- version(), halt(0).
parse_arguments(['--decode'|ArgList], I, W, Mode, Filename) :- 
    Mode=1,
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments([Arg|ArgList], I, W, Mode, Filename) :- 
    Arg='--wrap';Arg='-w', 
    ( [Val|T] = ArgList ->
        W=Val,
        parse_arguments(T, I, W, Mode, Filename)
    ;
        writeln('base64: a opção requer um argumento -- “w”\nTente "base64 --help" para mais informações.'),
        halt(0)
    ).
parse_arguments([Arg|ArgList], I, W, Mode, Filename) :- 
    Arg='--ignore-garbage';Arg='-i', 
    I=1, 
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments([Arg|_], _, _, _, _) :- 
    string_chars(Arg, Chars),
    [Fchar|Tail] = Chars,
    Fchar = '-',
    [Schar|_] = Tail,
    Schar = '-',
    write('base64: opção não reconhecida “'),
    write(Arg),
    writeln('”\nTente "base64 --help" para mais informações.'),
    halt(0).
parse_arguments([Arg|_], _, _, _, _) :- 
    string_chars(Arg, Chars),
    [Fchar|_] = Chars,
    Fchar = '-',
    write('base64: opção inválida “'),
    write(Arg),
    writeln('”\nTente "base64 --help" para mais informações.'),
    halt(0).
parse_arguments([Arg|ArgList], I, W, Mode, Filename) :- 
    Filename=Arg,
    parse_arguments(ArgList, I, W, Mode, Filename).
parse_arguments(_, _, _, _, Filename) :- 
    write('base64: operando extra “'),
    write(Filename),
    writeln('”\nTente "base64 --help" para mais informações.'),
    halt(0).


% Help message command
help :-
    writeln(
'Uso: base64 [OPÇÃO]... [ARQUIVO]
Codifica/decodifica na Base64 o ARQUIVO, ou entrada padrão, para saída padrão.

Se ARQUIVO não for especificado ou for -, lê a entrada padrão.
        
Argumentos obrigatórios para opções longas também o são para opções curtas.
  -d, --decode          decodifica os dados
  -i, --ignore-garbage  ao decodificar, ignora caracteres não alfabéticos
  -w, --wrap=COLS       quebra linhas codificadas após COLS caracteres
                            (padrão: 76). Use 0 para desabilitar

      --help     mostra esta ajuda e sai
      --version  informa a versão e sai
        
Os dados são codificados como descrito para o alfabeto base64 na RFC 4648.
Na decodificação, a entrada pode conter caracteres de nova linha além dos
bytes do alfabeto base64 formal. Use --ignore-garbage para tentar se recuperar
de quaisquer outros bytes fora do alfabeto no fluxo codificado.

Página de ajuda do GNU coreutils: <https://www.gnu.org/software/coreutils/>
Relate erros de tradução do base64: <https://translationproject.org/team/pt_BR.html>
Documentação completa em: <https://www.gnu.org/software/coreutils/base64>
ou disponível localmente via: info "(coreutils) base64 invocation"').


% Version message command
version :-
    writeln(
'base64 (GNU coreutils) 8.30
Copyright (C) 2018 Free Software Foundation, Inc.
Licença GPLv3+: GNU GPL versão 3 ou posterior <https://gnu.org/licenses/gpl.html>
Este é um software livre: você é livre para alterá-lo e redistribuí-lo.
NÃO HÁ QUALQUER GARANTIA, na máxima extensão permitida em lei.

Escrito por Simon Josefsson.').


% Decide each mode to call
call_encode_or_decode(_, W, 0, Filename) :- atom(W), encode(W, Filename).
call_encode_or_decode(_, _, 0, Filename) :- encode('76', Filename).
call_encode_or_decode(I, _, 1, Filename) :- number(I), decode(1, Filename).
call_encode_or_decode(_, _, 1, Filename) :- decode(0, Filename).


% Encode message
encode(W, Filename) :-
    % Read file
    open(Filename, read, Str),
    read_stream_to_codes(Str,Codes), % [23,12,13]
    close(Str),

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
decode(I, Filename) :-
    open(Filename, read, Str),
    read_stream_to_codes(Str,Codes), % [84,87,70,117]
    close(Str),
    atom_codes(String, Codes), % TWFu
    string_chars(String, Chars), % [T,W,F,u]
    index_to_base64(IndexList, Chars, 1), % [19,22,5,46]

    bin_to_index(Binary, IndexList, 1), % [[0,1,..,N],[1,0,..,N],..] N<=6
    pad_binary_list(Binary, BinaryFilled, 6), % [[0,1,..,N],[1,0,..,N],..] N=6

    flatten(BinaryFilled, FlattenBinary), % [0,1,..,1,0,..]

    % check if is divisible by 8 to part, otherwise fill remove zeros
    length(FlattenBinary, L),
    remove_zeros_end(FlattenBinary, L, BinaryRemoved),

    part(BinaryRemoved, 8, BinaryGroups), % [[0,1,..,N],[1,0,..,N],..] N=8

    codes_to_bin(BinaryCodes, BinaryGroups, 1),
    atom_codes(Text, BinaryCodes),

    writeln(Text).


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