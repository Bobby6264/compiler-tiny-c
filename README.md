# TinyC Part 3: Machine-Independent Code Generator

This project is Part 3 of the TinyC compiler assignment, focusing on building a machine-independent code generator. This code generator takes in TinyC programs and outputs three-address code (TAC) and a symbol table, designed to be architecture-neutral. This project uses Flex for lexical analysis and Bison for syntax parsing, with semantic actions implemented to produce TAC quads and manage symbol tables.

## Overview

The code generator processes a subset of the C language standard as defined in previous TinyC parts, including:
- **Expressions:** Arithmetic, relational, logical, and assignment expressions.
- **Declarations:** Supports `int`, `char`, `float`, and `void` types, with simple variables, pointers, arrays, and function declarations.
- **Statements:** Control flow statements, including conditional branches and function calls.
- **External Definitions:** Supports function definitions.

## Project Structure

- **makefile**: Automates the compilation of the code generator.
- **tinyC3_22CS30034_22CS30065.l**: Flex file defining lexical tokens.
- **tinyC3_22CS30034_22CS30065.y**: Bison file defining the grammar and semantic actions for TAC generation.
- **tinyC3_22CS30034_22CS30065_translator.cxx**: Core translator code handling TAC quads, symbol table operations, and helper functions.
- **tinyC3_22CS30034_22CS30065_translator.h**: Header file for declarations of the code generator functions and structures.

## Key Components

### 1. **Three-Address Code (TAC)**
   - **Binary Operations**: `x = y op z` (arithmetic, relational, bitwise, etc.)
   - **Unary Operations**: `x = op y` (logical negation, unary minus, etc.)
   - **Assignment**: `x = y`
   - **Conditional Jumps**: `if x goto L`, `ifFalse x goto L`
   - **Function Calls**: `y = call p, N`
   - **Return Statements**: `return v`
   - **Array and Pointer Operations**: Indexed assignments and address manipulations.

### 2. **Symbol Table**
   - **Global and Local Scopes**: Tracks global symbols and function-scoped symbols.
   - **Entry Attributes**: Each entry stores information such as type, size, initial value, offset, and nested scopes.
   - **Methods**:
     - `lookup(name)`: Find or create an entry.
     - `gentemp(type)`: Generate a temporary symbol for intermediate values.
     - `update(entry, fields)`: Update attributes of an existing entry.
     - `print()`: Display the symbol table in a formatted manner.

### 3. **Data Types and Storage**
   - Supported data types: `void`, `char`, `int`, `float`, and pointers.
   - Size assumptions:
     - `char` - 1 byte
     - `int` - 4 bytes
     - `float` - 8 bytes
     - `pointer` - 4 bytes

## Installation and Usage

1. **Compile the Code Generator**
   - Run `make` to compile the code generator using the `makefile`.

2. **Run the Code Generator**
   - Use the compiled code generator to process a TinyC source file.
   - Example: `./tinyC3 <input_file.c>`

3. **View Output**
   - The generated TAC and symbol table will be printed to the console or saved as specified in the Bison actions.
