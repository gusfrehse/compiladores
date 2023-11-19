
/* -------------------------------------------------------------------
 *            Arquivo: compilador.l
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Tipos, protótipos e variáveis globais do compilador (via extern)
 *
 * ------------------------------------------------------------------- */

%{


#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"

//#define IMPRIME(STR) {};
#define IMPRIME(STR) printf("%s    # %s \n", STR, token);

int nl = 1;

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z][a-zA-Z0-9]*

numero [0-9]+

comentario "(*".*"*)"

tipo (integer|boolean)

boolean (True|False)

%%

{pulo_linha} {nl++;}

{descarte}

{comentario}

program { simbolo  = simb_program;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("program ");
          return PROGRAM;
 }

var      { simbolo = simb_var;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("var  ");
          return VAR;
 }

begin { simbolo = simb_begin;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("begin ");
          return T_BEGIN;
 }

end { simbolo = simb_end;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("end  ");
          return T_END;
 }

:= { simbolo = simb_atribuicao;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" atribuicao  ");
          return ATRIBUICAO;
 }

\; { simbolo = simb_ponto_e_virgula;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" pt_virgula  ");
          return PONTO_E_VIRGULA;
 }

\: { simbolo = simb_dois_pontos;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" dois pontos ");
          return DOIS_PONTOS;
 }

\, { simbolo = simb_virgula;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" virgula  ");
          return VIRGULA;
 }


\. { simbolo = simb_ponto;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" ponto  ");
          return PONTO;
    }

\(  { simbolo = simb_abre_parenteses;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" abre_parenteses  ");
          return ABRE_PARENTESES;
    }

\)  { simbolo = simb_fecha_parenteses;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" fecha_parenteses ");
          return FECHA_PARENTESES;
 }

label { simbolo = simb_label;
		strncpy (token, yytext, TAM_TOKEN);
		IMPRIME(" label  ");
		return LABEL;
	  }

type	{ simbolo = simb_type;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" type  ");
		  return TYPE;
		}

procedure	{ simbolo = simb_procedure;
		      strncpy (token, yytext, TAM_TOKEN);
		      IMPRIME(" procedure  ");
		      return PROCEDURE;
		}

function { simbolo = simb_function;
		   strncpy (token, yytext, TAM_TOKEN);
		   IMPRIME(" function  ");
		   return FUNCTION;
		 }

goto { simbolo = simb_goto;
	   strncpy (token, yytext, TAM_TOKEN);
	   IMPRIME(" goto  ");
	   return GOTO;
	 }

if 	{ simbolo = simb_if;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" if  ");
	  return IF;
	}

then	{ simbolo = simb_then;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" then  ");
		  return THEN;
		}

else	{ simbolo = simb_else;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" else  ");
		  return ELSE;
		}

while	{ simbolo = simb_while;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" while  ");
		  return WHILE;
		}

do	    { simbolo = simb_do;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" do  ");
		  return DO;
		}

array	{ simbolo = simb_array;
		  strncpy (token, yytext, TAM_TOKEN);
		  IMPRIME(" array  ");
		  return ARRAY;
		}

of	{ simbolo = simb_of;
	  strncpy (token, yytext, TAM_TOKEN);
		IMPRIME(" of  ");
		return OF;
	}

\[	{ simbolo = simb_abre_colchetes;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" abre colchetes  ");
	  return ABRE_COLCHETES;
	}

\]	{ simbolo = simb_fecha_colchetes;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" fecha colchetes  ");
	  return FECHA_COLCHETES;
	}

div { simbolo = simb_div;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" div  ");
	  return DIV;
	}

and	{ simbolo = simb_and;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" and  ");
	  return AND;
	}

not { simbolo = simb_not;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" not  ");
	  return NOT;
	}

or	{ simbolo = simb_or;
	  strncpy (token, yytext, TAM_TOKEN);
	  IMPRIME(" or  ");
	  return OR;
	}


\>  { simbolo = simb_gt;
      strncpy (token, yytext, TAM_TOKEN);
      IMPRIME(" maior que  ");
      return MAIOR;
 	}

\<  { simbolo = simb_lt;
      strncpy (token, yytext, TAM_TOKEN);
      IMPRIME(" menor que  ");
      return MENOR;
 	}

\=  { simbolo = simb_eq;
      strncpy (token, yytext, TAM_TOKEN);
      IMPRIME(" igual a  ");
      return IGUAL;
 	}

\+ { simbolo = simb_soma;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" mais  ");
     return MAIS;
   }

\-  { simbolo = simb_sub;
      strncpy (token, yytext, TAM_TOKEN);
      IMPRIME(" menos  ");
      return MENOS;
 	}

\*  { simbolo = simb_mult;
      strncpy (token, yytext, TAM_TOKEN);
      IMPRIME(" vezes  ");
      return VEZES;
 	}

\<\> { simbolo = simb_diff;
       strncpy (token, yytext, TAM_TOKEN);
       IMPRIME(" diferente  ");
       return DIFERENTE;
 	 }

\<\= { simbolo = simb_lteq;
       strncpy (token, yytext, TAM_TOKEN);
       IMPRIME(" menor ou igual que  ");
       return MENOR_IGUAL;
	 }

\>\= { simbolo = simb_gteq;
       strncpy (token, yytext, TAM_TOKEN);
       IMPRIME(" maior ou igual que  ");
       return MAIOR_IGUAL;
}

read { simbolo = simb_read;
       strncpy (token, yytext, TAM_TOKEN);
       IMPRIME(" read  ");
       return READ;
     }


write { simbolo = simb_write;
		strncpy (token, yytext, TAM_TOKEN);
		IMPRIME(" write  ");
		return WRITE;
      }

{tipo} { simbolo = simb_tipo;
         strncpy (token, yytext, TAM_TOKEN);
         IMPRIME(" tipo  ");
         return TIPO;
	   }

{boolean} { simbolo = simb_boolean;
               strncpy (token, yytext, TAM_TOKEN);
               IMPRIME(" boolean  ");
               return VALOR_BOOL;
		     }

{ident} { simbolo = simb_identificador;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" ident  ");
          return IDENT;
        }

{numero} { simbolo =  simb_numero;
           strncpy (token, yytext, TAM_TOKEN);
           IMPRIME(" numero  ");
           return NUMERO;
         }	

%%
