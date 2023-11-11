
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"

#include "utils/symbols_table.h"
#include "utils/genlabels.h"

int num_vars;
int desloc_num_vars;
char mepa_buf[128];
int nivel_lexico;
int num_carrega_tipo;
struct cat_conteudo cc;
struct tab_simb *tabela;
struct simbolo s ,lista_simbolos[128];
struct parametro lista_parametros[128];
struct parametro param_aux;
struct simbolo *ps;
struct simbolo *esquerdo;
int esquerdo_recursao_func = 0;
struct simbolo *esquerdo_func[100];
int num_vars_por_nivel[10];
struct pilha_rotulos *p_rotulos;
struct rotulo rotulo_a;
int num_params;
char proc_name[128];
struct cat_conteudo conteudo;
int pilha_num_vars[1000];
char pilha_proc_name[100][128];
int pilha_proc = 0;
int ponteiro_pilha_num_vars = 0;
int em_chamada_de_funcao = 0;


enum tipo_dado{
    t_int,
    t_bool
};


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
%token READ WRITE

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
             geraCodigo (NULL, "INPP");
             tabela = symbols_table_init();
             p_rotulos = genlabels_table_init();
             nivel_lexico = 0;
             }
             PROGRAM IDENT
             ABRE_PARENTESES input_idents FECHA_PARENTESES PONTO_E_VIRGULA
             bloco PONTO {
             sprintf (mepa_buf, "DMEM %d", num_vars_por_nivel[0]);
             geraCodigo (NULL, mepa_buf);
             geraCodigo (NULL, "PARA");
             }
;


input_idents: IDENT VIRGULA IDENT
;

// =========== REGRA 2 ============= //
bloco       :
            parte_declara_vars
            {
            //fprintf(stderr,"COISA DE TESTE \n");
            rotulo_a = genlabels_label_generate(&p_rotulos);
            sprintf(mepa_buf, "DSVS %s", rotulo_a.rotulo);
            geraCodigo (NULL, mepa_buf);
            nivel_lexico++;
            }
            parte_declara_sub_rotinas
            {
            nivel_lexico --;
            rotulo_a = genlabels_label_get(&p_rotulos);
            geraCodigo (rotulo_a.rotulo, "NADA");
            }
            comando_composto
            {
            }
;



// =========== REGRA 8 ============= //
parte_declara_vars: {desloc_num_vars = 0;}
					VAR declaracao_de_vars/* {
					   sprintf(mepa_buf, "AMEM %d", num_vars);
                  ponteiro_pilha_num_vars++;
                  pilha_num_vars[ponteiro_pilha_num_vars] = num_vars;
					   geraCodigo(NULL,mepa_buf);
					   }*/


               |
;

// =========== REGRA 9 ============= //
declaracao_de_vars: declaracao_de_vars declaracao_de_var 
                  | declaracao_de_var

declaracao_de_var: {
                     num_carrega_tipo = 0;
                     num_vars = 0;
                  }
                  lista_idents DOIS_PONTOS tipo PONTO_E_VIRGULA{
                     sprintf(mepa_buf, "AMEM %d", num_vars);
                     ponteiro_pilha_num_vars++;
                     pilha_num_vars[ponteiro_pilha_num_vars] = num_vars;
                     geraCodigo(NULL,mepa_buf);
					   }

;

tipo        : TIPO {
                     if (!strcmp(token, "integer")){
                        symbols_table_add_type(&tabela, pas_integer, num_carrega_tipo);
                        $$ = pas_integer;
                     }   
                     else if (!strcmp(token, "boolean")){   
                        symbols_table_add_type(&tabela, pas_boolean, num_carrega_tipo);
                        $$ = pas_boolean;
                     }
                     else

                        perror("TIPO ERRADO, CORRIGE, TA ERRADO");
                     }
;


