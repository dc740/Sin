%{
/*
@author: Emilio Moretti
Copyright 2013 Emilio Moretti <emilio.morettiATgmailDOTcom>
This program is distributed under the terms of the GNU Lesser General Public License.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

/*#########################################
######### DECLARACIONES ###################
#########################################*/

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
//Imprimir tokens mientras se hace el parsing lexico?
//#define DEBUG_LEX_PARSER
//debugear parsing sintactico
//#define YYDEBUG 1

/**
 * *********************************************************
 * ******  Declracion de Variables y Funciones *************
 * *********************************************************
 */

/*
si el valor que se retorna si no esta en la tabla de simbolos se devuelve -1. (esto en yylval) por ej el parentesis, el punto, el signo mas... todo eso no va en la tabla de simbolos. y devuelven -1
*/


/*
limite para el id
*/
#define ID_LIMIT 25
#define CONST_LIMIT 5//5 chars to allow 65536 values (0-65535)
#define STR_LIMIT 100
#define LETRAS "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define DIGITOS "0123456789"

char* buffer; //store the code here before writting to a file
int label_counter; //create a general counter to create labels when we are parsing the code

std::ofstream arbol;

/*
intermediate code tree
*/
struct tree_node {
    int type;
    char value[100];
    char op_type[50];
    struct tree_node* left;
    struct tree_node* right;
};

typedef tree_node* p_node;
p_node tree = NULL;
//#define YYSTYPE p_node
void init_readable_tokens();

/*
We have to explicitly define yyerror
*/
void yyerror(const char *s);

const char* palabras_reservadas[] = {
		"int","print", "real","string"
};


// Caracter que vamos a usar para ir leyendo del archivo
char current_char;
// Archivo donde vamos a leer el codigo
FILE *program_file;





// Estructura con los datos del token
struct token {
   char nombre[100];
   int tipo;
   int longitud;
   int yylval;
};

// Estructura usada para guardar los tokens
struct nodo_token {
	int tipo;
	int yylval;
	struct nodo_token* ant;
	struct nodo_token* sig;
};

// Estructura usada para armar la tabla de simbolos
struct nodo_symbols{
	char nombre_nodo[100];
	char internal_name[100]; 
	//si es un tipo T_CONSTANT este campo se completa con el nombre de la variable que se usa en asm para referirse a la constante
	//si es un T_IDENT va el nombre del label
	//NOTA: ese valor se llena en la etapa de generación de código
	char op_type[50]; //string? real? int?
	struct nodo_symbols* ant;
	struct nodo_symbols* sig;
};

/*
Definimos las listas de tokens
*/
typedef nodo_token* lista_token;
lista_token tabla_tokens = NULL;
lista_token primer_token_tt = NULL;

/*
Definimos las listas de symbolos
*/
typedef nodo_symbols* lista_simbolos;
lista_simbolos tabla_simbolos = NULL;
lista_simbolos primer_nodo_ts = NULL;

int yylex(void);

int yyparse();

void init_token(token& t);

/*
Funciones de ayuda
*/
void error_comentario(token& t, const char* mensaje);
void imprime_nombre_TS(const char* nombre);
void imprimeLista(const lista_simbolos lista);
void imprimeListaToken(const lista_token lista);
int equal(const char* e1, const char* e2);
int buscar_nodo(const lista_simbolos lista , const char* nombre);
char* search_symbol_value(const lista_simbolos lista , int index);
void insertar_token(lista_token *lista_t , token& t);
void insertar_symbol(lista_simbolos *lista , token& t);
int buscar_reservada(char* palabra);
p_node create_tree_node(int type,const char* value,p_node left, p_node right,const char* op_type = NULL);
int imprimirArbol(p_node nodo, int index,int nodoPadre,const char* lado);
void insert_code(char* area, const char* new_code);
char * insert_text(char* original,int start_position, const char* new_code);
char * parse_n_generate(p_node nodo);
int generar_codigo();
nodo_symbols* search_symbol(const lista_simbolos list , int index);

/*
***********************************************************
******** Declaracion de las funciones de estado ***********
***********************************************************
*/

int ident_ini(token& t);
int ople(token& t);
int opmo(token& t);
int opeq(token& t);
int opxor(token& t);
int opor(token& t);
int nada(token& t);
int str_ini(token& t);
int constant_ini(token& t);
int negation(token& t);
int opand(token& t);
int opadd(token& t);
int opsub(token& t);
int opmul(token& t);
int opdiv(token& t);
int opaddspecial(token& t);
int opsubspecial(token& t);
int opmulspecial(token& t);
int opdivspecial(token& t);
int opat(token& t);
int newline(token& t);
int qmark(token& t);
int comma(token& t);
int semicolon(token& t);
int lpr(token& t);
int rpr(token& t);
int str_cont(token& t);
int str_end(token& t);
int str_last(token& t);
int lcurlyb(token& t);
int rcurlyb(token& t);
int constant_cont(token& t);
int constant_end(token& t);
int ident_cont(token& t);
int ident_end(token& t);
int comment1_ini(token& t);
int comment1_cont(token& t);
int comment1_end(token& t);
int comment2_ini(token& t);
int comment1_last(token& t);
int comment2_cont(token& t);
int comment2_end(token& t);
int comment2_last(token& t);



/**
 * *********************************************************
 * ************ Logica de matrices de estado ***************
 * *********************************************************
 */
static int matriz_estado [39][25]= {
{25,22,1,2,3,4,5,6,7,8,9,11,12,13,14,15,16,17,18,20,21,24,26,0,38},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,37,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,36,33,33,33,33,33,33,33,33,33,33,33,33},
{33,10,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,35,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,19,18,18,18,18,18,18},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,22,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,23,33,33,33},
{33,23,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,10,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{25,25,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,27,34,33,33,33,33,33,33,33,33,33,33,33,33},
{27,27,27,27,27,27,27,27,27,27,27,28,27,27,27,27,27,27,27,27,27,27,30,27,27},
{27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,29,27,27},
{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
{27,27,27,27,27,27,27,27,27,27,27,31,27,27,27,27,27,27,27,27,27,27,27,27,27},
{31,31,31,31,31,31,31,31,31,31,31,32,31,31,31,31,31,31,31,31,31,31,31,31,31},
{31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,27,31,31},
{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33},
{33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33,33}
};


int (*matriz_funciones [39][25])(token&) =  {
{&ident_ini,&constant_ini,&ople,&opmo,&opeq,&opxor,&negation,&opor,&opand,&nada,&nada,&nada,&opat,&qmark,&comma,&semicolon,&lpr,&rpr,&str_ini,&lcurlyb,&rcurlyb,&constant_ini,&nada,&nada,&newline},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opaddspecial,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd,&opadd},
{&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsubspecial,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub,&opsub},
{&constant_end,&constant_cont,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end},
{&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmulspecial,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul,&opmul},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_last,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont,&str_cont},
{&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end,&str_end},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&constant_end,&constant_cont,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_cont,&constant_end,&constant_end,&constant_end},
{&constant_end,&constant_cont,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end,&constant_end},
{&nada,&constant_cont,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&ident_cont,&ident_cont,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end,&ident_end},
{&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&comment1_ini,&opdivspecial,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv,&opdiv},
{&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment2_ini,&comment1_cont,&comment1_cont},
{&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_last,&comment1_cont,&comment1_cont},
{&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end,&comment1_end},
{&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment2_ini,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont,&comment1_cont},
{&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_last,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_cont,&comment2_last,&comment2_cont,&comment2_cont},
{&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment2_end,&comment1_cont,&comment2_cont,&comment2_cont},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada},
{&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada,&nada}
};


%}
%union {
  int val;
  tree_node* pointer;
}

%token T_OPAND<val>
%token T_OPOR<val>
%token T_OPXOR<val>
%token T_OPADD<val>
%token T_OPSUB<val>
%token T_OPMUL<val>
%token T_OPDIV<val>
%token T_OPADDSPECIAL<val>
%token T_OPSUBSPECIAL<val>
%token T_OPMULSPECIAL<val>
%token T_OPDIVSPECIAL<val>
%token T_IDENT<val>
%token T_CONSTANT<val>
%token T_LPR<val>
%token T_RPR<val>
%token T_NEGATION<val>
%token T_NEWLINE<val>
%token PR_TYPEINT<val>
%token PR_TYPESTR<val>
%token PR_TYPEREAL<val>
%token T_AT<val>
%token T_STR<val>
%token T_OPEQ<val>
%token T_OPMO<val>
%token T_OPLE<val>
%token T_QMARK<val>
%token T_COMMA<val>
%token T_SEMICOLON<val>
%token T_LCURLYB<val>
%token T_RCURLYB<val>
%token PR_PRINT<val>
%type <val> T_IDENT T_OPAND T_OPOR T_OPXOR T_OPADD T_OPSUB T_OPMUL T_OPDIV T_OPADDSPECIAL T_OPSUBSPECIAL T_OPMULSPECIAL T_OPDIVSPECIAL T_CONSTANT T_LPR T_RPR T_NEGATION T_NEWLINE PR_TYPEINT PR_TYPESTR PR_TYPEREAL T_AT T_STR T_OPEQ T_OPMO T_OPLE T_QMARK T_COMMA T_SEMICOLON T_LCURLYB T_RCURLYB PR_PRINT
%type <pointer> start block operation expr str_expr addsub t f special_assignation assignation vardecl if_expr cycle print comparation_eq comparation_more comparation_less comparation_more_eq comparation_less_eq comparations cycle_cond
%start start

%%


