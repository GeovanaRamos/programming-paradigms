# Base64

This repository has implementations of Base64 in Prolog and Assembly x86. For both implementations, it is necessary to have a *version.txt* and *help.txt* at the root of your repository.

## Prolog

Run the program with
```
./main.pl [OPTION]... [FILE]
```

Options:
- None to encode
- -d or --decode to decode
- -w N or --wrap N to break the output in N lines
- -i or --ignore-garbage to ignore chars outside Base64 index table
- --version to show the original version message from Base64
- --help to show the original help message from Base64

Obs: encoding works for all ISO-LATIN-1 inputs. However, decoding does not work if the original message was an ISO-LATIN-1 input. Although the result is theoretically correct, it is in UTF-8 and it needs to be converted to ISO-LATIN-1 to be visually correct.


## Assembly x86

Build the program with
```
nasm -f elf main.s && ld -m elf_i386 main.o -o main
```

Run the program with
```
./main [OPTION]... [FILE]
```

Options:
- None to encode
- -d or --decode to decode
- --version to show the original version message from Base64
- --help to show the original help message from Base64