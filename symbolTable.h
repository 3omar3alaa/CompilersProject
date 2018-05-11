#include<string.h>
#include "uthash.h"

struct Node{
    char* id;            /* we'll use this field as the key */
	int type;
    //char name[10];             
    UT_hash_handle hh; /* makes this structure hashable */
};
struct Node *symbolTable = NULL;


void printSymbolTable();
void declare(char* varName, int type) 
{
	struct Node *s;
	printf("varName %s, type %d\n",varName,type);
	s = malloc(sizeof(struct Node));
	s->id = varName;
	s->type = type;
		
    HASH_ADD_INT(symbolTable, id, s);  //id is the parameter to be the key

	printSymbolTable();	
}

void printSymbolTable()
{
	struct Node *s;
    for(s=symbolTable; s != NULL; s=s->hh.next) {
        printf("user id %s: name %d\n", s->id, s->type);
    }
}