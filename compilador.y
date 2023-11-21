%define parse.error verbose

%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"

#include "utils/symbols_table.h"
#include "utils/genlabels.h"

#define MEPA_WRITE(_buf, _cmd, ...) snprintf(_buf, sizeof(_buf), _cmd, __VA_ARGS__), geraCodigo(NULL, _buf)
#define LOG(_fmt, ...) fprintf(stderr, "%s:%d: " _fmt "\n", __func__, __LINE__ __VA_OPT__(,) __VA_ARGS__)
#define ASSERT(_expect, _fmt, ...) if (!(_expect)) LOG(_fmt, __VA_ARGS__), abort()

int current_num_vars;
int current_offset;
char mepa_buf[128];
int lexical_level;
int num_same_type;
struct symbols_content cc;
struct symbols_table *table;
struct symbols_symbol s;
struct symbols_parameter parameters[128];
int num_parameters;
struct symbols_parameter param_aux;
struct symbols_symbol *nested_functions[100];
int num_nested_functions = 0;
int num_vars_by_level[10];
struct genlabels_table *p_labels;
struct genlabels_label label_a;
struct symbols_content content;
int mem_allocations[1000];
int num_mem_allocations = 0;
char function_names[100][128];
int num_function_names = 0;
int inside_function_call = 0;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token LABEL TYPE PROCEDURE FUNCTION
%token GOTO IF THEN ELSE WHILE DO
%token ARRAY OF ABRE_COLCHETES FECHA_COLCHETES
%token DIV AND NOT OR TIPO VALOR_BOOL NUMERO
%token MAIOR MENOR IGUAL MENOR_IGUAL MAIOR_IGUAL DIFERENTE
%token MAIS MENOS VEZES
%token READ WRITE FORWARD

%union{
   char * str;  // define o tipo str
   int int_val; // define o tipo int_val
   struct simbolo *simb;
}

%type <str> relacao;
%type <int_val> fator;
%type <int_val> termo;
%type <int_val> expressao_simples;
%type <int_val> expressao;
%type <int_val> parametros_ou_nada;
%type <int_val> funcao_ou_ident;
%type <int_val> empilha_retorno;
%type <int_val> continua_atibui_ou_func;
%type <int_val> tipo;

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%


/* REGRAS QUE DEVEM SER IMPLEMNTADAS
1\2\8\9\10\11\12\13\14\16\17\18\19\20\23\22\25
\26\27\28\29\30
*/

// =========== REGRA 1 ============= //
programa    :{
               geraCodigo(NULL, "INPP");
               table = symbols_table_init();
               p_labels = genlabels_table_init();
               lexical_level = 0;
            }
            PROGRAM IDENT
            ABRE_PARENTESES input_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO {
               MEPA_WRITE(mepa_buf, "DMEM %d", num_vars_by_level[0]);
               geraCodigo (NULL, "PARA");
            }
;


input_idents: IDENT VIRGULA IDENT
;

// =========== REGRA 2 ============= //
bloco       :
            parte_declara_vars
            {
               label_a = genlabels_label_generate(p_labels);
               MEPA_WRITE(mepa_buf, "DSVS %s", label_a.label);
               ++lexical_level;
            }
            parte_declara_sub_rotinas {
               --lexical_level;
               label_a = genlabels_label_get(p_labels);
               geraCodigo (label_a.label, "NADA");
            }
            comando_composto
            {
            }
;



// =========== REGRA 8 ============= //
parte_declara_vars: {current_offset = 0;}
					VAR declaracao_de_vars
               |
;

// =========== REGRA 9 ============= //
declaracao_de_vars: declaracao_de_vars declaracao_de_var 
                  | declaracao_de_var

declaracao_de_var: {
                     num_same_type = 0;
                     current_num_vars = 0;
                  }
                  lista_idents DOIS_PONTOS tipo PONTO_E_VIRGULA {
                     MEPA_WRITE(mepa_buf, "AMEM %d", current_num_vars);
                     mem_allocations[num_mem_allocations++] = current_num_vars;
					   }

