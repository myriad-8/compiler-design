%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();
extern void print_token_summary();
int syntax_error_occurred = 0;

typedef struct ASTNode {
    char* type;
    int val;
    char name[100];
    struct ASTNode *left, *right, *third;
} ASTNode;

ASTNode* root = NULL;

ASTNode* make_node(char* type, ASTNode* left, ASTNode* right, ASTNode* third) {
    ASTNode* n = (ASTNode*)malloc(sizeof(ASTNode));
    n->type = strdup(type);
    n->val = 0; n->name[0] = '\0';
    n->left = left; n->right = right; n->third = third;
    return n;
}

ASTNode* make_num(int val) { ASTNode* n = make_node("NUM", NULL, NULL, NULL); n->val = val; return n; }
ASTNode* make_id(char* name) { ASTNode* n = make_node("ID", NULL, NULL, NULL); strcpy(n->name, name); return n; }
ASTNode* make_str(char* str) { ASTNode* n = make_node("STR", NULL, NULL, NULL); strcpy(n->name, str); return n; }

struct { char name[100]; } symbolTable[100];
int symCount = 0;

void addSymbol(char* name) {
    for(int i=0; i<symCount; i++) if(!strcmp(symbolTable[i].name, name)) return;
    strcpy(symbolTable[symCount++].name, name);
}

void print_symbol_table() {
    printf("\n=======================================================\n");
    printf("                SYMBOL TABLE REPORT\n");
    printf("=======================================================\n");
    for(int i = 0; i < symCount; i++) printf("  [%02d] Identifier : %s\n", i + 1, symbolTable[i].name);
    printf("=======================================================\n");
}

void print_ast(ASTNode* n, int depth) {
    if(!n) return;
    for(int i=0; i<depth; i++) printf("  | ");
    if(!strcmp(n->type, "NUM")) printf("[NUM: %d]\n", n->val);
    else if(n->name[0]) printf("[%s: %s]\n", n->type, n->name);
    else printf("[%s]\n", n->type);
    print_ast(n->left, depth+1); print_ast(n->right, depth+1); print_ast(n->third, depth+1);
}

#ifdef __cplusplus
extern "C" {
#endif
    void start_llvm_pipeline(ASTNode* root);
#ifdef __cplusplus
}
#endif
%}

%union { int num; char id[100]; struct ASTNode* node; }
%token <num> NUMBER
%token <id> ID STRING
%token TAKE SHOW IF ELSE WHILE
%token EQ NE GE LE LOGIC_AND LOGIC_OR
%type <node> program stmt else_part condition expression

%expect 0
%nonassoc IF_PREC
%nonassoc ELSE
%left LOGIC_OR LOGIC_AND
%left '|' '^' '&'
%left EQ NE '>' '<' GE LE
%left '+' '-'
%left '*' '/'
%right '~' '!'

%%
program: program stmt { 
            $$ = make_node("SEQ", $1, $2, NULL); root = $$; 
            printf("[SDT] Reduction: program -> program stmt\n"); 
         } 
       | stmt { 
            $$ = $1; root = $$; 
            printf("[SDT] Reduction: program -> stmt\n"); 
         } ;

stmt: ID '=' expression ';' { 
        addSymbol($1); $$ = make_node("ASSIGN", make_id($1), $3, NULL); 
        printf("[SDT] Action: Assigned expression to ID(%s)\n", $1);
    }
    | TAKE '(' STRING ',' ID ')' ';' { 
        addSymbol($5); $$ = make_node("TAKE", make_str($3), make_id($5), NULL); 
        printf("[SDT] Action: Input (TAKE) for ID(%s)\n", $5);
    }
    | SHOW '(' STRING ',' ID ')' ';' { 
        addSymbol($5); $$ = make_node("SHOW", make_str($3), make_id($5), NULL); 
        printf("[SDT] Action: Output (SHOW) for ID(%s)\n", $5);
    }
    | IF '(' condition ')' '{' program '}' else_part %prec IF_PREC { 
        $$ = make_node("IF", $3, $6, $8); 
        printf("[SDT] Action: IF Statement block created\n");
    }
    | WHILE '(' condition ')' '{' program '}' { 
        $$ = make_node("WHILE", $3, $6, NULL); 
        printf("[SDT] Action: WHILE Loop block created\n");
    } ;

else_part: ELSE '{' program '}' { $$ = $3; printf("[SDT] Action: ELSE block processed\n"); } 
         | { $$ = NULL; printf("[SDT] Action: No ELSE block\n"); } ;

condition: expression { $$ = $1; }
    | expression '>' expression { $$ = make_node(">", $1, $3, NULL); printf("[SDT] Cond: %s > %s\n", $1->type, $3->type); }
    | expression '<' expression { $$ = make_node("<", $1, $3, NULL); printf("[SDT] Cond: %s < %s\n", $1->type, $3->type); }
    | expression EQ expression  { $$ = make_node("==", $1, $3, NULL); printf("[SDT] Cond: %s == %s\n", $1->type, $3->type); }
    | condition LOGIC_AND condition { $$ = make_node("&&", $1, $3, NULL); printf("[SDT] Cond: %s && %s\n", $1->type, $3->type); } ;

expression: expression '+' expression { $$ = make_node("+", $1, $3, NULL); printf("[SDT] Expr: Addition (+)\n"); }
    | expression '-' expression { $$ = make_node("-", $1, $3, NULL); printf("[SDT] Expr: Subtraction (-)\n"); }
    | expression '&' expression { $$ = make_node("&", $1, $3, NULL); printf("[SDT] Expr: Bitwise AND (&)\n"); }
    | NUMBER { $$ = make_num($1); printf("[SDT] Leaf: NUMBER(%d)\n", $1); }
    | ID     { addSymbol($1); $$ = make_id($1); printf("[SDT] Leaf: ID(%s)\n", $1); } ;

%%

void yyerror(const char *s) { 
    extern char* yytext; 
    extern int yylineno; 
    syntax_error_occurred = 1; 
    printf("\n[ERROR] Line %d: Symbol '%s' (%s)\n", yylineno, yytext, s); 
}

int main(int argc, char *argv[]) {
    if (argc < 2) { printf("Usage: expresso_compiler <filename>\n"); return 1; }
    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if (!yyin) return 1;

    printf("\n--- SYNTAX DIRECTED TRANSLATION (SDT) LOG ---\n");
    yyparse();
    printf("----------------------------------------------\n");
    
    if (!syntax_error_occurred) {
        print_token_summary();
        printf("\n--- ABSTRACT SYNTAX TREE ---\n");
        if (root) print_ast(root, 0);
        print_symbol_table();
        if (root) start_llvm_pipeline(root);
    }
    return 0;
}