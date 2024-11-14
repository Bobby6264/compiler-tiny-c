%{  
#include "tinyC3_22CS30034_22CS30065_translator.h"

#include <iostream>              
#include <cstdlib>
#include <string>
#include <stdio.h>
#include <sstream>

using namespace std;

extern string var_type;			
extern int yylex(); 			
void yyerror(string s);			

%}
%union {            		
	
	Expression* Expression_pointer;		   //expression
	Statement* stat;		   //statement	
	arrayStructure* Arr;  		   	   //array type

	char unaryOp;	  		   //unary operator		
	char* char_value;		   //char value

	int instr_number;		   //instruction number used for backpatching
	int int_value;			   //integer value	
	int num_params;			   //number of parameters

	symboltype* sym_type;	   //symbol type  
	Symbol_table* sym_ptr;			   //symbol pointer
}  

%token <sym_ptr> IDENTIFIER

%token <int_value> INTEGER_CONSTANT
%token <char_value> FLOAT_CONSTANT
%token <char_value> CHARACTER_CONSTANT
%token <char_value> STRING_LITERAL

%token UNARY_INCREMENT UNARY_DECREMENT NOT
%token MUL DIV MOD PLUS MINUS COMPLEMENT XOR
%token DOT DOTS COMMA QUES_MARK COLON SEMICOLON
%token IMPLIES HASH

%token BITWISE_LEFT BITWISE_RIGHT BITWISE_AND BITWISE_OR
%token LOGICAL_AND LOGICAL_OR
%token LESS_THAN GREATER_THAN LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL

%token ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN PLUS_ASSIGN MINUS_ASSIGN 
%token BITWISE_LEFT_ASSIGN BITWISE_RIGHT_ASSIGN BITWISE_AND_ASSIGN XOR_ASSIGN BITWISE_OR_ASSIGN

%token EXTERN STATIC VOID CHAR SHORT INT LONG FLOAT DOUBLE CONST RESTRICT VOLATILE INLINE SIZEOF TYPEDEF UNION STRUCT

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN 

%right LOWER_THAN_ELSE ELSE

%type <instr_number> M 	
%type <stat> N 			

%type <Expression_pointer>
	expression
	expression_opt
	primary_expression 
	multiplicative_expression
	additive_expression
	shift_expression
	relational_expression
	equality_expression
	AND_expression
	exclusive_OR_expression
	inclusive_OR_expression
	logical_AND_expression
	logical_OR_expression
	conditional_expression
	assignment_expression
	expression_statement

%type <unaryOp> unary_operator

%type <num_params> argument_expression_list argument_expression_list_opt

%type <Arr> 
	postfix_expression
	unary_expression
	cast_expression

%type <stat>  
	statement
	compound_statement
	selection_statement
	iteration_statement
	labeled_statement 
	jump_statement
	block_item
	block_item_list
	block_item_list_opt

%type <sym_type> pointer

%type <sym_ptr> initializer
%type <sym_ptr> direct_declarator init_declarator declarator

%start translation_unit

%%

primary_expression 
		: IDENTIFIER 								
		{     
			$$ = new Expression();            				
			$$->type = "not-boolean";	
			$$->location = $1;			
		}
		| INTEGER_CONSTANT				   			
		{    
			checker(4); //checker is function used for debugging
			$$ = new Expression();	       			
			string str = to_string($1);     
			$$->location = gentemp(new symboltype("int"), str); 
			emit("=", $$->location->name, str);     
		}
		| FLOAT_CONSTANT				   			
		{  
			$$ = new Expression();
			string str = string($1);
			$$->location = gentemp(new symboltype("float"), str);
			emit("=", $$->location->name, str); 
		}
		| CHARACTER_CONSTANT               			
		{    
			$$ = new Expression();					
			string str = string($1);
			$$->location = gentemp(new symboltype("char"), str);
			emit("=", $$->location->name, str); 
		}
		| STRING_LITERAL  				  			
		{   
			$$ = new Expression();					
			string str = string($1);
			$$->location = gentemp(new symboltype("ptr"), str);
			$$->location->type->arrtype = new symboltype("char");  
		}
		| '(' expression ')'   
		{   
			$$ = $2;								
		}
		;
