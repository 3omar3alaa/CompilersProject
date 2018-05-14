#include <stdbool.h>
static int active = 1;
typedef enum { typeCon, typeId, typeOpr } nodeEnum;
  
/* constants */
typedef struct {
	bool isChar;
    int value;                  /* value of constant */
	char* char_value;                  /* value of constant in char */
} conNodeType;

/* identifiers */
typedef struct {
    //int i;                      /* subscript to sym array */
	char* name; 					/* string name*/
} idNodeType;

/* operators */
typedef struct {
    int oper;                   /* operator */
    int nops;                   /* number of operands */
    struct nodeTypeTag *op[4];	/* operands, extended at runtime */
} oprNodeType;

typedef struct nodeTypeTag {
    nodeEnum type;              /* type of node */

    union {
        conNodeType con;        /* constants */
        idNodeType id;          /* identifiers */
        oprNodeType opr;        /* operators */
    };
} nodeType;

extern int sym[26];
