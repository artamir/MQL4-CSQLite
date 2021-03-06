//+------------------------------------------------------------------+
//|                                                      csqlite.mqh |
//|                                            s.cornushov aka Graff |
//|                                              http://www.mql5.com |
//|                                                  $Revision: 105 $|
//+------------------------------------------------------------------+
#property copyright "Graff"
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define SQLITE_OK           0   /* Successful result */
/* beginning-of-error-codes */
#define SQLITE_ERROR        1   /* SQL error or missing database */
#define SQLITE_INTERNAL     2   /* Internal logic error in SQLite */
#define SQLITE_PERM         3   /* Access permission denied */
#define SQLITE_ABORT        4   /* Callback routine requested an abort */
#define SQLITE_BUSY         5   /* The database file is locked */
#define SQLITE_LOCKED       6   /* A table in the database is locked */
#define SQLITE_NOMEM        7   /* A malloc() failed */
#define SQLITE_READONLY     8   /* Attempt to write a readonly database */
#define SQLITE_INTERRUPT    9   /* Operation terminated by sqlite3_interrupt()*/
#define SQLITE_IOERR       10   /* Some kind of disk I/O error occurred */
#define SQLITE_CORRUPT     11   /* The database disk image is malformed */
#define SQLITE_NOTFOUND    12   /* Unknown opcode in sqlite3_file_control() */
#define SQLITE_FULL        13   /* Insertion failed because database is full */
#define SQLITE_CANTOPEN    14   /* Unable to open the database file */
#define SQLITE_PROTOCOL    15   /* Database lock protocol error */
#define SQLITE_EMPTY       16   /* Database is empty */
#define SQLITE_SCHEMA      17   /* The database schema changed */
#define SQLITE_TOOBIG      18   /* String or BLOB exceeds size limit */
#define SQLITE_CONSTRAINT  19   /* Abort due to constraint violation */
#define SQLITE_MISMATCH    20   /* Data type mismatch */
#define SQLITE_MISUSE      21   /* Library used incorrectly */
#define SQLITE_NOLFS       22   /* Uses OS features not supported on host */
#define SQLITE_AUTH        23   /* Authorization denied */
#define SQLITE_FORMAT      24   /* Auxiliary database format error */
#define SQLITE_RANGE       25   /* 2nd parameter to sqlite3_bind out of range */
#define SQLITE_NOTADB      26   /* File opened that is not a database file */
#define SQLITE_ROW         100  /* sqlite3_step() has another row ready */
#define SQLITE_DONE        101  /* sqlite3_step() has finished executing */

#define SQLITE3_STATIC     0 /*for sqlite3_bind_text16*/
#define SQLITE_TRANSIENT   -1 /*for sqlite3_bind_text16*/
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
#import "sqlite3.dll"
uint sqlite3_config(uint config_option);

uint sqlite3_open16(string filename,/* Database filename (UTF-8) */
                    uint &db_h       /* OUT: SQLite db handle */
                    );
uint sqlite3_finalize(uint h);
uint sqlite3_close(uint h);

uint sqlite3_prepare16_v2(
                          uint h,/* Database handle */
                          string q,/* SQL statement, UTF-16 encoded */
                          uint nByte,/* Maximum length of zSql in bytes. */
                          uint &ppStmt,/* OUT: Statement handle */
                          string pointer/* OUT: Pointer to unused portion of zSql */
                          );
uint sqlite3_prepare_v2(
                        uint h,/* Database handle */
                          uchar &q[],/* SQL statement, UTF-8 encoded */
                          uint nByte,/* Maximum length of zSql in bytes. */
                          uint &ppStmt,/* OUT: Statement handle */
                          string pointer/* OUT: Pointer to unused portion of zSql */
                        );                          

uint sqlite3_exec(
                  uint h,/* An open database */
                  uchar &SqlQ[],/* SQL to be evaluated */
                  uint callback,/* Callback function */
                  string s,/* 1st argument to callback */
                  string error                              /* Error msg written here UCHAR */
                  );
                  
int sqlite3_last_insert_rowid(uint h);                  
uint sqlite3_column_count(uint stmt_h);

string sqlite3_column_name16(uint stmt_h, int icol);

string sqlite3_column_decltype16(uint stmt_h, int icol);

uint sqlite3_step(uint stmt_h);

uint sqlite3_reset(uint sqlite3_stmt);

uint sqlite3_finalize(uint sqlite3_stmt);

string sqlite3_column_text16(uint stmt_h,uint iCol);

string sqlite3_errmsg16(uint h); // error message

uint sqlite3_extended_errcode(uint db);

uint sqlite3_next_stmt(uint h,uint stmt_h); /* 2nd param can be NULL*/

uint sqlite3_memory_used(void);