// =========== REGRA 10 ============= //
lista_idents: lista_idents VIRGULA IDENT {
               printf("adicionado token [%s]\n", token);
               s = symbols_table_create_symbol(token, SYMBOLS_TYPE_VARIABLE, nivel_lexico, cc, desloc_num_vars);
               symbols_table_add(&tabela, s);
               num_carrega_tipo++;
               num_vars++;
               desloc_num_vars++;
               num_vars_por_nivel[nivel_lexico]++;
               }
            | IDENT {
               printf("adicionado token [%s]\n", token);
               s = symbols_table_create_symbol(token, SYMBOLS_TYPE_VARIABLE, nivel_lexico, cc, desloc_num_vars);
               symbols_table_add(&tabela, s);
               num_carrega_tipo++;
               num_vars++;
               desloc_num_vars++;
               num_vars_por_nivel[nivel_lexico]++;
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
                        strcpy(pilha_proc_name[pilha_proc], token);
                        pilha_proc++;
                        num_params = 0;
                     }
                     parametros_formais_ou_nada {
                        rotulo_a = genlabels_label_generate(&p_rotulos);
                        sprintf(mepa_buf, "ENPR %d", nivel_lexico);
                        geraCodigo(rotulo_a.rotulo, mepa_buf);

                        strcpy(conteudo.proc.rotulo, rotulo_a.rotulo);
                        conteudo.proc.qtd_parametros = num_params;
                     
                        memcpy(conteudo.proc.lista, lista_parametros, sizeof(struct parametro)*num_params);
                        
                        // for(int i = 0; i < num_params; ++i){
                        //    printf("proc.lista[%d] tem tipo %d e passado por %d \n", i, ti.proc.lista[i].tipo, ti.proc.lista[i].passagem);
                        // }
                        //printf("nome: %s nivel: %d desloca: %d\n",proc_name, nivel_lexico, deslocamento);
                        symbols_table_set_offset(&tabela, num_params);

                        s = symbols_table_create_symbol(pilha_proc_name[pilha_proc-1], procedimento, nivel_lexico, conteudo, 0);

                        symbols_table_add(&tabela, s);

                     } PONTO_E_VIRGULA {symbols_table_print(&tabela);} bloco{
                           sprintf(mepa_buf, "DMEM %d", pilha_num_vars[ponteiro_pilha_num_vars]);
                           geraCodigo(NULL, mepa_buf);
                           ponteiro_pilha_num_vars--;
                           sprintf(mepa_buf, "RTPR %d, %d", nivel_lexico, num_params);
                           geraCodigo(NULL, mepa_buf);
                           rotulo_a = genlabels_label_get(&p_rotulos);
                           pilha_proc--;
                           symbols_table_remove_until(&tabela,pilha_proc_name[pilha_proc]);
                           //falta remover os simbolos da tabela de simbolos
                     } PONTO_E_VIRGULA
;

parametros_formais_ou_nada:
               ABRE_PARENTESES {num_params = 0;} declaracao_params FECHA_PARENTESES
               |
;

declara_function:
               FUNCTION IDENT {
                  strcpy(pilha_proc_name[pilha_proc], token);
                  pilha_proc++;
                  num_params = 0;
               } parametros_formais_ou_nada{
                  rotulo_a = genlabels_label_generate(&p_rotulos);
                  sprintf(mepa_buf, "ENPR %d", nivel_lexico);
                  geraCodigo(rotulo_a.rotulo, mepa_buf);

                  strcpy(conteudo.proc.rotulo, rotulo_a.rotulo);
                  conteudo.proc.qtd_parametros = num_params;
               
                  memcpy(conteudo.proc.lista, lista_parametros, sizeof(struct parametro)*num_params);
                  
                  symbols_table_set_offset(&tabela, num_params);

                  s = symbols_table_create_symbol(pilha_proc_name[pilha_proc-1], funcao, nivel_lexico, conteudo, -(4 + num_params));

                  symbols_table_add(&tabela, s);

               } DOIS_PONTOS TIPO{
                  symbols_table_add_type(&tabela, pas_integer, 1);
               } PONTO_E_VIRGULA bloco {

                     sprintf(mepa_buf, "DMEM %d", pilha_num_vars[ponteiro_pilha_num_vars]);
                     geraCodigo(NULL, mepa_buf);
                     ponteiro_pilha_num_vars--;
                     sprintf(mepa_buf, "RTPR %d, %d", nivel_lexico, num_params);
                     geraCodigo(NULL, mepa_buf);
                     rotulo_a = genlabels_label_get(&p_rotulos);
                     pilha_proc--;
                     symbols_table_remove_until(&tabela,pilha_proc_name[pilha_proc]);

               } PONTO_E_VIRGULA

