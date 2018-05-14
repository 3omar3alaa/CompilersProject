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
		case INIT:
			printf("\t%s\tDB\n",p->opr.op[0]->id.name);
			if (p->opr.nops > 1) 
			{
				ex(p->opr.op[1]);
				printf("\tpop\t%s\n", p->opr.op[0]->id.name);
			}
			break;
		case FUNC:
			printf("Proc\t%s\n",p->opr.op[0]->id.name);
			ex(p->opr.op[1]);
			printf("Ret\n");
			break;
		case FUNCBODY:
			ex(p->opr.op[0]);
			p=p->opr.op[1];
			while(p)
			{
				ex(p->opr.op[0]);
				p=p->opr.op[1];
			}
			break;
		case SWITCH:
		//variable to switch on
		ex(p->opr.op[0]);
		//First Case value check
		ex(p->opr.op[1]);
		//Jmp Not Equal ..
		printf("\tcompNE\n");
		//printf("\tpop\t%s\n", p->opr.op[1]);
		printf("\tjz\tL%03d\n", lbl1 = lbl++);
		//gen code of current CASE
		ex(p->opr.op[2]);
		//Remaining CASE
		p=p->opr.op[3];
		while(p)
		{
			//case label
			printf("L%03d:\n", lbl1);
			//Case value check
			ex(p->opr.op[0]);
			//Jmp Not Equal ..
			printf("\tcompNE\n");
			//printf("\tpop\t%s\n", p->opr.op[0]);
			printf("\tjz\tL%03d\n", lbl1 = lbl++);
			//gen code of current CASE
			ex(p->opr.op[1]);
			//next CASE
			p=p->opr.op[2];	
		}
		break;
		case CASE:
		break;
		case ITER:
			ex(p->opr.op[0]);
			p=p->opr.op[1];
			while(p)
			{
				ex(p->opr.op[0]);
				p=p->opr.op[1];
			}
		break;
		case FOR:
			ex(p->opr.op[1]);
			printf("\tpop\t%s\n", p->opr.op[0]->id.name);
			printf("L%03d:\n", lbl1 = lbl++);
			/*
			ex(p->opr.op[0]);
			ex(p->opr.op[1]);
			printf("\tcompGT\n");
			printf("\tjz\tL%03d\n", );
			printf("\tpop\tR1\n");
			*/
			printf("\tjG\t%s,\t%d,\tL%03d\n",p->opr.op[0]->id.name,p->opr.op[2]->con.value,lbl2=lbl++);
			ex(p->opr.op[3]);
			
			if(p->opr.op[1]->con.value>p->opr.op[2]->con.value) { printf("dec\t%s\n",p->opr.op[0]->id.name); }
			else { printf("\tinc\t%s\n",p->opr.op[0]->id.name); }
			
			printf("\tjmp\tL%03d\n", lbl1);
			printf("L%03d:\n", lbl2);
			break;
        case WHILE:
            printf("L%03d:\n", lbl1 = lbl++);
            ex(p->opr.op[0]);
            printf("\tjz\tL%03d\n", lbl2 = lbl++);
            ex(p->opr.op[1]);
            printf("\tjmp\tL%03d\n", lbl1);
            printf("L%03d:\n", lbl2);
            break;
		case DO:
			printf("L%03d:\n", lbl1 = lbl++);
			ex(p->opr.op[0]);
			ex(p->opr.op[1]);
			printf("\tjz\tL%03d\n", lbl1);
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
				if(p->opr.op[2])
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
            //ex(p->opr.op[0]);
			p=p->opr.op[0];
			switch(p->type)
			{
			case typeCon:  
				if(p->con.isChar)
					printf("\tprint\t%s\n", p->con.char_value); 
				else
					printf("\tprint\t%d\n", p->con.value); 
				break;
			case typeId:  
				printf("\tprint\t%s\n", p->id.name); 
				break;
			case typeOpr:
				break;
			}
            //printf("\tprint\n");	
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