;

tipo        : TIPO {
                     const int type = 0 == strcmp(token, "integer") 
                                       ?  SYMBOLS_VARIABLES_INTEGER
                                       : strcmp(token, "boolean") ? SYMBOLS_VARIABLES_BOOLEAN : SYMBOLS_VARIABLES_UNDEFINED;
                     symbols_table_add_type(table, type, num_same_type);
                     $$ = type;
            }
;


// =========== REGRA 10 ============= //
lista_idents: lista_idents VIRGULA IDENT {
               LOG("Adding token [%s]\n", token);
               s = symbols_table_create_symbol(token, SYMBOLS_TYPES_VARIABLE, lexical_level, cc, current_offset);
               symbols_table_add(table, s);
               ++num_same_type;
               ++current_num_vars;
               ++current_offset;
               ++num_vars_by_level[lexical_level];
            }
            | IDENT {
               LOG("Adding token [%s]\n", token);
               s = symbols_table_create_symbol(token, SYMBOLS_TYPES_VARIABLE, lexical_level, cc, current_offset);
               symbols_table_add(table, s);
               ++num_same_type;
               ++current_num_vars;
               ++current_offset;
               ++num_vars_by_level[lexical_level];
            }
;

// =========== REGRA 16 ============= //
comando_composto: T_BEGIN comandos T_END
;

parte_declara_sub_rotinas:
                           parte_declara_sub_rotinas declara_procedimento
                           | parte_declara_sub_rotinas declara_function 
                           |
;

declara_procedimento:
                     PROCEDURE IDENT {
                        strcpy(function_names[num_function_names++], token);
                        num_parameters = 0;
                     } parametros_formais_ou_nada {
                        label_a = genlabels_label_generate(p_labels);
                        sprintf(mepa_buf, "ENPR %d", lexical_level);
                        geraCodigo(label_a.label, mepa_buf);

                        strcpy(content.proc.label, label_a.label);
                        content.proc.n_params = num_parameters;
                     
                        memcpy(content.proc.params, parameters, sizeof(struct symbols_parameter) * num_parameters);
                        
                        symbols_table_set_offset(table, num_parameters);
                        s = symbols_table_create_symbol(function_names[num_function_names - 1], SYMBOLS_TYPES_PROCEDURE, lexical_level, content, 0);
                        symbols_table_add(table, s);

                     } PONTO_E_VIRGULA {symbols_table_print(table);} bloco {
                           MEPA_WRITE(mepa_buf, "DMEM %d", mem_allocations[--num_mem_allocations]);
                           MEPA_WRITE(mepa_buf, "RTPR %d, %d", lexical_level, num_parameters);
                           label_a = genlabels_label_get(p_labels);
                           symbols_table_remove_until(table,function_names[--num_function_names]);
                     } PONTO_E_VIRGULA
;

parametros_formais_ou_nada:
               ABRE_PARENTESES { num_parameters = 0; } declaracao_params FECHA_PARENTESES
               |
;

declara_function:
               FUNCTION IDENT {
                  strcpy(function_names[num_function_names++], token);
                  num_parameters = 0;
               } parametros_formais_ou_nada DOIS_PONTOS TIPO PONTO_E_VIRGULA {
                  label_a = genlabels_label_generate(p_labels);
                  sprintf(mepa_buf, "ENPR %d", lexical_level);
                  geraCodigo(label_a.label, mepa_buf);

                  strcpy(content.proc.label, label_a.label);
                  content.proc.n_params = num_parameters;
               
                  memcpy(content.proc.params, parameters, sizeof(struct symbols_parameter) * num_parameters);
                  symbols_table_set_offset(table, num_parameters);
                  s = symbols_table_create_symbol(function_names[num_function_names - 1], SYMBOLS_TYPES_FUNCTION, lexical_level, content, -(4 + num_parameters));
                  symbols_table_add(table, s);
                  symbols_table_add_type(table, SYMBOLS_VARIABLES_INTEGER, 1);
               } bloco_ou_forward PONTO_E_VIRGULA
