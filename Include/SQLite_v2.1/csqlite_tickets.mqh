//+------------------------------------------------------------------+
//|                                              csqlite_tickets.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#include <SQLite_v2.1\csqlite_base.mqh>
class CSQLiteTickets{
   private:
      CSQLiteBase *m_pDb; //указатель на переменную класса.
      CSQLiteQueryBuilder m_qb;//класс помошник создания запросов.
      
      bool        m_pDbCreatedInsight;
      string      m_tblT;  //таблица тикеты
      string      m_tblH;  //таблица исторических тикетов.
      string      m_tblTN; //таблица тикетов, которые есть в терминале на текущем тике.
      string      m_tblTO; //таблица тикетов, сохраненная с предыдущего тикета
      
      string      m_view_closed; //tickets.IT=1 and tickets.TI not in tickets_new.TI
      
      
   public:
      int   MNFilter;//Фильтрация тикетов по заданному магику
      string  SYFilter;//Фильтрация тикетов по заданному символу
      
   
   public:   
      CSQLiteTickets(){
         m_pDbCreatedInsight=false;
         MNFilter = -1;
         SYFilter = Symbol();
         #ifdef SYSTRADES
            MNFilter=TR_MN;
         #endif 
      }
      ~CSQLiteTickets(){
         Close();
      }
   
   public:
      int   _OrdersTotal();
      int   _Rows();      
   public:
      //Инициализация класса должна происходить
      //после инициализации класса CSQLiteBase
      //после установки доп параметров класса.
      void  Init(CSQLiteBase *pDb){
         m_pDb = pDb;
         InitVars();
         CreateTables();
         CreateViews();                     
      }
      void InitVars(){
         m_tblT = "table_tickets";
         m_tblH = "table_history";
         m_tblTO = "table_tickets_old";
         m_tblTN = "table_tickets_this";
         m_view_closed = "view_tickets_closed";
      }
      
      bool  CreateTables(){
         CArrayKeyVal columns;
         StdColumns(columns);
         //string   q=m_qb.buildTable(m_tblTN, columns);
         //bool     r=m_pDb.Exec(q);
         bool     r=m_pDb.CreateOrUpdateTable(m_tblTN, columns);
         
                  //q=m_qb.buildTable(m_tblTO, columns);
                  //r*=m_pDb.Exec(q);
                  r*=m_pDb.CreateOrUpdateTable(m_tblTO, columns);
                  
         CustomColumns(columns);         
                  //q=m_qb.buildTable(m_tblT, columns);
                  //r*=m_pDb.Exec(q);
                  r*=m_pDb.CreateOrUpdateTable(m_tblT, columns);
                  r*=m_pDb.CreateOrUpdateTable(m_tblH, columns);
         return(r);
      }
      
      void StdColumns(CArrayKeyVal &columns);
      void CustomColumns(CArrayKeyVal &columns);
      
      void Start(){
         START("========== BEGIN")
            m_pDb.Exec("BEGIN");
         END   
         //m_pDb.Delete(m_tblTO);
         //string q="INSERT INTO "+m_tblTO+" SELECT * FROM "+m_tblTN;
         //m_pDb.Exec(q);
         START("========== DELETE "+m_tblTN)
            m_pDb.Delete(m_tblTN);
         END
         //m_pDb.Exec("COMMIT");
         START("========= CHECK TICKETS")
            CheckTickets();   
         END
         
         START("========== COMMIT")
            m_pDb.Exec("COMMIT");
         END
         
      }
      
      void  Close(){
         if(m_pDbCreatedInsight){
            if(CheckPointer(m_pDb)==POINTER_DYNAMIC){
               delete m_pDb;
            }
         }
      }
      
      void CreateViews();
      void CheckTickets();      
      void GetStdData(int ticket, CArrayKeyVal &kv);
      void UpsertTicket(int ticket);
      void UpsertTicket(int ticket, CArrayKeyVal& kv);
      void UpsertTickets(double& tickets_array[], CArrayKeyVal& kv);
      void CopyClosedToHistory();      
};

