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
#define MAX_STR_CONST 1025
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

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
int string_const_size;
char *string_buf_ptr;

#define SET_ERROR(msg) \
	yylval.error_msg = msg;\
	return ERROR;
    
#define INSERT_CHAR_TO_STR_CONST(c) \
    if (string_const_size >= MAX_STR_CONST - 1) {\
	yylval.error_msg = "String constant too long";\
	return ERROR;}\
    string_buf[string_const_size++] = c;

    
/* TODO: move to somewhere else */
char get_escape_char() 
{
    char c;
    switch (yytext[1]) 
    {
	case 'n': c = '\n'; break;
	case 'b': c = '\b'; break;
	case 't': c = '\t'; break;
	case 'f': c = '\f'; break;
    }
    return c;
}

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */


%}

/*
 * Define names for regular expressions here.
 */

%x STR
%x CMT

DARROW          =>
DIGIT [0-9]


%%

 /*
  *  Nested comments
  */


"(*" 		{
    BEGIN(CMT);
}

<CMT><<EOF>> 	{
    BEGIN(INITIAL);
    SET_ERROR("EOF in comment");
}

<CMT>(.|\n)*"*)" {
    BEGIN(INITIAL);
}

"*)"		{
    SET_ERROR("Unmatched *)");
}

"--".*		{
    /* Single line comment */
}

 /*
  *  The multiple-character operators.
  */
"(" 		{ return '('; }
")" 		{ return ')'; }
"+"		{ return '+'; }
"-" 		{ return '-'; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{DARROW}	{ return (DARROW); }
(?:class)	{ return CLASS; } 
(?:if) 		{ return IF; }
(?:else) 	{ return ELSE; }
(?:fi) 		{ return FI; }
(?:then) 	{ return THEN; }
(?:while) 	{ return WHILE; }

true 		{
    cool_yylval.boolean = true;
    return BOOL_CONST;
}

flase		{
    cool_yylval.boolean = false;
    return BOOL_CONST;
}

{DIGIT}+ 	{ 
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
    BEGIN(STR); 
    string_const_size = 0;
}

<STR>\\\n 	{ /* Ignore the escaped new line */ }

<STR>\n		{
   BEGIN(INITIAL);
   yylval.error_msg = "Unterminated string constant";
   return ERROR; 
}

<STR><<EOF>> 	{
    yylval.error_msg = "EOF in string constant";
    return ERROR;
}

<STR>\0.*["]	{ 
    BEGIN(INITIAL);
    SET_ERROR("String contains null character"); 
}

<STR>\\[nbtf] 	{
    INSERT_CHAR_TO_STR_CONST(get_escape_char());
}

<STR>[^"\\]	{
    /* TODO: Test for \c !!! */
    INSERT_CHAR_TO_STR_CONST(yytext[0]);
}

<STR>["] 	{
    string_buf[string_const_size] = '\0';
    yylval.symbol = stringtable.add_string(string_buf, string_const_size);
    BEGIN(INITIAL); 
    return STR_CONST;
}

%%
