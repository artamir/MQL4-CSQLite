//+------------------------------------------------------------------+
//|                                                 csqlite_defs.mqh |
//|                                                          artamir |
//|                                                  artamir@mail.ru |
//|  															     $Revision: 105 $|
//+------------------------------------------------------------------+
#property copyright "artamir"
#property link      "artamir@mail.ru"
#property strict

//+------------------------------------------------------------------+
//|TYPES                                                             |
//+------------------------------------------------------------------+
struct ProgramInfo
  {
   string            path;
   string            name;
  };
//+------------------------------------------------------------------+
//|Структура КлючЗначение и выборка по ключу из массива                                                                  |
//+------------------------------------------------------------------+
//struct KeyVal
//  {
//   string            key;
//   string            val;
//  };
//
//struct structTableColumns{
//   string table;
//   string cols[];
//};

enum ENUM_DTY{
	ENUM_DTY_BUY=100,
	ENUM_DTY_SELL=101
};

enum ENUM_CLOSE_TYPE{
	ENUM_CLOSED_TYPE_MANUAL=1,
	ENUM_CLOSED_TYPE_TP=2,
	ENUM_CLOSED_TYPE_SL=3
};

enum ENUM_SQLITE_TYPE{
   SQLITE_TYPE_INTEGER=1,
   SQLITE_TYPE_FLOAT=2,
   SQLITE_TYPE_TEXT=3
};

struct LevelsStructure{
   int      nr;
   double   pr;
   ENUM_DTY dty;
   int      ty;
   double   lot;
   
   double   sl;
   double   tp;
   int      tp_pips;
   
   int      net_id;
   int      dont_send;
   int      tp_net_id;
   int      is_add_level;
   int      is_parent;
   double   this_price;
   int      this_step;
   double   ask;
   double   bid;
   
   LevelsStructure() {
      nr=0;
      pr=0.0;
      ty=-1;
      lot=0.0;
      sl=0.0;
      tp=0.0;
      tp_pips=0;
      net_id=0;
      dont_send=0;
      tp_net_id=0;
      is_add_level=0;
      is_parent=0;
      this_price=0.0;
      this_step=0;
      ask=0.0;
      bid=0.0;
   }
};

struct NetStructure{
   int nr;
   ENUM_DTY dty;
   NetStructure(){
      nr=1;
      dty=ENUM_DTY_BUY;
   }
};

int TRACE_tabs=0;
string TRACE_s="";
int DEBUG_tabs=0; 
string DEBUG_s="";

#ifdef TRACE
   //старт функции
	#define sf  TRACE_tabs++; TRACE_s="";for(int i=0;i<TRACE_tabs;i++){TRACE_s+="---|";}; Print(TRACE_s+__FUNCSIG__+"["+__LINE__+"]");
	//конец функции
	#define ef  TRACE_tabs--; if(TRACE_tabs<0)TRACE_tabs=0;
	#define sfo TRACE_tabs++; TRACE_s="";for(int i=0;i<TRACE_tabs;i++){TRACE_s+="---|";}; Print(TRACE_s+__FUNCSIG__+"["+__LINE__+"]{");
	#define efo ef; TRACE_s="";for(int i=0;i<TRACE_tabs;i++){TRACE_s+="---|";}; Print(TRACE_s+__FUNCSIG__+"["+__LINE__+"]}");
	
	//старт цикла
	#define sc(i) TRACE_s="";for(int i=0;i<TRACE_tabs;i++){TRACE_s+="---|";} StringReplace(TRACE_s,"}","");TRACE_s+="{";Print(TRACE_s+"["+i+"]");
	//конец цикла
	#define ec(i) TRACE_s="";for(int i=0;i<TRACE_tabs;i++){TRACE_s+="---|";} StringReplace(TRACE_s,"{","");TRACE_s+="}"; Print(TRACE_s+"["+i+"]"); 
	#define zx sf
	#define xz ef
#else
	#define sf 
	#define ef
	#define sfo
	#define efo
	#define zx
	#define xz
	#define sc(i)
	#define ec(i)
#endif

#define ROWS(a) ArrayRange(a,0)
#define LAST(a) ROWS(a)-1
#define ADDROW(a) ArrayResize(a,(ROWS(a)+1))
#define DROP(a) ArrayResize(a,0);

#define _PRINT(t) Print("DEBUG MSG :: FILE ["+(string)__FILE__+"] :: LINE ["+(string)__LINE__+"] :: FUNC ["+__FUNCSIG__+"] :: "+t); 

bool DBGAssertion = false;
#ifdef DEBUG
	#define DPrint(t) _PRINT(t)
	#define DEBUG_DB debug_testing=true;
	#define DPrintIf(t) if(DBGAssertion){_PRINT(t);}
#else 
	#define DPrint(t)
	#define DEBUG_DB 
	#define DPrintIf(t)
#endif 	

#ifdef DEBUG2
	#define DPrint2(t) _PRINT(t)
#else 
   #define DPrint2(t)
#endif     	

#ifdef DEBUG3
	#define DPrint3(t) _PRINT(t)
#else 
   #define DPrint3(t)
#endif     	

#ifdef DEBUG  
   #define assert(condition, message) \
      if(!(condition)) \
        { \
         string fullMessage= \
                            #condition+", " \
                            +__FILE__+", " \
                            +__FUNCSIG__+", " \
                            +"line: "+(string)__LINE__ \
                            +(message=="" ? "" : ", "+message); \
         \
         _PRINT("Assertion failed! "+fullMessage); \
         double x[]; \
         ArrayResize(x, 0); \
         if(STOP_ON_BAD_ASSERT){\
            x[1] = 0.0; \
         } \ 
        }
#else 
   #define assert(condition, message) ;
#endif
//+------------------------------------------------------------------+


//======================================================

#define LOGERR(err, errcode) Print("SQLite ERROR file["+ __FILE__ +"] line["+ (string)__LINE__ +"] " +"<"+__FUNCSIG__+">"+ " CODE ["+(string)errcode+"] "+(string)err);
#define LOGSQL(sql) Print("SQLite ERROR query :: "+sql);

#define STOP_HACK LOGERR("programm stoped",2001) stop_executing();