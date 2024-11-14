all: a.out
	mkdir -p outputFiles
	./a.out < testFiles/tinyC3_22CS30034_22CS30065_test1.c > outputFiles/tinyC3_22CS30034_22CS30065_quads1.out
	@echo "Test File 1 Successfully Translated !\n"
	./a.out < testFiles/tinyC3_22CS30034_22CS30065_test2.c > outputFiles/tinyC3_22CS30034_22CS30065_quads2.out
	@echo "Test File 2 Successfully Translated !\n"
	./a.out < testFiles/tinyC3_22CS30034_22CS30065_test3.c > outputFiles/tinyC3_22CS30034_22CS30065_quads3.out
	@echo "Test File 3 Successfully Translated !\n"
	./a.out < testFiles/tinyC3_22CS30034_22CS30065_test4.c > outputFiles/tinyC3_22CS30034_22CS30065_quads4.out
	@echo "Test File 4 Successfully Translated !\n"
	./a.out < testFiles/tinyC3_22CS30034_22CS30065_test5.c > outputFiles/tinyC3_22CS30034_22CS30065_quads5.out
	@echo "Test File 5 Successfully Translated !\n"

	@echo "\nALL TEST FILES SUCCESSFULLY TRANSLATED !! \n\n SEE FOLDER \"outputFiles\" \n\n"

a.out: lex.yy.o y.tab.o tinyC3_22CS30034_22CS30065_translator.o
	g++ -std=c++11 lex.yy.o y.tab.o tinyC3_22CS30034_22CS30065_translator.o -lfl

tinyC3_22CS30034_22CS30065_translator.o: tinyC3_22CS30034_22CS30065_translator.cxx tinyC3_22CS30034_22CS30065_translator.h
	g++ -std=c++11 -c tinyC3_22CS30034_22CS30065_translator.h
	g++ -std=c++11 -c tinyC3_22CS30034_22CS30065_translator.cxx

lex.yy.o: lex.yy.c
	g++ -std=c++11 -c lex.yy.c

y.tab.o: y.tab.c
	g++ -std=c++11 -c y.tab.c

lex.yy.c: tinyC3_22CS30034_22CS30065.l y.tab.h tinyC3_22CS30034_22CS30065_translator.h
	flex tinyC3_22CS30034_22CS30065.l

y.tab.c: tinyC3_22CS30034_22CS30065.y
	yacc -dtv tinyC3_22CS30034_22CS30065.y -Wno-yacc -Wno-precedence -Wno-conflicts-sr

y.tab.h: tinyC3_22CS30034_22CS30065.y
	yacc -dtv tinyC3_22CS30034_22CS30065.y -Wno-yacc -Wno-precedence -Wno-conflicts-sr

clean:
	rm -f lex.yy.c y.tab.c y.tab.h lex.yy.o y.tab.o tinyC3_22CS30034_22CS30065_translator.o y.output a.out tinyC3_22CS30034_22CS30065_translator.h.gch outputFiles/tinyC3_22CS30034_22CS30065_quads1.out outputFiles/tinyC3_22CS30034_22CS30065_quads2.out outputFiles/tinyC3_22CS30034_22CS30065_quads3.out outputFiles/tinyC3_22CS30034_22CS30065_quads4.out outputFiles/tinyC3_22CS30034_22CS30065_quads5.out
	rm -rf outputFiles
