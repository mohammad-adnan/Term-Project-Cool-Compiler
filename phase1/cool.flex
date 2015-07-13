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
#include <string>

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
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

#define MY_ERROR(errorMsg) yylval.error_msg = errorMsg; BEGIN INITIAL; return ERROR;

// length INCLUDES the null character!
char *mySpecialConvert(const char *someString, int length) {
	char *res = new char[length];
	for (int i = 0; i < length; ++i)
		res[i] = someString[i];
	return res;
}

int nOpenComments = 0;
std::string stringCharacters = "";

%}



/*
 * Define names for regular expressions here.
 */
 
%x INSINGLECOMMENT
%x INMULCOMMENT
%x INSTRING
%x INSTRINGESCAPE

%%


<INITIAL>[cC][lL][aA][sS][sS]	{return CLASS;}
<INITIAL>[eE][lL][sS][eE]	{return ELSE;}
<INITIAL>[fF][iI]	{return FI;}
<INITIAL>[iI][fF]	{return IF;}
<INITIAL>[iI][nN]	{return IN;}
<INITIAL>[iI][nN][hH][eE][rR][iI][tT][sS]	{return INHERITS;}
<INITIAL>[lL][eE][tT]	{return LET;}
<INITIAL>[lL][oO][oO][pP]	{return LOOP;}
<INITIAL>[pP][oO][oO][lL]	{return POOL;}
<INITIAL>[tT][hH][eE][nN]	{return THEN;}
<INITIAL>[wW][hH][iI][lL][eE]	{return WHILE;}
<INITIAL>[cC][aA][sS][eE]	{return CASE;}
<INITIAL>[eE][sS][aA][cC]	{return ESAC;}
<INITIAL>[oO][fF]	{return OF;}
<INITIAL>[nN][eE][wW]	{return NEW;}
<INITIAL>[iI][sS][vV][oO][iI][dD]	{return ISVOID;}
<INITIAL>[nN][oO][tT]	{return NOT;}

<INITIAL>t[rR][uU][eE] {yylval.boolean = 1; return BOOL_CONST;}
<INITIAL>f[aA][lL][sS][eE] {yylval.boolean = 0; return BOOL_CONST;}

 
<INITIAL>[0-9]+ {yylval.symbol = inttable.add_string(yytext); return INT_CONST;}
<INITIAL>[A-Z][a-zA-Z0-9_]*  {yylval.symbol = idtable.add_string(yytext); return TYPEID;}
<INITIAL>[a-z][a-zA-Z0-9_]*  {yylval.symbol = idtable.add_string(yytext); return OBJECTID;}

<INITIAL>[;,\(\){}:@\.\+\-\*/~<=] {return (int)yytext[0];}

<INITIAL>"=>"		{ return (DARROW); }
<INITIAL>"<-"		{ return (ASSIGN); }
<INITIAL>"<="		{ return (LE); }

<INITIAL>\" {BEGIN INSTRING;}

<INITIAL>\n {++curr_lineno;}
<INITIAL>\t {}
<INITIAL>[ ] {}

<INITIAL>. {MY_ERROR(yytext)}	/*Character that can't begin any battee5*/

 
<INITIAL>-- {BEGIN INSINGLECOMMENT;}
<INSINGLECOMMENT>\n {++curr_lineno; BEGIN INITIAL;}
<INSINGLECOMMENT>. {}

<INITIAL>\(\* {nOpenComments = 1; BEGIN INMULCOMMENT;}
<INMULCOMMENT>\(\* {++nOpenComments;}
<INMULCOMMENT>\n {++curr_lineno;}
<INMULCOMMENT><<EOF>> {MY_ERROR("EOF in comment!")}
<INMULCOMMENT>\*\) {--nOpenComments; if (nOpenComments == 0) BEGIN INITIAL;}
<INMULCOMMENT>. {}

<INSTRING>\\ {BEGIN INSTRINGESCAPE;}
<INSTRING>\n {++curr_lineno; stringCharacters = ""; MY_ERROR("New line in string!")}
<INSTRING>\0 {stringCharacters = ""; MY_ERROR("NULL in string!")}
<INSTRING><<EOF>> {stringCharacters = ""; MY_ERROR("EOF in string!")}
<INSTRING>\" {if (stringCharacters.size() <= MAX_STR_CONST) {yylval.symbol = strtable.add_string(mySpecialConvert(stringCharacters.c_str(), stringCharacters.size()+1)); stringCharacters = ""; BEGIN INITIAL; return STR_CONST;}else {stringCharacters = ""; MY_ERROR("Too long string!")}}
<INSTRING>. {stringCharacters += yytext[0];}
<INSTRINGESCAPE>\n {++curr_lineno; BEGIN INSTRING;}
<INSTRINGESCAPE>\0 {stringCharacters = ""; MY_ERROR("NULL in string!")}
<INSTRINGESCAPE><<EOF>> {stringCharacters = ""; MY_ERROR("EOF in string!")}
<INSTRINGESCAPE>b {stringCharacters += "\b"; BEGIN INSTRING;}
<INSTRINGESCAPE>t {stringCharacters += "\t"; BEGIN INSTRING;}
<INSTRINGESCAPE>n {stringCharacters += "\n"; BEGIN INSTRING;}
<INSTRINGESCAPE>f {stringCharacters += "\f"; BEGIN INSTRING;}
<INSTRINGESCAPE>0 {stringCharacters += "\0"; BEGIN INSTRING;}
<INSTRINGESCAPE>. {stringCharacters += yytext[0]; BEGIN INSTRING;}

%%
