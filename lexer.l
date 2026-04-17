%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int total_tokens = 0;
typedef struct {
    char category[30];
    char lexemes[100][100]; 
    int count;
} CategoryTracker;

CategoryTracker trackers[20]; 
int num_categories = 0;

void track_token(const char* category, const char* lexeme) {
    total_tokens++; 
    int c_idx = -1;
    for(int i = 0; i < num_categories; i++) {
        if(strcmp(trackers[i].category, category) == 0) {
            c_idx = i;
            break;
        }
    }
    if(c_idx == -1) {
        c_idx = num_categories++;
        strcpy(trackers[c_idx].category, category);
        trackers[c_idx].count = 0;
    }
    for(int i = 0; i < trackers[c_idx].count; i++) {
        if(strcmp(trackers[c_idx].lexemes[i], lexeme) == 0) return;
    }
    strcpy(trackers[c_idx].lexemes[trackers[c_idx].count++], lexeme);
}

void print_token_summary() {
    printf("\n=======================================================\n");
    printf("                TOKEN SUMMARY REPORT\n");
    printf("=======================================================\n");
    for(int i = 0; i < num_categories; i++) {
        printf("%-15s : ", trackers[i].category);
        for(int j = 0; j < trackers[i].count; j++) {
            printf("[%s] ", trackers[i].lexemes[j]);
        }
        printf("\n");
    }
    printf("-------------------------------------------------------\n");
    printf("TOTAL RAW TOKENS PROCESSED: %d\n", total_tokens);
    printf("=======================================================\n");
}
%}

%option yylineno

%%
"take"          { track_token("KEYWORD", yytext); return TAKE; }
"show"          { track_token("KEYWORD", yytext); return SHOW; }
"if"            { track_token("KEYWORD", yytext); return IF; }
"else"          { track_token("KEYWORD", yytext); return ELSE; }
"while"         { track_token("KEYWORD", yytext); return WHILE; }

"=="            { track_token("OPERATORS", yytext); return EQ; }
"!="            { track_token("OPERATORS", yytext); return NE; }
">="            { track_token("OPERATORS", yytext); return GE; }
"<="            { track_token("OPERATORS", yytext); return LE; }
"&&"            { track_token("OPERATORS", yytext); return LOGIC_AND; }
"||"            { track_token("OPERATORS", yytext); return LOGIC_OR; }

"+"|"-"|"*"|"/"|">"|"<"|"!"|"&"|"|"|"^"|"~"|"=" { track_token("OPERATORS", yytext); return yytext[0]; }
";"|"("|")"|"{"|"}"|"," { track_token("PUNCTUATION", yytext); return yytext[0]; }

\"([^\"]*)\"    {
    track_token("STRING_LIT", yytext);
    int len = strlen(yytext);
    strncpy(yylval.id, yytext + 1, len - 2);
    yylval.id[len - 2] = '\0';
    return STRING;
}

[0-9]+          { track_token("CONSTANTS", yytext); yylval.num = atoi(yytext); return NUMBER; }
[a-zA-Z][a-zA-Z0-9]* { track_token("IDENTIFIERS", yytext); strcpy(yylval.id, yytext); return ID; }
[ \t\n\r]+      { ; }
.               { track_token("UNKNOWN", yytext); return yytext[0]; }

%%
int yywrap() { return 1; }