postfix_expression 
		: primary_expression 
		{
			$$ = new arrayStructure();                        
			$$->location = $1->location;				
			$$->arrayStructure = $1->location;				
			$$->type = $1->location->type;			
		}
		| postfix_expression '[' expression ']'
		{
			checker(6);
			$$ = new arrayStructure();						
			$$->type = $1->type->arrtype;			
			$$->arrayStructure = $1->arrayStructure;				    
			$$->location = gentemp(new symboltype("int"));	
			$$->atype = "arr";						
			int sz = coutSize($$->type);					
			string str = to_string(sz);				
			emit("*",$$->location->name,$3->location->name,str);
			if($1->atype == "arr")                  
			{
				Symbol_table* temp_var = gentemp(new symboltype("int"));   
				emit("*",temp_var->name,$3->location->name,str);
				emit("+",$$->location->name,$1->location->name,temp_var->name);  
			}
		}
		| postfix_expression '(' argument_expression_list_opt ')'
		{     
			$$ = new arrayStructure();						
			$$->arrayStructure = gentemp($1->type);		
			string str = to_string($3);	
			emit("call",$$->arrayStructure->name,$1->arrayStructure->name,str);  
		}
		| postfix_expression DOT IDENTIFIER
		{
			// Handle struct member access
		}
		| postfix_expression IMPLIES IDENTIFIER
		{
			// Handle pointer to struct member access
		}
		| postfix_expression UNARY_INCREMENT
		{
			$$ = new arrayStructure();									 
			$$->arrayStructure = gentemp($1->arrayStructure->type);             
			emit("=",$$->arrayStructure->name,$1->arrayStructure->name);      
			emit("+",$1->arrayStructure->name,$1->arrayStructure->name,"1");   
		}
		| postfix_expression UNARY_DECREMENT
		{
			$$ = new arrayStructure();									
			$$->arrayStructure = gentemp($1->arrayStructure->type);		
			emit("=",$$->arrayStructure->name,$1->arrayStructure->name);	
			emit("-",$1->arrayStructure->name,$1->arrayStructure->name,"1"); 
		}
		| '(' type_name ')' '{' initializer_list '}'
		{
			// Handle compound literal
		}
		| '(' type_name ')' '{' initializer_list COMMA '}'
		{
			// Handle compound literal with trailing comma
		}
		;

argument_expression_list_opt 
		: %empty
		{
			checker(5);
			$$ = 0;                         
		}
		| argument_expression_list
		{
			$$ = $1;						
		}
		;


argument_expression_list 
		: assignment_expression
		{    
			$$ = 1;                              
			emit("param", $1->location->name);  
		}
		| argument_expression_list COMMA assignment_expression
		{
			$$ = $1 + 1;                         
			emit("param", $3->location->name); 
		}
		;


unary_expression 
		: postfix_expression						
		{
			$$ = $1;    						
		}
		| UNARY_INCREMENT unary_expression     
		{
			checker(1);
			emit("+",$2->arrayStructure->name,$2->arrayStructure->name,"1");  
			$$=$2;										  
		}
		| UNARY_DECREMENT unary_expression		
		{
			emit("-",$2->arrayStructure->name,$2->arrayStructure->name,"1");  
			$$=$2;											
		}
		| unary_operator cast_expression                    
		{      	
			$$=new arrayStructure();									
			switch($1)				
			{	  
				case '&':           
					$$->arrayStructure=gentemp((new symboltype("ptr")));
					$$->arrayStructure->type->arrtype=$2->arrayStructure->type;  
					emit("=&",$$->arrayStructure->name,$2->arrayStructure->name); 
					break;
				case '*':           
					$$->atype="ptr";
					$$->location=gentemp($2->arrayStructure->type->arrtype);   
					$$->arrayStructure=$2->arrayStructure;							 
					emit("=*",$$->location->name,$2->arrayStructure->name);    
					break;
				case '+':  
					$$=$2;				
					break;
				case '-':				
					$$->arrayStructure=gentemp(new symboltype($2->arrayStructure->type->type));  
					emit("MINUS",$$->arrayStructure->name,$2->arrayStructure->name);
					break;
				case '~':                   
					$$->arrayStructure=gentemp(new symboltype($2->arrayStructure->type->type));
					emit("~",$$->arrayStructure->name,$2->arrayStructure->name);
					break;
				case '!':				
					$$->arrayStructure=gentemp(new symboltype($2->arrayStructure->type->type));
					emit("!",$$->arrayStructure->name,$2->arrayStructure->name);
					break;
			}
		}
		| SIZEOF unary_expression 									{	}
		| SIZEOF '(' type_name ')'	{	}
		;


unary_operator
		: BITWISE_AND
		{
			$$ = '&';					
		}
		| MUL
		{
			$$ = '*';					
		}
		| PLUS
		{
			$$ = '+';					
		}
		| MINUS
		{
			$$ = '-';					
		}
		| COMPLEMENT
		{
			$$ = '~';					
		}
		| NOT
		{
			$$ = '!';					
		}
		;


