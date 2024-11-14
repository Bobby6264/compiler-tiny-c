#include "tinyC3_22CS30034_22CS30065_translator.h"
#include <bits/stdc++.h>
using namespace std;

string var_type;
Symbol_table *ST;
Symbol_table *globalST;
quadArray Q;
basicType basictyp;
Symbol_table *currSymbolPtr;

symboltype::symboltype(string type, symboltype *arrtype, int w) // constructor
{
	this->width = w;
	this->type = type;
	this->arrtype = arrtype;
	this->count = 0;
}

string convertFloat2String(float x) // convert float to string
{
	std::ostringstream buff;
	buff << x;
	return buff.str();
}

void backpatch(list<int> list1, int addr) // backpatch the list
{
	string str = to_string(addr);
	for (int index : list1)
	{
		Q.arrayStructure[index].res = str;
	}
}

list<int> makelist(int init) // make a new list and return it
{
	list<int> newlist(1, init);

	return newlist;
}

list<int> merge(list<int> &a, list<int> &b) // merge the two lists
{
	a.merge(b);

	return a;
}

int coutSize(symboltype *t) // return the size of the type
{
	if (t->type == "void")
		return basictyp.size[1];
	else if (t->type == "float")
		return basictyp.size[4];
	else if (t->type == "char")
		return basictyp.size[2];
	else if (t->type == "int")
		return basictyp.size[3];
	else if (t->type == "ptr")
		return basictyp.size[5];
	else if (t->type == "arr")
		return t->width * coutSize(t->arrtype);
	else if (t->type == "func")
		return basictyp.size[6];
	else
		return -1;
}

string coutType(symboltype *t) // return the type of the symbol
{
	if (t == NULL)
		return "null";
	else if (t->type == "ptr")
		return "ptr(" + coutType(t->arrtype) + ")";
	else if (t->type == "arr")
	{
		string str = to_string(t->width);
		return "arr(" + str + "," + coutType(t->arrtype) + ")";
	}
	else
		return t->type;
}

void basicType::addType(string t, int s) // add a new type to the basic type
{
	type.push_back(t);
	size.push_back(s);
	count = 1;
}

Symbol_table::Symbol_table(string name, string t, symboltype *arrtype, int width) // constructor
{
	(*this).name = name;
	type = new symboltype(t, arrtype, width);
	size = coutSize(type);
	initial_value = "";
	nested_table = NULL;
	count = 0;
	offset = 0;
	parent = NULL;
}

void checker(int number) // check the type of the program
{
	if (number == 0)
	{
		cout << "Type check successful" << endl;
	}
}

Symbol_table *Symbol_table::update(symboltype *t) // update the type of the symbol
{
	type = t;
	size = coutSize(t);
	return this;
}

void Symbol_table::update() // update the offset of the symbols in the table
{
	int temp = 0;
	list<Symbol_table *> tb;

	for (auto &entry : table)
	{
		entry.offset = temp;
		temp += entry.size;
		if (entry.nested_table != NULL)
			tb.push_back(entry.nested_table);
	}

	for (auto &nestedTable : tb)
	{
		nestedTable->update();
	}
}

Symbol_table *Symbol_table::lookup(string name) // find a symbol in the table
{
	for (auto &entry : table)
	{
		if (entry.name == name)
			return &entry;
	}
	Symbol_table *s = new Symbol_table(name);
	table.push_back(*s);
	return &table.back();
}

Symbol_table *gentemp(symboltype *t, string str_new) // generate a new temporary symbol
{
	string tmp_name = "$" + to_string(ST->count++);
	Symbol_table *s = new Symbol_table(tmp_name);
	(*s).type = t;
	(*s).size = coutSize(t);
	(*s).initial_value = str_new;
	ST->table.push_back(*s);
	return &ST->table.back();
}

