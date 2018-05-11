#include<string.h>
#include "uthash.h"


struct Node{
    const char* id;            	/* we'll use this field as the key */
	int varType;			   	// int, float, string...etc 
	int varKind;				// var, const, function, parameter
	int hasValue;				
    //char name[10];             
    UT_hash_handle hh; /* makes this structure hashable */
};
struct Node *symbolTable = NULL;

//Prototypes
void yyerror(char *s);
void printSymbolTable();
int getType(char *varName);
struct Node *find_Var(char* varName);
int compare (int leftOpr, int rightOpr);
void assign(char* varName, int valType);
void declare(char* varName, int varType, int valType, int varKind); 


void declare(char* varName, int varType, int valType, int varKind) 
{
	struct Node *s = find_Var(varName);
	if(s == NULL) //if variable not declared before then add it
	{
		if (varType == valType || valType == -1) //if its type and value are equal then add it OR declared with no assignment
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
			HASH_ADD_KEYPTR(hh, symbolTable, s->id, strlen(s->id), s);  //id is the parameter to be the key
			printSymbolTable();
		}
		else
		{
			yyerror("Invalid Type\n");
		}
	}
	else 
	{
		yyerror("Declared Before");
	}
}

void assign(char* varName, int valType)
{
	struct Node *s = find_Var(varName);
	if(s != NULL) //the variable was already declared before
	{
		int varType = s->varType;
		printf("The type of the variable is %d\n",varType);
		if(varType != valType)
		{
			yyerror("Not equal val and type values\n");
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
		yyerror("incompatible types");
		return -1;
	}
}
int getType(char *varName)
{
	struct Node *s = find_Var(varName);
	if(s != NULL)
	{
		if(s->hasValue == 1)
		{
			return s->varType;
		}
		else
		{
			return -1;
		}
	}
	else
	{
		return -1;
	}
}

void printSymbolTable()
{
	printf("\nVariable\tType\tKind\t\tHas_Value\n");
	printf("=================================================\n");
	struct Node *s;
    for(s=symbolTable; s != NULL; s=s->hh.next) 
	{
        printf("%s\t\t", s->id);
		switch (s->varType) 
		{
			case 0:
				printf("INT\t");
				break;
			case 1:
				printf("FLOAT\t");
				break;
			case 2:
				printf("CHAR\t");
				break;	
			case 3:
				printf("STRING\t");
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
				printf("No\n");
				break;
			case 1:
				printf("Yes\n");
				break;
			case -1:
				printf("%d\n",s->hasValue);
				break;
		}
    }
}