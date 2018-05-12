#include <stdio.h>
#include "proj.h"
#include "proj.tab.h"

static int lbl;

int ex(nodeType *p) {
	
    int lbl1, lbl2;

    if (!p) 
	{
		printf("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n");
		return 0;
	}
	//printf("In ex\n");
    switch(p->type) {
    case typeCon:  
		//printf("Code for con\n");
		if(p->con.isChar)
			printf("\tpush\t%s\n", p->con.char_value); 
		else
			printf("\tpush\t%d\n", p->con.value); 
        break;
    case typeId:  
		//printf("Code for id\n");
        printf("\tpush\t%s\n", p->id.name); 
        break;
    case typeOpr:
		//printf("Code for oper\n");
        switch(p->opr.oper) {
        case WHILE:
            printf("L%03d:\n", lbl1 = lbl++);
            ex(p->opr.op[0]);
            printf("\tjz\tL%03d\n", lbl2 = lbl++);
            ex(p->opr.op[1]);
            printf("\tjmp\tL%03d\n", lbl1);
            printf("L%03d:\n", lbl2);
            break;
		//print variable value should be in symbol table 
        case IF:
            ex(p->opr.op[0]);
            if (p->opr.nops > 2) {
                /* if else */
                printf("\tjz\tL%03d\n", lbl1 = lbl++);
                ex(p->opr.op[1]);
                printf("\tjmp\tL%03d\n", lbl2 = lbl++);
                printf("L%03d:\n", lbl1);
                ex(p->opr.op[2]);
                printf("L%03d:\n", lbl2);
            } else {
                /* if */
                printf("\tjz\tL%03d\n", lbl1 = lbl++);
                ex(p->opr.op[1]);
                printf("L%03d:\n", lbl1);
            }
            break;
		case ELSE:
			ex(p->opr.op[0]);
			break;
        case PRINT:     
            ex(p->opr.op[0]);
            printf("\tprint\n");
            break;
        case '=':       
            ex(p->opr.op[1]);
            printf("\tpop\t%s\n", p->opr.op[0]->id.name);
            break;
        case UMINUS:    
            ex(p->opr.op[0]);
            printf("\tneg\n");
            break;
        default:
            ex(p->opr.op[0]);
            ex(p->opr.op[1]);
            switch(p->opr.oper) {
            case '+':   printf("\tadd\n"); break;
            case '-':   printf("\tsub\n"); break; 
            case '*':   printf("\tmul\n"); break;
            case '/':   printf("\tdiv\n"); break;
            case '<':   printf("\tcompLT\n"); break;
            case '>':   printf("\tcompGT\n"); break;
            case GE:    printf("\tcompGE\n"); break;
            case LE:    printf("\tcompLE\n"); break;
            case NE:    printf("\tcompNE\n"); break;
            case EQ:    printf("\tcompEQ\n"); break;
            }
        }
    }
    return 0;
}
