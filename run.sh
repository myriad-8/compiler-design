#!/bin/bash
flex lexer.l
bison -d parser.y
g++ -c codegen.cpp `llvm-config --cxxflags` -o codegen.o
gcc -c lex.yy.c parser.tab.c
g++ lex.yy.o parser.tab.o codegen.o `llvm-config --ldflags --libs all --system-libs` -o expresso_compiler
sudo cp expresso_compiler /usr/local/bin/

# IMAGE_NAME="ghcr.io/myriad-8/compiler-design/expresso:latest"


# docker pull $IMAGE_NAME

# docker run --rm -v $(pwd):/src $IMAGE_NAME /src/$1