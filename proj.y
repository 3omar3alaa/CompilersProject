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

int valType;
int varKind;
int funcType;           /* Function Type */
int oprVarType;         /* get type of variable when it is an operand */
int currValType;        /* to save the value of left operand in mathematical expression */
int oprVarScope;        /* get the scope of a variable in arithmatic operation */
int pScope = 0;         /* Parent Scope */
int currVarScope = 0;   /* hold the scope of the left operand */
int scopeCount = -1;    
int func_scope;
int varBoolType;        /* Name of a variable in bool_expr */
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
        float fValue;               /* float value */
        char* varName;              /* variable name */
        char* cValue;               /* char value */
        char* sValue;               /* string value */
        nodeType *nPtr;             /* node pointer */
}

%token <iValue> INTEGER
%token <varName> VARIABLE
%token <fValue> FLOAT
%token <cValue> CHAR
%token <sValue> STRING
%token WHILE IF PRINT FOR DO IN SWITCH CASE INT  BREAK RETURN ITER FUNC FUNCBODY INIT CALL
%nonassoc IFX   
%nonassoc ELSE
%nonassoc CONST


%left GE LE EQ NE '>' '<' AND OR XOR
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr bool_expr types switch_case itr_stmt if_stmt func func_body function values

%%

program:
        function                { exit(0); }
        ;

function:
          function func         	{ printf("Function: \n"); ex($2); freeNode ($2); }
        | /* NULL means epsilon */ 	{printf("Function: NULL\n");}
        ;

func:
          types { funcType = varType; } VARIABLE openScope {oprTypeStack = newStack(100); oprScopeStack = newStack(100); } params ')' '{' { func_scope = scopeCount; } func_body RETURN expr ';' closeScope		{ printf("Func\n"); varKind = FUNCTION; declare($3,funcType,-1,varKind,func_scope, currVarScope); checkReturnType(funcType, oprVarType); $$=opr(FUNC, 2, id($3), $10); }
        ;
openScope:
		 '{' 																				{ scopeCount++; printf("Scope Opened %d\n",scopeCount); openScope(scopeCount, &pScope);}
		|'(' 																				{ scopeCount++; printf("Scope Opened %d\n",scopeCount); openScope(scopeCount, &pScope);}
		;
		
closeScope:
         '}'                                                                                { printf("Scope Closed %d\n",scopeCount); closeScope(&pScope);}
        ; 
params:
		  types VARIABLE ',' params															{ printf("Params\n"); varKind = PARAMETER; declare($2,varType,-1, varKind, pScope, currVarScope); }
		| types VARIABLE																	{ printf("Params\n"); varKind = PARAMETER; declare($2,varType,-1, varKind, pScope, currVarScope); }
		|																					{ printf("Params: empty\n"); }
		;
        
func_call_params:
          VARIABLE ',' func_call_params                                                     { printf("Func_Call_Params: Variable\n"); }
        | VARIABLE                                                                          { printf("Func_Call_Params: Variable only\n"); }
        | values ',' func_call_params                                                       { printf("Func_Call_Params: Values\n"); }
        | values                                                                            { printf("Func_Call_Params: Values only\n"); }
        |                                                                                   { printf("Func_Call_Params: empty\n"); }
        |error {printf("Error: Incorrect function call parameters.\n");}
		; 
        
func_body:
        stmt  func_body                                                              	    { $$=opr(FUNCBODY, 2, $1, $2);}
        |                                                                                   { $$=NULL; printf("Func_Body: empty\n"); }
        ;         
stmt:   
          ';'                                                                               { $$ = opr(';', 2, NULL, NULL);}
        | expr ';'                                                                          { $$ = $1; printf("In expr\n");}
        | PRINT expr ';'                                                                    { $$ = opr(PRINT, 1, $2);}
        | PRINT error ';'																	{ printf("Error: You cannot print empty text.\n"); active = 0;}
		| VARIABLE '=' expr ';'                                                             { $$ = opr('=', 2, id($1), $3); varKind = VAR; assign($1, oprVarType, oprVarScope);}
        | types VARIABLE ';'                                                                { $$ = opr(INIT, 1, id($2)); varKind = VAR; declare($2,varType,-1, varKind, pScope, oprVarScope);}
        | error VARIABLE ';' 																{ printf("Error: Incorrect data type. Skipping statement ...\n"); active = 0;}
		| types VARIABLE '=' expr ';'                                                       { $$ = opr(INIT, 2, id($2), $4); varKind = VAR; declare($2,varType,oprVarType,varKind, pScope, oprVarScope);}
        | error VARIABLE '=' expr ';' 														{ printf("Error: Incorrect data type. Skipping statement ...\n"); active = 0;}
		| CONST types VARIABLE '=' values ';'                                               { $$ = opr(INIT, 2, id($3), $5); printf("Stmt: CONST VARIABLE\n"); varKind = CONSTANT; declare($3,varType,oprVarType,varKind, pScope, oprVarScope);}
        | VARIABLE '(' func_call_params ')'                                                 { $$ = opr(CALL, 1, id($1)); printf("Expr: Function Call Params\n"); }
        | types VARIABLE '=' VARIABLE '(' func_call_params ')'                              { $$ = opr(CALL, 1, id($4)); printf("Expr: Function Call Params\n"); }
        | VARIABLE '=' VARIABLE '(' func_call_params ')'                                    { $$ = opr(CALL, 1, id($3)); printf("Expr: Function Call Params\n"); }
        | WHILE '(' bool_expr ')' openScope itr_stmt closeScope                             { $$ = opr(WHILE, 2, $3, $6); }
        | WHILE error openScope itr_stmt closeScope 										{ printf("Error: Incorrect while intialization.\n");}
		| WHILE '(' bool_expr ')' openScope error closeScope 								{ printf("Error: Incorrect while body.\n");}
		| WHILE error openScope error closeScope											{ printf("Error: Incorrect while syntax.\n");}
		| DO openScope itr_stmt '}' WHILE '(' bool_expr ')'                          	    { $$ = opr(DO, 2, $3, $7); }
        | DO openScope error closeScope WHILE '(' bool_expr ')'								{ printf("Error: Incorrect do body.\n");}	
		| IF '(' bool_expr ')' openScope itr_stmt closeScope if_stmt                        { $$ = opr(IF, 3, $3, $6, $8); printf("Stmt: IF \n"); }
        | IF '(' bool_expr ')' openScope error closeScope if_stmt 							{ printf("Error: Incorrect If statement body.\n"); active = 0;}
        | IF error openScope itr_stmt closeScope if_stmt 									{ printf("Error: Please provide a correct if condition.\n");}
		| IF error openScope error closeScope if_stmt										{ printf("Error: Incorrect if syntax.\n");}
		| FOR VARIABLE IN '(' INTEGER ',' INTEGER ')' openScope itr_stmt closeScope         { $$ = opr(FOR, 4, id($2), con($5), con($7), $10); assign($2, 0, oprVarScope);}
        | FOR error openScope itr_stmt closeScope 											{ printf("Error: Incorrect for intialization.\n");}
		| FOR error openScope error closeScope 												{ printf("Error: Incorrect for syntax.\n");}			
		| SWITCH '(' VARIABLE ')' openScope CASE INTEGER ':' stmt BREAK ';' switch_case closeScope  { $$ = opr(SWITCH,4,id($3),con($7),$9,$12); }
        | SWITCH '(' VARIABLE ')' openScope error closeScope  								{ printf("Error: Incorrect switch case body.\n");}
		| SWITCH '(' error ')' openScope CASE INTEGER ':' stmt BREAK ';' switch_case closeScope  {printf("Error: Please provide a variable for the switch.\n");}
		| SWITCH '(' error ')' openScope error closeScope  									{ printf("Error: Wrong switch syntax.\n");}
		| error ';' 																		{ printf("Error: Incorrect statement encountered.\n");}
        ;