/*#########################################
############## BNF ########################
#########################################*/
start : block{tree=$1} //el tope del arbol
block : operation nuevas_lineas {const char* code = "block";
		$$=create_tree_node(-3,code,$1, NULL);}
      | block operation nuevas_lineas {const char* code = "block";
		$$=create_tree_node(-2,code,$1, $2);}
operation : special_assignation {$$=$1}
          | assignation {$$=$1}
          | vardecl {$$=$1}
          | if_expr {$$=$1}
          | cycle {$$=$1}
          | print {$$=$1}
expr : expr T_OPAND addsub {const char* code = "and";
		$$=create_tree_node(T_OPAND,code,$1, $3);}
     | expr T_OPOR addsub {const char* code = "or";
		$$=create_tree_node(T_OPOR,code,$1, $3);}
     | expr T_OPXOR  addsub {const char* code = "xor";
		$$=create_tree_node(T_OPXOR,code,$1, $3);}
     | addsub {$$=$1}
addsub : addsub T_OPADD t {const char* code = "add";
		$$=create_tree_node(T_OPADD,code,$1, $3);}
       | addsub T_OPSUB t {const char* code = "sub";
		$$=create_tree_node(T_OPSUB,code,$1, $3);}
       | t {$$=$1}
t : t T_OPMUL f {const char* code = "mul";
		$$=create_tree_node(T_OPMUL,code,$1, $3);}
  | t T_OPDIV f {const char* code = "div";
		$$=create_tree_node(T_OPDIV,code,$1, $3);}
  | f {$$=$1}
f : T_IDENT {
		//const char* value = search_symbol_value(primer_nodo_ts , $1); //devolvemos el nombre del identificador
		char ident_position[10];
                snprintf(ident_position, 10, "%d", $1);
		$$=create_tree_node(T_IDENT,ident_position,NULL, NULL);
	}
  | T_CONSTANT {
		const char* value = search_symbol_value(primer_nodo_ts ,  $1); //devolvemos el valor de la constante
                char constant_position[10];
                snprintf(constant_position, 10, "%d", $1);
                const char * type;
                if (strchr(value,'.') != NULL){
					type = "real";
                }
                else
                {
					type = "int";
                }
                $$=create_tree_node(T_CONSTANT,constant_position,NULL, NULL,type);
		
	}
  | T_LPR  expr  T_RPR {$$=$2;}
  | T_NEGATION T_LPR  expr T_RPR {const char* code = "negation"; $$=create_tree_node(T_NEGATION,code,$3, NULL);}


nuevas_lineas :  nuevas_lineas T_NEWLINE | T_NEWLINE

/*
variable assignation
*/


