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
uint sqlite3_column_count(uint stmt_h);

string sqlite3_column_name16(uint stmt_h, int icol);

uint sqlite3_step(uint stmt_h);

uint sqlite3_reset(uint sqlite3_stmt);

uint sqlite3_finalize(uint sqlite3_stmt);

string sqlite3_column_text16(uint stmt_h,uint iCol);

string sqlite3_errmsg16(uint h); // error message

uint sqlite3_extended_errcode(uint db);

uint sqlite3_next_stmt(uint h,uint stmt_h); /* 2nd param can be NULL*/

uint sqlite3_memory_used(void);

// Binds
int sqlite3_bind_double(uint sqlite3_stmt,uint colnum,double inp_double);
int sqlite3_bind_int(uint sqlite3_stmt,uint colnum,int inp_int);
int sqlite3_bind_text16(uint sqlite3_stmt,uint colnum,string txt,uint size_in_bytes,int param);
//---

int sqlite3_threadsafe(void);

#import
//+------------------------------------------------------------------+
//|   struct to export sql results
//+------------------------------------------------------------------+
struct sql_results// sql results export struct
  {
   string            value[];
   string            colname[];
  };
  
#ifndef BASE
#include <SQLite_v2.1\csqlite_defs.mqh> 
#endif   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSQLite
  {
public:  
   string            db_column_names[];  
   //structTableColumns tbl_cols[];
   bool					connected;
   string				last_error_text;
   uint					last_error_code;
public:
   bool              connect(string db_file);
   bool              exec(string query);
   string            get_cell(string query);
   uint              get_array(string query,sql_results &out[]);
   //uint              get_array(string query,sql_results2 &r[]);
   //uint              get_array(sql_results2 &r[]); //подготовить и забаиндить вручную
   
   string            get_db_file(){return db_host_file;};
   // Transactions
   bool              prepare_insert_transaction(string TableName);
   bool              begin_transaction(void) { return(exec("BEGIN;"));}
   bool              commit_transaction(void){ return(exec("COMMIT;"));}
   // Binds http://www.sqlite.org/c3ref/bind_blob.html
   bool              bind_int(uint colnum,int inp_int){return(sqlite3_bind_int(db_stmt_h,colnum,inp_int)==SQLITE_OK ? true : false);}
   bool              bind_double(uint colnum,double inp_double){return(sqlite3_bind_double(db_stmt_h,colnum,inp_double)==SQLITE_OK ? true : false);}
   bool              bind_text(uint colnum,string inp_str){return(sqlite3_bind_text16(db_stmt_h,colnum,inp_str,StringLen(inp_str)*2,SQLITE3_STATIC)==SQLITE_OK ? true : false);}

   uint              step(void){ uint r = sqlite3_step(db_stmt_h); if(r != SQLITE_ROW){int a=1;} if(r==SQLITE_ERROR){LOGERR(error(), errcode());} return(r); }
   bool              reset(void){ bool b=true; uint r=sqlite3_reset(db_stmt_h); if(r != SQLITE_OK){b=false; LOGERR(error(), errcode());} return(b);} /*http://www.sqlite.org/c3ref/reset.html*/
   bool              finalize(void){ return(sqlite3_finalize(db_stmt_h)==SQLITE_OK ? true : false);} /*http://www.sqlite.org/c3ref/finalize.html*/
   
   bool              next(void){uint r=step(); if(r==SQLITE_ROW){return(true);} if(r==SQLITE_DONE){reset(); finalize(); return(false);}else{LOGERR(error(), errcode());}return(false);};
   string            value(int column_index){return(sqlite3_column_text16(db_stmt_h, column_index));};                     
                     //prepare("select * from table"); while(next()){ чего-то делаем с данными из запроса }

   uint              column_count(){return(sqlite3_column_count(db_stmt_h));};
   string            column_name(int column_index=0){return(sqlite3_column_name16(db_stmt_h, column_index));}
                        
   uint              memory_used(void) {return(sqlite3_memory_used());} /*http://www.sqlite.org/c3ref/memory_highwater.html*/
   string            error(void){last_error_text = sqlite3_errmsg16(db_hwd); return(last_error_text);}
   uint              errcode(void){last_error_code = sqlite3_extended_errcode(db_hwd); return(last_error_code);}

   void					CSQLite(){connected = false;};
   void             ~CSQLite(); // destructor
   
   bool              prepare(string query);
   bool              is_prepared(){
                        bool res = (!db_stmt_h)? false : true;
                        return(res);
                     }
                     
   int               Stmt(){return(db_stmt_h);}
   void              Stmt(const int stmt){db_stmt_h=stmt;}                     
private:
   uchar             db_stmt[];
   int               db_stmt_h; // query handle
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
   if(sqlite3_prepare16_v2(db_hwd,query,-1,db_stmt_h,NULL)!=SQLITE_OK || !db_stmt_h) //+(MA) 2016-07-29
     {
      Print("SQLite preparation failure. Error "+error());
      Print(query);
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| SQLite one way execution function. This wont return result(s)
//+------------------------------------------------------------------+
bool CSQLite::exec(string query)
  {
   uchar q[];
   u2a(query,q);
   if(sqlite3_exec(db_hwd,q,NULL,NULL,NULL)!=SQLITE_OK){ Print("SQLite exec failure. Error "+error()); return(false); }
   ArrayFree(q);
   return(true);
  }
//+------------------------------------------------------------------+
//| SQLite prepare insert transaction
//+------------------------------------------------------------------+
bool CSQLite::prepare_insert_transaction(string TableName)
  {
//Getting column names
   string query="PRAGMA table_info('"+TableName+"');";
   sql_results columns[];
   get_array(query,columns);
//End of Getting column names
//Generating transactional insert query
   string names,vals;
   for(int i=0;i<ArraySize(columns);i++)
     {
      names+=columns[i].value[1]+",";
      vals+="?,";
     }
   string insq="INSERT INTO "+TableName+" ("+names+") VALUES ("+vals+");";
   StringReplace(insq,",)",")"); //removing last ,s
                                 //End of Generating transactional insert query
   //Print(insq);                                 
   ArrayFree(columns);

   return(prepare(insq));
  }
//+------------------------------------------------------------------+
//| This fanction will return only the first column of the first row (A:1)
//+------------------------------------------------------------------+
string CSQLite::get_cell(string query)
  {
   prepare(query);
   if(sqlite3_column_count(db_stmt_h)>1) Print("Warning! Query returned more than one cell. Function get_cell will return only one cell.");
   if(step()!=SQLITE_ROW) {Print("Error: get_cell query didnt returned results.");Print("Query: "+query); sqlite3_finalize(db_stmt_h); return(NULL);}
   string r=sqlite3_column_text16(db_stmt_h,0);
   reset();
   finalize();
   return(r);
  }
//+------------------------------------------------------------------+
//| This function will return string array as *sql_results*
//+------------------------------------------------------------------+
uint CSQLite::get_array(string query,sql_results &out[])
  {
   prepare(query);
   uint column_count=sqlite3_column_count(db_stmt_h);
   
   uint i=0;
   
   while(step()==SQLITE_ROW)
     {
      ArrayResize(out,i+1);
      ArrayResize(out[i].value,column_count);
      for(uint j=0;j<column_count;j++)
        {
         out[i].value[j]=sqlite3_column_text16(db_stmt_h,j);
        }
      i++;
     }

   if(ArrayRange(out,0)>0){
      for(uint ic=0;ic<column_count;ic++){
         ArrayResize(db_column_names,ic+1);
         ArrayResize(out[0].colname,ic+1);
         db_column_names[ic]=sqlite3_column_name16(db_stmt_h,ic);
         out[0].colname[ic]=db_column_names[ic];
      }
   }

   reset();
   finalize();
   return(i);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| This function will return string array as *sql_results*
//+------------------------------------------------------------------+
//uint CSQLite::get_array(string query,sql_results2 &r[])
//  {
//   prepare(query);
//   uint column_count=sqlite3_column_count(db_stmt_h);
//   string col_names[];
//   ArrayResize(col_names, 0, column_count);
//   
//   
//   //ArrayResize(db_column_names,column_count);
//   //for(uint ic=0;ic<column_count;ic++){
//   //   db_column_names[ic]=sqlite3_column_name16(db_stmt_h,ic);
//   //}
//   uint i=0;
//   while(step()==SQLITE_ROW)
//     {
//      
//      ArrayResize(r,i+1);
//      ArrayResize(r[i].kv,column_count);
//      
//      for(uint j=0;j<column_count;j++)
//        {
//         r[i].kv[j].val=sqlite3_column_text16(db_stmt_h,j);
//         //r[i].kv[j].key=db_column_names[j];
//         if(ArrayRange(col_names,0)==column_count){
//            r[i].kv[j].key = col_names[j];
//         }else{
//            ArrayResize(col_names, j+1);
//            col_names[j]=sqlite3_column_name16(db_stmt_h,j);
//            StringToUpper(col_names[j]);
//            r[i].kv[j].key = col_names[j];
//         }
//        }
//      i++;
//     }
//   reset();
//   finalize();
//   return(i);
//  }
  
//  uint CSQLite::get_array(sql_results2 &r[])
//  {
//   uint column_count=sqlite3_column_count(db_stmt_h);
//   string col_names[];
//   ArrayResize(col_names, 0, column_count);
//   
//   
//   //ArrayResize(db_column_names,column_count);
//   //for(uint ic=0;ic<column_count;ic++){
//   //   db_column_names[ic]=sqlite3_column_name16(db_stmt_h,ic);
//   //}
//   uint i=0;
//   while(step()==SQLITE_ROW)
//     {
//      
//      ArrayResize(r,i+1);
//      ArrayResize(r[i].kv,column_count);
//      
//      for(uint j=0;j<column_count;j++)
//        {
//         r[i].kv[j].val=sqlite3_column_text16(db_stmt_h,j);
//         //r[i].kv[j].key=db_column_names[j];
//         if(ArrayRange(col_names,0)==column_count){
//            r[i].kv[j].key = col_names[j];
//         }else{
//            ArrayResize(col_names, j+1);
//            col_names[j]=sqlite3_column_name16(db_stmt_h,j);
//            StringToUpper(col_names[j]);
//            r[i].kv[j].key = col_names[j];
//         }
//        }
//      i++;
//     }
//   reset();
//   finalize();
//   return(i);
//  }