cast_expression 
		: unary_expression
		{
			$$ = $1;     				
		}
		| '(' type_name ')' cast_expression
		{ 								
			$$=new arrayStructure();				
			$$->arrayStructure=convertType($4->arrayStructure,var_type);    
		}
		;


multiplicative_expression 
		: cast_expression 					   
		{
			$$ = new Expression();             
			if($1->atype=="arr") 			  
			{
				$$->location = gentemp($1->location->type);	  
				emit("=[]",  $$->location->name,$1->arrayStructure->name, $1->location->name);  
			}
			else if($1->atype=="ptr")         
			{ 
				$$->location = $1->location;       
			}
			else 							
			{
				$$->location = $1->arrayStructure;		
			}
		}
		| multiplicative_expression MUL cast_expression      
		{ 
			if(!TypeCheck($1->location, $3->arrayStructure))  
			{    
				cout << " Mismatch of Data Type " << endl;	   
			}
			else 
			{
				$$ = new Expression();	
				$$->location = gentemp(new symboltype($1->location->type->type));
				emit("*",$$->location->name,$1->location->name, $3->arrayStructure->name);
			}
		}
		| multiplicative_expression DIV cast_expression         
		{ 
			if(!TypeCheck($1->location, $3->arrayStructure)) 
			{        
				cout<<"	Mismatch of Data Type "<< endl;	       
			}
			else 
			{
				$$ = new Expression();	
				$$->location = gentemp(new symboltype($1->location->type->type));
				emit("/",$$->location->name,$1->location->name, $3->arrayStructure->name);
			}
		}
		| multiplicative_expression MOD cast_expression            
		{ 
			if(!TypeCheck($1->location, $3->arrayStructure))  
			{       
				cout<<"	Mismatch of Data Type "<< endl;         
			}
			else
			{
				$$ = new Expression();	
				$$->location = gentemp(new symboltype($1->location->type->type));
				emit("%",$$->location->name,$1->location->name, $3->arrayStructure->name);
			}
		}
		;
additive_expression 
		: multiplicative_expression
		{ 
			$$ = $1;   					
		}
		| additive_expression PLUS multiplicative_expression    
		{
			if(!TypeCheck($1->location, $3->location))
			{
				cout <<" Mismatch of Data Type "<< endl;      
			}
			else    
			{
				$$ = new Expression();	
				$$->location = gentemp(new symboltype($1->location->type->type));
				emit("+",$$->location->name, $1->location->name, $3->location->name);
			}
		}
		| additive_expression MINUS multiplicative_expression    
		{
			if(!TypeCheck($1->location, $3->location))
			{
				cout << " Mismatch of Data Type "<< endl;          
			}
			else 
			{
				$$ = new Expression();	
				$$->location = gentemp(new symboltype($1->location->type->type));
				emit("-",$$->location->name, $1->location->name, $3->location->name);
			}
		}
		;
shift_expression 
		: additive_expression
		{
			$$ = $1;  					
		}
		| shift_expression BITWISE_LEFT additive_expression   
		{ 
			if(!($3->location->type->type == "int"))
			{
				cout << " Shifting cannot be done : Not an integer value "<< endl; 						//print error 
			}
			else           
			{		
				$$ = new Expression();	
				$$->location = gentemp(new symboltype("int"));
				emit("<<",$$->location->name, $1->location->name, $3->location->name);
			}
		}
		| shift_expression BITWISE_RIGHT additive_expression     
		{ 
			if(!($3->location->type->type == "int"))
			{
				cout << " Shifting cannot be done : Not an integer value "<< endl; 						//print error 
			}
			else            
			{		
				$$ = new Expression();	
				$$->location = gentemp(new symboltype("int"));
				emit(">>", $$->location->name, $1->location->name, $3->location->name);
			}
		}
		;