void Symbol_table::print()
{
	int next_instr = 0;
	for (int t1 = 0; t1 < 50; t1++)
		cout << "**";
	cout << endl;
	cout << "Table Name: " << (*this).name << "\t\t\t Parent Name: ";
	if (((*this).parent == NULL))
		cout << "NULL" << endl;
	else
		cout << (*this).parent->name << endl;
	for (int ti = 0; ti < 50; ti++)
		cout << "**";
	cout << endl;

	cout << "Name";
	for (int i = 0; i < 11; i++)
		cout << " ";
	cout << "Type";
	for (int i = 0; i < 16; i++)
		cout << " ";
	cout << "Initial Value";
	for (int i = 0; i < 7; i++)
		cout << " ";
	cout << "Size";
	for (int i = 0; i < 11; i++)
		cout << " ";
	cout << "Offset";
	for (int i = 0; i < 9; i++)
		cout << " ";
	cout << "Nested" << endl;
	for (int i = 0; i < 100; i++)
		cout << " ";
	cout << endl;
	ostringstream str1;
	list<Symbol_table *> tb;
	for (auto it : table)
	{
		cout << it.name;
		for (int i = 0; i < 15 - it.name.length(); i++)
			cout << " ";
		string typeres = coutType(it.type);
		cout << typeres;
		for (int i = 0; i < 20 - typeres.length(); i++)
			cout << " ";
		cout << it.initial_value;
		for (int i = 0; i < 20 - it.initial_value.length(); i++)
			cout << " ";
		cout << it.size;
		str1 << it.size;
		for (int i = 0; i < 15 - str1.str().length(); i++)
			cout << " ";
		str1.str("");
		str1.clear();
		cout << it.offset;
		str1 << it.offset;
		for (int i = 0; i < 15 - str1.str().length(); i++)
			cout << " ";
		str1.str("");
		str1.clear();
		if (it.nested_table == NULL)
		{
			cout << "NULL" << endl;
		}
		else
		{
			cout << it.nested_table->name << endl;
			tb.push_back(it.nested_table);
		}
	}

	for (int i = 0; i < 100; i++)
		cout << "#";
	cout << "\n\n";
	for (auto iter : tb)
	{
		iter->print();
	}
}

Symbol_table *convertType(Symbol_table *s, string return_type) // convert the type of the symbol
{
	Symbol_table *new_s = gentemp(new symboltype(return_type));

	if ((*s).type->type == "float") // float to int, char, double
	{
		if (return_type == "int")
		{
			emit("=", new_s->name, "float2int(" + (*s).name + ")");
			return new_s;
		}
		else if (return_type == "double")
		{
			emit("=", new_s->name, "float2double(" + (*s).name + ")");
			return new_s;
		}
		else if (return_type == "char")
		{
			emit("=", new_s->name, "float2char(" + (*s).name + ")");
			return new_s;
		}
		return s;
	}
	else if ((*s).type->type == "char") // char to int, float
	{
		if (return_type == "int")
		{
			emit("=", new_s->name, "char2int(" + (*s).name + ")");
			return new_s;
		}
		else if (return_type == "float")
		{
			emit("=", new_s->name, "char2float(" + (*s).name + ")");
			return new_s;
		}
		return s;
	}
	else if ((*s).type->type == "int") // int to float, char
	{
		if (return_type == "float")
		{
			emit("=", new_s->name, "int2float(" + (*s).name + ")");
			return new_s;
		}
		else if (return_type == "char")
		{
			emit("=", new_s->name, "int2char(" + (*s).name + ")");
			return new_s;
		}
		return s;
	}
	return s;
}

bool TypeCheck(Symbol_table *&s1, Symbol_table *&s2) // check if the two symbols have same type
{
	symboltype *t2 = s2->type;
	symboltype *t1 = s1->type;
	int flag = 0;
	if (TypeCheck(t1, t2))
		flag = 1;
	else if (s2 = convertType(s2, t1->type))
		flag = 1;
	else if (s1 = convertType(s1, t2->type))
		flag = 1;
	if (flag)
		return true;
	else
		return false;
}

bool TypeCheck(symboltype *t1, symboltype *t2) // check if the two types are same
{
	int flag = 0;
	if (t1 == NULL || t2 == NULL || t1->type != t2->type)
		return false;
	else if (t1 == NULL && t2 == NULL)
		return true;
	else
		return TypeCheck(t1->arrtype, t2->arrtype);
}

quad::quad(string res, string arg1, string op, string arg2) // constructor
{
	(*this).arg1 = arg1;
	(*this).res = res;
	(*this).arg2 = arg2;
	(*this).op = op;
}

quad::quad(string res, int arg1, string op, string arg2) // constructor
{
	(*this).arg1 = to_string(arg1);
	(*this).res = res;
	(*this).op = op;
	(*this).arg2 = arg2;
}

quad::quad(string res, float arg1, string op, string arg2) // constructor
{
	(*this).res = res;
	(*this).arg2 = arg2;
	(*this).op = op;
	(*this).arg1 = convertFloat2String(arg1);
}