; 

//====================================================================
declaracao_params: declaracao_params PONTO_E_VIRGULA declaracao_param 
                  | declaracao_param
;

declaracao_param: {
                     num_same_type = 0;
                  }
                   lista_params_formais DOIS_PONTOS tipo {
                     for(int i = num_parameters; i > num_parameters - num_same_type; --i) {
                        parameters[i-1].type = $4;
                     }
                     ++num_same_type;
                   }

;

lista_params_formais:   
                        lista_params_formais VIRGULA parametro { ++num_parameters; }
                        | parametro { ++num_parameters; }
;

//=======================================================================
parametro:
         VAR IDENT {
            cc.param.kind = param_aux.kind = SYMBOLS_PARAMETERS_REFERENCE;
            parameters[num_parameters] = param_aux;

            printf("Adding token [%s]", token);
            s = symbols_table_create_symbol(token, SYMBOLS_TYPES_PARAMETER, lexical_level, cc, -1);
            symbols_table_add(table, s);

            ++num_same_type;
         } 
         |  IDENT {
            cc.param.kind = param_aux.kind = SYMBOLS_PARAMETERS_COPY;
            parameters[num_parameters] = param_aux;

            LOG("Adding token [%s]", token);
            s = symbols_table_create_symbol(token, SYMBOLS_TYPES_PARAMETER, lexical_level, cc, -1);
            LOG("n_params = %d; offset = %d\n\n", num_parameters, s.offset);
            symbols_table_add(table, s);

            ++num_same_type;
         }
;

// =========== REGRA 17 ============= //
comandos: 
         comandos PONTO_E_VIRGULA comando 
         | comando 
         |
;

// =========== REGRA 18 ============= //
comando: 
         atribui_ou_func  { LOG("ASSIGNMENT/FUNCTION OP CHOSEN"); }
         | comando_composto
         | comando_condicional
         | comando_repetitivo
         | leitura
         | escrita
; 
         
 
// =========== REGRA 19 ============= //
atribui_ou_func:
         IDENT {
            nested_functions[num_nested_functions++] = symbols_table_lookup(table, token);
            ASSERT(nested_functions[num_nested_functions - 1] != NULL, "Unknown token '%s'", token);
            LOG("Name = %s\n", nested_functions[num_nested_functions-1]->name);
         }
         continua_atibui_ou_func {
            if ($3 == 1)
               --num_nested_functions;
         }
;

continua_atibui_ou_func:
                  ATRIBUICAO atribui_contiunuacao  { $$ = 1; LOG("ASSIGNMENT OP"); }
                  | parametros_ou_nada { $$ = 2; LOG("FUNCTION OP"); }
;


atribui_contiunuacao: { LOG("ASSIGNMENT OP (continuation)"); }
                   expressao{
                     const struct symbols_symbol *ret = nested_functions[num_nested_functions - 1];
                     char const *command = NULL;

                     switch (ret->type) {
                     case SYMBOLS_TYPES_VARIABLE:
                     case SYMBOLS_TYPES_FUNCTION:
                        ASSERT($2 == ret->content.var_type, "Unexpected type: %d; Expected: %d", $2, ret->content.var_type);
                        command = "ARMZ %d, %d";
                        break;
                     case SYMBOLS_TYPES_PARAMETER:
                        ASSERT($2 == ret->content.param.type, "Unexpected type: %d; Expected: %d", $2, ret->content.param.type);
                        command = ret->content.param.kind == SYMBOLS_PARAMETERS_COPY ? "ARMZ %d, %d" : "ARMI %d, %d";
                        break;
                     }
                     MEPA_WRITE(mepa_buf, command, ret->lexical_level, ret->offset);
                  }
;



