//+------------------------------------------------------------------+
//|                                                 csqlite_base.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#define BASE

//#include <Object.mqh>
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
#include <SQLite_v2.1\csqlite_querybuilder.mqh>

#include <SQLite_v2.1\sysNormalize.mqh>
#include <SQLite_v2.1\sysTrades.mqh>

class CSQLiteBase{
   private:
      CSQLite        *m_pConnector;
      string         m_errtext;
      uint           m_errcode;
      string         m_sql;
      CSQLiteCursor  *m_cursor_cache_columns; //кэш курсора запроса для изучения колонок таблицы 
      string         m_table_name; //для хранения кэша имени таблицы для которой узнаются колонки
      bool           m_Initialized;
      bool           m_is_transaction;//если была команда BEGIN. команда COMMIT снимает флаг активной транзакции
      CSQLiteQueryBuilder m_qb;
         
   public:
      CSQLiteBase(){
         m_Initialized=false;
      };
      ~CSQLiteBase(){
         Close();
      };
   
   public:
      void           Init(CSQLite *pConnector){
                        m_pConnector=pConnector; 
                        m_pConnector.stop_on_prepare_fail=true;
                        m_Initialized=true;
                     };
                     
      void           Close(){
                        m_Initialized=false;
                        if(CheckPointer(m_cursor_cache_columns)==POINTER_DYNAMIC){
                           delete m_cursor_cache_columns;
                        }
                     };
      CSQLite        *Connector(){return(m_pConnector);};
      string         GetDBFile(){return m_pConnector.get_db_file();};
      
   public:
      string         Get(string select, string tbl, string where=""){
                        string result=NULL;
                        
                        CSQLiteCursor* p=Query(select, tbl, where);
                        
                        result=p.GetValue(0);
                        
                        if(CheckPointer(p)==POINTER_DYNAMIC){
                           delete p;
                        }
                        
                        return(result);
                     }
      bool           Is_Transaction(){return(m_is_transaction);}
      bool           Exec(string const q){
                        if(q=="" || q==NULL){
                           LOGERR("query is empty",2001);
                           STOP_HACK
                           return(false);
                        }
                        if(!m_Initialized){
                           LOGERR("class is not initialized whith connector",2000);
                           STOP_HACK
                           return(false);
                        }
                        
                        if(q=="BEGIN"){
                           m_is_transaction = true;
                        }
                        
                        if(q=="COMMIT"){
                           m_is_transaction = false;
                        }
                        
                        if(!m_pConnector.exec(q)){
                           m_errcode=m_pConnector.errcode();
                           m_errtext=m_pConnector.error();
                           m_sql=q;
                           LOGERR(m_errtext,m_errcode);
                           LOGSQL(q);
                           return(false);
                        }
                        return(true);
                     };
      bool           Prepare(string const q){
                        if(!m_pConnector.prepare(q)){
                           m_errcode=m_pConnector.errcode();
                           m_errtext=m_pConnector.error();
                           m_sql=q;
                           LOGERR(m_errtext,m_errcode);
                           LOGSQL(m_sql);
                           return(false);
                        }
                        return(true);
                     };
                           
      int            Stmt(){return(m_pConnector.Stmt());};
      void           Stmt(int istmt){m_pConnector.Stmt(istmt);}                     
      
      uint           Step(){return(m_pConnector.step());}
      
      bool           Reset(){return(m_pConnector.reset());}
      string         Sql(){
                        uint pSql = m_pConnector.sql_pointer();
                        return(ptr2str(pSql));
                     }                        
      string         Expanded_sql(){
                        uint pSql = m_pConnector.expanded_sql_pointer();
                        return(ptr2str(pSql));
                     }                  
      bool           Bind_text(int index, string const text){
                        DPrint((string)index+"="+(string)text);
                        return(m_pConnector.bind_text(index, text));
                     };
                     
      void          Reset_bindings(){m_pConnector.clear_bindings();}                                    
      
      bool          Delete(const string tbl_name, const string where_clause=""){
                        string q="DELETE FROM "+tbl_name+" "+((where_clause!="")?"WHERE "+where_clause:"");
                        return(Exec(q));
                    }
               
      int           Insert(string const tbl, CArrayKeyVal &kv){
                        string q = buildInsert(tbl, kv);
                        Exec(q);
                        return(m_pConnector.last_insert_rowid());
                     };
      
      int           Insert(string const tbl, string const nullColumnHack="_ID"){
                        string q = "INSERT INTO "+tbl+" ("+nullColumnHack+") VALUES (NULL)";
                        Exec(q);
                        return(m_pConnector.last_insert_rowid());
      }                     
      