relational_expression 
		: shift_expression
		{ 
			$$ = $1;				
		}
		| relational_expression LESS_THAN shift_expression     
		{
			if(!TypeCheck($1->location, $3->location)) 
			{
				cout << " Mismatch of Data Type "<< endl;       
			}
			else 
			{     								
				$$ = new Expression();
				$$->type = "bool";                  
				$$->trueList = makelist(Q.arrayStructure.size()); 
				$$->falseList = makelist(Q.arrayStructure.size()+1); 
				emit("<","",$1->location->name, $3->location->name);
				emit("goto", "");	
			}
		} 
		| relational_expression GREATER_THAN shift_expression        
		{
			if(!TypeCheck($1->location, $3->location)) 
			{
				cout << " Mismatch of Data Type "<< endl;			
			}
			else 
			{							
				$$ = new Expression();
				$$->type = "bool";                   
				$$->trueList = makelist(Q.arrayStructure.size());   
				$$->falseList = makelist(Q.arrayStructure.size()+1);  
				emit(">","",$1->location->name, $3->location->name);
				emit("goto", "");	
			}
		}
		| relational_expression LESS_EQUAL shift_expression     
		{
			if(!TypeCheck($1->location, $3->location)) 
			{
				cout << " Mismatch of Data Type "<< endl;        
			}
			else 
			{    							
				$$ = new Expression();
				$$->type = "bool";               
				$$->trueList = makelist(Q.arrayStructure.size());    
				$$->falseList = makelist(Q.arrayStructure.size()+1); 
				emit("<=","",$1->location->name, $3->location->name);
				emit("goto", "");	
			}
		}
		| relational_expression GREATER_EQUAL shift_expression  
		{
			if(!TypeCheck($1->location, $3->location)) 
			{
				cout << " Mismatch of Data Type "<< endl;		
			}
			else 
			{    							
				$$ = new Expression();
				$$->type = "bool";                 
				$$->trueList = makelist(Q.arrayStructure.size());  
				$$->falseList = makelist(Q.arrayStructure.size()+1); 
				emit(">=","",$1->location->name, $3->location->name);
				emit("goto", "");	
			}
		}
		;


equality_expression 
		: relational_expression
		{
			$$ = $1;   					
		}
		| equality_expression EQUAL relational_expression    
		{
			if(!TypeCheck($1->location, $3->location)) 
			{
				cout << " Mismatch of Data Type "<< endl;      
			}
			else 
			{
				convertBool2Int($1);                 
				convertBool2Int($3);				  
				$$ = new Expression();				  
				$$->type = "bool";					  
				$$->trueList = makelist(Q.arrayStructure.size());      
				$$->falseList = makelist(Q.arrayStructure.size()+1);  
				emit("==", "", $1->location->name, $3->location->name);  
				emit("goto", "");				
			}
		}
		| equality_expression NOT_EQUAL relational_expression
		{
			if(!TypeCheck($1->location, $3->location))  
			{
				cout <<" Mismatch of Data Type "<< endl;        
			}
			else 
			{
				convertBool2Int($1);                
				convertBool2Int($3);               
				$$ = new Expression();
				$$->type = "bool";                
				$$->trueList = makelist(Q.arrayStructure.size());    
				$$->falseList = makelist(Q.arrayStructure.size()+1); 
				emit("!=", "", $1->location->name, $3->location->name); 
				emit("goto", "");				
			}
			
		}
		;


AND_expression 
		: equality_expression
		{
			$$ = $1; 				
		}
		| AND_expression BITWISE_AND equality_expression
		{
			if(!TypeCheck($1->location, $3->location))
			{	
				cout << " Mismatch of Data Type "<< endl;       
			}
			else 
			{            
				convertBool2Int($1);                
				convertBool2Int($3);                
				$$ = new Expression(); 				
				$$->type = "not-boolean";           
				$$->location = gentemp(new symboltype("int"));
				emit("&", $$->location->name, $1->location->name,$3->location->name);
			}
		}
		;

exclusive_OR_expression 
		: AND_expression
		{
			$$ = $1;    			
		}
		| exclusive_OR_expression XOR AND_expression
		{
			
			if(!TypeCheck($1->location, $3->location))    
			{
				cout << " Mismatch of Data Type "<< endl;       
			}
			else 
			{
				convertBool2Int($1);                
				convertBool2Int($3);                
				$$ = new Expression(); 				
				$$->type = "not-boolean";           
				$$->location = gentemp(new symboltype("int"));
				emit("^", $$->location->name, $1->location->name, $3->location->name); 
			}
		}
		;


inclusive_OR_expression 
		: exclusive_OR_expression
		{
			$$ = $1;    			
		}
		| inclusive_OR_expression BITWISE_OR exclusive_OR_expression
		{ 
			if(!TypeCheck($1->location, $3->location))
			{
				cout << "Mismatch of Data Type "<< endl;       
			}
			else 
			{
				convertBool2Int($1);	          
				convertBool2Int($3);              
				$$ = new Expression(); 				
				$$->type = "not-boolean";         
				$$->location = gentemp(new symboltype("int"));
				emit("|", $$->location->name, $1->location->name, $3->location->name);
			} 
		}
 		;
