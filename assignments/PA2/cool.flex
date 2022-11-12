/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STRING_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STRING_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

/**
 * The current size of the string literal. This will be updated while the lexer  
 * is in the STRING state 
 */
int string_const_size;

/**
 * The macro for returning an error 
 */
#define SET_ERROR(msg) \
	yylval.error_msg = msg;\
	return ERROR;
    
/**
 * Insert a single char to the current string constant buffer. 
 * It first cheks for the current length. If the buffer is full it will 
 * return an ERROR. Otherwise, the character will be inserted to the buffer 
 */
#define INSERT_CHAR_TO_STRING_CONST(c) \
    if (string_const_size >= MAX_STRING_CONST - 1) {\
	yylval.error_msg = "String constant too long";\
	BEGIN(STRING_ERROR);\
	return ERROR;}\
    string_buf[string_const_size++] = c;

/**
 * This is used when a /n, /t, /f, /b is detected. It will return the corresponding
 * espcate sequence by checking the yytext.
 */
char get_escape_char() 
{
    /* Decide based on the second charater of the yytext */
    switch (yytext[1]) 
    {
	case 'n': return '\n';
	case 'b': return '\b';
	case 't': return '\t';
	case 'f': return '\f';
    }
    return 0;
}

%}

/**
 * The state when the lexer inside a multiline comment 
 */
%x COMMENT

/**
 * The state of the lexer when it is inside a string literal 
 */
%x STRING

/**
 * The lexer enters the STRING_ERROR state when an error (null character or string is too 
 * long) is occured. The state will be changed to the INITIAL when the "end of the string" 
 * is reached.
 */
%x STRING_ERROR

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT 		[0-9]
NAME		[a-zA-Z0-9_]


%%

 /*
  *  Nested comments
  */


"(*" 		{
    BEGIN(COMMENT);
}

<COMMENT><<EOF>> 	{
    BEGIN(INITIAL);
    SET_ERROR("EOF in comment");
}

<COMMENT>"*)" {
    BEGIN(INITIAL);
}

<COMMENT>\n		{
    curr_lineno++;
}

<COMMENT>.	 	{
    //std::cout << yytext << std::endl;
}

"*)"		{
    SET_ERROR("Unmatched *)");
}

"--".*		{
    /* Single line comment */
}

 /*
  *  The operators.
  */
"."		{ return '.'; }
","		{ return ','; }
"(" 		{ return '('; }
")" 		{ return ')'; }
"+"		{ return '+'; }
"-" 		{ return '-'; }
"<"		{ return '<'; }
":"		{ return ':'; }
";"		{ return ';'; }
"{"		{ return '{'; }
"}"		{ return '}'; }
"="		{ return '='; }
"<-"		{ return ASSIGN; }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{DARROW}	{ return DARROW; }
(?i:class)	{ return CLASS; } 
(?i:if) 	{ return IF; }
(?i:else) 	{ return ELSE; }
(?i:fi) 	{ return FI; }
(?i:then) 	{ return THEN; }
(?i:while) 	{ return WHILE; }
(?i:let)	{ return LET; }
(?i:pool)	{ return POOL; }
(?i:inherits)	{ return INHERITS; }
(?i:in)		{ return IN; }
(?i:loop)	{ return LOOP; }
(?i:then)	{ return THEN; }
(?i:case)	{ return CASE; }
(?i:esac)	{ return ESAC; }
(?i:new)	{ return NEW; }
(?i:of)		{ return OF; }
(?i:not)	{ return NOT; }


t(?i:rue) 		{
    /* The first letter must be lower and rest is case insensitive */
    cool_yylval.boolean = true;
    return BOOL_CONST;
}

f(?i:alse)		{
    /* The first letter must be lower and rest is case insensitive */
    cool_yylval.boolean = false;
    return BOOL_CONST;
}

[a-z]{NAME}* {
    /* The ids that start with a lower case letter is a object id */
    cool_yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}

[A-Z]{NAME}* {
    /* The ids that start with a upper case letter is a type id */
    cool_yylval.symbol = idtable.add_string(yytext);
    return TYPEID;
}

{DIGIT}+	{ 
    yylval.symbol = inttable.add_int(atol(yytext));
    return INT_CONST;
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
["] 		{ 
    /* Start of the string literal */
    BEGIN(STRING); 
    string_const_size = 0;
}

<STRING>\\\n 	{ 
    /* Ignore the escaped new line */ 
    curr_lineno++;
}

<STRING,STRING_ERROR>\n		{
   curr_lineno++;
   BEGIN(INITIAL);
   yylval.error_msg = "Unterminated string constant";
   return ERROR; 
}

<STRING><<EOF>> 	{
    yylval.error_msg = "EOF in string constant";
    return ERROR;
}

<STRING>\0		{ 
    BEGIN(STRING_ERROR);
    SET_ERROR("String contains null character"); 
}

<STRING>\\[nbtf] 	{
    INSERT_CHAR_TO_STRING_CONST(get_escape_char());
}

<STRING>[^"\\]	{
    /* TODO: Test for \c !!! */
    INSERT_CHAR_TO_STRING_CONST(yytext[0]);
}

<STRING>["] 	{
    /* Then end of a legal string literal */
    string_buf[string_const_size] = '\0';
    /* Add the found string to the string table */
    yylval.symbol = stringtable.add_string(string_buf, string_const_size);
    BEGIN(INITIAL); 
    return STR_CONST;
}

<STRING_ERROR>["] {
    /* When an error occured in the string the error ends at " */
    BEGIN(INITIAL);
}

\n		{
    /* Need to update the number of lines in the INITAL state */
    curr_lineno++;
}

[ \t]	{ /* Ignore white spaces */ }

.	{ 
    /* A character doesn't belong to above rules is an error */
    SET_ERROR(yytext);
}

%%
