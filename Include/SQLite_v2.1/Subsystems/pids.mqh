//+------------------------------------------------------------------+
//|                                                         pids.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#include <SQLite_v2.1\Subsystems\Subsystem.mqh>
class CPids :public CSubsystem{
   private:
      int      m_id; //ид сетки для формирования апдэйта для установки значений заданных полей.
   
   public:   
      string   view_worked;
      string   view_closed;
   
   protected:
      virtual void StdColumns(CArrayKeyVal &columns);
   
   public:
      CPids();
      ~CPids(){};
      
   public:
      virtual  bool   Init( CSQLiteBase* pDb );
               void   CreateViews();
               int    Add (  );
               bool   Set ( CArrayKeyVal& kv, string where="" );
               string Get( string column="_ID", string where="" );
               int    GetId(  )        { return(m_id); }
               void   SetId( int id )  { m_id=id;      } 
};

void CPids::CPids( void ){
   m_tbl = "table_pids";
   view_worked = "view_pids_worked";
   view_closed = "view_pids_closed";
}

bool CPids::Init( CSQLiteBase* pDb ){
   bool result=true;
   CSubsystem::Init( pDb );
   
   CArrayKeyVal columns;
   StdColumns( columns );
   m_pDb.CreateOrUpdateTable( m_tbl, columns );
   CreateViews();
   return( result );
}

void CPids::CreateViews(void){
//   string q ="select TP.* FROM "+m_tbl+" as TP "
//            +"inner join table_nets as TN ON (TN.PID_ID=TP._ID) "
//            +"INNER join table_levels as TL ON (TL.NET_ID=TN._ID AND TL.IS_ADD_LEVEL=0) "
//            +"inner join table_tickets as TT ON (TT.LEVEL_ID=TL._ID AND TT.IT=1) "
//            +"GROUP BY TP._ID ";
//          m_pDb.CreateOrUpdateView(view_worked,q);
//
//          q ="select pid_id from ( "
//             +"    select pid_id, sum(it) as it from( "
//             +"        select TL.TP_NET_ID AS NET_ID, TT.IT from table_tickets as TT  "
//             +"        left join table_levels as TL ON TL._ID = TT.LEVEL_ID "
//             +"        left join table_nets as TN ON TN._ID = TL.NET_ID "
//             +"        where TL.IS_ADD_LEVEL = 0 "
//             +"        GROUP BY TL.TP_NET_ID, TT.IT) "
//             +"    group by net_id) "
//             +"where it =0 "
//             +" ";
//          m_pDb.CreateOrUpdateView(view_closed,q);              
//          
}

int CPids::Add( void ){
   int   result=-1;
   int   last_insert_row_id=m_pDb.Insert(m_tbl,"_ID");
         m_id=(int)GetValue("_ID","ROWID="+(string)last_insert_row_id);
         result=m_id;
   return( result );      
}

bool CPids::Set( CArrayKeyVal& kv , string where=""){
   bool result = true;
   
   string sWhere=where;
   if(where==""){
      sWhere="_ID="+(string)m_id;
   }
   
   string q=m_pDb.buildUpdate(m_tbl,kv,sWhere);
   result=m_pDb.Exec(q);
   
   return( result );
}

string CPids::Get( string column="_ID", string where="" ){
   CSQLiteCursor* pCursor = m_pDb.Query(column, m_tbl, where);
   
   string result = pCursor.GetValue(column);
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   } 
   
   return(result);
}

void CPids::StdColumns( CArrayKeyVal &columns ){
   m_qb.buildColumn( columns,"_ID", SQLITE_TYPE_INTEGER,true,true );
   m_qb.buildColumn( columns,"DTY", SQLITE_TYPE_INTEGER );
   m_qb.buildColumn( columns,"TP",  SQLITE_TYPE_FLOAT );
   m_qb.buildColumn( columns,"PR",  SQLITE_TYPE_FLOAT );
   m_qb.buildColumn( columns,"NR",  SQLITE_TYPE_INTEGER );//уровень сетки
   m_qb.buildColumn( columns,"PID", SQLITE_TYPE_INTEGER );//ид сессии
}