logical_AND_expression 
		: inclusive_OR_expression
		{
			$$ = $1;        			
		}
		| logical_AND_expression N LOGICAL_AND M inclusive_OR_expression
		{ 
			convertInt2Bool($5);   
			backpatch($2->nextList, Q.arrayStructure.size()); 
			convertInt2Bool($1);   
			$$ = new Expression();  
			$$->type = "bool";
			backpatch($1->trueList, $4);  
			$$->trueList = $5->trueList;    
			$$->falseList = merge($1->falseList, $5->falseList);  
		}
		;
logical_OR_expression 
		: logical_AND_expression
		{
			$$ = $1;         			
		}
		| logical_OR_expression N LOGICAL_OR M logical_AND_expression
		{ 
			convertInt2Bool($5);   
			backpatch($2->nextList, Q.arrayStructure.size()); 
			convertInt2Bool($1); 
			$$ = new Expression();    
			$$->type = "bool";
			backpatch($1->falseList, $4);   
			$$->trueList = merge($1->trueList, $5->trueList);
			$$->falseList = $5->falseList;
		}
		;
conditional_expression 
		: logical_OR_expression
		{
			$$ = $1;           			
		}
		| logical_OR_expression N QUES_MARK M expression N COLON M  conditional_expression
		{
			
			$$->location = gentemp($5->location->type);   
			$$->location->update($5->location->type);
			emit("=", $$->location->name, $9->location->name); 
			list<int> l = makelist(Q.arrayStructure.size());    
			emit("goto", "");                 
			backpatch($6->nextList, Q.arrayStructure.size());  
			emit("=", $$->location->name, $5->location->name);
			list<int> m = makelist(Q.arrayStructure.size());   
			l = merge(l, m);						
			emit("goto", "");						
			backpatch($2->nextList, Q.arrayStructure.size());   
			convertInt2Bool($1);                   
			backpatch($1->trueList, $4);          
			backpatch($1->falseList, $8);          
			backpatch(l, Q.arrayStructure.size());
		}
		;
assignment_expression 
		: conditional_expression
		{
			$$ = $1;            	    
		}
		| unary_expression assignment_operator assignment_expression
		{
			if($1->atype=="arr")      
			{
				$3->location = convertType($3->location, $1->type->type);
				emit("[]=", $1->arrayStructure->name, $1->location->name, $3->location->name);	
			}
			else if($1->atype=="ptr")    
			{
				emit("*=", $1->arrayStructure->name, $3->location->name);	
			}
			else                          
			{
				$3->location = convertType($3->location, $1->arrayStructure->type->type);
				emit("=", $1->arrayStructure->name, $3->location->name);
			}
			$$ = $3;
		}
		;
assignment_operator
		: ASSIGN     			{	}
		| MUL_ASSIGN			{	}
		| DIV_ASSIGN			{	}
		| MOD_ASSIGN			{	}
		| PLUS_ASSIGN			{	}
		| MINUS_ASSIGN			{	}
		| BITWISE_LEFT_ASSIGN	{	}
		| BITWISE_RIGHT_ASSIGN	{	}
		| BITWISE_AND_ASSIGN	{	}
		| XOR_ASSIGN			{	}
		| BITWISE_OR_ASSIGN		{	}
		;


expression 
		: assignment_expression
		{
			$$ = $1;            	
		}
		| expression COMMA assignment_expression 	{	}
		;
constant_expression 
		: conditional_expression   {	}
		;


// -------------------------------- 2. DECLARATIONS ------------------------------


declaration 
		: declaration_specifiers init_declarator_list_opt SEMICOLON	{	}
		;
init_declarator_list_opt 
        : init_declarator_list    {    }
        | /* empty */             %empty {    }
        ;

declaration_specifiers 
		: storage_class_specifier declaration_specifiers_opt	{	}
		| type_specifier declaration_specifiers_opt				{	}
		| type_qualifier declaration_specifiers_opt				{	}
		| function_specifier declaration_specifiers_opt			{	}
		;


declaration_specifiers_opt 
		: declaration_specifiers {	}
		| %empty				 {	}	
		;


init_declarator_list 
		: init_declarator 								{	}
		| init_declarator_list COMMA init_declarator 	{	}
		;


init_declarator 
		: declarator  
		{
			$$=$1;	             	//equating the value of 2 expressions  
		}
		| declarator ASSIGN initializer
		{
			if($3->initial_value!="") 
				$1->initial_value=$3->initial_value;    //initialising declarator with value of initializer
			emit("=", $1->name, $3->name);     //copy value instruction
		}
		;

storage_class_specifier 
		: EXTERN 	{	}
		| STATIC	{	}
		;