uint sqlite3_sql(uint h);//return pointer to sql text used to prepare stmt
uint sqlite3_expanded_sql(uint h);
// Binds
int sqlite3_bind_double(uint sqlite3_stmt,uint colnum,double inp_double);
int sqlite3_bind_int(uint sqlite3_stmt,uint colnum,int inp_int);
int sqlite3_bind_text16(uint sqlite3_stmt,uint colnum,string txt,uint size_in_bytes,int param);
int sqlite3_bind_text(uint sqlite3_stmt,uint colnum,uchar &txt[],uint size_in_bytes,int param);
int sqlite3_clear_bindings(uint sqlite3_stmt);
//---

int sqlite3_threadsafe(void);

#import
  
#ifndef BASE
#include <SQLite_v2.1\csqlite_defs.mqh> 
#include <SQLite_v2.1\csqlite_funcs.mqh> 
#endif   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSQLite
  {
public:  
   bool					connected;
   string				last_error_text;
   uint					last_error_code;
   bool              stop_on_prepare_fail;
public:
   bool              connect(string db_file);
   bool              exec(string query);
   int               last_insert_rowid(){return((int)sqlite3_last_insert_rowid(db_hwd));}   
   string            get_db_file(){return db_host_file;};
   
   bool              bind_int(uint colnum,int inp_int){return(sqlite3_bind_int(db_stmt_h,colnum,inp_int)==SQLITE_OK ? true : false);}
   bool              bind_int(int stmt_h,uint colnum,int inp_int){return(sqlite3_bind_int(stmt_h,colnum,inp_int)==SQLITE_OK ? true : false);}
   
   bool              bind_double(uint colnum,double inp_double){return(sqlite3_bind_double(db_stmt_h,colnum,inp_double)==SQLITE_OK ? true : false);}
   bool              bind_double(int stmt_h,uint colnum,double inp_double){return(sqlite3_bind_double(stmt_h,colnum,inp_double)==SQLITE_OK ? true : false);}
   
   bool              bind_text(uint colnum,string inp_str){
                        DPrint((string)colnum+"="+inp_str);
                        uchar q[];
                        u2a(inp_str,q);
                        //int r=sqlite3_bind_text16(db_stmt_h,colnum,inp_str,StringLen(inp_str)*2,SQLITE3_STATIC);
                        int r=sqlite3_bind_text(db_stmt_h,colnum,q,-1,SQLITE3_STATIC);
                        return(r==SQLITE_OK ? true : false);
                     }
   //bool              bind_text(uint colnum,string inp_str){return(sqlite3_bind_text16(db_stmt_h,colnum,inp_str,-1,SQLITE3_STATIC)==SQLITE_OK ? true : false);}
   bool              bind_text(int stmt_h,uint colnum,string inp_str){return(sqlite3_bind_text16(db_stmt_h,colnum,inp_str,StringLen(inp_str)*2,SQLITE3_STATIC)==SQLITE_OK ? true : false);}

   int               clear_bindings(){return(sqlite3_clear_bindings(db_stmt_h));}

   uint              step(void){ uint r = sqlite3_step(db_stmt_h); if(r != SQLITE_ROW){int a=1;} if(r==SQLITE_ERROR){LOGERR(error(), errcode());} return(r); }
   uint              step(int stmt_h){ uint r = sqlite3_step(stmt_h); if(r != SQLITE_ROW){int a=1;} if(r==SQLITE_ERROR){LOGERR(error(), errcode());} return(r); }
   bool              reset(void){ bool b=true; uint r=sqlite3_reset(db_stmt_h); if(r != SQLITE_OK){b=false; LOGERR(error(), errcode());} return(b);} /*http://www.sqlite.org/c3ref/reset.html*/
   bool              reset(int stmt_h){ bool b=true; uint r=sqlite3_reset(stmt_h); if(r != SQLITE_OK){b=false; LOGERR(error(), errcode());} return(b);} /*http://www.sqlite.org/c3ref/reset.html*/
   bool              finalize(int stmt_h=-1){
                        DPrint("stmt_h="+stmt_h);
                        int _stmt_h=(stmt_h==-1)?db_stmt_h:stmt_h;
                        bool result = false;
                        if(ISVAL(db_stmts,_stmt_h)){
                           result = finalize_core(_stmt_h);
                           if(result){
                              DELVAL(db_stmts,_stmt_h);
                           }   
                        }else{
                           result=true;
                        }
                        return(result);
                     }
   void              finalize_all(){
                        Print("db_stmts = "+(string)stmt_count());
                        while(ROWS(db_stmts)>0){
                           finalize(db_stmts[LAST(db_stmts)]);
                        }
                     }                  
   bool              finalize_core(void){ return(sqlite3_finalize(db_stmt_h)==SQLITE_OK ? true : false);} /*http://www.sqlite.org/c3ref/finalize.html*/
   bool              finalize_core(int stmt_h){ return(sqlite3_finalize(stmt_h)==SQLITE_OK ? true : false);} /*http://www.sqlite.org/c3ref/finalize.html*/
   
   bool              next(void){uint r=step(); if(r==SQLITE_ROW){return(true);} if(r==SQLITE_DONE){reset(); finalize(); return(false);}else{LOGERR(error(), errcode());}return(false);};
   bool              next(int stmt_h){uint r=step(stmt_h); if(r==SQLITE_ROW){return(true);} if(r==SQLITE_DONE){reset(stmt_h); finalize(stmt_h); return(false);}else{LOGERR(error(), errcode());}return(false);};
   string            value(int column_index){return(sqlite3_column_text16(db_stmt_h, column_index));};                     
   string            value(int stmt_h, int column_index){return(sqlite3_column_text16(stmt_h, column_index));};                     
                     //prepare("select * from table"); while(next()){ чего-то делаем с данными из запроса }

   uint              column_count(){return(sqlite3_column_count(db_stmt_h));};
   uint              column_count(int stmt_h){return(sqlite3_column_count(stmt_h));};
   string            column_name(int column_index=0){return(sqlite3_column_name16(db_stmt_h, column_index));}
   string            column_name(int stmt_h, int column_index=0){return(sqlite3_column_name16(stmt_h, column_index));}                        
   
   string            column_type(int stmt_h, int column_index=0){
                        string s = sqlite3_column_decltype16(stmt_h, column_index);
                        return(s);
                     }
                        
   uint              memory_used(void) {return(sqlite3_memory_used());} /*http://www.sqlite.org/c3ref/memory_highwater.html*/
   string            error(void){last_error_text = sqlite3_errmsg16(db_hwd); return(last_error_text);}
   uint              errcode(void){last_error_code = sqlite3_extended_errcode(db_hwd); return(last_error_code);}

   void					CSQLite(){connected = false;stop_on_prepare_fail=true;};
   void             ~CSQLite(); // destructor
   
   bool              prepare(string query);
   bool              is_prepared(){
                        bool res = (!db_stmt_h)? false : true;
                        return(res);
                     }
                     
   int               Stmt(){return(db_stmt_h);}
   void              Stmt(const int stmt){db_stmt_h=stmt;}                     
   uint              sql_pointer(){return(sqlite3_sql(db_stmt_h));}
   uint              expanded_sql_pointer(){return(sqlite3_expanded_sql(db_stmt_h));}
   int               stmt_count(){return(ROWS(db_stmts));}
private:
   uchar             db_stmt[];
   int               db_stmt_h; // query handle
   int               db_stmts[];
   string            db_host_file;
   int               u2a(string txt,uchar &out[]){ return(StringToCharArray(txt,out)); }
protected:
   int               db_hwd; // db connection handle   
  };
