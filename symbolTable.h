#include<string.h>
#include "uthash.h"


struct Node{
    const char* id;            	/* we'll use this field as the key */
	int varType;			   	// int, float, string...etc 
	int varKind;				// var, const, function, parameter
	int hasValue;
	int scope;					// scope of the varibale
    //char name[10];             
    UT_hash_handle hh; /* makes this structure hashable */
};
struct Node *symbolTable = NULL;
int parent_Scope_Arr[100] = { 0 }; //First element has parent scope equal 1
//Prototypes
void yyerror(char *s);
void printSymbolTable();
int getType(char *varName);
int getScope(char* varName);
void closeScope(int *pScope);
int getTypeBoolExpr(char* varName);	//returns the type of a variable inside a bool expression only if it has a value
struct Node *find_Var(char* varName);
int compare (int leftOpr, int rightOpr);
void openScope(int scopeCount, int *pScope);
void checkReturnType(int funcType, int returnType);
int compareScopes(int currVarScope, int oprVarScope);
void assign(char* varName, int valType, int operandsScope);
void boolExprValidation (int leftOprType, int rightOprType);
void declare(char* varName, int varType, int valType, int varKind, int scope, int operandsScope); 


void declare(char* varName, int varType, int valType, int varKind, int scope, int operandsScope) //should not compare scope and operandsScope in case of function/constants/parameters
{
	struct Node *s = find_Var(varName);
	if(s == NULL) //if variable not declared before then add it
	{
		if (varType == valType || valType == -1) //if its type and value are equal then add it OR declared with no assignment
		{
			if( (varKind == 0 && compareScopes(scope,operandsScope) != -1) || varKind != 0) //scopes are matching OR anything but variable, then add directly to the symbol table
			{
				printf("varName %s, varType %d, varKind %d\n",varName,varType,varKind);
				s = malloc(sizeof(struct Node));
				s->id = varName;
				s->varType = varType;
				s->varKind = varKind;
				if(valType == -1)
					s->hasValue = 0;
				else
					s->hasValue = 1;
				s-> scope = scope;
				HASH_ADD_KEYPTR(hh, symbolTable, s->id, strlen(s->id), s);  //id is the parameter to be the key
				printSymbolTable();
			}
			else
			{
				yyerror("Invalid Scope");
			}
		}
		else
		{
			yyerror("Invalid Type");
		}
	}
	else 
	{
		yyerror("Multiple Declaration");
	}
}

void assign(char* varName, int valType, int operandsScope)
{
	struct Node *s = find_Var(varName);
	if(s != NULL) //the variable was already declared before
	{
		int varType = s->varType;
		int scope = s->scope;
		printf("The type of the variable is %d\n",varType);
		if(varType != valType || compareScopes(scope,operandsScope)==-1)
		{
			yyerror("Not equal val and type values OR Invalid Scope\n");
			return;
		}
		s->hasValue = 1;
		printSymbolTable();
	}
	else //The variable was not declared before
	{
		yyerror("Variable Not declared before");
	}
}
struct Node *find_Var(char* varName) 
{
    struct Node *s;
    HASH_FIND_STR(symbolTable , varName, s );  /* s: output pointer */
    return s;
}

int compare (int leftOpr, int rightOpr)
{
	if(leftOpr == rightOpr)
		return leftOpr;
	else
	{
		printf ("Incompatible types: leftOpr %d\t\trightOpr %d\t\t\n",leftOpr,rightOpr);
		yyerror("incompatible types");
		return -1;
	}
}

int getType(char *varName)
{
	struct Node *s = find_Var(varName);
	if(s != NULL)
	{
		return s->varType;
	}
	else
	{
		printf("Get Type: Could not find %s\n",varName);
		return -1;
	}
}

int getTypeBoolExpr(char* varName)
{
	struct Node *s = find_Var(varName);
	if(s != NULL)
	{
		if(s -> hasValue == 1)
			return s->varType;
		else
			return -1;
	}
	else
	{
		printf("Get Type Bool Expr: Could not find %s\n",varName);
		return -1;
	}
}

void boolExprValidation (int leftOprType, int rightOprType)
{
	if(leftOprType == -1 || rightOprType == -1)
	{
		yyerror("Bool Expression: An Operand is not Declared");
		return;
	}
	if(leftOprType != rightOprType)
	{
		printf("Bool Expression: Invalid Operands Types left: %d\tright:%d\n",leftOprType,rightOprType);
		yyerror("Bool Expression: Invalid Operands Types left: %d\t\t right:%d");
	}
}

void checkReturnType(int funcType, int returnType)
{
	if(funcType != returnType)
		yyerror("Function Return Type Mismatch");
}

int getScope(char* varName)
{
	struct Node *s = find_Var(varName);
	if (s != NULL)
	{
		return s-> scope;
	}
	else
	{
		yyerror("Variable not declared before");
		return -1;
	}
}

int compareScopes(int currVarScope, int oprVarScope)
{
	if(currVarScope == oprVarScope)
		return currVarScope;
	else 
	{
		int i;
		if(currVarScope > oprVarScope)
		{
			i = currVarScope;
			while (i != 0 && i != oprVarScope)
			{
				i = parent_Scope_Arr[i];
			}
			if(i == oprVarScope)
				return currVarScope;
			else
				return -1;
		}
		else
		{
			i = oprVarScope;
			while (i != 0 && i != currVarScope)
			{
				i = parent_Scope_Arr[i];
			}
			if(i == currVarScope) 
				return oprVarScope; //return the largest value
			else
				return -1;
		}
	}
}

void openScope(int scopeCount, int *pScope)
{
	parent_Scope_Arr[scopeCount] = *pScope;
	printf("Open Scope: scopeCount %d, pScope before %d",scopeCount,*pScope);
	*pScope = scopeCount;
	printf(", pScope after %d\n",*pScope);
}

void closeScope(int *pScope)
{
	printf("Close Scope: pScope before %d,",*pScope);
	*pScope = parent_Scope_Arr[*pScope];
	printf(" pScope after %d\n",*pScope);
}
	
void printSymbolTable()
{
	printf("\nVariable\tType\t\tKind\t\tHas_Value\tScope\n");
	printf("=====================================================================\n");
	struct Node *s;
    for(s=symbolTable; s != NULL; s=s->hh.next) 
	{
        printf("%s\t\t", s->id);
		switch (s->varType) 
		{
			case 0:
				printf("INT\t\t");
				break;
			case 1:
				printf("FLOAT\t\t");
				break;
			case 2:
				printf("CHAR\t\t");
				break;	
			case 3:
				printf("STRING\t\t");
				break;	
		}
		
		switch (s->varKind)
		{
			case 0:
				printf("Variable\t");
				break;
			case 1:
				printf("Constant\t");
				break;
			case 2:
				printf("Function\t");
				break;
			case 3:
				printf("Parameter\t");
				break;
		}
		
		switch (s->hasValue)
		{
			case 0:
				printf("No\t\t");
				break;
			case 1:
				printf("Yes\t\t");
				break;
			case -1:
				printf("%d\t\t",s->hasValue);
				break;
		}
		printf("%d\n",s->scope);
    }
	int i;
	/*for (i = 0; i < 7; i++)
	{
		printf("index %d\t\tparent %d\n",i,parent_Scope_Arr[i]);
	}*/
}