type_specifier       
		: VOID   {  var_type = "void";  }
		| CHAR   {  var_type = "char";  }
		| SHORT  {  var_type = "short"; }					
		| INT 	 {  var_type = "int";   }
		| LONG   {  var_type = "long";  }
		| FLOAT  {  var_type = "float"; }
		| DOUBLE {  var_type = "double";}				
		;

specifier_qualifier_list 
		: type_specifier specifier_qualifier_list_opt	{	}
		| type_qualifier specifier_qualifier_list_opt	{	}
		;

specifier_qualifier_list_opt 
		: specifier_qualifier_list  {	}
		| %empty					{	}
		;

type_qualifier 
		: CONST 	{	}
		| RESTRICT	{	}
		| VOLATILE	{	}
		;

function_specifier 
		: INLINE 	{	}
		;

declarator 
		: pointer direct_declarator
		{
			symboltype *t = $1;
			
			//for multidimensional arrays, move in depth until base type is obtained
			while(t->arrtype!=NULL) 
				t = t->arrtype;          
			
			t->arrtype = $2->type;                //add the base type 
			
			$$ = $2->update($1);                  //update
			
		}
		| direct_declarator		{	}
		;


direct_declarator 
		: IDENTIFIER         
		{
			$$ = $1->update(new symboltype(var_type));   //add a new variable of var_type
			
			currSymbolPtr = $$;
			
		}
		| '(' declarator ')'  
		{ 
			$$ = $2; 						//equating the value of declarators
		}
		| direct_declarator '[' type_qualifier_list assignment_expression ']'		{	}
		| direct_declarator '[' assignment_expression ']'		
		{
			symboltype *t = $1->type;   //creating symbol of type(declarator)
			
			symboltype *prev = NULL;
			
			while(t->type == "arr") 
			{
				prev = t;	
				t = t->arrtype;      //keep moving recursively to get basetype
				
			}
			if(prev==NULL) 
			{
				int temp = atoi($3->location->initial_value.c_str());      //get initial value
				
				symboltype* s = new symboltype("arr", $1->type, temp);        //create new symbol with that initial value
				
				$$ = $1->update(s);   //update the symbol table
				
			}
			else 
			{
				prev->arrtype =  new symboltype("arr", t, atoi($3->location->initial_value.c_str()));
				
				$$ = $1->update($1->type);
				
			}
		}
		| direct_declarator '[' type_qualifier_list    ']'		{	}
		| direct_declarator '[' ']'		
		{
			symboltype *t = $1->type;  //creating symbol of type(declarator)
			
			symboltype *prev = NULL;
			
			while(t->type == "arr") 
			{
				prev = t;	
				t = t->arrtype;         //keep moving recursively to base type
				
			}
			if(prev==NULL) 
			{
				symboltype* s = new symboltype("arr", $1->type, 0);    //no initial values, simply keep 0
				
				$$ = $1->update(s);
				
			}
			else 
			{
				prev->arrtype =  new symboltype("arr", t, 0);
				
				$$ = $1->update($1->type);
				
			}
		}
		| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'		   {   }
		| direct_declarator '[' STATIC assignment_expression ']'		                         {   }
		| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'          {   }
		| direct_declarator '[' type_qualifier_list MUL ']'                                {   }
		| direct_declarator '[' MUL ']'  {   }
		| direct_declarator '(' Changetable parameter_type_list ')'
		{
			ST->name = $1->name;		//stating the name of the symbol table
			
			if($1->type->type !="void") 		//if function has a return type
			{
				Symbol_table *s = ST->lookup("return");   //lookup for return value	
				s->update($1->type);
				
			}
			$1->nested_table=ST;       
			
			ST->parent = globalST;			    //directing the parent pointer
			
			ST = globalST;
			currSymbolPtr = $$;
			
		}
		| direct_declarator '(' Changetable ')'
		{    
			ST->name = $1->name;		//stating the name of the symbol table
			
			if($1->type->type !="void")  	     //if function has a return type
			{
				Symbol_table *s = ST->lookup("return");   //lookup for return value	
				s->update($1->type);
				
							
			}
			$1->nested_table=ST;
			
			ST->parent = globalST;		        //directing the parent pointer
			
			ST = globalST;
			currSymbolPtr = $$;
			
		}
		| direct_declarator '(' identifier_list ')'
		{   }
		;

Changetable
		: %empty 
		{ 	
			if(currSymbolPtr->nested_table==NULL) 
			{ 
				ST = new Symbol_table("");	
			}
			else 
			{
				ST = currSymbolPtr->nested_table;
				emit("label", ST->name);
			}
		}
		;