// =========== REGRA 20 ============= //
funcao_ou_ident:
               IDENT {
                  nested_functions[num_nested_functions++] = symbols_table_lookup(table, token);
                  ASSERT(nested_functions[num_nested_functions - 1] != NULL, "Couldn't find token '%s'", token);
                  LOG("Name = %s; Type %d; Variable Type = %d",
                      nested_functions[num_nested_functions - 1]->name,
                      nested_functions[num_nested_functions - 1]->type,
                      nested_functions[num_nested_functions - 1]->content.var_type);
               }

               parametros_ou_nada {
                  const struct symbols_symbol *ret = nested_functions[num_nested_functions - 1];
                  char const *command = NULL;
                  int return_type = -1;

                  const struct symbols_symbol *func = nested_functions[num_nested_functions - 2];
                  if (inside_function_call && (func->content.proc.params[num_parameters].kind == SYMBOLS_PARAMETERS_REFERENCE)) {
                     LOG("Entered a function call...\n"
                         "Token to be searched = '%s'; Params count = %d; Passing by reference = %d",
                         func->name, num_parameters, func->content.proc.params[num_parameters].type);

                     switch (ret->type) {
                     case SYMBOLS_TYPES_VARIABLE:
                        command = "CREN %d, %d";
                        return_type = ret->content.var_type;
                        break;
                     case SYMBOLS_TYPES_PARAMETER:
                        command = ret->content.param.kind == SYMBOLS_PARAMETERS_COPY ? "CREM %d, %d" : "CRVL %d, %d";
                        return_type = ret->content.param.type;
                        break;
                     }
                  } else {
                     switch (ret->type) {
                     case SYMBOLS_TYPES_VARIABLE:
                        command = "CRVL %d, %d";
                        return_type = ret->content.var_type;
                        break;
                     case SYMBOLS_TYPES_PARAMETER:
                        command = ret->content.param.kind == SYMBOLS_PARAMETERS_COPY ? "CRVL %d, %d" : "CRVI %d, %d";
                        return_type = ret->content.param.type;
                        break;
                     }
                  }
                  LOG("Type is %d", ret->type);

                  if (return_type != -1) {
                     MEPA_WRITE(mepa_buf, command, ret->lexical_level, ret->offset);
                     $$ = return_type;
                  }
                  --num_nested_functions;
               }
;

parametros_ou_nada:
                 empilha_retorno ABRE_PARENTESES {num_parameters = 0; inside_function_call = 1;} lista_params {inside_function_call = 0;} FECHA_PARENTESES {
                  ASSERT(nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_FUNCTION || nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_PROCEDURE, "Not a function or procedure (%s)", nested_functions[num_nested_functions - 1]->name);
                  ASSERT(nested_functions[num_nested_functions-1]->content.proc.n_params == num_parameters, "Wrong amount of parameters (%d vs %d)", nested_functions[num_nested_functions-1]->content.proc.n_params, num_parameters);
                  $$ = SYMBOLS_VARIABLES_UNDEFINED;
                  MEPA_WRITE(mepa_buf, "CHPR %s, %d", nested_functions[num_nested_functions-1]->content.proc.label , lexical_level);
                }
                | empilha_retorno {
                  if(nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_FUNCTION || nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_PROCEDURE){
                     $$ = SYMBOLS_VARIABLES_UNDEFINED; //caso seja procedure
                     if(nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_FUNCTION){
                        geraCodigo(NULL, "AMEM 1");
                        $$ = nested_functions[num_nested_functions-1]->content.param.type;
                     }
                     MEPA_WRITE(mepa_buf, "CHPR %s, %d", nested_functions[num_nested_functions-1]->content.proc.label , lexical_level);
                  }
                }
;

empilha_retorno:  {
                     if (nested_functions[num_nested_functions-1]->type == SYMBOLS_TYPES_FUNCTION){
                        geraCodigo(NULL, "AMEM 1");
                        $$ = nested_functions[num_nested_functions-1]->content.param.type;
                     }
                  }
;

lista_params:  
               lista_params VIRGULA expressao { ++num_parameters; }
               | { LOG("%d", num_parameters); } expressao { ++num_parameters; }
;

