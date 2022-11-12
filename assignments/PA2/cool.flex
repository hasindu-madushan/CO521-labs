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
	BEGIN(STR_ERROR);\
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

%x CMT
%x STR
%x STR_ERROR

DARROW          =>
DIGIT 		[0-9]


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

<CMT>"*)" {
    BEGIN(INITIAL);
}

<CMT>\n		{
    curr_lineno++;
}

<CMT>.	 	{
    //std::cout << yytext << std::endl;
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


true 		{
    cool_yylval.boolean = true;
    return BOOL_CONST;
}

flase		{
    cool_yylval.boolean = false;
    return BOOL_CONST;
}

[a-z][a-zA-Z0-9_]* {
    cool_yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}

[A-Z][a-zA-Z0-9_]* {
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
    BEGIN(STR); 
    string_const_size = 0;
}

<STR>\\\n 	{ 
    /* Ignore the escaped new line */ 
    curr_lineno++;
}

<STR,STR_ERROR>\n		{
   curr_lineno++;
   BEGIN(INITIAL);
   yylval.error_msg = "Unterminated string constant";
   return ERROR; 
}

<STR><<EOF>> 	{
    yylval.error_msg = "EOF in string constant";
    return ERROR;
}

<STR>\0		{ 
    BEGIN(STR_ERROR);
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

<STR_ERROR>["] {
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