      void           Upsert(string tbl, CArrayKeyVal& kv, string where){
                        START("========== BUILD UPDATE ")
                           if(kv.Total() == 0){
                              return; //нет данных для обновления
                           }
                           string update = buildUpdate(tbl, kv, where)+";";
                           DPrint("UPDATE :: "+update);
                        END
                        
                        START("========== EXEC UPDATE");
                           Exec(update);
                        END       
                        
                        START("========== QUERY SELECT changes()");       
                           CSQLiteCursor* pUpdate = RawQuery("SELECT changes();");
                        END
                        
                        START("========== GET changes()");
                           int changes = (int)pUpdate.GetValue("changes()");
                        END
                        
                        START("========== DELETE POINTER pUpdate")   
                           if(CheckPointer(pUpdate)==POINTER_DYNAMIC){
                              delete pUpdate;
                           }
                        END
                        
                        if(changes<=0){
                           START("========== BUILD INSERT")
                              string insert = buildInsert(tbl, kv, false);
                           END
                           
                           START("========== EXEC INSERT")
                              Exec(insert);
                           END
                        }                                              
      }
                         
      string         PrepareInsert(string tbl, CArrayKeyVal &kv,string where="");                               
      
      string         buildInsert(string const tbl, CArrayKeyVal &kv, bool need_column_exists_check = true){
                        string q="INSERT INTO "+tbl+" ";
                        string col_set="";
                        string val_set="";
                     
                        for(int i=0; i<kv.Total(); i++)
                          {
                          
                           //if(!IsColumnExists(tbl,kv[i].key)){continue;}
                           kv.Index(i);
                           if(need_column_exists_check){
                              if(!IsColumnExist(tbl, kv.Key())){continue;}
                           }   
                           col_set=col_set+" '"+kv.Key()+"',";
                           val_set=val_set+" '"+kv.Val()+"',";
                     
                           
                          }
                     
                        col_set=col_set!="" ? "("+col_set+")" : "";
                        val_set=val_set!="" ? "("+val_set+")" : "";
                        
                        StringReplace(col_set,",)",")");
                        StringReplace(val_set,",)",")");
                        
                        q=q+col_set+" VALUES "+val_set;
                        return(q);
                     };
      
      string         buildUpdate(const string tbl, CArrayKeyVal &kv, const string where){
                        string q="UPDATE OR IGNORE '"+tbl+"' SET ";
                        while(kv.Next()){
                           q=q+""+kv.Key()+"='"+kv.Val()+"'";
                           if(kv.Index()<kv.Total()-1){//добавляем запятые
                              q=q+", ";
                           }
                        }
                          
                        q+=" WHERE "+where;
                                                
                        return(q);
                     }
      
      CSQLiteCursor *RawQuery(const string q){
                        Prepare(q);
                        CSQLiteCursor *cursor = new CSQLiteCursor(m_pConnector);
                        return(cursor);
                     }
      
      string         buildQuery(string const cols, string const from, string const where=""){
                        string q="SELECT ";
                        
                        q+= cols==NULL ? "* " : cols+" ";
                        q+= "FROM "+from+" ";
                        q+= (where=="")||(where==NULL) ? "" : "WHERE "+where;
                        
                        return(q);
                     };
      
      CSQLiteCursor  *Query(string const cols, string const from, string const where, string &where_args[]){
                        string q=buildQuery(cols, from, where);
                        DPrint(q);
                        
                        CString s;
                        s.Assign(q);
                        
                        if(ROWS(where_args) >= 1){   
                           
                           for(int i=0; i<ROWS(where_args); i++){
                              DPrint(where_args[i]);
                              s.ReplaceFirst("?", where_args[i]);
                           }
                        }
                        
                        q=s.Str();
                        DPrint(q);
                        //Prepare(q);
                        //CSQLiteCursor *cursor = new CSQLiteCursor(m_pConnector);
                        return(RawQuery(q));
                     };
      
      CSQLiteCursor  *Query(string const cols, string const from, string const where=""){
                        string a[];
                        ArrayResize(a,0);
                        return(Query(cols, from, where,a));
                     };
                     
      CSQLiteCursor  *Query(string const cols, string const from, CArrayKeyVal* where){
                        string a[];
                        string where_string="";
                       
                        int count = where.Total();
                        ArrayResize(a,count);
                        for(int i=0; i<count; i++){
                           where.Index(i);
                           string key=where.Key();
                           string val=where.Val();
                           
                           //bool   is_query=where.IsQuery();
                           //if(!is_query){
                              val="'"+val+"'"; 
                           //}
                           
                           where_string+=key+"="+val+((i<count-1)?" AND ":"");
                           
                        }
                        
                        DPrint("where_string = "+where_string);
                        
                        return(Query(cols,from,where_string));
                        
                     };                     

      bool           IsTableExistBySelectError(const string tbl_name){
                        string q="SELECT * FROM "+tbl_name+" LIMIT 0";
                        bool stop_on_prepare_fail = m_pConnector.stop_on_prepare_fail=false;
                        bool r = Prepare(q);
                        m_pConnector.finalize();
                        m_pConnector.stop_on_prepare_fail = stop_on_prepare_fail;
                        if( !r ){
                           DPrint("Table <"+tbl_name+"> not exists");
                        }
                        return(r);
                     }
                                          