// =========== REGRA 22 ============= //
comando_condicional:
                  if_then cond_else {
                     label_a = genlabels_label_get(p_labels);
                     geraCodigo (label_a.label, "NADA"); 
                  }
;

if_then:
         IF expressao {
            ASSERT($2 == SYMBOLS_VARIABLES_BOOLEAN, "Unexpected type: %d; Expected: %d", $2, SYMBOLS_VARIABLES_BOOLEAN);
            label_a = genlabels_label_generate(p_labels);
            label_a = genlabels_label_generate(p_labels);
            MEPA_WRITE(mepa_buf, "DSVF %s", label_a.label);
         }
         THEN comando {
            label_a = p_labels->labels[p_labels->top - 2];
            MEPA_WRITE(mepa_buf, "DSVS %s", label_a.label);
            label_a = genlabels_label_get(p_labels);
            geraCodigo(label_a.label, "NADA"); 
         }
;

cond_else: 
               ELSE comando
              | %prec LOWER_THAN_ELSE
;                

// =========== REGRA 23 ============= //
comando_repetitivo:{
                        label_a = genlabels_label_generate(p_labels);
                        geraCodigo(label_a.label, "NADA"); 
                     }
                     WHILE while_resto
;                     
while_resto:                     
                     expressao {
                        ASSERT($1 == SYMBOLS_VARIABLES_BOOLEAN, "Unexpected type: %d; Expected: %d", $1, SYMBOLS_VARIABLES_BOOLEAN);
                        label_a = genlabels_label_generate(p_labels);
                        MEPA_WRITE(mepa_buf, "DSVF %s", label_a.label);
                     }
                     DO comando{
                        label_a = p_labels->labels[p_labels->top-2];
                        MEPA_WRITE(mepa_buf, "DSVS %s", label_a.label);
                        label_a = p_labels->labels[p_labels->top-1];
                        geraCodigo (label_a.label, "NADA"); 
                        genlabels_table_pop_n(p_labels, 2);
                     }
;

// =========== REGRA 25 ============= //
expressao:
            expressao_simples relacao expressao_simples{
               geraCodigo(NULL, $2);
               ASSERT($1 == $3, "Unexpected type: %d; Expected: %d", $1, $3);
               $$ = SYMBOLS_VARIABLES_BOOLEAN;
            }
            | expressao_simples {
               $$ = $1;
            }
;

// =========== REGRA 26 ============= //
relacao:
         IGUAL          { $$ = "CMIG"; }
         | MENOR        { $$ = "CMME"; }
         | MAIOR        { $$ = "CMMA"; }
         | MAIOR_IGUAL  { $$ = "CMAG"; }
         | MENOR_IGUAL  { $$ = "CMEG"; }
         | DIFERENTE    { $$ = "CMDG"; }
;

// =========== REGRA 27 ============= //
expressao_simples:
               termo {
                  $$ = $1;
               }
               | MAIS termo {
                  ASSERT($2 == SYMBOLS_VARIABLES_INTEGER, "Unexpected type: %d; Expected: %d", $2, SYMBOLS_VARIABLES_BOOLEAN);
                  $$ = $2;
               }
               | MENOS termo {
                  geraCodigo(NULL, "INVR");
                  ASSERT($2 == SYMBOLS_VARIABLES_INTEGER, "Unexpected type: %d; Expected: %d", $2, SYMBOLS_VARIABLES_BOOLEAN);
                  $$ = $2;
               }
               | expressao_simples MAIS termo  {
                  geraCodigo(NULL, "SOMA");
                  ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_INTEGER, "Expression between incompatible types (%d, %d)", $1, $3);
                  $$ = $3;
               }
               | expressao_simples MENOS termo {
                  geraCodigo(NULL, "SUBT");
                  ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_INTEGER, "Expression between incompatible types (%d, %d)", $1, $3);
                  $$ = $3;
               }
               | expressao_simples OR termo {
                  geraCodigo(NULL, "DISJ");
                  ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_BOOLEAN, "Expression between incompatible types (%d, %d)", $1, $3);
                  $$ = $3;
               }
