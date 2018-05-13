%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "proj.h"
#include "symbolTable.h"

/* prototypes */

int yylex(void);
int varType;
int valType;
int varKind;
int funcType; 			/* Function Type */
int oprVarType; 		/* get type of variable when it is an operand */
int currValType; 		/* to save the value of left operand in mathematical expression */
int oprVarScope;		/* get the scope of a variable in arithmatic operation */
int pScope = 0;			/* Parent Scope */
int currVarScope = 0; 	/* hold the scope of the left operand */
int scopeCount = -1;	
int func_scope;
int varBoolType;		/* Name of a variable in bool_expr */
int currBoolType;
void yyerror(char *s);
Stack* oprTypeStack;
Stack* oprScopeStack;
enum { VAR, CONSTANT, FUNCTION , PARAMETER } kind;

nodeType *opr(int oper, int nops, ...);
nodeType *id(char* var_name);
nodeType *con(int value);
nodeType *conChar(char* value);
void freeNode(nodeType *p);
int ex(nodeType *p);
%}

%union {

		int iValue;                 /* integer value */
		float fValue;				/* float value */
		char * varName;	            /* variable name */
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

%type <nPtr> stmt expr bool_expr types switch_case itr_stmt if_stmt func values

%%

program:
        function                { exit(0); }
        ;

function:
          function func         { printf("Function: \n"); }
        | /* NULL means epsilon */
        ;

func:
	      types { funcType = varType; } VARIABLE openScope {oprTypeStack = newStack(100); oprScopeStack = newStack(100); } params ')' '{' { func_scope = scopeCount; } func_body RETURN expr ';' closeScope		{ printf("Func\n"); varKind = FUNCTION; declare($3,funcType,-1,varKind,func_scope, currVarScope); checkReturnType(funcType, oprVarType); }

openScope:
		 '{' 																						{ scopeCount++; printf("Scope Opened %d\n",scopeCount); openScope(scopeCount, &pScope);}
		|'(' 																						{ scopeCount++; printf("Scope Opened %d\n",scopeCount); openScope(scopeCount, &pScope);}
		;
closeScope:
		 '}'																						{ printf("Scope Closed %d\n",scopeCount); closeScope(&pScope);}
		; 
params:
		  types VARIABLE ',' params																	{ printf("Params\n"); varKind = PARAMETER; declare($2,varType,-1, varKind, pScope, currVarScope); }
		| types VARIABLE																			{ printf("Params\n"); varKind = PARAMETER; declare($2,varType,-1, varKind, pScope, currVarScope); }
		|																							{ printf("Params: empty\n"); }
		;
		
func_call_params:
		  VARIABLE ',' func_call_params																{ printf("Func_Call_Params: Variable\n"); }
		| VARIABLE																					{ printf("Func_Call_Params: Variable only\n"); }
		| values ',' func_call_params																{ printf("Func_Call_Params: Values\n"); }
		| values																		   			{ printf("Func_Call_Params: Values only\n"); }
		|																							{ printf("Func_Call_Params: empty\n"); }
		; 
		
func_body:
		  stmt func_body																			{ printf("Func_Body\n"); ex($1); freeNode ($1);}
		|																							{ printf("Func_Body: empty\n"); }
		;		  
stmt:	
          ';'                            															{ printf("Stmt: \n"); $$ = opr(';', 2, NULL, NULL);}
        | expr ';'                       															{ printf("Stmt: print expr\n"); $$ = $1; printf("In expr\n");}
        | PRINT expr ';'                 															{ printf("Stmt: expr\n"); $$ = opr(PRINT, 1, $2);}
        | VARIABLE '=' expr ';'          															{ printf("Stmt: Variable Assignment: var %s = expr \n",$1); varKind = VAR; assign($1, oprVarType, oprVarScope);$$ = opr('=', 2, id($1), $3);}
		| types VARIABLE ';'																		{ printf("Stmt: Variable Declaration \n"); varKind = VAR; declare($2,varType,-1, varKind, pScope, oprVarScope);}
		| types VARIABLE '=' expr ';'          														{ printf("Stmt: var %s = expr\n", $2); varKind = VAR; declare($2,varType,oprVarType,varKind, pScope, oprVarScope); $$ = opr('=', 2, id($2), $4);}
		| CONST types VARIABLE '=' values ';' 														{ printf("Stmt: CONST VARIABLE\n"); varKind = CONSTANT; declare($3,varType,oprVarType,varKind, pScope, oprVarScope);}
		| VARIABLE '(' func_call_params ')' 														{ printf("Expr: Function Call Params\n"); }
		| types VARIABLE '=' VARIABLE '(' func_call_params ')' 										{ printf("Expr: Function Call Params\n"); }
		| VARIABLE '=' VARIABLE '(' func_call_params ')' 											{ printf("Expr: Function Call Params\n"); }
        | WHILE '(' bool_expr ')' openScope stmt itr_stmt closeScope								{ printf("Stmt: while\n"); $$ = opr(WHILE, 2, $3, $6);}
		| DO openScope stmt itr_stmt '}' WHILE '(' bool_expr ')'									{ printf("Stmt: Do While\n"); }
        | IF '(' bool_expr ')' openScope stmt itr_stmt closeScope if_stmt							{ printf("Stmt: IF \n"); $$ = opr(IF, 2, $3, $6);}
		| FOR VARIABLE IN '(' INTEGER ',' INTEGER ')' openScope stmt itr_stmt closeScope			{ printf("Stmt: For Loop\n"); assign($2, 0, oprVarScope); }
		| SWITCH '(' VARIABLE ')' openScope CASE INTEGER ':' stmt BREAK ';' switch_case closeScope	{ printf("Stmt: Switch Case\n"); }
        ;


		
if_stmt:
		ELSE openScope stmt itr_stmt closeScope														{ printf("If_Stmt: Else clause\n"); }
		| /* NULL */																				{ printf("If_Stmt: empty\n"); }
		;
		
itr_stmt:
		stmt itr_stmt																				{ printf ("Itr_Stmt: iterative\n"); }
		| /* NULL */																				{ printf ("Itr_Stmt: empty\n"); }
		;
	
switch_case:
		CASE INTEGER ':' stmt BREAK ';' switch_case													{ printf("Switch_Case: iterative\n"); }
		| /* NULL */																				{ printf("Switch Case: empty\n"); }		
		;

values:
		  INTEGER																					{ printf("Values: INTEGER %d\n",$1); 	valType = 0; $$ = con($1);}
		| FLOAT																						{ printf("Values: FLOAT %f\n",$1); 		valType = 1; $$ = con($1);}
		| CHAR																						{ printf("Values: CHAR %s\n",$1); 		valType = 2; $$ = conChar($1);}
		| STRING																					{ printf("Values: STRING %s\n",$1); 	valType = 3; $$ = conChar($1);}
		;
types:
		  INT																						{ printf("Types: INT \n"); 		varType = 0;}
		| FLOAT																						{ printf("Types: FLOAT\n"); 	varType = 1;}
		| CHAR																						{ printf("Types: CHAR\n"); 		varType = 2;}
		| STRING																					{ printf("Types: STRING\n"); 	varType = 3;}
		;

expr:
          values																					{ printf("Expr: Values\n"); oprVarType = valType; oprVarScope = pScope;}
        | VARIABLE              																	{ $$ = id($1); printf("Expr: var %s\n", $1); oprVarType = getType($1); oprVarScope = getScope($1); printf("operand %s  oprVarType %d\n",$1, oprVarType);}
        | expr  '+' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('+', 2, $1, $4); }         
        | expr  '-' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('-', 2, $1, $4);}         
        | expr  '*' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('*', 2, $1, $4);}         
        | expr  '/' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('/', 2, $1, $4);}        
        | expr  '<' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('<', 2, $1, $4);}         
        | expr  '>' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('>', 2, $1, $4);}         
        | expr  GE  { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(GE, 2, $1, $4);}          
        | expr  LE  { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(LE, 2, $1, $4);}        
        | expr  NE  { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(NE, 2, $1, $4);}          
        | expr  EQ  { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr 		{ oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(EQ, 2, $1, $4);}          
        ;

bool_expr:
	      bool_expr  '<' { currBoolType = varBoolType; } bool_expr    								{ printf("Bool_Expr: less than\n"); 			boolExprValidation(currBoolType,varBoolType); $$ = opr('<', 2, $1, $4);}
        | bool_expr  '>' { currBoolType = varBoolType; } bool_expr									{ printf("Bool_Expr: greater than\n"); 			boolExprValidation(currBoolType,varBoolType); $$ = opr('>', 2, $1, $4);}
        | bool_expr  GE	 { currBoolType = varBoolType; } bool_expr     								{ printf("Bool_Expr: greater than or equal\n"); boolExprValidation(currBoolType,varBoolType); $$ = opr(GE, 2, $1, $4);}
        | bool_expr  LE  { currBoolType = varBoolType; } bool_expr      							{ printf("Bool_Expr: less than or equal\n"); 	boolExprValidation(currBoolType,varBoolType); $$ = opr(LE, 2, $1, $4);}
        | bool_expr  NE  { currBoolType = varBoolType; } bool_expr     								{ printf("Bool_Expr: not equal\n"); 			boolExprValidation(currBoolType,varBoolType); $$ = opr(NE, 2, $1, $4);}
        | bool_expr  EQ  { currBoolType = varBoolType; } bool_expr     								{ printf("Bool_Expr: equal\n"); 				boolExprValidation(currBoolType,varBoolType); $$ = opr(EQ, 2, $1, $4);}
        | bool_expr  AND { currBoolType = varBoolType; } bool_expr  								{ printf("Bool_Expr: And\n"); 					boolExprValidation(currBoolType,varBoolType); $$ = opr(AND, 2, $1, $4);}
        | bool_expr  OR  { currBoolType = varBoolType; } bool_expr  								{ printf("Bool_Expr: Or\n"); 					boolExprValidation(currBoolType,varBoolType); $$ = opr(OR, 2, $1, $4);}
        | bool_expr  XOR { currBoolType = varBoolType; } bool_expr    								{ printf("Bool_Expr: Xor\n");					boolExprValidation(currBoolType,varBoolType); $$ = opr(XOR, 2, $1, $4);}	
		| values 																					{ printf("Bool_Expr: Values\n"); 				varBoolType = valType; }
		| VARIABLE																					{ $$ = id($1); printf("Bool_Expr: Var\n"); 		varBoolType = getTypeBoolExpr($1); }
		;

%%

nodeType *con(int value) {
    //printf("In con %d\n",value);
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeCon;
    p->con.value = value;
    p->con.isChar=0;
    
    return p;
}

nodeType *conChar(char* value) {
    //printf("In con %s\n",value);
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeCon;
    p->con.char_value = value;
    p->con.isChar=1;
    
    return p;
}

nodeType *id(char* var_name) {
    //printf("In id %s\n",var_name);
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");
        
    /* copy information */
    p->type = typeId;
    p->id.name = var_name;

    return p;
}

nodeType *opr(int oper, int nops, ...) {
    //printf("In opr %d\n",oper);
    va_list ap;
    nodeType *p;
    int i;

    /* allocate node, extending op array */
    if ((p = malloc(sizeof(nodeType) + (nops-1) * sizeof(nodeType *))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for (i = 0; i < nops; i++)
        p->opr.op[i] = va_arg(ap, nodeType*);
    va_end(ap);
    return p;
}

void freeNode(nodeType *p) {
    int i;

    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++)
            freeNode(p->opr.op[i]);
    }
    free (p);
}




void yyerror(char *s) {
    fprintf(stdout, "%s \n", s);
}


int main(void) {
    yyparse();
    return 0;
}