; 




//====================================================================
declaracao_params: declaracao_params PONTO_E_VIRGULA declaracao_param 
                  | declaracao_param
;

declaracao_param: {
                     num_carrega_tipo = 0;
                  }
                   lista_params_formais DOIS_PONTOS tipo {
                     for(int i = num_params; i > num_params - num_carrega_tipo; i--){
                        lista_parametros[i-1].tipo = $4;
                     }
                     num_carrega_tipo++;
                   }

;

lista_params_formais:   
                        lista_params_formais VIRGULA parametro {num_params++;}
                        | parametro {num_params++;}
;

//=======================================================================
parametro:
         VAR IDENT {
            cc.param.passagem = SYMBOLS_PARAMETERS_REFERENCE;
            param_aux.passagem = SYMBOLS_PARAMETERS_REFERENCE;
            lista_parametros[num_params] = param_aux;
            printf("adicionado token [%s]\n", token);
            s = symbols_table_create_symbol(token, SYMBOLS_TYPES_PARAMETER, nivel_lexico, cc, -1);
            symbols_table_add(&tabela, s);
            num_carrega_tipo++;
         } 
         |  IDENT {
            cc.param.passagem = parametro_copia;
            param_aux.passagem = parametro_copia;
            lista_parametros[num_params] = param_aux;
            printf("adicionado token [%s]\n", token);
            s = symbols_table_create_symbol(token, SYMBOLS_TYPES_PARAMETER, nivel_lexico, cc, -1);
            printf("OI %d\n\n\n", num_params);
            printf("TCHAU %d\n\n\n", s.deslocamento);
            symbols_table_add(&tabela, s);
            num_carrega_tipo++;
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
         atribui_ou_func  {printf("ATRIBUICAO/FUNCAO ESCOLHIDA \n");}
         | comando_composto
         | comando_condicional
         | comando_repetitivo
         | leitura
         | escrita
; 
         
 
// =========== REGRA 19 ============= //
atribui_ou_func:
         IDENT {
            if((esquerdo_func[esquerdo_recursao_func] = busca(&tabela, token)) == NULL){
               printf("ERRO: identificador {%s} nao encontrado/nao declarado", token );
               abort();
            }
            esquerdo_recursao_func++;
            printf("INDO PARA O ATRIBUI OU PARAMETROS\n");
            printf("identificador achado = %s\n", esquerdo_func[esquerdo_recursao_func-1]->identificador);
         }
         continua_atibui_ou_func{
            if ($3 == 1 )
                esquerdo_recursao_func--;
         }
;

continua_atibui_ou_func:
                  ATRIBUICAO atribui_contiunuacao {$$ = 1; printf("ATRIBUICAO ESCOLHIDA \n");}
                  | parametros_ou_nada {$$ = 2; printf( "FUNCAO ESCOLHIDA \n");}
;


atribui_contiunuacao: { printf("ATRIBUICAO ESCOLHIDA - continuacao\n");}
                   expressao{
                     
                     if(esquerdo_func[esquerdo_recursao_func-1]->categoria == SYMBOLS_TYPE_VARIABLE){
                        if($2 == esquerdo_func[esquerdo_recursao_func-1]->conteudo.var.tipo){
                           sprintf(mepa_buf, "ARMZ %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                        }else{
                           printf ("ERRO: expresao entre tipos incompativeis \n");
                           abort();
                        }
                     }else if (esquerdo_func[esquerdo_recursao_func-1]->categoria == parametro){
                        if($2 == esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo){
                           if (esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == parametro_copia ){
                              sprintf(mepa_buf, "ARMZ %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                           }else if (esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == SYMBOLS_PARAMETERS_REFERENCE){
                              sprintf(mepa_buf, "ARMI %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                           }
                        }else {
                           printf ("ERRO: expresao entre tipos incompativeis \n");
                           abort();
                        }
                     } 
                     else if(esquerdo_func[esquerdo_recursao_func-1]->categoria == funcao){
                         if($2 == esquerdo_func[esquerdo_recursao_func-1]->conteudo.var.tipo){
                           sprintf(mepa_buf, "ARMZ %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                        }else{
                           printf ("ERRO: expresao entre tipos incompativeis \n");
                           abort();
                        } 
                     }
                  }
;



// =========== REGRA 20 ============= //
funcao_ou_ident:
               IDENT {
                  if((esquerdo_func[esquerdo_recursao_func] = busca(&tabela, token)) == NULL){
                        printf("falha ao procurar token %s\n", token);
                     abort();
                  }
                  esquerdo_recursao_func++;  //evita de esquerdo_func se sobrescrito dentro de uma chamada recursiva de funcao_ou_ident
                  printf("identificador achado = %s\n", esquerdo_func[esquerdo_recursao_func-1]->identificador);
               }
               parametros_ou_nada{
                  if (em_chamada_de_funcao){
                     printf("EM CHAMADA DE FUNCAO AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n");
                     printf("token sendo pesquisado %s, numero atual = %i\n", esquerdo_func[esquerdo_recursao_func-2]->identificador, num_params);
                     printf("por referencia? %i\n", esquerdo_func[esquerdo_recursao_func-2]->conteudo.proc.lista[num_params].tipo);
                     if (esquerdo_func[esquerdo_recursao_func-2]->conteudo.proc.lista[num_params].passagem == SYMBOLS_PARAMETERS_REFERENCE){
                        printf("EH UMA REFERENCIA BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n");
                        if (esquerdo_func[esquerdo_recursao_func-1]->categoria == SYMBOLS_TYPE_VARIABLE){
                           printf("EH UMA VARAIVEL CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n");
                           sprintf(mepa_buf, "CREN %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                           $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.var.tipo;
                        }else if (esquerdo_func[esquerdo_recursao_func-1]->categoria == parametro){
                            printf("EH UMA PARAMETRO DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n");
                           if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == parametro_copia){
                              sprintf(mepa_buf, "CREM %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                              $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                           }else if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == SYMBOLS_PARAMETERS_REFERENCE){
                              sprintf(mepa_buf, "CRVL %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                              $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                           }
                        }
                     }else {
                        if (esquerdo_func[esquerdo_recursao_func-1]->categoria == SYMBOLS_TYPE_VARIABLE){
                           sprintf(mepa_buf, "CRVL %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                           $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.var.tipo;
                        }else if (esquerdo_func[esquerdo_recursao_func-1]->categoria == parametro){
                           if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == parametro_copia){
                              sprintf(mepa_buf, "CRVL %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                              $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                           }else if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == SYMBOLS_PARAMETERS_REFERENCE){
                              sprintf(mepa_buf, "CRVI %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                              geraCodigo(NULL, mepa_buf);
                              $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                           }
                        }
                     }
                  }else{
                     if (esquerdo_func[esquerdo_recursao_func-1]->categoria == SYMBOLS_TYPE_VARIABLE){
                        sprintf(mepa_buf, "CRVL %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                        geraCodigo(NULL, mepa_buf);
                        $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.var.tipo;
                     }else if (esquerdo_func[esquerdo_recursao_func-1]->categoria == parametro){
                        if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == parametro_copia){
                           sprintf(mepa_buf, "CRVL %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                           $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                        }else if(esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.passagem == SYMBOLS_PARAMETERS_REFERENCE){
                           sprintf(mepa_buf, "CRVI %d, %d",esquerdo_func[esquerdo_recursao_func-1]->nivel , esquerdo_func[esquerdo_recursao_func-1]->deslocamento );
                           geraCodigo(NULL, mepa_buf);
                           $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                        }
                     }
                  }
                  esquerdo_recursao_func--;
               }
;

parametros_ou_nada:
                 empilha_retorno ABRE_PARENTESES {num_params = 0; em_chamada_de_funcao = 1;}lista_params {em_chamada_de_funcao = 0;} FECHA_PARENTESES {
                 if(esquerdo_func[esquerdo_recursao_func-1]->categoria == funcao || esquerdo_func[esquerdo_recursao_func-1]->categoria == procedimento){
                     $$ = undefined_type; //caso seja procedure
                     if (esquerdo_func[esquerdo_recursao_func-1]->conteudo.proc.qtd_parametros != num_params){
                        printf("%d %d\n", esquerdo_func[esquerdo_recursao_func-1]->conteudo.proc.qtd_parametros, num_params);
                        printf("ERRO: numero errado de parametros\n");
                        abort();
                     }
                     sprintf(mepa_buf, "CHPR %s, %d", esquerdo_func[esquerdo_recursao_func-1]->conteudo.proc.rotulo , nivel_lexico );
                     geraCodigo(NULL, mepa_buf);
                  }else{
                     printf("ERRO: {%s} nao eh funcao ou procedimento\n", esquerdo_func[esquerdo_recursao_func-1]->identificador);
                     abort();
                  }
                }
                | empilha_retorno {
                  if(esquerdo_func[esquerdo_recursao_func-1]->categoria == funcao || esquerdo_func[esquerdo_recursao_func-1]->categoria == procedimento){
                     $$ = undefined_type; //caso seja procedure
                     if(esquerdo_func[esquerdo_recursao_func-1]->categoria == funcao){
                        geraCodigo(NULL, "AMEM 1");
                        $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                     }
                     sprintf(mepa_buf, "CHPR %s, %d", esquerdo_func[esquerdo_recursao_func-1]->conteudo.proc.rotulo , nivel_lexico );
                     geraCodigo(NULL, mepa_buf);
                  }
                }
;

empilha_retorno:  {
                     if(esquerdo_func[esquerdo_recursao_func-1]->categoria == funcao){
                        geraCodigo(NULL, "AMEM 1");
                        $$ = esquerdo_func[esquerdo_recursao_func-1]->conteudo.param.tipo;
                     }
                  }
;

lista_params:  
               lista_params VIRGULA expressao {num_params++; }
               | {printf("%d\n",num_params); }expressao {num_params++;}
;

// =========== REGRA 22 ============= //
comando_condicional:
                  if_then cond_else {
                        //fprintf(stderr, "TERMONOU O BHUR \n");
                        rotulo_a = genlabels_label_get(&p_rotulos);
                        geraCodigo (rotulo_a.rotulo, "NADA"); 
                  }
;

if_then:
         IF expressao {
            if($2 == pas_boolean){
               rotulo_a = genlabels_label_generate(&p_rotulos); // segundo rotulo que vai se usado depois
                rotulo_a = genlabels_label_generate(&p_rotulos); // segundo rotulo que vai se usado depois
               sprintf(mepa_buf, "DSVF %s",rotulo_a.rotulo);
               geraCodigo(NULL, mepa_buf);
            }else{
               exit(1);
            }
         }
         THEN comando {
            rotulo_a = p_rotulos->pilha[p_rotulos->topo-2];
            sprintf(mepa_buf, "DSVS %s",rotulo_a.rotulo);
            geraCodigo(NULL, mepa_buf);
            rotulo_a = genlabels_label_get(&p_rotulos);
            geraCodigo (rotulo_a.rotulo, "NADA"); 
         }
;

cond_else: 
               ELSE comando
              | %prec LOWER_THAN_ELSE
;                

// =========== REGRA 23 ============= //
comando_repetitivo:{
                        rotulo_a = genlabels_label_generate(&p_rotulos); //cria um rotulo mas esse e o proximo rotulo vai ser usado como fila e nao como pilha
                        geraCodigo (rotulo_a.rotulo, "NADA"); 
                     }
                     WHILE while_resto
;                     
while_resto:                     
                     expressao {
                        if($1 == pas_boolean){
                           rotulo_a = genlabels_label_generate(&p_rotulos); // segundo rotulo que vai se usado depois
                           sprintf(mepa_buf, "DSVF %s",rotulo_a.rotulo);
                           geraCodigo(NULL, mepa_buf);
                        }else{
                           abort();
                        }   
                     }
                     DO comando{
                        rotulo_a = p_rotulos->pilha[p_rotulos->topo-2];
                        sprintf(mepa_buf, "DSVS %s",rotulo_a.rotulo);
                        geraCodigo(NULL, mepa_buf);
                        rotulo_a = p_rotulos->pilha[p_rotulos->topo-1];
                        geraCodigo (rotulo_a.rotulo, "NADA"); 
                        symbols_table_pop_n(&p_rotulos, 2);
                     }
;

// =========== REGRA 25 ============= //
expressao:
            expressao_simples relacao expressao_simples{
               geraCodigo(NULL, $2);
               if ($1 == $3)
                  $$ = pas_boolean;
               else{
                  printf ("ERRO: expressao entre tipos incompativeis \n");
                  abort();
               }
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
                  if ($2 == pas_integer)
                     $$ = $2;
                  else{
                     printf ("ERRO: expresao entre tipos incompativeis \n");
                     abort();
                  }
               }
               | MENOS termo {
                  geraCodigo(NULL, "INVR");
                  if ($2 == pas_integer)
                     $$ = $2;
                  else{
                     printf ("ERRO: expresao entre tipos incompativeis \n");
                     abort();
                  }
               }
               | expressao_simples MAIS termo  {
                  geraCodigo( NULL, "SOMA");
                  if ($1 == $3 && $1 == pas_integer)
                     $$ = $3;
                  else{
                     printf ("ERRO: expresao entre tipos incompativeis \n");
                     abort();
                  }
               }
               | expressao_simples MENOS termo {
                  geraCodigo( NULL, "SUBT");
                  if ($1 == $3 && $1 == pas_integer)
                     $$ = $3;
                  else{
                     printf ("ERRO: expresao entre tipos incompativeis \n");
                     abort();
                  }
               }
               | expressao_simples OR termo {
                  geraCodigo( NULL, "DISJ");
                  if ($1 == $3 && $1 == pas_boolean)
                     $$ = $3;
                  else{
                     printf ("ERRO: expresao entre tipos incompativeis \n");
                     abort();
                  }
               }
;

termo: 
      fator  {
         $$ = $1;
      }
      | termo DIV fator  {
         geraCodigo( NULL, "DIVI");
         if ($1 == $3 && $1 == pas_integer)
            $$ = $3;
         else{
            printf ("ERRO: expresao entre tipos incompativeis \n");
            abort();
         }
      }
      | termo VEZES fator  {
         geraCodigo( NULL, "MULT");
         if ($1 == $3 && $1 == pas_integer)
            $$ = $3;
         else{
            printf ("ERRO: expresao entre tipos incompativeis \n");
            abort();
         }
      }
      | termo AND fator  {
          geraCodigo( NULL, "CONJ");
          if ($1 == $3 && $1 == pas_boolean)
            $$ = $3;
          else{
            printf ("ERRO: expresao entre tipos incompativeis \n");
            abort();
          }
      }
;

fator:
      funcao_ou_ident {
        $$ = $1;
      }
      | NUMERO {
         sprintf (mepa_buf, "CRCT %d", atoi(token));
         geraCodigo(NULL, mepa_buf);
         $$ = pas_integer;
      }   
      | VALOR_BOOL {
         if(strcmp(token, "True") == 0)
            sprintf (mepa_buf, "CRCT %d", 1);
         else
            sprintf (mepa_buf, "CRCT %d", 0);
         geraCodigo(NULL, mepa_buf);
         $$ = pas_boolean;
      }
      | ABRE_PARENTESES expressao_simples FECHA_PARENTESES{
         $$ = $2;
      }
      | NOT fator{
         if($2 == pas_boolean){
            geraCodigo(NULL, "NEGA");
            $$ = $2;
         }   
         else
            abort();
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
                  IDENT{
                     geraCodigo(NULL, "LEIT");
                     printf("buscando token %s\n", token);
                     if((ps = busca(&tabela, token)) != NULL){
                        sprintf(mepa_buf, "ARMZ %d, %d",ps->nivel , ps->deslocamento );
                        geraCodigo(NULL, mepa_buf);
                     }else{
                        printf("falha ao procurar token %s\n", token);
                        abort();
                     }
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
                     if ($1 != undefined_type)
                        geraCodigo(NULL, "IMPR");
                     else {
                        printf("parametro incompativel\n");
                     }   
                  }

;



%%

int main (int argc, const char **argv) {
   extern FILE* yyin;

   if (argc<2 || argc>2) {
      printf("usage compilador <arq>a %d\n", argc);
      return EXIT_FAILURE;
   }

   FILE *fp = fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return EXIT_FAILURE;
   }

/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */

   yyin=fp;
   yyparse();

   symbols_table_print(&tabela);

   return EXIT_SUCCESS;
}
