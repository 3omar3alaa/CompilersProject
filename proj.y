%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "proj.h"
#include "symbolTable.h"

/* prototypes */

int yylex(void);
int varType;
void yyerror(char *s);
int sym[26];                    /* symbol table */
%}

%union {

		int iValue;                 /* integer value */
		float fValue;				/* float value */
		char* varName;	            /* variable name */
		char* cValue;				/* char value */
		char* sValue;				/* string value */
		nodeType *nPtr;             /* node pointer */
}

%token <iValue> INTEGER
%token <varName> VARIABLE
%token <fValue> FLOAT
%token <cValue> CHAR
%token <sValue> STRING
%token WHILE IF PRINT FOR DO IN SWITCH CASE INT  BREAK RETURN
%nonassoc IFX
%nonassoc ELSE
%nonassoc CONST


%left GE LE EQ NE '>' '<' AND OR XOR
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr bool_expr b_expr types switch_case itr_stmt if_stmt func

%%

program:
        function                { exit(0); }
        ;

function:
          function func         { printf("Function: \n"); }
        | /* NULL means epsilon */
        ;

func:
	      types VARIABLE '(' params ')' '{' func_body RETURN expr ';' '}'					{ printf("Func\n"); }
		  
params:
		  types VARIABLE ',' params															{ printf("Params\n"); }
		| types VARIABLE																	{ printf("Params\n"); }
		|																					{ printf("Params: empty\n"); }
		;
		
func_call_params:
		  VARIABLE ',' func_call_params														{ printf("Func_Call_Params: Variable\n"); }
		| VARIABLE																			{ printf("Func_Call_Params: Variable only\n"); }
		| values ',' func_call_params														{ printf("Func_Call_Params: Values\n"); }
		| values																		   	{ printf("Func_Call_Params: Values only\n"); }
		|																					{ printf("Func_Call_Params: empty\n"); }
		; 
		
func_body:
		  stmt func_body																	{ printf("Func_Body\n"); }
		|																					{ printf("Func_Body: empty\n"); }
		;		  
stmt:	
          ';'                            													{ printf("Stmt: \n"); }
        | expr ';'                       													{ printf("Stmt: print expr\n");}
        | PRINT expr ';'                 													{ printf("Stmt: expr\n"); }
        | VARIABLE '=' expr ';'          													{ printf("Stmt: var %s = expr \n",$1); }
		| types VARIABLE ';'																{ printf("Stmt: Variable Declaration\n"); }
		| types VARIABLE '=' expr ';'          												{ printf("Stmt: var %s = expr\n", $2); declare($2,varType);}
		| CONST types VARIABLE '=' values ';' 												{ printf("Stmt: CONST VARIABLE\n");}
		| VARIABLE '(' func_call_params ')' 												{ printf("Expr: Function Call Params\n"); }
		| types VARIABLE '=' VARIABLE '(' func_call_params ')' 								{ printf("Expr: Function Call Params\n"); }
		| VARIABLE '=' VARIABLE '(' func_call_params ')' 									{ printf("Expr: Function Call Params\n"); }
        | WHILE '(' bool_expr ')' '{' stmt itr_stmt '}'										{ printf("Stmt: while\n"); }
		| DO '{' stmt itr_stmt '}' WHILE '(' bool_expr ')'									{ printf("Stmt: Do While\n"); }
        | IF '(' bool_expr ')' '{' stmt itr_stmt '}' if_stmt								{ printf("Stmt: IF \n"); }
		| FOR VARIABLE IN '(' INTEGER ',' INTEGER ')' '{' stmt itr_stmt '}'					{ printf("Stmt: For Loop\n"); }
		| SWITCH '(' VARIABLE ')' '{' CASE INTEGER ':' stmt BREAK ';' switch_case '}'		{ printf("Stmt: Switch Case\n"); }
        ;


		
if_stmt:
		ELSE '{' stmt itr_stmt '}'															{ printf("If_Stmt: Else clause\n"); }
		| /* NULL */																		{ printf("If_Stmt: empty\n"); }
		;
		
itr_stmt:
		stmt itr_stmt																		{ printf ("Itr_Stmt: iterative\n"); }
		| /* NULL */																		{ printf ("Itr_Stmt: empty\n"); }
		;
	
switch_case:
		CASE INTEGER ':' stmt BREAK ';' switch_case											{ printf("Switch_Case: iterative\n"); }
		| /* NULL */																		{ printf("Switch Case: empty\n"); }		
		;

values:
		  INTEGER																			{ printf("Values: INTEGER %d\n",$1); }
		| FLOAT																				{ printf("Values: FLOAT %f\n",$1); 	}
		| CHAR																				{ printf("Values: CHAR %s\n",$1); 	}
		| STRING																			{ printf("Values: STRING %s\n",$1); 	}
		;
types:
		  INT																				{ printf("Types: INT %s\n"); varType = 0;}
		| FLOAT																				{ printf("Types: FLOAT\n"); varType = 1;}
		| CHAR																				{ printf("Types: CHAR\n"); varType = 2;}
		| STRING																			{ printf("Types: STRING\n"); varType = 3;}
		;

expr:
          values																			{ printf("Expr: Values\n"); }
        | VARIABLE              															{ printf("Expr: var %s\n", $1); }
        | expr '+' expr         
        | expr '-' expr         
        | expr '*' expr         
        | expr '/' expr         
        | expr '<' expr         
        | expr '>' expr         
        | expr GE expr          
        | expr LE expr          
        | expr NE expr          
        | expr EQ expr          
        ;

bool_expr:
	      b_expr '<' b_expr    																{ printf("Bool_Expr: less than\n"); }
        | b_expr '>' b_expr																	{ printf("Bool_Expr: greater than\n");}
        | b_expr GE b_expr      															{ printf("Bool_Expr: greater than or equal\n");}
        | b_expr LE b_expr      															{ printf("Bool_Expr: less than or equal\n");}
        | b_expr NE b_expr      															{ printf("Bool_Expr: not equal\n");}
        | b_expr EQ b_expr      															{ printf("Bool_Expr: equal\n");}
        | bool_expr AND bool_expr  															{ printf("Bool_Expr: And\n");}
        | bool_expr OR bool_expr   															{ printf("Bool_Expr: Or\n");}
        | b_expr XOR b_expr    																{ printf("Bool_Expr: Xor\n");}	
		| b_expr					
		;
		
b_expr:
		  b_expr '+' b_expr         
        | b_expr '-' b_expr         
        | b_expr '*' b_expr         
        | b_expr '/' b_expr
		| values               																{ printf("B_Expr: Values\n"); }
        | VARIABLE              															{ printf("B_Expr: Var\n"); }
		;
%%

void yyerror(char *s) {
    fprintf(stdout, "%s \n", s);
}


int main(void) {
    yyparse();
    return 0;
}