//+------------------------------------------------------------------+
//| SQLite connection func
//+------------------------------------------------------------------+
bool CSQLite::connect(string db_file)
  {
   sqlite3_config(3); //serialized
   if(sqlite3_open16(db_file,db_hwd)!=SQLITE_OK){ Print("SQLite init failure. Error "+error()); return(false); }
   db_host_file=db_file;
   connected = true;
   return(true);
  }
//+------------------------------------------------------------------+
//| destructor  
//+------------------------------------------------------------------+
void CSQLite::~CSQLite()
  {
   //uint stmt_h_kill;
   //while(stmt_h_kill==sqlite3_next_stmt(db_hwd,NULL))
   //  {
   //   if(sqlite3_finalize(stmt_h_kill)!=SQLITE_OK) Print("SQLite finalization failure. Error "+error());
   //  }
   finalize();//+(MA) 2017/4/13 11:36)
   if(sqlite3_close(db_hwd)!=SQLITE_OK) Print("SQLite close failure. Error "+error());
  }
//+-----------------------------------------------------------------+
//| prepare func wrapper
//+-----------------------------------------------------------------+
bool CSQLite::prepare(string query)
  {
   uint result = sqlite3_prepare16_v2(db_hwd,query,-1,db_stmt_h,NULL);
   
   if(db_stmt_h){
      ADD(db_stmts,db_stmt_h);
   }
   if(result!=SQLITE_OK || !db_stmt_h) //+(MA) 2016-07-29
     {
      Print("SQLite preparation failure. Error "+error());
      Print(query);
      if(stop_on_prepare_fail){
         finalize_all();
         int a[];
         a[4]=7;
      }
      return(false);
     }
   ADD(db_stmts,db_stmt_h);  
   return(true);
  }
//+------------------------------------------------------------------+
//| SQLite one way execution function. This wont return result(s)
//+------------------------------------------------------------------+
bool CSQLite::exec(string query)
  {
   uchar q[];
   u2a(query,q);
   if(sqlite3_exec(db_hwd,q,NULL,NULL,NULL)!=SQLITE_OK){ 
      Print("SQLite exec failure. Error "+error()); 
      if(stop_on_prepare_fail){
         int a[];
         a[7]=4;
      }
      return(false); 
   }
   ArrayFree(q);
   return(true);
  }
