/**
 * @file tinyC3_22CS30034_22CS30065_translator.h
 * @brief Header file for the tinyC3 translator containing class and function declarations.
 */

#ifndef _TRANSLATE_H
#define _TRANSLATE_H

#include <bits/stdc++.h>
using namespace std;

class symboltype;
class Symbol_table;
class quad;
class quadArray;
class basicType;
struct Statement;
struct arrayStructure;
struct Expression;

/**
 * @class Symbol_table
 * @brief Represents a symbol table entry.
 */
class Symbol_table {
public:
	string name; ///< Name of the symbol.
	symboltype* type; ///< Type of the symbol.
	int size; ///< Size of the symbol.
	int offset; ///< Offset of the symbol.
	Symbol_table* nested_table; ///< Pointer to nested symbol table.
	string initial_value; ///< Initial value of the symbol.
	Symbol_table* update(symboltype*); ///< Updates the symbol type.

	int count; ///< Count of symbols.
	list<Symbol_table> table; ///< List of symbols.
	Symbol_table* parent; ///< Pointer to parent symbol table.
	Symbol_table* lookup(string); ///< Looks up a symbol by name.
	void print(); ///< Prints the symbol table.
	void update(); ///< Updates the symbol table.
	Symbol_table(string name = "", string t = "int", symboltype* ptr = NULL, int width = 0); ///< Constructor.
};

/**
 * @class symboltype
 * @brief Represents the type of a symbol.
 */
class symboltype {
public:
	string type; ///< Type name.
	int width; ///< Width of the type.
	int count; ///< Count of the type.
	symboltype* arrtype; ///< Pointer to array type.
	symboltype(string, symboltype* ptr = NULL, int width = 1); ///< Constructor.
};

/**
 * @class quad
 * @brief Represents a quadruple in intermediate code.
 */
class quad {
public:
	string op; ///< Operator.
	string arg1; ///< First argument.
	string arg2; ///< Second argument.
	string res; ///< Result.

	void print(); ///< Prints the quadruple.

	quad(string res, string arg1, string op = "=", string arg2 = ""); ///< Constructor for string arguments.
	quad(string res, int arg1, string op = "=", string arg2 = ""); ///< Constructor for integer arguments.
	quad(string res, float arg1, string op = "=", string arg2 = ""); ///< Constructor for float arguments.
};

/**
 * @class quadArray
 * @brief Represents an array of quadruples.
 */
class quadArray {
public:
	vector<quad> arrayStructure; ///< Vector of quadruples.
	void print(); ///< Prints the array of quadruples.
};

/**
 * @class basicType
 * @brief Represents basic types and their sizes.
 */
class basicType {
public:
	vector<string> type; ///< Vector of type names.
	vector<int> size; ///< Vector of type sizes.
	int count; ///< Count of types.
	void addType(string, int); ///< Adds a new type and its size.
};

/**
 * @struct Statement
 * @brief Represents a statement with a list of next instructions.
 */
struct Statement {
	list<int> nextList; ///< List of next instructions.
};

/**
 * @struct arrayStructure
 * @brief Represents an array structure.
 */
struct arrayStructure {
	string atype; ///< Array type.
	Symbol_table* location; ///< Location of the array.
	Symbol_table* arrayStructure; ///< Array structure.
	symboltype* type; ///< Type of the array elements.
	int count; ///< Count of the array.
};

/**
 * @struct Expression
 * @brief Represents an expression with various attributes.
 */
struct Expression {
	Symbol_table* location; ///< Location of the expression.
	string type; ///< Type of the expression.
	int NUmber_of_expr; ///< Number of expressions.
	list<int> trueList; ///< List of true instructions.
	list<int> falseList; ///< List of false instructions.
	list<int> nextList; ///< List of next instructions.
};

extern char* yytext; ///< External lexer text.
extern int yyparse(); ///< External parser function.
extern Symbol_table* ST; ///< Current symbol table.
extern Symbol_table* globalST; ///< Global symbol table.
extern Symbol_table* currSymbolPtr; ///< Current symbol pointer.
extern quadArray Q; ///< Quadruple array.
extern basicType basictyp; ///< Basic types.

/**
 * @brief Generates a temporary symbol.
 * @param type Type of the symbol.
 * @param init Initial value of the symbol.
 * @return Pointer to the generated symbol.
 */
Symbol_table* gentemp(symboltype*, string init = "");

/**
 * @brief Emits a quadruple with integer argument.
 * @param res Result.
 * @param arg1 First argument.
 * @param arg2 Second argument.
 * @param arg Additional argument.
 */
void emit(string, string, int, string arg = "");

/**
 * @brief Emits a quadruple with float argument.
 * @param res Result.
 * @param arg1 First argument.
 * @param arg2 Second argument.
 * @param arg Additional argument.
 */
void emit(string, string, float, string arg = "");

/**
 * @brief Emits a quadruple with string arguments.
 * @param res Result.
 * @param arg1 First argument.
 * @param arg2 Second argument.
 * @param arg Additional argument.
 */
void emit(string, string, string arg1 = "", string arg2 = "");

/**
 * @brief Backpatches a list of instructions.
 * @param list List of instructions.
 * @param target Target instruction.
 */
void backpatch(list<int>, int);

/**
 * @brief Creates a new list with a single instruction.
 * @param index Instruction index.
 * @return List of instructions.
 */
list<int> makelist(int);

/**
 * @brief Merges two lists of instructions.
 * @param l1 First list.
 * @param l2 Second list.
 * @return Merged list.
 */
list<int> merge(list<int>& l1, list<int>& l2);

/**
 * @brief Converts a symbol to a different type.
 * @param sym Symbol to convert.
 * @param type Target type.
 * @return Pointer to the converted symbol.
 */
Symbol_table* convertType(Symbol_table*, string);

/**
 * @brief Checks if two symbols have the same type.
 * @param s1 First symbol.
 * @param s2 Second symbol.
 * @return True if types match, false otherwise.
 */
bool TypeCheck(Symbol_table*& s1, Symbol_table*& s2);

/**
 * @brief Checks if two types are the same.
 * @param t1 First type.
 * @param t2 Second type.
 * @return True if types match, false otherwise.
 */
bool TypeCheck(symboltype*, symboltype*);

/**
 * @brief Computes the size of a type.
 * @param type Type to compute size for.
 * @return Size of the type.
 */
int coutSize(symboltype*);

/**
 * @brief Converts a type to a string representation.
 * @param type Type to convert.
 * @return String representation of the type.
 */
string coutType(symboltype*);

/**
 * @brief Converts a float to a string.
 * @param value Float value to convert.
 * @return String representation of the float.
 */
string convertFloat2String(float);

/**
 * @brief Converts an integer expression to a boolean expression.
 * @param expr Expression to convert.
 * @return Pointer to the converted expression.
 */
Expression* convertInt2Bool(Expression*);

/**
 * @brief Converts a boolean expression to an integer expression.
 * @param expr Expression to convert.
 * @return Pointer to the converted expression.
 */
Expression* convertBool2Int(Expression*);

void checker(int number); ///< Checks the type of the program.

#endif