if_stmt:
        ELSE openScope itr_stmt closeScope                                                  { $$ = opr(ELSE,1,$3); }
        | /* NULL */                                                                        { $$=NULL; }
        ;
        
itr_stmt:
        stmt itr_stmt                                                                       { $$=opr(ITER, 2, $1, $2); }
        | /* NULL */                                                                        { $$=NULL; }
        ;
    
switch_case:
        CASE INTEGER ':' stmt BREAK ';' switch_case                                         { $$ = opr(CASE,3,con($2),$4,$7); }
        | /* NULL */                                                                        { $$=NULL;}     
        | error ';' {printf("Error: Incorrect switch case syntax. Did you forget a case?\n"); active = 0;}
        ;

values:
          INTEGER                                                                           { $$ = con($1); 	valType = 0; oprVarType = valType;}
        | FLOAT                                                                             { $$ = con($1); 	valType = 1; oprVarType = valType;}
        | CHAR                                                                              { $$ = conChar($1); valType = 2; oprVarType = valType;}
        | STRING                                                                            { $$ = conChar($1); valType = 3; oprVarType = valType;}
        ;
        
types:
          INT                                                                               { varType = 0;}
        | FLOAT                                                                             { varType = 1;}
        | CHAR                                                                              { varType = 2;}
        | STRING                                                                            { varType = 3;}
        ;
        
expr:
          values                                                                            			{ oprVarType = valType; oprVarScope = pScope;}
        | VARIABLE                                                                          			{ $$ = id($1); oprVarType = getType($1); oprVarScope = getScope($1);}
        | expr '+' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('+', 2, $1, $4); }
        | expr '-' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('-', 2, $1, $4); }
        | expr '*' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('*', 2, $1, $4); }
        | expr '/' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('/', 2, $1, $4); }
        | expr '<' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('<', 2, $1, $4); }
        | expr '>' { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr('>', 2, $1, $4); }
        | expr  GE { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(GE, 2, $1, $4); }
        | expr  LE { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(LE, 2, $1, $4); }
        | expr  NE { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(NE, 2, $1, $4); }
        | expr  EQ { push(&oprVarType,oprTypeStack); push(&oprVarScope,oprScopeStack);} expr            { oprVarType = compare(*(int*)pop(oprTypeStack), oprVarType); oprVarScope = compareScopes(*(int*)pop(oprScopeStack),oprVarScope); $$ = opr(EQ, 2, $1, $4); }
        ;   
    
bool_expr:  
          bool_expr '<' { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType); $$ = opr('<', 2, $1, $4); }
        | bool_expr '>' { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType); $$ = opr('>', 2, $1, $4); }
        | bool_expr GE  { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType);  $$ = opr(GE, 2, $1, $4); }
        | bool_expr LE  { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType);  $$ = opr(LE, 2, $1, $4); }
        | bool_expr NE  { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType);  $$ = opr(NE, 2, $1, $4); }
        | bool_expr EQ  { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType);  $$ = opr(EQ, 2, $1, $4); }
        | bool_expr AND { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType); $$ = opr(AND, 2, $1, $4); }
        | bool_expr OR  { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType);  $$ = opr(OR, 2, $1, $4); }
        | bool_expr XOR { currBoolType = varBoolType; } bool_expr                           { boolExprValidation(currBoolType,varBoolType); $$ = opr(XOR, 2, $1, $4); } 
        | values                                                                            { varBoolType = valType; }
        | VARIABLE                                                                          { $$ = id($1); varBoolType = getTypeBoolExpr($1);}
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



int main(void) {
    yyparse();
    return 0;
}