;

bloco_ou_forward:
      FORWARD { }
      | bloco {
         MEPA_WRITE(mepa_buf, "DMEM %d", mem_allocations[--num_mem_allocations]);
         MEPA_WRITE(mepa_buf, "RTPR %d, %d", lexical_level, num_parameters);
         label_a = genlabels_label_get(p_labels);
         symbols_table_remove_until(table, function_names[--num_function_names]);
      }
;

termo: 
      fator  {
         $$ = $1;
      }
      | termo DIV fator  {
         geraCodigo(NULL, "DIVI");
         ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_INTEGER, "Expression between incompatible types (%d, %d)", $1, $3);
         $$ = $3;
      }
      | termo VEZES fator  {
         geraCodigo(NULL, "MULT");
         ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_INTEGER, "Expression between incompatible types (%d, %d)", $1, $3);
         $$ = $3;
      }
      | termo AND fator  {
         geraCodigo(NULL, "CONJ");
         ASSERT($1 == $3 && $1 == SYMBOLS_VARIABLES_BOOLEAN, "Expression between incompatible types (%d, %d)", $1, $3);
         $$ = $3;
      }
;

fator:
      funcao_ou_ident {
         $$ = $1;
      }
      | NUMERO {
         MEPA_WRITE(mepa_buf, "CRCT %ld", strtol(token, NULL, 10));
         $$ = SYMBOLS_VARIABLES_INTEGER;
      }   
      | VALOR_BOOL {
         MEPA_WRITE(mepa_buf, "CRCT %d", 0 == strcmp(token, "True"));
         $$ = SYMBOLS_VARIABLES_BOOLEAN;
      }
      | ABRE_PARENTESES expressao_simples FECHA_PARENTESES {
         $$ = $2;
      }
      | NOT fator {
         ASSERT($2 == SYMBOLS_VARIABLES_BOOLEAN, "Unexpected type: %d; Expected: %d", $2, SYMBOLS_VARIABLES_BOOLEAN);
         geraCodigo(NULL, "NEGA");
         $$ = $2;
      }
;



// =========== LEITURA ============= //
leitura: 
         READ ABRE_PARENTESES parametros_de_leitura FECHA_PARENTESES
;

parametros_de_leitura:
                     parametros_de_leitura VIRGULA parametro_leitura
                        | parametro_leitura
;

parametro_leitura:
                  IDENT {
                     geraCodigo(NULL, "LEIT");
                     LOG("Searching token '%s' ...", token);
                     struct symbols_symbol *ps = symbols_table_lookup(table, token);
                     ASSERT(ps != NULL, "Couldn't find token '%s'", token);
                     MEPA_WRITE(mepa_buf, "ARMZ %d, %d", ps->lexical_level, ps->offset);
                  }
;


// =========== ESCRITA ============= //
escrita: 
        WRITE ABRE_PARENTESES parametros_de_escrita FECHA_PARENTESES 
;

parametros_de_escrita:
                     parametros_de_escrita VIRGULA parametro_escrita
                        | parametro_escrita
;

parametro_escrita:
                  expressao_simples {
                     if ($1 != SYMBOLS_VARIABLES_UNDEFINED)
                        geraCodigo(NULL, "IMPR");
                     else
                        LOG("Incompatible parameter");
                  }

;



%%

int main (int argc, const char **argv) {
   extern FILE* yyin;

   if (argc<2 || argc>2) {
      LOG("Usage: ./%s <file>", argv[0]);
      return EXIT_FAILURE;
   }

   FILE *fp = fopen (argv[1], "r");
   if (fp == NULL) {
      LOG("Usage: ./%s <file>", argv[0]);
      return EXIT_FAILURE;
   }

/* -------------------------------------------------------------------
 *  Inicia a table de S�mbolos
 * ------------------------------------------------------------------- */

   yyin = fp;
   yyparse();

   symbols_table_print(table);

   return EXIT_SUCCESS;
}