pointer 
		: MUL type_qualifier_list_opt
		{ 
			$$ = new symboltype("ptr");			
		}        
		| MUL type_qualifier_list_opt pointer
		{ 
			$$ = new symboltype("ptr",$3);        
		}
		;

type_qualifier_list 
		: type_qualifier  						{   }
		| type_qualifier_list type_qualifier 	{	}
		;


type_qualifier_list_opt 
		: type_qualifier_list  {	}
		| %empty			   {	}
		;


parameter_type_list 
		: parameter_list 			 {	 }
		| parameter_list COMMA DOTS  {	 }
		;


parameter_list 
		: parameter_declaration							{	}
		| parameter_list COMMA parameter_declaration	{	}
		;


parameter_declaration 
		: declaration_specifiers declarator  	{	}
		| declaration_specifiers 				{	}
		;


identifier_list 
		: IDENTIFIER 						 {    }
		| identifier_list COMMA IDENTIFIER   {	  }
		;


type_name 
		: specifier_qualifier_list {   }
		;


initializer 
		: assignment_expression
		{
			$$ = $1->location;  //equating the value of expression to initialiser
		}
		| '{' initializer_list '}'        {  }
		| '{' initializer_list COMMA '}'  {  }
		;


initializer_list 
		: designation_opt initializer 						  {  }
		| initializer_list COMMA designation_opt initializer  {  }
		;


designation 
		: designator_list ASSIGN  {   }
		;


designation_opt 
		: designation 	{	}
		| %empty		{	}
		;


designator_list 
		: designator                 {   }
		| designator_list designator {   }
		;


designator 
		: '[' constant_expression ']'  {   }
		| DOT IDENTIFIER                                                {   }
		;


// -------------------------------- 3. STATEMENTS ------------------------------


statement 
		: labeled_statement  {    }
		| compound_statement
		{	
			$$ = $1;  					//equating the value of the statements
		}
		| expression_statement
		{ 
			$$=new Statement();         //create new statement with same nextList
			$$->nextList=$1->nextList; 
		}
		| selection_statement
		{
			$$ = $1;  					//equating the value of the statements
		}
		| iteration_statement
		{
			$$ = $1;  					//equating the value of the statements 
		}
		| jump_statement
		{
			$$ = $1;  					//equating the value of the statements   
		}
		;


labeled_statement 
		: IDENTIFIER COLON statement 				{	}
		| CASE constant_expression COLON statement  {	}
		| DEFAULT COLON statement 					{	}
		;


compound_statement 
		: '{' block_item_list_opt '}'  
		{
			$$=$2;  					//equating the value of the statements	  
		}
		;


block_item_list 
		: block_item
		{
			$$ = $1;  					//equating the value of the statements
		}
		| block_item_list M block_item
		{
			$$ = $3;  					//equating the value of the statements
			backpatch($1->nextList,$2);		//after $1, move to block_item via $2
		}
		;


block_item 
		: declaration
		{
			$$ = new Statement();    	//create a new Statement object  
		}
		| statement
		{
			$$ = $1;  					//equating the value of the statements
		}
		;


block_item_list_opt 
		: block_item_list  
		{ 
			$$ = $1;  					//equating the value of the statements 
		}
		| %empty           
		{  
			$$ = new Statement();        //create a new Statement object
		}
		;


expression_statement 
		: expression_opt SEMICOLON    {   }
		;


expression_opt 
		: expression
		{
			$$ = $1;   					//equating the value of the statements
		}
		| %empty
		{
			$$ = new Expression();		//creating a new Expression object
 		}
		;


selection_statement 
		: IF '(' expression N ')' M statement N %prec "LOWER_THAN_ELSE"
		{
			backpatch($4->nextList, Q.arrayStructure.size());//nextList of N goes to nextinstr
			
			convertInt2Bool($3);        		 //convert expression to bool
			
			$$ = new Statement();        		 //Create a new Statement object
			
			backpatch($3->trueList, $6);         //if expression is true, go to M i.e just before statement body
			
			list<int> temp = merge($3->falseList, $7->nextList);   
			//merge falseList of expression, nextList of statement and second N
			
			$$->nextList = merge($8->nextList, temp);
			
		}
		| IF '(' expression N ')' M statement N ELSE M statement
		{
			backpatch($4->nextList, Q.arrayStructure.size()); //nextList of N goes to nextinstr
			
			convertInt2Bool($3);        		 //convert expression to bool
			
			$$ = new Statement();       		 //create a new Statement object
			
			backpatch($3->trueList, $6);         //when expression is true, go to M1 else go to M2
			
			backpatch($3->falseList, $10);
			
			list<int> temp = merge($7->nextList, $8->nextList);       
			//merge the nextLists of the statements and second N
			
			$$->nextList = merge($11->nextList,temp);	
			
		}
		| SWITCH '(' expression ')' statement {   }
		;


