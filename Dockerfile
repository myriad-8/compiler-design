# --- STAGE 1: Build ---
FROM fedora:36 AS builder

# Use dnf for everything; added zlib/ncurses which LLVM usually links against
RUN dnf install -y \
    gcc-c++ make flex bison \
    llvm-devel clang \
    zlib-devel ncurses-devel \
    && dnf clean all

WORKDIR /app
COPY . .

# Generate Lexer/Parser
RUN flex lexer.l && bison -d parser.y

# Compile Expresso
# Note: $(llvm-config ...) handles the flags. Removed -I/usr/include/llvm14 
# because llvm-config provides the correct path automatically.
RUN g++ -o expresso lex.yy.c parser.tab.c codegen.cpp \
    -std=c++17 \
    $(llvm-config --cxxflags --ldflags --libs all --system-libs) \
    -Wno-write-strings

# --- STAGE 2: Runtime ---
FROM fedora:36

# Essential: Expresso likely needs 'clang' at runtime to link the generated code
RUN dnf install -y llvm-libs clang && dnf clean all

WORKDIR /app
# Copy to /usr/local/bin so it's in the system PATH
COPY --from=builder /app/expresso /usr/local/bin/expresso

# Set the entrypoint to the binary name directly
ENTRYPOINT ["expresso"]