      bool           IsTableExist(string const tbl_name){
                        bool r=false;
                        CSQLiteCursor *cursor = Query("count(*)","sqlite_master","TYPE='table' and NAME='"+tbl_name+"'");                                   
                        if(cursor.Next()){
                           if((int)cursor.GetValue(0) > 0){
                              r=true;
                           }else{
                              r=IsTableExistBySelectError(tbl_name);
                           }
                        }
                        
                        delete cursor;
                        return(r);
                     };                 
      
      bool           UpdateColumnCursorCache(const string tbl){
                        if(tbl!=m_table_name){
                           m_table_name=tbl;
                           if(CheckPointer(m_cursor_cache_columns)==POINTER_DYNAMIC){
                              delete m_cursor_cache_columns;
                           }
                           m_cursor_cache_columns = RawQuery("SELECT * FROM "+tbl+" LIMIT 0");
                        }
                        return(true);
                     }
      
      bool           IsColumnExist(const string tbl, const string col_name){
                        bool res = true;
                        
                        UpdateColumnCursorCache(tbl);
                        
                        if(m_cursor_cache_columns.GetColumnIndex(col_name)<0){
                           res=false;
                        }
                        
                        return(res); 
                     }
      
      string         PrintColumnNames(const string tbl){
                        UpdateColumnCursorCache(tbl);
                        string s=m_cursor_cache_columns.GetColumnNameString();
                        DPrint(s);
                        return(s);
                     }
                     
      string         PrintColumnNamesWithType(const string tbl){
                        UpdateColumnCursorCache(tbl);
                        string s=m_cursor_cache_columns.GetColumnNamesWhithTypeString();
                        DPrint(s);
                        return(s);
                     }                     
                     
      string         Max(string const column_name, string const tbl){
                        string res="";
                        string _column_name=column_name;
                        if(_column_name==NULL){
                           _column_name="_ID";
                        }
                        CSQLiteCursor *pCursor = Query("MAX("+_column_name+")",tbl);
                        if(pCursor.Next()){
                           res = pCursor.GetValue(0);
                        }
                        
                        delete pCursor;
                        return(res);
                     };
                     
      bool           CreateOrUpdateTable(const string tbl_name, CArrayKeyVal &columns){
                        string create_table = m_qb.buildTable(tbl_name, columns, false);
                        DPrint("create_table_query = "+create_table);
                        if(!IsTableExist(tbl_name)){
                           DPrint("Table <"+tbl_name+"> not exists");
                           return(Exec(create_table));
                        }
                        
                        bool needUpdate = false;
                        UpdateColumnCursorCache(tbl_name);
                        CArrayKeyVal columns_old;
                        m_cursor_cache_columns.GetColumnNames(columns_old);
                        
                        if(!needUpdate){
                           if(columns.Total() != columns_old.Total()){
                              needUpdate = true;
                           }
                        }
                        
                        if(needUpdate){
                           DPrint("Table <"+tbl_name+"> need update");
                           columns_old.DeleteNotExistsKeys(columns);
                           
                           string columns_old_string = columns_old.JoinKeys(",");
                           
                           string q = "DROP TABLE IF EXISTS sqlitestudio_temp_table; \n";
                                  q+= "CREATE TABLE sqlitestudio_temp_table AS SELECT * FROM "+tbl_name+";\n";
                                  q+= "DROP TABLE "+tbl_name+"; \n";
                                  q+= create_table+";\n";
                                  q+= "INSERT INTO "+tbl_name+" ("+columns_old_string+") SELECT "+columns_old_string+" FROM sqlitestudio_temp_table; \n";
                                  q+= "DROP TABLE sqlitestudio_temp_table;";
                           DPrint("update query = "+q);                                  
                           return(Exec(q));                                                 
                        }
                        return(true);
                     };
                     
         bool  CreateOrUpdateView(string view, string q){
            bool result=true;
            string _q   = "DROP VIEW IF EXISTS "+view+";\n"
                        + "CREATE VIEW "+view+" AS "+q+";\n";
            result = Exec(_q);
            return(result);            
         };                                                          
      
};

string CSQLiteBase::PrepareInsert(string tbl, CArrayKeyVal &kv, string where=""){
   string q="INSERT INTO `"+tbl+"` ";
   string col_set="(";
   string val_set="(";

   for(int i=0; i<kv.Total(); i++)
     {
     
      //if(!IsColumnExists(tbl,kv[i].key)){continue;}
      kv.Index(i);
      col_set=col_set+"`"+kv.Key()+"`";
      val_set=val_set+"'"+kv.Val()+"'";

      if(i<kv.Total()-1)
        {
         col_set=col_set+",";
         val_set=val_set+",";
        }
     }

   col_set=col_set+")";
   val_set=val_set+")";
   q=q+col_set+" VALUES "+val_set;

   //if(where != ""){
   //   where = " WHERE ("+where+")";
   //   
   //}
   
   //StringAdd(q,where);
   return(q);               
}