void quad::print() // print the quad
{
	int next_instr = 0;
	if (op == "+")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "-")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "*")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "/")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "%")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "|")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "^")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "&")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "==")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == "!=")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == "<=")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == "<")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == ">")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == ">=")
	{
		cout << "if " << arg1 << " " << op << " " << arg2 << " goto L" << res;
	}
	else if (op == "goto")
	{
		cout << "goto L" << res;
	}
	else if (op == ">>")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "<<")
	{
		cout << res << " = " << arg1 << " " << op << " " << arg2;
	}
	else if (op == "=")
	{
		cout << res << " = " << arg1;
	}
	else if (op == "=&")
	{
		cout << res << " = &" << arg1;
	}
	else if (op == "=*")
	{
		cout << res << " = *" << arg1;
	}
	else if (op == "*=")
	{
		cout << "*" << res << " = " << arg1;
	}
	else if (op == "uminus")
	{
		cout << res << " = -" << arg1;
	}
	else if (op == "~")
	{
		cout << res << " = ~" << arg1;
	}
	else if (op == "!")
	{
		cout << res << " = !" << arg1;
	}
	else if (op == "=[]")
	{
		cout << res << " = " << arg1 << "[" << arg2 << "]";
	}
	else if (op == "[]=")
	{
		cout << res << "[" << arg1 << "]" << " = " << arg2;
	}
	else if (op == "return")
	{
		cout << "return " << res << endl;
	}
	else if (op == "param")
	{
		cout << "param " << res;
	}
	else if (op == "call")
	{
		cout << res << " = " << "call " << arg1 << ", " << arg2;
	}
	else if (op == "label")
	{
		cout << res << ": ";
	}
	else
	{
		cout << "Can't find , error" << op;
	}
}

void quadArray::print() // print the quad array
{
	for (int i = 0; i < 100; i++)
		cout << "*";
	cout << endl;
	cout << "Three Address Code:" << endl;
	for (int i = 0; i < 100; i++)
		cout << "*";
	cout << endl;
	int j = 0;
	for (auto &q : arrayStructure)
	{
		if (q.op == "label")
		{
			cout << endl
				 << "L" << j << ": ";
			q.print();
		}
		else
		{
			cout << endl
				 << "L" << j << ": ";
			for (int i = 0; i < 4; i++)
				cout << " ";
			q.print();
		}
		j++;
	}
	for (int i = 0; i < 100; i++)
		cout << "*";
	cout << endl;
}

void emit(string op, string res, string arg1, string arg2) // add a new quad to the quad array
{
	quad *q1 = new quad(res, arg1, op, arg2);

	Q.arrayStructure.push_back(*q1);
}

void emit(string op, string res, int arg1, string arg2) // add a new quad to the quad array
{
	quad *q2 = new quad(res, arg1, op, arg2);

	Q.arrayStructure.push_back(*q2);
}

void emit(string op, string res, float arg1, string arg2) // add a new quad to the quad array
{
	quad *q3 = new quad(res, arg1, op, arg2);
	Q.arrayStructure.push_back(*q3);
}

Expression *convertInt2Bool(Expression *e) // convert into bool and add the related quads
{
	if (e->type != "bool")
	{
		e->falseList = makelist(Q.arrayStructure.size());
		emit("==", "", e->location->name, "0");
		e->trueList = makelist(Q.arrayStructure.size());
		emit("goto", "");
		e->type = "bool";
	}
	return e;
}

Expression *convertBool2Int(Expression *e) // convert into int and add the related quads
{
	if (e->type == "bool")
	{

		e->location = gentemp(new symboltype("int"));

		backpatch(e->trueList, Q.arrayStructure.size());

		emit("=", e->location->name, "true");

		int p = Q.arrayStructure.size() + 1;

		string str = to_string(p);

		emit("goto", str);

		backpatch(e->falseList, Q.arrayStructure.size());

		emit("=", e->location->name, "false");
	}
	return e;
}

int main()
{
	basictyp.addType("null", 0); // adding all the possible types to basic type
	basictyp.addType("void", 0);
	basictyp.addType("char", 1);
	basictyp.addType("int", 4);
	basictyp.addType("float", 8);
	basictyp.addType("ptr", 4);
	basictyp.addType("arr", 0);
	basictyp.addType("func", 0);

	globalST = new Symbol_table("Global"); // creating the global symbol table
	ST = globalST;

	yyparse();
	globalST->update(); // updating the offset of the symbols in the table

	cout << "\n";

	Q.print();		   // printing the quad array
	globalST->print(); // printing the symbol table

	exit(0);
};