assignation : expr T_AT T_IDENT {//const char* value = search_symbol_value(primer_nodo_ts , $3); //devolvemos el nombre del identificador
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				$$=create_tree_node(T_AT,"at",$1, ident_node);}
            | str_expr T_AT T_IDENT {//const char* value = search_symbol_value(primer_nodo_ts , $3);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				$$=create_tree_node(T_AT,"strat",$1, ident_node);}

special_assignation: expr T_OPADDSPECIAL T_IDENT {
		        char var_position[100];
                snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				const char* code = "add";
				p_node add_node=create_tree_node(T_OPADD,code,$1, ident_node);
				$$=create_tree_node(T_AT,"at",add_node, ident_node);}
		   | expr T_OPSUBSPECIAL T_IDENT {
				char var_position[100];
                snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				const char* code = "sub";
				p_node sub_node=create_tree_node(T_OPSUB,code,$1, ident_node);
				$$=create_tree_node(T_AT,"at",sub_node, ident_node);
		   }
		   | expr T_OPMULSPECIAL T_IDENT {
				char var_position[100];
				snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				const char* code = "mul";
				p_node mul_node=create_tree_node(T_OPMUL,code,$1, ident_node);
				$$=create_tree_node(T_AT,"at",mul_node, ident_node);
		   }
		   | expr T_OPDIVSPECIAL T_IDENT {
				char var_position[100];
                snprintf(var_position, 100, "%d", $3);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				const char* code = "div";
				p_node div_node=create_tree_node(T_OPDIV,code,$1, ident_node);
				$$=create_tree_node(T_AT,"at",div_node, ident_node);
		   }

/*
variable declaration
*/
vardecl : PR_TYPEINT T_IDENT {//const char* value = search_symbol_value(primer_nodo_ts , $2);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $2);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				$$=create_tree_node(PR_TYPEINT,"intdecl",ident_node, NULL);}
        | PR_TYPESTR T_IDENT {//const char* value = search_symbol_value(primer_nodo_ts , $2);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $2);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				$$=create_tree_node(PR_TYPESTR,"strdecl",ident_node, NULL);}
        | PR_TYPEREAL T_IDENT {//const char* value = search_symbol_value(primer_nodo_ts , $2);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $2);
				p_node ident_node = create_tree_node(T_IDENT,var_position,NULL, NULL);
				$$=create_tree_node(PR_TYPEREAL,"realdecl",ident_node, NULL);}
	| PR_TYPEINT assignation {$$=create_tree_node(PR_TYPEINT,"initialized_intdecl",$2, NULL);}
        | PR_TYPESTR assignation {$$=create_tree_node(PR_TYPESTR,"initialized_strdecl",$2, NULL);}
        | PR_TYPEREAL assignation {$$=create_tree_node(PR_TYPEREAL,"initialized_realdecl",$2, NULL);}

/*
Strings operations
*/
str_expr :  T_STR {//const char* value = search_symbol_value(primer_nodo_ts , $1);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $1);
		$$ = create_tree_node(T_STR,var_position,NULL, NULL,"string");}
            | str_expr T_OPADD  T_STR   {//const char* value = search_symbol_value(primer_nodo_ts , $3);
		                char var_position[100];
                                snprintf(var_position, 100, "%d", $3);
		p_node string_node = create_tree_node(T_STR,var_position,NULL, NULL);
		$$ = create_tree_node(T_OPADD,"addstr",$1, string_node,"string");}

/*
comp
*/
comparation_eq : expr T_OPEQ expr {$$ = create_tree_node(T_OPEQ,"eq",$1, $3);}
               | str_expr T_OPEQ str_expr  {$$ = create_tree_node(T_OPEQ,"streq",$1, $3);}
comparation_more : expr T_OPMO expr {$$ = create_tree_node(T_OPMO,"mo",$1, $3);}
               | str_expr T_OPMO str_expr {$$ = create_tree_node(T_OPMO,"strmo",$1, $3);}
comparation_less : expr T_OPLE expr {$$ = create_tree_node(T_OPLE,"le",$1, $3);}
               | str_expr T_OPLE str_expr  {$$ = create_tree_node(T_OPLE,"strle",$1, $3);}
comparation_more_eq : expr T_OPMO T_OPEQ expr {$$ = create_tree_node(T_OPEQ,"moeq",$1, $4);}
               | str_expr T_OPMO T_OPEQ str_expr  {$$ = create_tree_node(T_OPEQ,"strmoeq",$1, $4);}
comparation_less_eq : expr T_OPLE T_OPEQ expr {$$ = create_tree_node(T_OPEQ,"leeq",$1, $4);}
               | str_expr T_OPLE T_OPEQ str_expr {$$ = create_tree_node(T_OPEQ,"strleeq",$1, $4);}


/*
IF
*/
comparations :  comparation_eq  {$$=$1;}
              | comparation_more  {$$=$1;}
              | comparation_less  {$$=$1;}
              | comparation_more_eq  {$$=$1;}
              | comparation_less_eq  {$$=$1;}


if_expr : comparations  T_QMARK nuevas_lineas block T_COMMA nuevas_lineas block T_SEMICOLON {
										p_node tmp = create_tree_node(T_QMARK,"ifelse",$4, $7); 
										$$= create_tree_node(T_QMARK,"if",$1,tmp); 
										}
	| comparations T_QMARK nuevas_lineas block T_SEMICOLON  {$$ = create_tree_node(T_QMARK,"if",$1,$4);}


/*
Cycles. You can do for, while, and repeat-until loops using the
following syntax
*/
cycle_cond : comparations  {$$ = create_tree_node(-1, "cyclecond", NULL, $1);}
           | block comparations {$$ = create_tree_node(-1, "cyclecond", $1, $2);}

cycle : T_LCURLYB cycle_cond T_RCURLYB  nuevas_lineas block T_SEMICOLON {$$ = create_tree_node(T_LCURLYB,"cycle",$2,$5);}
      | T_LCURLYB cycle_cond T_RCURLYB T_SEMICOLON  {$$ = create_tree_node(T_LCURLYB,"cycle",$2,NULL);}


/*
output
*/
print : PR_PRINT T_LPR expr T_RPR {$$ = create_tree_node(PR_PRINT, "print",$3,NULL);}
       | PR_PRINT T_LPR str_expr T_RPR  {$$ = create_tree_node(PR_PRINT, "strprint",$3,NULL);}
%%
/*
* ***********************************************************
* **************** IMPLEMENTACION LEXICA ********************
* ***********************************************************
*/

p_node create_tree_node(int type,const char* value,p_node left, p_node right,const char* op_type){
	p_node new_node = new(tree_node);
	
	strcat(new_node->value,value);
	if (op_type){
		snprintf(new_node->op_type,50,op_type);
	}
	else{
		snprintf(new_node->op_type,50,"__");
	}
	new_node->type = type;
	if (left != NULL){
		new_node->left = left;
	   }
	if (right != NULL){
		new_node->right = right;
	   }
	return new_node;
}

// yyerror llamado por bison
void yyerror(const char *s){
printf("## Error: %s\n\n",s);
exit(-1);
}

void error_comentario(token& t, const char* mensaje){
	printf("## Error: %s\n\n", mensaje);
	exit(1);
}

int imprimirArbol(p_node nodo, int index,int nodoPadre,const char* lado){
int aux=index;
if (nodo->left){
    aux++;
    aux=imprimirArbol(nodo->left, aux,index,"izq");
}
if (nodo->right){
    aux++;
    aux=imprimirArbol(nodo->right, aux,index,"der");
}
//printf("Nodo:%i -- Padre: %i -- Lado: %s --Tipo: %i -- Valor: %s\n",index,nodoPadre,lado,nodo->type,nodo->value);
arbol << "Nodo: " << index << "-- Padre:" << nodoPadre << " -- Lado: " << lado << " --Tipo: " << nodo->type << " -- Valor: " << nodo->value << std::endl;
return aux;
}


void imprime_nombre_TS(const char* nombre){
  printf("Tabla de simbolos %s\n\n",nombre);
}

void imprimeLista(const lista_simbolos lista){
	  //guardar el buffer en un archivo
	  std::ofstream out("Tabla.txt");
	  if(! out)
	  {  
		std::cout<<"Cannot open output file\n";
		   exit(-1);
	  }
	  
	  out << "Tabla de simbolos: " << std::endl;
	  
    lista_simbolos act;
    act = lista;
    if(lista!=NULL){
        while(act->sig!=NULL){
            //printf("Simbolo: %s\n", act->nombre_nodo);
            out << "Simbolo: " << (act->nombre_nodo) << std::endl;
            act = act->sig;
        }
    }
    out << "Simbolo: " << (act->nombre_nodo) << std::endl;
    out.close();
    
    
}

void imprimeListaToken(const lista_token lista){
    lista_token act;
	act = lista;
    if(lista!=NULL){
        while(act->sig!=NULL){
            printf("Tipo Token: %d\n", act->tipo);
            act = act->sig;
        }
    }
    printf("Tipo Token: %d\n", act->tipo);
    printf("Fin lista token\n\n");
}

int equal(const char* e1, const char* e2){
  if(e1 == e2)
    return 0;
  else
    return 1;
}

/*
Search position.
Given a symbol index, it returns the value from the symbol table
*/
char* search_symbol_value(const lista_simbolos lista , int index){
	int posicion = -1;
	lista_simbolos act;
	act = lista;

	for (int i=0;i<index;i++){
			act = act->sig;
		}
	
	return act->nombre_nodo;
}

nodo_symbols* search_symbol(const lista_simbolos list , int index){
	int posicion = -1;
	lista_simbolos act;
	act = list;

	for (int i=0;i<index;i++){
			act = act->sig;
		}
	
	return act;
}



/**
 * Si encuentra el token, retorna la posicion sino retorna -1
 */
int buscar_nodo(const lista_simbolos lista , const char* nombre){
	int posicion = -1;
	lista_simbolos act;
	act = lista;
	if(act!=NULL){
		int aux = 0;
		// Si la lista no es vacia y no encontro el token, sigue buscando
		while(act!=NULL){

			if (strcmp(act->nombre_nodo,nombre)!=0){
				act = act->sig;
				aux++;
			}
			else {
				break;
			}
		}
		// Si la lista no es vacia y no encontro el token, retorna -1
		//if(act!=NULL && strcmp(act->nombre_nodo,nombre)!=0){
		// Si es != de null es porque salio porque los strings son iguales
		if(act!=NULL){
			posicion = aux;
		}
		else {
			// Si es null, es porque llego al final y no encontro nada
			posicion = -1;
		}
	}
	return posicion;
}

void insertar_token(lista_token *lista_t , token& t){
	lista_token nuevo_nodo;
	//nuevo_nodo = (lista_token)malloc(sizeof(lista_token));
	nuevo_nodo = new(nodo_token);

	// Si la lista viene vacia, la inicializa con el primero
	if((*lista_t)==NULL){
		//strcpy(nuevo_nodo->tipo, t.tipo);
		nuevo_nodo->tipo = t.tipo;
		nuevo_nodo->yylval = t.yylval;
		nuevo_nodo->sig = NULL;
		nuevo_nodo->ant = NULL;
		(*lista_t)= nuevo_nodo;
		primer_token_tt = nuevo_nodo;
	}
	// Agrega al final el nuevo token
	else {
		nuevo_nodo->tipo = t.tipo;
		//strcpy(nuevo_nodo->tipo, t.tipo);
		nuevo_nodo->yylval = t.yylval;
		(*lista_t)->sig = nuevo_nodo;
		nuevo_nodo->ant = (*lista_t);
		nuevo_nodo->sig = NULL;

		(*lista_t)= nuevo_nodo;
	}
	//imprimeLista(primera_nodo);
}

void insertar_symbol(lista_simbolos *lista , token& t){
    int busqueda = buscar_nodo(primer_nodo_ts, t.nombre);
    if(busqueda != -1){
		t.yylval = busqueda;
	}
	else {
		lista_simbolos nuevo;
		//nuevo = (lista_simbolos)malloc(sizeof(lista_simbolos));
		nuevo = new(nodo_symbols);

		// Si la lista viene vacia, la inicializa con el primero
		if((*lista)==NULL){
			strcpy(nuevo->nombre_nodo, t.nombre);
			(*lista)= nuevo;
			strncpy(nuevo -> internal_name,"__",2);
			nuevo->sig = NULL;
			nuevo->ant = NULL;
			primer_nodo_ts = nuevo;
		}
		// Agrega al final el nuevo token
		else {
			strcpy(nuevo->nombre_nodo, t.nombre);
			(*lista)->sig = nuevo;
			strncpy(nuevo -> internal_name,"__",2);
			nuevo->ant = (*lista);
			nuevo->sig = NULL;
			(*lista) = nuevo;
		}
	}
	//imprimeLista(primera_nodo);
}

/**
 * Retorna la posicion si la palabra es reservada, sino retorna -1
 */
int buscar_reservada(char* palabra){
	/* Busqueda binaria en vector ordenado. */
	int encontrado = -1;
	int izquierda = 0;
	int centro = 0;

	int derecha = sizeof(palabras_reservadas) / sizeof(palabras_reservadas[0]);
	derecha--;
	while ((encontrado == -1) && (izquierda <= derecha)) {
		centro = (izquierda + derecha) / 2;
		if (strcmp(palabra, palabras_reservadas[centro]) < 0) {
			derecha = centro - 1;
		}
		else {
			if (strcmp(palabra, palabras_reservadas[centro]) > 0)
				izquierda = centro + 1;
			else
				encontrado = centro;
		}
	}
	return encontrado;
}

int get_evento(char c){
    int result;

    switch(c){
        case '<':
             result = 2;
             break;
        case '>':
             result = 3;
             break;
        case '=':
             result = 4;
             break;
        case '!':
             result = 5;
             break;
        case '~':
             result = 6;
             break;
        case '|':
             result = 7;
             break;
        case '&':
             result = 8;
             break;
        case '+':
             result = 9;
             break;
        case '-':
             result = 10;
             break;
        case '*':
             result = 11;
             break;
        case '@':
             result = 12;
             break;
        case '?':
             result = 13;
             break;
        case ',':
             result = 14;
             break;
        case ';':
             result = 15;
             break;
        case '(':
             result = 16;
             break;
        case ')':
             result = 17;
             break;
        case '\'':
             result = 18;
             break;
        case '{':
             result = 19;
             break;
        case '}':
             result = 20;
             break;
        case '.':
             result = 21;
             break;
        case '/':
             result = 22;
             break;
        case ':':
             result = 24;
             break;
         case '\t':
             result = 23;
             break;
        case '\n':
             result = 24;
             break;
         case ' ':
             result = 23;
             break;

        default :
            if(NULL != strchr(LETRAS,c)){
                    result = 0;
            }
            else {
                if(NULL != strchr(DIGITOS,c)){
                    result = 1;
                }
                else {
                    result = 100;
                }
            }
            break;
     }
     return result;
}


/*
***********************************************************
********** Inicio de las funciones de estado **************
***********************************************************
*/
int ident_ini(token& t){
	t.longitud = 0;
	t.nombre[t.longitud] = current_char;
	t.longitud++;
	//printf("Inicio ID: %d %c \n", t.longitud, current_char);
}
int ident_cont(token& t){
	if (t.longitud < ID_LIMIT){
        t.nombre[t.longitud] = current_char;
        t.longitud++;
        }
	else{
		char error_msg[100];
		strcat(error_msg,"La variable ");
 		strcat(error_msg,t.nombre);
		strcat(error_msg," exede la cantidad de caracteres permitidos.");
		error_comentario(t, error_msg);
	}
}
int ident_end(token& t){
	int reservada = buscar_reservada(t.nombre);
	if (reservada != -1){
		switch(reservada){
		case 0:
			t.tipo = PR_TYPEINT;
			break;
		case 1:
			t.tipo = PR_PRINT;
			break;
		case 2:
			t.tipo = PR_TYPEREAL;
			break;
		case 3:
			t.tipo = PR_TYPESTR;
			break;
		}
		//printf("Palabra reservada %s ,tipo %i\n", t.nombre,t.tipo);
		t.yylval = -1;
	}
	else {
		t.tipo = T_IDENT;
		insertar_symbol(&tabla_simbolos, t);
		//printf("Identificador %s. Nombre nodo actual: %s\n", t.nombre, tabla_simbolos->nombre_nodo);
		t.yylval = buscar_nodo(primer_nodo_ts, t.nombre);
	}
	insertar_token(&tabla_tokens, t);
	//printf("Fin ID. Longitud: %d current_char: %c tipo: %d \n", t.longitud, current_char, t.tipo);
	return t.yylval;
}
int ople(token& t){
	t.tipo = T_OPLE;
	insertar_token(&tabla_tokens, t);
	//printf("Token <\n");
	t.yylval = -1;
	return t.yylval;
}
int opmo(token& t){
	t.tipo = T_OPMO;
	insertar_token(&tabla_tokens, t);
	//printf("Token >\n");
	t.yylval = -1;
	return t.yylval;
	}

int opeq(token& t){
	t.tipo = T_OPEQ;
	insertar_token(&tabla_tokens, t);
	//printf("Token =\n");
	t.yylval = -1;
	return t.yylval;
}
int opxor(token& t){
	t.tipo = T_OPXOR;
	insertar_token(&tabla_tokens, t);
	//printf("Token !\n");
	t.yylval = -1;
	return t.yylval;
}
int opor(token& t){
	t.tipo = T_OPOR;
	insertar_token(&tabla_tokens, t);
	//printf("Token |\n");
	t.yylval = -1;
	return t.yylval;
}
int nada(token& t){
}
int newline(token& t){
	t.tipo = T_NEWLINE;
	insertar_token(&tabla_tokens, t);
	//printf("Token = NEW LINE\n");
	t.yylval = -1;
	return t.yylval;
}
int str_ini(token& t){
	t.longitud = 0;
	//t.nombre[t.longitud] = current_char;
	//t.longitud++;
	//printf("Inicio String: %d %c \n", t.longitud, current_char);
}
int str_cont(token& t){
	if (t.longitud < STR_LIMIT){
        t.nombre[t.longitud] = current_char;
        t.longitud++;
        }
	else{
		char error_msg[100];
		strcat(error_msg,"La variable ");
 		strcat(error_msg,t.nombre);
		strcat(error_msg," exede la cantidad de caracteres permitidos.");
		error_comentario(t, error_msg);
	}
}

int str_last(token& t){
}

int str_end(token& t){

	t.tipo = T_STR;
	insertar_symbol(&tabla_simbolos, t);
	//printf("String %s. Nodo actual: %s\n", t.nombre, tabla_simbolos->nombre_nodo);

	insertar_token(&tabla_tokens, t);
	//printf("Fin String. Longitud: %d current_char: %c tipo: %d \n", t.longitud, current_char, t.tipo);
	t.yylval = buscar_nodo(primer_nodo_ts, t.nombre);
	return t.yylval;
}

int constant_ini(token& t){
	t.longitud = 0;
	t.nombre[t.longitud] = current_char;
	t.longitud++;
	//printf("Inicio CONST. longitud:%d current_char:%c \n", t.longitud, current_char);
}
int constant_cont(token& t){
	if (t.longitud < CONST_LIMIT){
		t.nombre[t.longitud] = current_char;
		t.longitud++;
        }
	else{
		char error_msg[100];
		strcat(error_msg,"La variable ");
 		strcat(error_msg,t.nombre);
		strcat(error_msg," exede la cantidad de caracteres permitidos.");
		error_comentario(t, error_msg);
	}
}
int constant_end(token& t){
	t.tipo = T_CONSTANT;
        insertar_symbol(&tabla_simbolos, t);
	//printf("Constante %s Nodo actual:%s\n", t.nombre, tabla_simbolos->nombre_nodo);

	insertar_token(&tabla_tokens, t);
	//printf("Fin Constante. Longitud: %d current_char: %c tipo: %d \n", t.longitud, current_char, t.tipo);
	t.yylval = buscar_nodo(primer_nodo_ts, t.nombre);
	return t.yylval;
}
int negation(token& t){
	t.tipo = T_NEGATION;
	insertar_token(&tabla_tokens, t);
	//printf("Token ~\n");
	t.yylval = -1;
	return t.yylval;
	}
int opand(token& t){
	t.tipo = T_OPAND;
	insertar_token(&tabla_tokens, t);
	//printf("Token &\n");
	t.yylval = -1;
	return t.yylval;
	}
int opadd(token& t){
	t.tipo = T_OPADD;
	insertar_token(&tabla_tokens, t);
	//printf("Token +\n");
	t.yylval = -1;
	return t.yylval;
	}
int opaddspecial(token& t){
	t.tipo = T_OPADDSPECIAL;
	insertar_token(&tabla_tokens, t);
	//printf("Token +@\n");
	t.yylval = -1;
	return t.yylval;
	}
int opsub(token& t){
	t.tipo = T_OPSUB;
	insertar_token(&tabla_tokens, t);
	//printf("Token -\n");
	t.yylval = -1;
	return t.yylval;
	}
int opsubspecial(token& t){
	t.tipo = T_OPSUBSPECIAL;
	insertar_token(&tabla_tokens, t);
	//printf("Token -@\n");
	t.yylval = -1;
	return t.yylval;
	}
int opmul(token& t){
	t.tipo = T_OPMUL;
	insertar_token(&tabla_tokens, t);
	//printf("Token *\n");
	t.yylval = -1;
	return t.yylval;
	}
int opmulspecial(token& t){
	t.tipo = T_OPMULSPECIAL;
	insertar_token(&tabla_tokens, t);
	//printf("Token *@\n");
	t.yylval = -1;
	return t.yylval;
	}
int opat(token& t){
	t.tipo = T_AT;
	insertar_token(&tabla_tokens, t);
	//printf("Token @\n");
	t.yylval = -1;
	return t.yylval;
	}
int qmark(token& t){
	t.tipo = T_QMARK;
	insertar_token(&tabla_tokens, t);
	//printf("Token ?\n");
	t.yylval = -1;
	return t.yylval;
}
int comma(token& t){
	t.tipo = T_COMMA;
	insertar_token(&tabla_tokens, t);
	//printf("Token ,\n");
        t.yylval = -1;
	return t.yylval;
}
int semicolon(token& t){
	t.tipo = T_SEMICOLON;
	insertar_token(&tabla_tokens, t);
	//printf("Token ;\n");
	t.yylval = -1;
	return t.yylval;
	}
int lpr(token& t){
	t.tipo = T_LPR;
	insertar_token(&tabla_tokens, t);
	//printf("Token (\n");
	t.yylval = -1;
	return t.yylval;
}
int rpr(token& t){
	t.tipo = T_RPR;
	insertar_token(&tabla_tokens, t);
	//printf("Token )\n");
	t.yylval = -1;
	return t.yylval;
}
int lcurlyb(token& t){
	t.tipo = T_LCURLYB;
	insertar_token(&tabla_tokens, t);
	//printf("Token {\n");
	t.yylval = -1;
	return t.yylval;
}
int rcurlyb(token& t){
	t.tipo = T_RCURLYB;
	insertar_token(&tabla_tokens, t);
	//printf("Token }\n");
	t.yylval = -1;
	return t.yylval;
}
int opdiv(token& t){
	t.tipo = T_OPDIV;
	insertar_token(&tabla_tokens, t);
	//printf("Token /\n");
	t.yylval = -1;
	return t.yylval;
}
int opdivspecial(token& t){
	t.tipo = T_OPDIVSPECIAL;
	insertar_token(&tabla_tokens, t);
	//printf("Token /@\n");
		t.yylval = -1;
	return t.yylval;
}
int comment1_ini(token& t){
}
int comment1_cont(token& t){
}
int comment1_end(token& t){
}
int comment2_ini(token& t){
}
int comment1_last(token& t){
}
int comment2_cont(token& t){
}
int comment2_end(token& t){
}
int comment2_last(token& t){
}
/*
***********************************************************
********** Fin de las funciones de estado *****************
***********************************************************
*/




/**
 * Inicializamos estructura en vacio
 */
void init_token(token& t){
	// Inicializamos el vector en vacio
	memset(t.nombre, 0, 100);
	t.longitud = 0;
	t.yylval = -1;
}

int yylex(void){
	if (feof(program_file)!=0){
		return 0; //if this is the end of file, do not parse anymore!
		}
	token t;
	init_token(t);
	int estado = 0;
	int final = 33;
	int columna = 0;
	while (estado != final){
		columna = get_evento(current_char);
		(*matriz_funciones[estado][columna])(t);
		estado = matriz_estado[estado][columna];
		if  (estado != final){
			current_char = getc(program_file);
			if (feof(program_file)!=0){
				current_char = ' '; //if this is the end of file, end the token
			}
		}
	}
#ifdef DEBUG_LEX_PARSER
		printf("## %i. Tipo: %s. %s\n",t.tipo,buscar_string_legible(t.tipo),t.nombre);
#endif
	yylval.val = t.yylval;
	return t.tipo;
}


void insert_code(char* area, const char* new_code){
	int buffer_len = strlen(buffer);
	int new_code_len=strlen(new_code);
	int destination_len = buffer_len  + new_code_len;
	char* destination = new char[destination_len+1];
	char* pointer_to_area;
	if (strcmp(".data",area)==0){
		pointer_to_area = strstr (buffer,"#1#");
	}
	else if (strcmp(".bss",area)==0){
		pointer_to_area = strstr (buffer,"#2#");
	}
	else{//.text
		pointer_to_area = strstr (buffer,"#3#");
	}
	int position = pointer_to_area - buffer;
	strncpy(destination,buffer,position); //now we are ready to insert the new code in destination
	strncpy(destination+position,new_code,new_code_len);//and the final step is to copy the remainig chars from the buffer
	strncpy(destination+position+new_code_len,buffer + position,buffer_len - position);
	destination[destination_len] = '\0';
	delete(buffer);
	buffer = destination;
}

char * insert_text(char* original,int start_position, const char* new_code){
	int buffer_len = strlen(original);
	int new_code_len=strlen(new_code);
	int destination_len = buffer_len  + new_code_len;
	char* destination = new char[destination_len +1];

	strncpy(destination,original,start_position); //now we are ready to insert the new code in destination
	strncpy(destination+start_position,new_code,new_code_len);//and the final step is to copy the remainig chars from the buffer
	strncpy(destination+start_position+new_code_len,original + start_position,buffer_len - start_position);
	delete(original);
	destination[destination_len] = '\0';
	return destination;
}

int generar_codigo(){
    //let's create a temporary buffer to store the information
	std::ifstream is;
	is.open ("bootstrap.asm", std::ios::binary );
    if (!is)
    {
		std::cout << "error opening bootstrap file." << std::endl;
		exit(-1);
    }
    
	// get length of file:
	is.seekg (0, std::ios::end);
	int length = is.tellg();
	is.seekg (0, std::ios::beg);

	// allocate memory:
	buffer = new char [length+1]; //+1 because we store the end of string after the code

	// read data as a block:
	is.read (buffer,length);
	is.close();
	
	buffer[length] = '\0';
	//the buffer is full now
	parse_n_generate(tree);
}

void deduce_op_type(p_node node,char * left_node_type, char * right_node_type){
	if (strstr(left_node_type,"__") == NULL){
		snprintf(node -> op_type,50,left_node_type);
	}
	else if (strstr(left_node_type,"__") == NULL){
		snprintf(node -> op_type,50,right_node_type);
	}
	else{
		snprintf(node -> op_type,50,"__");
	}
}

char * switch_functions(p_node node,char * left_label, char * right_label){
	
	char * left_value;
	char * right_value;
	char * value = node -> value;
	char * dot_pointer;
	int ts_position = 0;
	int type = node -> type;
	int label_len = 0;
	int code_buffer_len = 500;
	int last_label_pos = 0;
	nodo_symbols* ident_symbol;
	char * variable_label;
	char * code_buffer = new char [code_buffer_len];
	char * return_label = new char [code_buffer_len];;
	if (node -> left != NULL){
	left_value = node -> left -> value;
	}
	if (node -> right != NULL){
	right_value = node -> right -> value;
	}
	
	switch(type){
		case T_IDENT: 	//T_IDENT (ts_position,NULL, NULL)
			ts_position = atoi(value);
			ident_symbol = search_symbol(primer_nodo_ts , ts_position);
			snprintf(node -> op_type,50,ident_symbol->op_type);
			
			snprintf(ident_symbol-> internal_name,code_buffer_len,"__%s",ident_symbol->nombre_nodo);
			snprintf(code_buffer,code_buffer_len,"%s_%d:\nmov (%s),%%eax\npushl %%eax\n\0",ident_symbol-> internal_name,label_counter,ident_symbol-> internal_name);
			snprintf(return_label,code_buffer_len,"%s_%d\0",ident_symbol-> internal_name,label_counter);
			label_counter++;
			insert_code(".text", code_buffer); //lets place the code where it should be
			break;
		case T_CONSTANT: //T_CONSTANT (ts_position,NULL, NULL)
			//the trick with constants is that we have to verify if they are already declared
			ts_position = atoi(value);
			ident_symbol = search_symbol(primer_nodo_ts , ts_position);
			dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
			
			/*
			declare the variable if it's not done
			*/
			if (strcmp(ident_symbol-> internal_name,"__") == 0){ //its not declared! let's do it
					if ( dot_pointer == NULL){ //integer
						snprintf(code_buffer, code_buffer_len, "__int_%d\0", label_counter);
						
						strncpy(ident_symbol-> internal_name,code_buffer,strlen(code_buffer));
						ident_symbol-> internal_name[strlen(code_buffer)] ='\0';
						//add code to declare the variable
						snprintf(code_buffer,code_buffer_len,"def_int %s, %s\n",ident_symbol-> internal_name,ident_symbol-> nombre_nodo);				
						//code buffer is ready, let's insert it in the .data area
						insert_code(".data", code_buffer);
					}
					else{ //real
						snprintf(code_buffer, code_buffer_len, "__real_%d\0", label_counter);
						
						strncpy(ident_symbol-> internal_name,code_buffer,strlen(code_buffer));
						ident_symbol-> internal_name[strlen(code_buffer)] ='\0';
						//add code to declare the variable
						char * integer = new char[CONST_LIMIT];
						char * decimal = new char[CONST_LIMIT];
						int position = dot_pointer - ident_symbol-> nombre_nodo;
						strncpy(integer,ident_symbol-> nombre_nodo,position);
						integer[position] = '\0';
						strncpy(decimal,dot_pointer+1,CONST_LIMIT);
						
						snprintf(code_buffer,code_buffer_len,"%s:\n.float %s.%s\n",ident_symbol-> internal_name,integer,decimal);
						//code buffer is ready, let's insert it in the .data area
						insert_code(".data", code_buffer);
					}
				}

			snprintf(return_label,code_buffer_len,"%s__decl_%d\0",ident_symbol-> internal_name,label_counter);
			/*
			now insert the code to return the variable
			*/
			if ( dot_pointer != NULL){ //it's a real
				snprintf(code_buffer,code_buffer_len,"%s:\nmovl (%s),%%eax\npushl %%eax\n",return_label,ident_symbol-> internal_name);
				insert_code(".text", code_buffer);
				
			}
			else{ //it's an integer
				snprintf(code_buffer,code_buffer_len,"%s:\nxor %%eax,%%eax\nmovw (%s),%%ax\npushl %%eax\n",return_label,ident_symbol-> internal_name);
				insert_code(".text", code_buffer);
			}
			
			label_counter++;
			break;		
		case T_OPAND:  //T_OPAND ("and",expresion, expresion) (expresion results are stored in the stack)
			deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
		    //return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__and_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__and_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
            
            //regular code: this code is placed at the end of the .text area
            snprintf(code_buffer, code_buffer_len, "__and_%d:\n\0", label_counter);
			code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %eax\npopl %ebx\nand %ebx,%eax\npushl %eax\n"); //insert the text after the label
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			break;
		case T_OPOR:  //T_OPOR ("or",expresion, expresion)
			deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
			//return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__or_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__or_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
            
            //regular code: this code is placed at the end of the .text area
            snprintf(code_buffer, code_buffer_len, "__or_%d:\n\0", label_counter);
			code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %eax\npopl %ebx\nor %ebx,%eax\npushl %eax\n"); //insert the text after the label
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			break;
		case T_OPXOR:  //T_OPXOR ("xor",expresion, expresion)
			deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
			//return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__xor_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__xor_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
            
            //regular code: this code is placed at the end of the .text area
            snprintf(code_buffer, code_buffer_len, "__xor_%d:\n\0", label_counter);
			code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %eax\npopl %ebx\nxor %ebx,%eax\npushl %eax\n"); //insert the text after the label
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			break;
		case T_OPADD:  //T_OPADD ("add",expresion, expresion) T_OPADD ("addstr",expresion, string)
			deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
			ts_position = atoi(node -> left -> value);
			ident_symbol = search_symbol(primer_nodo_ts , ts_position);
			dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
				
			if (strcmp(node -> op_type, "string") == 0){
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__add_str_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__add_str_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);
				
				//regular code: this code is placed at the end of the .text area
				//snprintf(code_buffer, code_buffer_len, "__add_str_%d:\nmovl 4(%%esp),%%eax\npush %%eax\ncall strlen\npush %%eax\nmovl 4(%%esp),%%eax\npush %%eax\ncall strlen\npushl %%eax\nmovl 4(%%esp),%%ebx\nadd %%ebx,%%eax\n\npushl %%eax\n \ncall get_space\n\nmovl 12(%%esp),%%esi\nmovl 4(%%esp),%%ecx\nmov %%eax,%%edi\nrep movsb\nmovl 8(%%esp),%%esi\nmovl (%%esp),%%ecx\nrep movsb\nxor %%eax,%%eax\nstosb\nmovl 8(%%esp),%%edi\nmovl (%%esp),%%ecx\nrep stosb\nmovl 12(%%esp),%%edi\nmovl 4(%%esp),%%ecx\nrep stosb\npopl %%eax\npopl %%eax\npopl %%eax\npopl %%eax\nmovl (string_temp),%%eax\npushl %%eax\n", label_counter);
				//don't clear the variables after using them.
				snprintf(code_buffer, code_buffer_len, "__add_str_%d:\nmovl 4(%%esp),%%eax\npush %%eax\ncall strlen\npush %%eax\nmovl 4(%%esp),%%eax\npush %%eax\ncall strlen\npushl %%eax\nmovl 4(%%esp),%%ebx\nadd %%ebx,%%eax\n\npushl %%eax\n \ncall get_space\n\nmovl 12(%%esp),%%esi\nmovl 4(%%esp),%%ecx\nmov %%eax,%%edi\nrep movsb\nmovl 8(%%esp),%%esi\nmovl (%%esp),%%ecx\nrep movsb\nxor %%eax,%%eax\nstosb\npopl %%eax\npopl %%eax\npopl %%eax\npopl %%eax\nmovl (string_temp),%%eax\npushl %%eax\n", label_counter);
				insert_code(".text", code_buffer); //lets place the code where it should be
				label_counter++;
			}
			else if (strcmp(node -> op_type, "real") == 0){ //es un real
			 //return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__add_real_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__add_real_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
            
            //regular code: this code is placed at the end of the .text area
            snprintf(code_buffer, code_buffer_len, "__add_real_%d:\n\0", label_counter);
			snprintf(code_buffer, code_buffer_len,"popl %%eax\npopl %%ebx\nmov %%eax,(fbuffer)\nflds fbuffer\nmov %%ebx,fbuffer\nflds fbuffer\nfadd %%st(1),%%st\nfstps fbuffer\nmov (fbuffer),%%eax\npushl %%eax\n");
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			}

			else{
            //return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__add_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__add_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
            
            //regular code: this code is placed at the end of the .text area
            snprintf(code_buffer, code_buffer_len, "__add_%d:\n\0", label_counter);
			code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %ebx\npopl %eax\nadd %ebx,%eax\npushl %eax\n"); //insert the text after the label
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			}
			break;
		case T_OPSUB: //("sub",expresion, expresion):
            deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
			ts_position = atoi(node -> left -> value);
			ident_symbol = search_symbol(primer_nodo_ts , ts_position);
			dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
		
			if (strcmp(node -> op_type, "real") == 0){ //es un real
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__sub_real_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__sub_real_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);

				//regular code: this code is placed at the end of the .text area
				snprintf(code_buffer, code_buffer_len, "__sub_real_%d:\n\0", label_counter);
				snprintf(code_buffer, code_buffer_len,"popl %%eax\npopl %%ebx\nmov %%eax,(fbuffer)\nflds fbuffer\nmov %%ebx,fbuffer\nflds fbuffer\nfsub %%st(1),%%st\nfstps fbuffer\nmov (fbuffer),%%eax\npushl %%eax\n");
				insert_code(".text", code_buffer); //lets place the code where it should be
				label_counter++;
			}

			else{
			//return label code (this label is placed on top of the child nodes)
		    snprintf(return_label,code_buffer_len, "__sub_block_%d\0", label_counter);
		    snprintf(code_buffer, code_buffer_len, "__sub_block_%d:\n\0", label_counter);
		    last_label_pos = strstr(buffer,left_label) - buffer;
		    buffer = insert_text(buffer,last_label_pos,code_buffer);
		    
		    //regular code: this code is placed at the end of the .text area
		    snprintf(code_buffer, code_buffer_len, "__sub_%d:\n\0", label_counter);
				code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %ebx\npopl %eax\nsub %ebx,%eax\npushl %eax\n"); //insert the text after the label
				insert_code(".text", code_buffer); //lets place the code where it should be
				label_counter++;
		    	}
			break;

		case PR_TYPEINT:  //("intdecl",identificador,NULL) ("initialized_intdecl",identificador,NULL)
			snprintf(return_label,code_buffer_len, "%s_decl", left_label);
			
			if (strcmp(left_value,"at") == 0){//int initialized assignation
				ts_position = atoi(node -> left -> right -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
				snprintf(code_buffer,code_buffer_len, "%s:\n\0",return_label);
				snprintf(node -> left -> right -> op_type,50,"int");
				insert_code(".text", code_buffer);	
			}
			else { //int declaration
				ts_position = atoi(node -> left -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
				//if it was a declaration, we need to pop the value, so the stack is balanced (we pushed the value in the var node)
				snprintf(code_buffer,code_buffer_len, "%s:\npopl %%eax\n\0",return_label);
				snprintf(node -> left -> op_type,50,"int");
				insert_code(".text", code_buffer);
			}

			snprintf(node -> op_type,50,"int");
			snprintf(ident_symbol-> op_type,50,"int");
			//add code to declare the variable
			snprintf(code_buffer,code_buffer_len,"def_int ");
			code_buffer = insert_text(code_buffer,8,ident_symbol-> internal_name);
			code_buffer = insert_text(code_buffer,8+strlen(ident_symbol-> internal_name),", 0\n\0");					
			//code buffer is ready, let's insert it in the .data area
			insert_code(".data", code_buffer);
			break;
		case PR_TYPEREAL: //("realdecl",identificador)	PR_TYPEREAL("initialized_realdecl",identificador)
			snprintf(return_label,code_buffer_len, "%s_decl", left_label);
			if (strcmp(left_value,"at") == 0){//real initialized assignation
				ts_position = atoi(node -> left -> right -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
				snprintf(code_buffer,code_buffer_len, "%s:\n\0",return_label);
				snprintf(node -> left -> right -> op_type,50,"real");
				insert_code(".text", code_buffer);	
			}
			else { //real declaration
				ts_position = atoi(node -> left -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
				//if it was a simple declaration, we need to pop the value, so the stack is balanced (we pushed the value in the var node)
				snprintf(code_buffer,code_buffer_len, "%s:\npopl %%eax\n\0",return_label);
				snprintf(node -> left -> op_type,50,"real");
				insert_code(".text", code_buffer);
			}
			snprintf(ident_symbol-> op_type,50,"real");
			snprintf(node -> op_type,50,"real");
			//add code to declare the variable
			snprintf(code_buffer,code_buffer_len,"%s:\n.float 0.0\n\0",ident_symbol-> internal_name);			
			//code buffer is ready, let's insert it in the .data area
			insert_code(".data", code_buffer);
			break;
		case T_AT: //("at",expresion,identificador) ("strat",expresion,identificador)
			//return label code (this label is placed on top of the child nodes)
            snprintf(return_label,code_buffer_len, "__at_block_%d\0", label_counter);
            snprintf(code_buffer, code_buffer_len, "__at_block_%d:\n\0", label_counter);
            last_label_pos = strstr(buffer,left_label) - buffer;
            buffer = insert_text(buffer,last_label_pos,code_buffer);
			
			
			ts_position = atoi(node -> right -> value);
			ident_symbol = search_symbol(primer_nodo_ts , ts_position);

			//strings, reals and integers are treated the same. just move the 32 bits value to the destination variable. (reals are 32 bits, ints are 16 bits but allocated in 16 bits space, and strings are 32 bit pointers.)
			snprintf(code_buffer,code_buffer_len,"__at_%d:\npopl %%ebx\npopl %%eax\nmovl %%eax,(%s)\n",label_counter,ident_symbol-> internal_name);
			
			
			insert_code(".text", code_buffer); //lets place the code where it should be
			label_counter++;
			break;
		case T_QMARK: //("if",comparations,block) ("if",comparations,ifelse)	("ifelse",block,block)
			
			
			/*
			pop eax.
			eax == 0 -> true
			eax == 1 -> false
			*/
			if (strcmp(node -> value,"ifelse") == 0){ // ("ifelse",block,block)
				snprintf(return_label,code_buffer_len, right_label);	//return else label
				snprintf(code_buffer, code_buffer_len, "__if_end_%d:\n", label_counter);
				insert_code(".text", code_buffer); 
				
				snprintf(code_buffer, code_buffer_len, "jmp __if_end_%d\n\0", label_counter);
				int right_label_pos = strstr(buffer,right_label) - buffer;
				buffer = insert_text(buffer,right_label_pos,code_buffer);
				
				//insert the comparation code above the left_label
				snprintf(code_buffer, code_buffer_len, "__if_cond_%d:\npopl %%eax\nmov $1,%%ebx\ncmp %%eax,%%ebx\nje %s\n\0", label_counter, right_label);
				int left_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,left_label_pos,code_buffer);
			}
			if ((strcmp(node -> value,"if") == 0) && (strcmp(node -> right -> value,"ifelse") == 0)){ //("if",comparations,ifelse)
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__if_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__if_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);			
			}
			if ((strcmp(node -> value,"if") == 0) && (strcmp(node -> right -> value,"ifelse") != 0)){ // ("if",comparations,block)
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__if_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__if_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);
			
				//end of if label
				snprintf(code_buffer, code_buffer_len, "__if_end_%d:\n", label_counter);
				insert_code(".text", code_buffer); 
				//return label code (this label is placed on top of the child nodes)
				snprintf(code_buffer, code_buffer_len, "__if_cond_%d:\npopl %%eax\nmov $1,%%ebx\ncmp %%eax,%%ebx\nje __if_end_%d\n\0", label_counter, label_counter);
				int right_label_pos = strstr(buffer,right_label) - buffer;
				buffer = insert_text(buffer,right_label_pos,code_buffer);
			}
			
			label_counter++;
			break;
		case T_OPEQ: //("eq",expresion, expresion) ("streq",expresion, expresion) ("leeq",expresion, expresion) ("strleeq",expresion, expresion) ("moeq",expresion, expresion) ("strmoeq",expresion, expresion)
				deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__eq_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__eq_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);
				
			
				if (strcmp(node -> op_type, "string") == 0){
					if ((strcmp(node -> value,"eq") == 0) || (strcmp(node -> value,"streq") == 0)){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__streq_%d:\npopl %%esi\npopl %%edi\ncall string_equals\npushl %%eax\n",label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
					else if ((strcmp(node -> value,"leeq") == 0) || (strcmp(node -> value,"strleeq") == 0)){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__streq_%d:\npopl %%esi\npopl %%edi\npushl %%edi\npushl %%esi\ncall string_below\npushl %%eax\nmovl 4(%%esp),%%esi\nmovl 8(%%esp),%%edi\ncall string_equals\npopl %%ebx\nand %%ebx,%%eax\npopl %%ecx\npopl %%ecx\npushl %%eax\n",label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
						}
					else if ((strcmp(node -> value,"moeq") == 0) || (strcmp(node -> value,"strmoeq") == 0)){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__streq_%d:\npopl %%esi\npopl %%edi\npushl %%edi\npushl %%esi\ncall string_above\npushl %%eax\nmovl 4(%%esp),%%esi\nmovl 8(%%esp),%%edi\ncall string_equals\npopl %%ebx\nand %%ebx,%%eax\npopl %%ecx\npopl %%ecx\npushl %%eax\n",label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
				}
				if (strcmp(node -> op_type, "int") == 0){
					if (strcmp(node -> value,"eq") == 0) { //int,string or real comparison
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__eq_%d:\npopl %%ebx\npopl %%eax\ncmp %%ebx,%%eax\nje iseq_%d\nmov $1,%%eax\njmp endeq_%d\niseq_%d:\nxor %%eax,%%eax\nendeq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
						}
					else if (strcmp(node -> value,"leeq") == 0){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__less_eq_%d:\npopl %%ebx\npopl %%eax\ncmp %%ebx,%%eax\njbe isless_%d\nmov $1,%%eax\njmp endless_eq_%d\nisless_%d:\nxor %%eax,%%eax\nendless_eq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
					else if (strcmp(node -> value,"moeq") == 0){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__more_eq_%d:\npopl %%ebx\npopl %%eax\ncmp %%ebx,%%eax\njae ismore_%d\nmov $1,%%eax\njmp endmore_eq_%d\nismore_%d:\nxor %%eax,%%eax\nendmore_eq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
						}
				}
				if (strcmp(node -> op_type, "real") == 0){
					if (strcmp(node -> value,"eq") == 0) {
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__eq_%d:\npopl %%ebx\npopl %%eax\nmov %%ebx,(fbuffer)\nflds fbuffer\nmov %%eax,(fbuffer)\nflds fbuffer\nfcomip\nfstp %%st(0) # to clear stack\nje iseq_%d\nmov $1,%%eax\njmp endeq_%d\niseq_%d:\nxor %%eax,%%eax\nendeq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
					else if (strcmp(node -> value,"leeq") == 0){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__less_eq_%d:\npopl %%ebx\npopl %%eax\nmov %%ebx,(fbuffer)\nflds fbuffer\nmov %%eax,(fbuffer)\nflds fbuffer\nfcomip\nfstp %%st(0) # to clear stack\njbe isless_%d\nmov $1,%%eax\njmp endless_eq_%d\nisless_%d:\nxor %%eax,%%eax\nendless_eq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
					else if (strcmp(node -> value,"moeq") == 0){
					//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__more_eq_%d:\npopl %%ebx\npopl %%eax\nmov %%ebx,(fbuffer)\nflds fbuffer\nmov %%eax,(fbuffer)\nflds fbuffer\nfcomip\nfstp %%st(0) # to clear stack\njae ismore_%d\nmov $1,%%eax\njmp endmore_eq_%d\nismore_%d:\nxor %%eax,%%eax\nendmore_eq_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
				}
				
				label_counter++;
			break;
		case T_LCURLYB: //("cycle",block,block) ("cycle",block,NULL)
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__cycle_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__cycle_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);
				
				snprintf(code_buffer, code_buffer_len, "__cycle_cond_%d:\npopl %%eax\nmov $1,%%ebx\ncmp %%eax,%%ebx\nje __cycle_end_%d\n\0", label_counter, label_counter);
				
				if (node -> right != NULL){ //we have a right side, we have to insert the condition between the two blocks
					int right_label_pos = strstr(buffer,right_label) - buffer;
					buffer = insert_text(buffer,right_label_pos,code_buffer);
				}
				else{ //no right side, just insert the condition after the block code
					insert_code(".text", code_buffer);
				}
				
				
				
				//end of cycle label
				snprintf(code_buffer, code_buffer_len, "jmp __cycle_block_%d\n__cycle_end_%d:\n", label_counter, label_counter);
				insert_code(".text", code_buffer);
				
				label_counter++;
			break;
		case T_OPMUL: //("mul",expresion, expresion)
				deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
				ts_position = atoi(node -> left -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);
				dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
				
				if (strcmp(node -> op_type, "real") == 0){ //es un real
					//return label code (this label is placed on top of the child nodes)
					snprintf(return_label,code_buffer_len, "__mul_real_block_%d\0", label_counter);
					snprintf(code_buffer, code_buffer_len, "__mul_real_block_%d:\n\0", label_counter);
					last_label_pos = strstr(buffer,left_label) - buffer;
					buffer = insert_text(buffer,last_label_pos,code_buffer);

					//regular code: this code is placed at the end of the .text area
					snprintf(code_buffer, code_buffer_len, "__mul_real_%d:\n\0", label_counter);
					snprintf(code_buffer, code_buffer_len,"popl %%eax\npopl %%ebx\nmov %%eax,(fbuffer)\nflds fbuffer\nmov %%ebx,fbuffer\nflds fbuffer\nfmul %%st(1),%%st\nfstps fbuffer\nmov (fbuffer),%%eax\npushl %%eax\n");
					insert_code(".text", code_buffer); //lets place the code where it should be
					label_counter++;
				}

				else{
					//return label code (this label is placed on top of the child nodes)
					snprintf(return_label,code_buffer_len, "__mul_block_%d\0", label_counter);
					snprintf(code_buffer, code_buffer_len, "__mul_block_%d:\n\0", label_counter);
					last_label_pos = strstr(buffer,left_label) - buffer;
					buffer = insert_text(buffer,last_label_pos,code_buffer);
				
					//regular code: this code is placed at the end of the .text area
					snprintf(code_buffer, code_buffer_len, "__mul_%d:\n\0", label_counter);
					code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %ebx\npopl %eax\nmul %ebx\npushl %eax\n"); //insert the text after the label
					insert_code(".text", code_buffer); //lets place the code where it should be
					label_counter++;
				}

			break;
			case T_OPDIV: // ("div",expresion, expresion)
				deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
				ts_position = atoi(node -> left -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);
				dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
			
				if (strcmp(node -> op_type, "real") == 0){ //es un real
					 //return label code (this label is placed on top of the child nodes)
				    snprintf(return_label,code_buffer_len, "__div_real_block_%d\0", label_counter);
				    snprintf(code_buffer, code_buffer_len, "__div_real_block_%d:\n\0", label_counter);
				    last_label_pos = strstr(buffer,left_label) - buffer;
				    buffer = insert_text(buffer,last_label_pos,code_buffer);
				    
				    //regular code: this code is placed at the end of the .text area
				    snprintf(code_buffer, code_buffer_len, "__div_real_%d:\n\0", label_counter);
				    snprintf(code_buffer, code_buffer_len,"popl %%eax\npopl %%ebx\nmov %%eax,(fbuffer)\nflds fbuffer\nmov %%ebx,fbuffer\nflds fbuffer\nfdiv %%st(1),%%st\nfstps fbuffer\nmov (fbuffer),%%eax\npushl %%eax\n");
				    insert_code(".text", code_buffer); //lets place the code where it should be
				    label_counter++;
				}

				else{				
	


					//return label code (this label is placed on top of the child nodes)
					snprintf(return_label,code_buffer_len, "__div_block_%d\0", label_counter);
					snprintf(code_buffer, code_buffer_len, "__div_block_%d:\n\0", label_counter);
					last_label_pos = strstr(buffer,left_label) - buffer;
					buffer = insert_text(buffer,last_label_pos,code_buffer);
				
					//regular code: this code is placed at the end of the .text area
					snprintf(code_buffer, code_buffer_len, "__div_%d:\n\0", label_counter);
					code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %ebx\npopl %eax\ndiv %ebx\npushl %eax\n"); //insert the text after the label
					insert_code(".text", code_buffer); //lets place the code where it should be
					label_counter++;
				}
			break;
			case T_OPMO: //("mo",expresion, expresion) ("strmo",expresion, expresion)
				deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__more_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__more_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);
				
				if ((strcmp(right_value,"strmo") == 0) || (strcmp(node -> op_type, "string") == 0)){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__streq_%d:\npopl %%esi\npopl %%edi\ncall string_above\npushl %%eax\n",label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
				}
				else{
					if (strcmp(node -> op_type, "int") == 0){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__more_%d:\npopl %%ebx\npopl %%eax\ncmp %%ebx,%%eax\nja ismore_%d\nmov $1,%%eax\njmp endmore_%d\nismore_%d:\nxor %%eax,%%eax\nendmore_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
						}
					else{
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__more_%d:\npopl %%ebx\npopl %%eax\nmov %%ebx,(fbuffer)\nflds fbuffer\nmov %%eax,(fbuffer)\nflds fbuffer\nfcomip\nfstp %%st(0) # to clear stack\nja ismore_%d\nmov $1,%%eax\njmp endmore_%d\nismore_%d:\n xor %%eax,%%eax\nendmore_%d:\n pushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
				}
				label_counter++;
			break;
			case T_OPLE: //("le",expresion, expresion) ("strle",expresion, expresion)
				deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
					//return label code (this label is placed on top of the child nodes)
					snprintf(return_label,code_buffer_len, "__less_block_%d\0", label_counter);
					snprintf(code_buffer, code_buffer_len, "__less_block_%d:\n\0", label_counter);
					last_label_pos = strstr(buffer,left_label) - buffer;
					buffer = insert_text(buffer,last_label_pos,code_buffer);
					
				if ((strcmp(right_value,"strmo") == 0) || (strcmp(node -> op_type, "string") == 0)){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__streq_%d:\npopl %%esi\npopl %%edi\ncall string_below\npushl %%eax\n",label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
				}
				else{
					if (strcmp(node -> op_type, "int") == 0){
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__less_%d:\npopl %%ebx\npopl %%eax\ncmp %%ebx,%%eax\njb isless_%d\nmov $1,%%eax\njmp endless_%d\nisless_%d:\nxor %%eax,%%eax\nendless_%d:\npushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
						}
					else{
						//regular code: this code is placed at the end of the .text area
						snprintf(code_buffer, code_buffer_len,"__less_%d:\npopl %%ebx\npopl %%eax\nmov %%ebx,(fbuffer)\nflds fbuffer\nmov %%eax,(fbuffer)\nflds fbuffer\nfcomip\nfstp %%st(0) # to clear stack\njb isless_%d\nmov $1,%%eax\njmp endless_%d\nisless_%d:\n xor %%eax,%%eax\nendless_%d:\n pushl %%eax\n",label_counter,label_counter,label_counter,label_counter,label_counter,label_counter);
						insert_code(".text", code_buffer); //lets place the code where it should be
					}
				}
				label_counter++;
			break;
			case T_NEGATION: //("negation",expresion, null)
				//return label code (this label is placed on top of the child nodes)
				snprintf(return_label,code_buffer_len, "__not_block_%d\0", label_counter);
				snprintf(code_buffer, code_buffer_len, "__not_block_%d:\n\0", label_counter);
				last_label_pos = strstr(buffer,left_label) - buffer;
				buffer = insert_text(buffer,last_label_pos,code_buffer);

				//regular code: this code is placed at the end of the .text area
				snprintf(code_buffer, code_buffer_len, "__not_%d:\n\0", label_counter);
				code_buffer = insert_text(code_buffer,strlen(code_buffer),"popl %eax\nnot %ax\npushl %eax\n"); //insert the text after the label
				insert_code(".text", code_buffer); //lets place the code where it should be
				label_counter++;
			break;
			case T_STR: // (ts_position,NUL,NULL)
				//the trick with constants is that we have to verify if they are already declared
				ts_position = atoi(value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);
				snprintf(node -> op_type,50,"string");
				/*
				declare the variable if it's not done
				*/
				if (strcmp(ident_symbol-> internal_name,"__") == 0){ //its not declared! let's do it
					snprintf(code_buffer, code_buffer_len, "__constant_str_%d\0", label_counter);
					strncpy(ident_symbol-> internal_name,code_buffer,strlen(code_buffer));
					ident_symbol-> internal_name[strlen(code_buffer)] ='\0';
					//add code to declare the variable
					snprintf(code_buffer,code_buffer_len,"def_str %s, \"%s\"\n",ident_symbol-> internal_name,ident_symbol-> nombre_nodo);				
					//code buffer is ready, let's insert it in the .data area
					insert_code(".data", code_buffer);
				}

				snprintf(return_label,code_buffer_len,"%s__decl_%d\0",ident_symbol-> internal_name,label_counter);
				snprintf(code_buffer,code_buffer_len,"%s:\nmovl $%s,%%eax\npushl %%eax\n",return_label,ident_symbol-> internal_name);
				insert_code(".text", code_buffer);

				label_counter++;
			break;
			case PR_TYPESTR: //("strdecl",identificador) ("initialized_strdecl",identificador) //NO TERMINADO!
				snprintf(return_label,code_buffer_len, "%s_decl", left_label);
				
				if ((strcmp(left_value,"at") == 0) || (strcmp(left_value,"strat") == 0)){//string initialized assignation
					ts_position = atoi(node -> left -> right -> value);
					ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
					snprintf(code_buffer,code_buffer_len, "%s:\n\0",return_label);
					snprintf(node -> left -> right -> op_type,50,"string");
					insert_code(".text", code_buffer);	
				}
				else { //string declaration
					ts_position = atoi(node -> left -> value);
					ident_symbol = search_symbol(primer_nodo_ts , ts_position);	
					//if it was a declaration, we need to pop the value, so the stack is balanced (we pushed the value in the var node)
					snprintf(code_buffer,code_buffer_len, "%s:\npopl %%eax\n\0",return_label);
					snprintf(node -> left -> op_type,50,"string");
					insert_code(".text", code_buffer);
				}
				snprintf(ident_symbol-> op_type,50,"string");
				snprintf(node -> op_type,50,"string");
				//add code to declare the variable
				snprintf(code_buffer,code_buffer_len,"def_int "); //def int BECAUSE WE DECLARE AN INT THAT POINTS TO A STRING
				code_buffer = insert_text(code_buffer,8,ident_symbol-> internal_name);
				code_buffer = insert_text(code_buffer,8+strlen(ident_symbol-> internal_name),", 0\n\0");					
				//code buffer is ready, let's insert it in the .data area
				insert_code(".data", code_buffer);
				break;
			case PR_PRINT: //("print",expresion,NULL)	PR_PRINT("strprint",expresion,NULL)
							deduce_op_type(node,node -> left -> op_type, node -> right -> op_type);
				ts_position = atoi(node -> left -> value);
				ident_symbol = search_symbol(primer_nodo_ts , ts_position);
				dot_pointer = strchr(ident_symbol->nombre_nodo,'.');
			
				if (strcmp(node -> op_type, "string") == 0){ //es un string
					 //return label code (this label is placed on top of the child nodes)
				    snprintf(return_label,code_buffer_len, "__print_string_%d\0", label_counter);
				    snprintf(code_buffer, code_buffer_len, "__print_string_%d:\n\0", label_counter);
				    last_label_pos = strstr(buffer,left_label) - buffer;
				    buffer = insert_text(buffer,last_label_pos,code_buffer);
				    
				    //regular code: this code is placed at the end of the .text area
				    snprintf(code_buffer, code_buffer_len, "__print_string_%d:\n\0", label_counter);
				    snprintf(code_buffer, code_buffer_len,"movl (%%esp),%%eax\npush %%eax\n call strlen\npush %%eax\nmovl 4(%%esp),%%eax\npush %%eax\ncall print_str\npop %%eax\n");
				    insert_code(".text", code_buffer); //lets place the code where it should be
				    label_counter++;
				}

				else{				
					 //return label code (this label is placed on top of the child nodes)
				    snprintf(return_label,code_buffer_len, "__print_string_%d\0", label_counter);
				    snprintf(code_buffer, code_buffer_len, "__print_string_%d:\n\0", label_counter);
				    last_label_pos = strstr(buffer,left_label) - buffer;
				    buffer = insert_text(buffer,last_label_pos,code_buffer);
				    
				    //regular code: this code is placed at the end of the .text area
				    snprintf(code_buffer, code_buffer_len, "__print_string_%d:\n\0", label_counter);
				    snprintf(code_buffer, code_buffer_len,"movb $'0',%%al\ncall putc\nmovb $'x',%%al\ncall putc\npop %%eax\nrol $16,%%eax\ncall Hex2ASCII\nrol $16,%%eax\ncall Hex2ASCII\nmovb $10,%%al\ncall putc\n");
				    insert_code(".text", code_buffer); //lets place the code where it should be
				    label_counter++;
				}
			break;
					/*
			Estas no es necesario implementarlas. El default case las abarca		
			-3 ("block",operacion,NULL)
			-2 ("block",block,operacion)
			-1("cyclecond",NULL,comparations)
			-1("cyclecond",block,comparations)
			*/
			default:
				//if it's not defined, just send the left label up!
				if (left_label!= NULL){
				snprintf(return_label,code_buffer_len, left_label);
				}
				else{
				snprintf(return_label,code_buffer_len, right_label);
				}
				break;
		}
	
	//clean up the memory used:
	if (left_label != NULL){
		delete(left_label);
		left_label = NULL;
	}
	
	if (right_label != NULL){
		delete(right_label);
		right_label = NULL;
	}
	
	
	return return_label;
}

char * parse_n_generate(p_node nodo){
	char * return_value_left = NULL;
	char * return_value_right = NULL;
	if (nodo->left){
		return_value_left=parse_n_generate(nodo->left);
	}
	if (nodo->right){
		return_value_right=parse_n_generate(nodo->right);
	}
	 //we add our code here when needed	and we also return our top code label
	return switch_functions(nodo,return_value_left,return_value_right);
}


int main(int argc, char *argv[]) {
    //yydebug = 1;
    //token t;
    char letra;
    tabla_simbolos = NULL;
    tabla_tokens = NULL;

    char* salida;
    int tipotoken;

    //Apertura del programa a compilar, de solo lectura
    program_file = fopen("./prueba.txt","r");
    if (program_file==NULL) {
       printf( "No se puede abrir el programa. \n\n" );
       exit(1);
    }

    // Leemos el primer caracter
    current_char = getc(program_file);

    yyparse();

    //Se cierra el programa de entrada.
    if (fclose(program_file)!=0)
       printf( "Problemas para cerrar el programa\n" );

	imprimeLista(primer_nodo_ts);

	  //guardar el arbol en un archivo
	  arbol.open("Intermedia.txt");
	  	  
	  if(! arbol)
	  {  
		std::cout<<"Cannot open output file\n";
		   return 1;
	  }
    arbol << "Nodos del arbol: " << std::endl;
    imprimirArbol(tree, 0,-1,"centro");
    arbol.close();
    
    generar_codigo();
	
	//guardar el buffer en un archivo
	  std::ofstream out("Final.asm");
	  if(! out)
	  {  
		std::cout<<"Cannot open output file\n";
		   return 1;
	  }
	  
	  
	  
	  out.write(buffer,strlen(buffer));
	  out.close();
}

