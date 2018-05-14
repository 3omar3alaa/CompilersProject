%{
#include <stdlib.h>
#include<string.h>
#include "proj.h"
#include "proj.tab.h"
void yyerror(char *);
%}
%option yylineno
%%

[0-9]+\.[0-9]+ 	{
                yylval.fValue = atof(yytext);
                return FLOAT;
            }	
			
0           {
                yylval.iValue = atoi(yytext);
                return INTEGER;
            }

		
[1-9][0-9]* {
                yylval.iValue = atoi(yytext);
                return INTEGER;
            }

[-()<>=+*/;:{}.,] {
                return *yytext;
            }

">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"&&"			return AND;
"||"			return OR;
"^"				return XOR;
"while"         return WHILE;
"if"            return IF;
"break"			return BREAK;
"else"          return ELSE;
"print"         return PRINT;
"in"			return IN; 
"const"			return CONST;
"for"			return FOR;
"do"			return DO;
"switch"		return SWITCH;
"case"			return CASE;
"int"			return INT;
"char"			return CHAR;
"float"			return FLOAT;
"string"		return STRING;
"return"		return RETURN;

\"[a-zA-Z0-9 \t\n-()<>=+*/:.,_\@\#\$\%]+\"	{									 
                yylval.sValue = strdup(yytext);
				return STRING;
            }
			
\'[a-zA-Z]\' {									 
                yylval.cValue = strdup(yytext);
                return CHAR;
            }

[a-zA-Z][a-zA-Z_]*  { 
                yylval.varName = strdup(yytext);
                return VARIABLE;
            }
   
[ \t\n]+        ;       /* ignore whitespace */

.               yyerror("Unknown character");
%%
int yywrap(void) {
    return 1;
}
void yyerror(char *s) {
    printf("\nError: Error in Line: %d\n%s ",yylineno,s);
}
