//+------------------------------------------------------------------+
//|                                     csqlite_datamanipulation.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#ifndef BASE
#include <SQLite_v2.1\msvcrt\memcpy.mqh>
#include <SQLite_v2.1\msvcrt\strlen.mqh>
#include <SQLite_v2.1\msvcrt\strcpy.mqh>
#include <SQLite_v2.1\csqlite_array_string.mqh>
#include <SQLite_v2.1\csqlite_array_obj.mqh>
#include <SQLite_v2.1\csqlite_string.mqh>
#include <SQLite_v2.1\csqlite_defs.mqh>
#include <SQLite_v2.1\csqlite_funcs.mqh>
#include <SQLite_v2.1\csqlite_ckeyval.mqh>
#include <SQLite_v2.1\csqlite.mqh>
#include <SQLite_v2.1\csqlite_cursor.mqh>
#endif

class CSQLiteQueryBuilder{
     
   public:
      CSQLiteQueryBuilder(){};
      ~CSQLiteQueryBuilder(){};
      
      string   buildTableHeader(const string tbl_name, bool if_not_exists=true, bool is_temp=false){
                  string q="CREATE "
                          +((is_temp)?" TEMP ":"")
                          +"TABLE "
                          +((if_not_exists)?" IF NOT EXISTS ":"")
                          +"'"+tbl_name+"'"
                          +" ";
                  
                  return(q);
               }
      
      string   buildTable(const string tbl_name, const string column_defs, bool if_not_exists=true, bool is_temp=false){
                  string cols = "("+((column_defs==NULL||column_defs=="")?" _ID INTEGER PRIMARY KEY AUTOINCREMENT ":column_defs)+")";
                 
                  string q=buildTableHeader(tbl_name, if_not_exists, is_temp)+cols;
                  return(q);
               }
               
      string   buildTableAs(const string tbl_name, const string as_select_stmt, bool if_not_exists=true, bool is_temp=false){
               
                  string q=buildTableHeader(tbl_name, if_not_exists, is_temp)+"AS "+as_select_stmt;
                  return(q);
               }               
      
      string   buildTable(const string tbl, CArrayKeyVal &column_def, const bool if_not_exists=true, const bool is_temp=false){
                  string columns = "";
                  bool isNext=false;
                  while(column_def.Next()){
                     columns+=column_def.Key()+" "+column_def.Val()+",";
                  };
                  
                  if(StringLen(columns)>0){
                     columns+=")";
                     StringReplace(columns,",)","");
                  }
                  return(buildTable(tbl, columns, if_not_exists, is_temp));
               }
      
      string   SQLiteType2String(ENUM_SQLITE_TYPE type){
                  string res="";
                  switch(type){
                     case SQLITE_TYPE_INTEGER:res="INTEGER";break;
                     case SQLITE_TYPE_FLOAT  :res="FLOAT";break;
                     case SQLITE_TYPE_TEXT   :res="TEXT";break;
                     default :res="";break;
                  }
                  
                  return res;
               }
      bool     buildColumn(   CArrayKeyVal           &kv, 
                              const string      name, 
                              ENUM_SQLITE_TYPE  type, 
                              bool              is_primary_key=false, 
                              bool              is_autoincrement=false,
                              bool              is_unique=false,
                              bool              is_not_null=false){
                  
                  string column_type = buildColumnType(  type, 
                                                         is_primary_key, 
                                                         is_autoincrement,
                                                         is_unique,
                                                         is_not_null);
                  kv.Add(name, column_type);
                  return(true);
               }

      string   buildColumn(   const string      name, 
                              ENUM_SQLITE_TYPE  type, 
                              bool              is_primary_key=false, 
                              bool              is_autoincrement=false,
                              bool              is_unique=false,
                              bool              is_not_null=false){
                  
                  string s = name+" "+buildColumnType(type, 
                                                      is_primary_key, 
                                                      is_autoincrement,
                                                      is_unique,
                                                      is_not_null);
                  return(s);
               }
                              
      string   buildColumnType(  ENUM_SQLITE_TYPE  type, 
                                 bool              is_primary_key=false, 
                                 bool              is_autoincrement=false,
                                 bool              is_unique=false,
                                 bool              is_not_null=false){
                  
                  string s=SQLiteType2String(type)+" "+( (is_primary_key)?"PRIMARY KEY":"" );
                  if(is_autoincrement){
                     if(type != SQLITE_TYPE_INTEGER){
                        DPrint("CAN NOT APPLY AUTOINCTEMENT ON NON INTEGER COLUMN TYPE");
                     }else{
                        s+=" AUTOINCREMENT";
                     }
                  }
                  s+=(is_unique)?" UNIQUE":"";
                  s+=(is_not_null)?" NOT NULL":"";
                  return(s);
               } 
               
   bool  buildColumnDefaultValue(CArrayKeyVal &columns, const string dv="''"){
      columns.Val(columns.Val()+" DEFAULT "+dv);
      return(true);
   }
};