void CSQLiteTickets::StdColumns(CArrayKeyVal &columns){
   columns.Clear();  //CKeyVal,name,sqlite_type,pr key, autoincrement, unique, notnull 
   //m_qb.buildColumn(columns,  "_ID",   SQLITE_TYPE_INTEGER, true,    true);
   m_qb.buildColumn(            columns,  "TI",       SQLITE_TYPE_INTEGER, true,    false,   true);            //OrderTicket
   m_qb.buildColumn(            columns,  "TY",       SQLITE_TYPE_INTEGER, false,   false,   false,   true);   //OrderType
   m_qb.buildColumn(            columns,  "LOT",      SQLITE_TYPE_FLOAT,   false,   false,   false,   true);   //OrderLots
   m_qb.buildColumn(            columns,  "OOP",      SQLITE_TYPE_FLOAT,   false,   false,   false,   true);   //OrderOpenPrice
   m_qb.buildColumn(            columns,  "OOT",      SQLITE_TYPE_INTEGER, false,   false,   false,   true);   //OrderOpenTime
   m_qb.buildColumn(            columns,  "OCP",      SQLITE_TYPE_FLOAT,   false,   false,   false,   true);   //OrderClosePrice
   m_qb.buildColumn(            columns,  "OCT",      SQLITE_TYPE_INTEGER, false,   false,   false,   true);   //OrderCloseTime
   m_qb.buildColumn(            columns,  "SY",       SQLITE_TYPE_TEXT,    false,   false,   false,   true);   //OrderSymbol
   m_qb.buildColumn(            columns,  "TP",       SQLITE_TYPE_FLOAT,   false,   false);
   m_qb.buildColumnDefaultValue(columns, (string)0.0);
   m_qb.buildColumn(            columns,  "SL",       SQLITE_TYPE_FLOAT,   false,   false);
   m_qb.buildColumnDefaultValue(columns, (string)0.0);
   m_qb.buildColumn(            columns,  "OPR",      SQLITE_TYPE_FLOAT);
   m_qb.buildColumnDefaultValue(columns, (string)0.0);
   m_qb.buildColumn(            columns,  "DTY",      SQLITE_TYPE_INTEGER); //Направление тикета
   m_qb.buildColumn(            columns,  "COMMENT",  SQLITE_TYPE_TEXT);
}

void CSQLiteTickets::CustomColumns(CArrayKeyVal &columns){
   m_qb.buildColumn(columns, "LEVEL_ID", SQLITE_TYPE_INTEGER); //ID уровня, которому принадлежит тикет
   m_qb.buildColumn(columns, "NET_ID",   SQLITE_TYPE_INTEGER); //ID сетки для которой выставляется уровень
   m_qb.buildColumn(columns, "PID_ID",   SQLITE_TYPE_INTEGER); //ID сессии для которой выставляется сетка
   m_qb.buildColumn(columns, "IT",       SQLITE_TYPE_INTEGER); //Если тикет не закрыт и не удален, тогда 1
   m_qb.buildColumn(columns, "PID",      SQLITE_TYPE_INTEGER); //ИД сессии, чтоб можно было прицепить фикс профит
   
}

void CSQLiteTickets::CreateViews(void){
   string q="SELECT TI FROM "+m_tblT+" WHERE IT=1 AND TI NOT IN (SELECT TI FROM "+m_tblTN+")";
   m_pDb.CreateOrUpdateView(m_view_closed,q);
   
   q = "SELECT count(*) as count FROM "+m_tblT+" WHERE IT=1";
   m_pDb.CreateOrUpdateView("view_tickets_orders_total",q);
}

void CSQLiteTickets::CheckTickets(void){
   
   CArrayKeyVal order_info;
   bool is_transaction = m_pDb.Is_Transaction();
   
   if(!is_transaction){
      START("========== BEGIN")
         m_pDb.Exec("BEGIN");
      END
   }
   
   START("========== FOR ORDER SELECT")
      int ot = OrdersTotal();
      for(int i=0; i<ot; i++){
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){continue;}
         
         if(MNFilter>-1){
            if(OrderMagicNumber() != MNFilter){continue;}
         }
         
         if(SYFilter != "" && SYFilter != NULL){
            if(OrderSymbol() != SYFilter){continue;}
         }
         
         order_info.Clear();
         int ti = OrderTicket();
         
         GetStdData(ti, order_info);
         DPrint(order_info.toString());
         START("================ INSERT "+m_tblTN);
         m_pDb.Insert(m_tblTN,order_info);
         END
         START("================ UPSERT"+m_tblT);
         m_pDb.Upsert(m_tblT,order_info,"TI="+(string)ti);
         END
      }
   END
   
   START("============= QUERY ON "+m_view_closed)
      CSQLiteCursor* pClosed = m_pDb.Query(NULL,m_view_closed);
   END
   
   START("========== WHILE NEXT "+m_view_closed)
      while(pClosed.Next()){
         order_info.Clear();
         int ti = (int)pClosed.GetValue("TI");
         GetStdData(ti, order_info);
         if(order_info.Total()==0){
            continue;
         }
         START("============== UPSERT "+m_tblT)
            m_pDb.Upsert(m_tblT,order_info,"TI="+(string)ti);
         END
      }
   END
   
   if(!is_transaction){
      START("=============== COMMIT")
         m_pDb.Exec("COMMIT");
      END
   }
   START("============== DELETE CURSOR")
   if(CheckPointer(pClosed)==POINTER_DYNAMIC){
      delete pClosed;
   }
   END
   
}

