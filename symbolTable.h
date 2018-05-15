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

typedef struct Stack Stack;
struct Stack{
  int counter;
  int max;
  void** container;
};

struct Node *symbolTable = NULL;
int parent_Scope_Arr[100] = { 0 }; //First element has parent scope equal 0


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
int checkParentScope(int currVarScope, int pScope);
void checkReturnType(int funcType, int returnType);
int compareScopes(int currVarScope, int oprVarScope);
void boolExprValidation (int leftOprType, int rightOprType);
void assign(char* varName, int valType, int operandsScope, int pScope);
void declare(char* varName, int varType, int valType, int varKind, int scope, int operandsScope); 
void addVariable (char* varName, int varType, int valType, int varKind, int scope, int operandsScope);


//Stack Functions 
Stack* newStack(int size);
void push(void* item, Stack* stack);
void* pop(Stack* stack);


void addVariable (char* varName, int varType, int valType, int varKind, int scope, int operandsScope)
{
	if (varType == valType || valType == -1) //if its type and value are equal then add it OR declared with no assignment
	{
		if( (varKind == 0 && checkParentScope(operandsScope,scope) != -1) || varKind != 0) //scopes are matching OR anything but variable, then add directly to the symbol table
		{
			struct Node *s;
			//printf("Info: varName %s, varType %d, varKind %d\n",varName,varType,varKind);
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
			printf("\nError: %s is Declared in Invalid Scope\n",varName);
		}
	}
	else
	{
		printf("\nError: Type Mismatch in Declaring Variable %s\n",varName);
	}
}

void declare(char* varName, int varType, int valType, int varKind, int scope, int operandsScope) //should not compare scope and operandsScope in case of function/constants/parameters
{
	struct Node *s = find_Var(varName);
	if(s == NULL) //if variable not declared before then add it
	{
		addVariable(varName,varType,valType,varKind,scope,operandsScope);
	}
	else 
	{
		if( s->scope != scope || s->varType != varType ) //if same variable already declared but in different scope then add it OR has diferent type
		{
			addVariable(varName,varType,valType,varKind,scope,operandsScope);
		}
		else //if the variable is already declared in the same scope then print error
		{
			printf("\nError: Multiple Declaration Of Variable %s\n",varName);
		}
	}
}

void assign(char* varName, int valType, int operandsScope, int pScope)
{
	//Must check that s->Scope is a parent of pScope before assigning 
	struct Node *s = find_Var(varName);
	if(s != NULL) //the variable was already declared before
	{
		int varType = s->varType;
		int scope = s->scope;
		if(checkParentScope(scope,pScope)!= -1 && (s-> varKind == 0 || s-> varKind == 3))
		{
			//printf("Info: Assign: varName %s Type %d, Scope %d, operandsScope %d, compareScopes %d\n",varName,varType,scope,operandsScope,compareScopes(scope,operandsScope));
			if(varType != valType || compareScopes(scope,operandsScope)==-1)
			{
				//printf("varName %s, scope %d, operandsScope %d\n",varName,scope,operandsScope);
				s->hasValue = 0;
				printf("\nError: Not equal val and type values OR Invalid Scope\n");
				return;
			}
			s->hasValue = 1;
			printSymbolTable();
		}
		else
		{
			if(s-> varKind != 0 && s-> varKind != 3)
			{
				printf("\nError: Invalid Assignment for %s\n", varName);
				return;
			}
			else if (varType != valType)
			{
				printf("\nError: Type Mismatch in Assigning Variable %s\n",varName);
			}
			printf("\nError: Variable Assigned %s in Invalid Scope\n",varName);
		}
	}
	else //The variable was not declared before
	{
		printf("\nError: Variable Not declared before\n");
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
		printf ("Error: Incompatible types: leftOpr %d\t\trightOpr %d\t\t\n",leftOpr,rightOpr);
		printf("\nError: incompatible types");
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
		printf("\nError: Get Type: Could not find %s\n",varName);
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
		printf("\nError: Get Type Bool Expr: Could not find %s\n",varName);
		return -1;
	}
}

void boolExprValidation (int leftOprType, int rightOprType)
{
	if(leftOprType == -1 || rightOprType == -1)
	{
		yyerror("Error: Bool Expression: An Operand is not Declared\n");
		return;
	}
	if(leftOprType != rightOprType)
	{
		printf("\nError: Bool Expression: Invalid Operands Types left: %d\tright:%d\n",leftOprType,rightOprType);
		//printf("\nError: Bool Expression: Invalid Operands Types left: %d\t\t right:%d\n");
	}
}

void checkReturnType(int funcType, int returnType)
{
	if(funcType != returnType)
		printf("\nError: Function Return Type Mismatch\n");
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
		printf("\nError: Variable not declared before\n");
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

int checkParentScope(int currVarScope, int pScope)
{
	if(currVarScope == pScope)
		return currVarScope;
	else if (currVarScope > pScope) //assign is outside the variables scope
		return -1;
	else //if pScope > currVarScope => check that currVarScope is a parent to  pScope
	{
		int i = pScope;
		while (i != 0 && i != currVarScope)
		{
			i = parent_Scope_Arr[i];
		}
		if(i == currVarScope)
			return pScope;
		else
			return -1;
	}
}

void openScope(int scopeCount, int *pScope)
{
	parent_Scope_Arr[scopeCount] = *pScope;
	//printf("Info: Open Scope: scopeCount %d, pScope before %d",scopeCount,*pScope);
	*pScope = scopeCount;
	//printf(", pScope after %d\n",*pScope);
}

void closeScope(int *pScope)
{
	//printf("Info: Close Scope: pScope before %d,",*pScope);
	*pScope = parent_Scope_Arr[*pScope];
	//printf(" pScope after %d\n",*pScope);
}
	
void printSymbolTable()
{
	printf("\nVariable\tType\t\tKind\t\tHas_Value\tScope\n");
	printf("=====================================================================\n");
	//printf("begin symboltable\n");
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
	//printf("end symboltable\n");
	//int i;
	/*for (i = 0; i < 7; i++)
	{
		printf("index %d\t\tparent %d\n",i,parent_Scope_Arr[i]);
	}*/
}
  

Stack* newStack(int size){
  /* NYI: better error checks */
  if (size < 5){
    size = 5;
  }
 
  Stack* stack = malloc(sizeof(Stack));
  stack->container = malloc(sizeof(void**) * size);
 
  stack->counter = 0;
  stack->max = size;
  //printf("Success: Stack created successfully\n");
  return stack;
}
 
void push(void* item, Stack* stack)
{
  //printf("Info: In Push\n");		
  stack->container[stack->counter] = item;
  stack->counter++;
  //printf("Info: Stack: Pushed Value %d\n",*(int*)item);
}
 
void* pop(Stack* stack)
{
  if (stack->counter > 0)
  {
	//printf("Info: In Pop\n");
    stack->counter--;
	//printf("Info: Stack: Popped Value %d\n",*(int*)(stack->container[stack->counter]));
    return stack->container[stack->counter];
  }
  
  return NULL;
}