iteration_statement 
		: WHILE M '(' expression ')' M statement  
		{
			$$ = new Statement();    		//create a new Statement object
			
			convertInt2Bool($4);    	    //convert int value to bool
			
			backpatch($7->nextList, $2);	// M1 to go back to expression again
			
			backpatch($4->trueList, $6);	// M2 to go to statement if the expression is true
			
			$$->nextList = $4->falseList;   //when expression is false, move out of loop
			
			// Emit to prevent fallthrough
			string str= to_string($2);			
			
			emit("goto", str);
			
		}
		| DO M statement M WHILE '(' expression ')' SEMICOLON
		{
			$$ = new Statement();     		//create a new Statement object
			
			convertInt2Bool($7);      		//convert int value to bool
			
			backpatch($7->trueList, $2);	// M1 to go back to statement if expression is true
			
			backpatch($3->nextList, $4);	// M2 to go to check expression if statement is complete
			
			$$->nextList = $7->falseList;  //move out if statement is false
			
		}
		| FOR '(' expression_statement M expression_statement ')' M statement
		{
			$$ = new Statement();     		//create a new Statement object
			
			convertInt2Bool($5);      		//convert int value to bool
			
			backpatch($5->trueList,$7);     //if expression is true, go to M2
			
			backpatch($8->nextList,$4);     //after statement, go back to M1
			
			string str= to_string($4);
			
			emit("goto", str);              //prevent fallthrough
			
			$$->nextList = $5->falseList;   //move out if statement is false
			
		}
		| FOR '(' expression_statement M expression_statement M expression N ')' M statement
		{
			$$ = new Statement();     		//create a new Statement object
			
			convertInt2Bool($5);           //convert int value to boolean
			
			backpatch($5->trueList, $10);	//if expression is true, go to M2
			
			backpatch($8->nextList, $4);	//after N, go back to M1
			
			backpatch($11->nextList, $6);	//statement go back to expression
			
			string str= to_string($4);
			
			emit("goto", str);				//prevent fallthrough
			
			$$->nextList = $5->falseList;	//move out if statement is false	
			
		}
		;


jump_statement 
		: GOTO IDENTIFIER SEMICOLON
		{
			$$ = new Statement();      		//create a new Statement object 
		}
		| CONTINUE SEMICOLON
		{
			$$ = new Statement();           //create a new Statement object   
		}
		| BREAK SEMICOLON
		{
			$$ = new Statement();      		//create a new Statement object    
		}
		| RETURN expression SEMICOLON
		{
			$$ = new Statement();     		//create a new Statement object
			
			//emit return with the name of the return value
			emit("return",$2->location->name);
			
		}
		| RETURN SEMICOLON
		{
			$$ = new Statement();     		//create a new Statement object
			
			emit("return","");              //emit return
			
		}
		;


// -------------------------------- 4. EXTERNAL DEFINITIONS  --------------------

translation_unit 
		: external_declaration                   
		{
			// Single external declaration
		}
		| translation_unit external_declaration  
		{
			// Multiple external declarations
		}
		;

external_declaration
		: function_definition  
		{
			// Function definition
		}
		| declaration          
		{
			// Variable declaration
		}
		;

function_definition
		: declaration_specifiers declarator declaration_list_opt Changetable compound_statement
		{
			// Set the parent of the current symbol table to the global symbol table
			ST->parent = globalST;
			
			// Change the current symbol table back to the global symbol table
			ST = globalST;
		}
		;

declaration_list
		: declaration                   
		{
			// Single declaration in the list
		}
		| declaration_list declaration  
		{
			// Multiple declarations in the list
		}
		;

declaration_list_opt
		: declaration_list  
		{
			// Optional declaration list
		}
		| %empty            
		{
			// Empty declaration list
		}
		;

M 		: %empty 
		{
			// Store the index of the next instruction for backpatching
			$$ = Q.arrayStructure.size();
		}   
		;

N 		: %empty
		{
			// Create a new statement for backpatching
			$$ = new Statement();
			
			// Store the index of the next goto statement to guard against fallthrough
			$$->nextList = makelist(Q.arrayStructure.size());
			
			// Emit a goto statement
			emit("goto", "");
		}
		;


%%

// Called on error in case invalid input is obtained that cannot
// parsed by the parser generated by Bison
void yyerror(string str) {  
	cout << str << endl;
}