void CSQLiteTickets::UpsertTicket(int ticket){
   CArrayKeyVal kv;
   GetStdData(ticket, kv);
   m_pDb.Upsert(m_tblT,kv,"TI="+(string)ticket);
}

void CSQLiteTickets::UpsertTicket(int ticket,CArrayKeyVal& kv){
   START("========== UpsertTicket ");
      START("========== GetStdData");
         GetStdData(ticket,kv);
      END
      START("========== m_pDb.Upsert")
         m_pDb.Upsert(m_tblT,kv,"TI="+(string)ticket);
      END
   END
}

void CSQLiteTickets::UpsertTickets(double &tickets_array[],CArrayKeyVal& kv){
   
   //Если транзакция была открыта до вызова процедуры, то она должна быть закрыта после процедуры.
   bool is_transaction = m_pDb.Is_Transaction();
   
   if(!is_transaction){
      m_pDb.Exec("BEGIN");
   }   
   for(int i=0; i<ArrayRange(tickets_array,0); i++){
      UpsertTicket((int)tickets_array[i], kv);
   }
   if(!is_transaction){
      m_pDb.Exec("COMMIT");
   }
}

void CSQLiteTickets::GetStdData(int ticket,CArrayKeyVal &kv){
   if(!OrderSelect(ticket, SELECT_BY_TICKET)){return;}
   kv.Add("TI",ticket);
   kv.Add("TY",OrderType());
   kv.Add("LOT",OrderLots());
   kv.Add("TP",OrderTakeProfit());
   kv.Add("SL",OrderStopLoss());
   kv.Add("OOP",OrderOpenPrice());
   kv.Add("OOT",OrderOpenTime());
   kv.Add("SY",OrderSymbol());
   kv.Add("OCP",OrderClosePrice());
   kv.Add("OCT",OrderCloseTime());
   int it=(OrderCloseTime()>0)?0:1;
   kv.Add("IT",it);
   kv.Add("OPR",OrderProfit()+OrderSwap()+OrderCommission());
   
      ENUM_DTY dty;
      if(OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP){
         dty = ENUM_DTY_BUY;
      }else{
         dty = ENUM_DTY_SELL;
      }
   kv.Add("DTY",dty);
   kv.Add("COMMENT",OrderComment());
   
}

void CSQLiteTickets::CopyClosedToHistory(void){
   bool is_transaction = m_pDb.Is_Transaction();
   if(!is_transaction){
      START("========== BEGIN")
         m_pDb.Exec("BEGIN");
      END
   }   
   
   START("========== COPY")
      string q="INSERT INTO "+m_tblH+" SELECT * FROM "+m_tblT+" WHERE IT=0";   
      m_pDb.Exec(q);
   END
   
   START("========== DELETE CLOSED")
      m_pDb.Delete(m_tblT,"IT=0");
   END
      
   if(!is_transaction){   
      START("========== COMMIT")
         m_pDb.Exec("COMMIT");
      END
   }   
   
}

int CSQLiteTickets::_OrdersTotal(void){
   int result=0;
   
   string q="select * from view_tickets_orders_total";
   CSQLiteCursor* p=m_pDb.RawQuery(q);
   
   result = (int)p.GetValue(0);
   
   if(CheckPointer(p) == POINTER_DYNAMIC){
      delete p;
   }
   
   return(result);
}

int CSQLiteTickets::_Rows(void){
   int result=0;
   
   result=(int)m_pDb.Get("count(*) as count","table_tickets");
   
   return(result);
}