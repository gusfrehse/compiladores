 # -------------------------------------------------------------------
 #            Arquivo: Makefile
 # -------------------------------------------------------------------
 #              Autor: Bruno Müller Junior
 #               Data: 08/2007
 #      Atualizado em: [09/08/2020, 19h:01m]
 #
 # -------------------------------------------------------------------

$DEPURA=1

UTILS_DIR = utils

EXAMPLES_DIR = examples

compilador: lex.yy.c compilador.tab.c compilador.o compilador.h $(UTILS_DIR)/symbols_table.o $(UTILS_DIR)/genlabels.o
	gcc lex.yy.c compilador.tab.c compilador.o $(UTILS_DIR)/symbols_table.o $(UTILS_DIR)/genlabels.o -o compilador -lfl -ly -lc

lex.yy.c: compilador.l compilador.h
	flex compilador.l

compilador.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

compilador.o : compilador.h compiladorF.c
	gcc -c compiladorF.c -o compilador.o

$(UTILS_DIR)/symbols_table.o:
	$(MAKE) -C $(UTILS_DIR) symbols_table.o

$(UTILS_DIR)/genlabels.o:
	$(MAKE) -C $(UTILS_DIR) genlabels.o

clean :
	@ rm -f compilador.tab.* lex.yy.c compilador.o compilador
	@ $(MAKE) -C $(UTILS_DIR) $@

test :
	for ex in $(EXAMPLES_DIR)/*; do \
		echo -n "Testando $$ex/pgma.pas: "; \
		./compilador $$ex/pgma.pas > /dev/null 2>&1; \
		diff $$ex/MEPA MEPA > /dev/null 2>&1 && echo "OK" || echo "FAILED"; \
	done