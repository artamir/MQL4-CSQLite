//+------------------------------------------------------------------+
//|                                                    SanLevels.mq4 |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict

//#define DEBUG
#define STOP_ON_BAD_ASSERT false
//#define TEST
//#define DB_IN_FILE

int start_testing = 0;
int end_testing=0;
string test_name = "";

string test_print_otstup = "";

int start_array_timer[];
string start_array_names[];
int testing_last_index;


#define MAX(a,b) ((a>b)?a:b)

#ifdef TEST
#define GET_TEST_OTSTUP test_print_otstup=""; \
                        for(int test_index_counter=0; test_index_counter < LAST(start_array_names); test_index_counter++){ \
                           test_print_otstup+="    ";\
                        } 
#define TPrint(t) Print(test_print_otstup + t); 

#define START(t) test_name = t; \
                 start_testing = (int)GetMicrosecondCount();\
                 ADD(start_array_timer,start_testing);\
                 ADD(start_array_names,test_name);\
                 GET_TEST_OTSTUP \
                 Print(test_print_otstup +"{"+ t);
                 

#define END end_testing = (int)GetMicrosecondCount();\
                           testing_last_index = LAST(start_array_names);\
                           start_testing = start_array_timer[testing_last_index];\
                           test_name = start_array_names[testing_last_index];\
                           GET_TEST_OTSTUP \
                           ArrayResize(start_array_timer,(MAX(ROWS(start_array_timer)-1,0)));\
                           ArrayResize(start_array_names,(MAX(ROWS(start_array_names)-1,0)));\
                           PrintFormat(test_print_otstup +"}"+test_name+" ended in %f sec.",((end_testing-start_testing)/1000000.0));
#else 
   #define START(t)
   #define END
   #define TPrint(t)
#endif                            

#include <SQLite_v2.1\csqlite_tickets.mqh>
#include <SQLite_v2.1\subsystems\nets.mqh>
#include <SQLite_v2.1\subsystems\levels.mqh>

CSQLite SQLiteConnector;
CSQLiteBase db;
CNets nets;
CLevels levels;
CSQLiteTickets tickets;

input int S  = 100;
input int SPlus = 0;
input int TP = 700;
//если текущая сетка закрылась по тейку,
//то удалять ТП с противоположной сетки,
input bool DeleteTPFromRevers = false;
input int LL = 4;
input double Lot = 0.1;
input double Multy_revers = 1;
input double Multy_revers_multy = 2;
input double Multy_net = 2;
//input bool   useLockNet = false;
////суммарный объем сетки будет равен текущему объему противоположных тикетов
////если лот уровня будет больше или равен текущему объему сетки.
//input bool   LockNetKoef = 1.00; //Lock = 100% 

input bool useFixProfit=true;
input double FixProfit_Amount=500;

input bool useFixDD=true;
input double FixDD_Amount=500;

//если профит реверса больше минуса сетки, тогда закрываем 
//тикеты сетки.
input bool useFixIfReversGreat = false;
//разрешает использовать профит брошенных реверсных
input bool useFixReversWONet = false;
//разрешает не привязывать реверсные к противоположной сетке
input bool useReversWOTP = false;


int _S   = 100; //Шаг между уровнями сетки
int _SPlus = 0; //Увеличение шага от уровня сетки
int _TP  = 700; //тп от первого уровня сетки
int _LL  = 4;   //Лимитник выставлять каждый 4-й уровень  
double _Lot = 0.1;//Стартовый объем уровня сетки
double _Multy_revers = 1;//Коэф. изменения объема реверсного уровня
double _Multy_revers_multy = 2;//Коэф. увеличения объемов реверсных уровней. 
double _Multy_net = 2;//Коэф. изменения объема сетки

//double ThisPrice=0.0;

int pid=0;
int up_net_nr=0;
int up_net_nr_minus = 0;
int dw_net_nr=0;
int dw_net_nr_minus = 0;
int up_net_id=0;
int dw_net_id=0;

int levels_count=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   _S=S;
   _SPlus=SPlus;
   _TP=TP;
   _LL=LL;
   _Lot=Lot;
   _Multy_revers=Multy_revers;
   _Multy_revers_multy = Multy_revers_multy;
   _Multy_net=Multy_net;
   
   levels_count = (int)_TP/_S;
   
   Init();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Deinit();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   START("========== START");
      Start();
   END   
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void Start()
  {
   
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
   START("========= TICKETS -> START")
      tickets.Start();
   END
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);

//{ --- должна быть 1 сетка вверх и 1 сетка вниз
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
   START("========== SETPID");
      SetPid();
   END
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
   
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
   START("========== SEND NR");   
      SetNR();
   END   
   TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
   
   //ThisPrice = Ask;
   bool need_up_net=false;
   bool need_dw_net=false;
   
   //{ --- если сетка вверх закрыта, то создаем сетку
   START("========== IF UP NET CLOSED") 
      TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
      if(UpNetClosed()){
         TPrint("CSQLiteCursorCounter = "+CSQLiteCursorCounter);
         START("========== NEW UP NET")
            need_up_net=true;
            up_net_id = NewNet(ENUM_DTY_BUY, Ask);        
            SetNR();
            DPrint("new up net id :: "+(string)up_net_id);
         END
      }
   END
   //}

   //{ --- если сетка вниз закрыта, то создаем сетку
   START("========== IF DW NET CLOSED")
      if(DwNetClosed()){
         START("========== NEW DW NET")
            need_dw_net=true;
            dw_net_id = NewNet(ENUM_DTY_SELL, Bid);
            SetNR();
            DPrint("new dw net id :: "+(string)dw_net_id);
         END
      }
   END
   //}

   if(need_up_net){
      START("========== NEW UP LEVELS")
         if(up_net_nr > 1){
            if(DeleteTPFromRevers){
               DeleteTPFrom(ENUM_DTY_SELL);
               CArrayKeyVal kv;
               kv.Add("TP",0);
               nets.Set(kv,"_ID="+(string)dw_net_id);
            }
         }
         NewUpLevels();
      END   
   }
   
   if(need_dw_net){
      START("========== NEW DW LEVELS")
         if(dw_net_nr > 1){
            if(DeleteTPFromRevers){
               DeleteTPFrom(ENUM_DTY_BUY);
               CArrayKeyVal kv;
               kv.Add("TP",0);
               nets.Set(kv,"_ID="+(string)up_net_id);
            }
         }
      
         NewDwLevels();
      END
   }
//} --- Проверка сеток и уровней


//{ --- Проверка заполнения уровней ордерами
   //{ --- Получаем уровни, которые не заполнены тикетами.
   
   /*
      SELECT * FROM table_levels WHERE _ID NOT IN (SELECT LEVEL_ID FROM table_tickets WHERE LEVEL_ID NOT NULL)
   */
   START("========== SELECT LEVELS WO TICKETS")
      string q ="select * FROM view_levels_wo_tickets \n"
               +" ";
      START("========== SEND TICKETS ALL")
               
         START("========== SELECT LEVELS WO TICKETS RawQuery");               
            CSQLiteCursor *pCursor = db.RawQuery(q);
         END
         
         START("========== BEGIN")
            db.Exec("BEGIN");
         END
         
         while(pCursor.Next()){
            START("========== pCursor.GetRowString()")
               DPrint(pCursor.GetRowString());
            END
            START("========== SEND TICKET");
               SendTicket(pCursor);
            END   
         }
         
         if(CheckPointer(pCursor)==POINTER_DYNAMIC){
            START("========== DELETE POINTER LEVELS WO TICKETS")
               delete pCursor;
            END
         }
         
         START("========== COMMIT")
            db.Exec("COMMIT");
         END   
      END
   END
   //}
//} --- Проверка заполнения уровней ордерами

   START("========== DELETE REVERS ON CLOSED TP_NET_ID")
              q="select * from table_tickets as TT "
               +"left join table_levels as TL on TL._ID = TT.LEVEL_ID "
               +"where TL.TP_NET_ID IN "
               +"(select net_id from view_nets_closed) "
               +"and TL.IS_ADD_LEVEL = 1 "
               +"and TT.IT = 1 "
               +" ";
      CSQLiteCursor* pTickets = db.RawQuery(q);
      while(pTickets.Next()){
         TR_CloseByTicket((int) pTickets.GetValue("TI"));
      }
      
      if(CheckPointer(pTickets)==POINTER_DYNAMIC){
         delete pTickets;
      }
   END
   
   START("===================== FIX PROFIT")
      if(useFixProfit){
         FixProfit(FixProfit_Amount);
      }
   END
   
   START("==================== FIX DD")
      if(useFixDD){
         FixProfit(-FixDD_Amount);
      }
   END
   
   START("=================== FixReversGreatest")
      if(useFixIfReversGreat){
         FixReversGreatest(up_net_id);
         FixReversGreatest(dw_net_id);
      }
   END
   
  }
//+------------------------------------------------------------------+

void Init(){
   //{ --- Установка соединения с файлом базы данных
   string Path=MQLInfoString(MQL_PROGRAM_PATH)+"."+(string)AccountNumber()+"."+Symbol()+".sqlite3";
   string db_file=Path;
   if(IsTesting()){
      #ifndef DB_IN_FILE
      db_file=":memory:";
      #else 
      db_file=MQLInfoString(MQL_PROGRAM_PATH)+".TEST."+Symbol()+"."+(string)(int)TimeLocal()+".sqlite3";
      #endif 
   }
   SQLiteConnector.connect(db_file);
   //}
   
   //{ --- Инициализация CSQLiteBase передачей указателя на коннектор
   db.Init(GetPointer(SQLiteConnector));
   db.Exec("PRAGMA journal_mode=WAL");  
   //}
   
   //{ --- Инициализация класса net передачей указателя на класс CSQLiteBase
   //       CSQLiteBase должен быть инициализирован указателем на коннектор
   nets.Init(GetPointer(db));
   //}
   
   //{ --- Инициализация класса level передачей указателя на класс CSQLiteBase
   //       CSQLiteBase должен быть инициализирован указателем на коннектор
   levels.Init(GetPointer(db));
   //}
   
   //{ --- Инициализация класса tickets передачей указателя на класс CSQLiteBase
   //       CSQLiteBase должен быть инициализирован указателем на коннектор
   tickets.Init(GetPointer(db));
   //}
   
   //{ --- Создание вьюх для совы
   START("CreateOrUpdateView(view_levels_wo_tickets")
      string q="select *, \n"
                  +"    case when TL.IS_ADD_LEVEL = 0 THEN \n"
                  +"           (select count(ti) from table_tickets as TT where TT.LEVEL_ID=TL._ID) \n"
                  +"         else \n"
                  +"           (select count(ti) from table_tickets as TT where TT.LEVEL_ID=TL._ID and ((TT.IT=1) or (TT.IT=0) or (TL.TP_NET_ID IN (select * from view_nets_closed)))) \n"
                  +"    END COUNT,\n"
                  +"    (select TP from table_nets as TN where TN._ID=TL.TP_NET_ID) as TP \n"
                  +" from table_levels as TL \n"
                  +"where count = 0 \n"
                  +" ";
      db.CreateOrUpdateView("view_levels_wo_tickets",q);
   END
   //}
}

void Deinit(){
   
}

bool FixProfit(double amount){
   bool result=false;
   CSQLiteCursor* p=db.RawQuery("SELECT SUM(OPR) AS PROFIT FROM table_tickets WHERE PID="+(string)pid);
   double profit=(double)p.GetValue("PROFIT");
   if(CheckPointer(p)==POINTER_DYNAMIC){
      delete p;
   }
   Comment("pid = "+(string)pid+"\n",
           "profit = "+DoubleToStr(profit,2)+"\n",
           "active cursors = "+(string)CSQLiteCursorCounter+"\n",
           "up_net_nr = "+up_net_nr+" profit = "+DoubleToStr(GetNetProfit(up_net_id),2)+" revers = "+DoubleToStr(GetReversProfit(up_net_id),2)+" revers wo =  "+DoubleToStr(GetReversWOProfit(ENUM_DTY_SELL),2)+"\n",
           "dw_net_nr = "+dw_net_nr+" profit = "+DoubleToStr(GetNetProfit(dw_net_id),2)+" revers = "+DoubleToStr(GetReversProfit(dw_net_id),2)+" revers wo =  "+DoubleToStr(GetReversWOProfit(ENUM_DTY_BUY),2)+"\n");
   
   if(((amount > 0)&&(profit >= amount))||((amount < 0)&&(profit<=amount))){
      result=true;
      TR_CloseAll(TR_MN);
   }
   return(result);
}

bool UpNetClosed(){
   bool result = true;
   string q="select * from table_nets AS TN "
            +"WHERE TN.DTY=100 and TN._ID not in (select * from view_nets_closed) "
            +" ";
   START("========== SELECT UP NetClosed RawQuery")         
      CSQLiteCursor* pCursor = db.RawQuery(q);
   END
   
   START("========== CHECKING IF IS ONE OR MORE RESULT")
   if(pCursor.Next()){
      up_net_id = (int)pCursor.GetValue("_ID");
      result=false;
   }
   END
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }            
   
   return(result);
}

bool DwNetClosed(){
   bool result = true;
   string q="select * from table_nets AS TN "
            +"WHERE TN.DTY=101 and TN._ID not in (select * from view_nets_closed) "
            +" ";
            
   CSQLiteCursor* pCursor = db.RawQuery(q);
   if(pCursor.Next()){
      dw_net_id=(int)pCursor.GetValue("_ID");
      result=false;
   }
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }            
   
   return(result);
}

int NewNet(ENUM_DTY dty, double ThisPrice){
   int sign = (dty==ENUM_DTY_BUY)?1:-1;
   double tp_price=ThisPrice + sign*_TP*Point();
   
   int nr=(dty==ENUM_DTY_BUY)?(up_net_nr-up_net_nr_minus):(dw_net_nr-dw_net_nr_minus);
   nr++;
   
   if(dty == ENUM_DTY_BUY){
      up_net_nr_minus = 0;
   }else{
      dw_net_nr_minus = 0;
   }
   
   nets.Add();
   CArrayKeyVal kv;
   kv.Add("DTY",dty);
   kv.Add("TP",tp_price);
   kv.Add("PR",ThisPrice);
   kv.Add("NR",nr);
   kv.Add("PID", pid);
   nets.Set(kv);
   return(nets.GetId());
}

void NetLevels(double ThisPrice, int PRSign, ENUM_DTY DTY, int NetId, int ReversNetId, int NetNr){
      
      ENUM_DTY ReversDTY = (DTY==ENUM_DTY_BUY)?ENUM_DTY_SELL:ENUM_DTY_BUY;
      int Type = (DTY==ENUM_DTY_BUY)?OP_BUYSTOP:OP_SELLSTOP;
      int beforeTP = _TP;
      int nr=1;
      double tp_price = ThisPrice + PRSign*_TP*Point();
      
      double level_lot = _Lot;
      for(int i=1; i<NetNr; i++){
         level_lot*=_Multy_net;
      } 
      
      db.Exec("BEGIN");
      int ReversLevel = 0;
      int ThisStep = _S;
      while(beforeTP > ThisStep){
         DPrint("nr :: "+nr+"; beforeTP :: "+beforeTP+"; ThisStep :: "+ThisStep);
         
         double level_pr = ThisPrice + PRSign*ThisStep*Point();
         
         LevelsStructure ls;
         ls.nr       = nr;
         ls.pr       = level_pr;
         ls.dty      = DTY;
         ls.ty       = Type;
         ls.lot      = level_lot;
         ls.net_id   = NetId;
         ls.tp_net_id = NetId;
         ls.is_add_level = 0;
         ls.this_price = ThisPrice;
         ls.this_step = ThisStep;
         ls.ask = Ask;
         ls.bid = Bid;
         levels.Add(ls);
         //levels.Add(nr, level_pr, DTY, Type, level_lot, NetId, NetId, 0);
         
         DPrint((string)nr+"%"+(string)_LL +"= "+(string)(nr%_LL));
         if(nr%_LL == 0){
            ReversLevel++;
            double ReversLot = level_lot*_Multy_revers;
            if(_Multy_revers_multy != 1){
               for(int i=1; i<ReversLevel; i++){
                  ReversLot*=_Multy_revers_multy;
               }   
            }
            
            if(useReversWOTP){
               ReversNetId = -1;
            }
            
            levels.Add(nr, level_pr, ReversDTY, -1, ReversLot, NetId, ReversNetId, 1);
         }
         //beforeTP-=_S+nr*_SPlus;
         ThisStep += _S + nr*_SPlus;
         nr++;
         
      }
      db.Exec("COMMIT");
}

void NewUpLevels(){
   START("ADD BUY LEVELS")
      double ThisPrice = nets.Get("PR", "_ID="+(string)up_net_id);
      NetLevels(  ThisPrice,
                  1,
                  ENUM_DTY_BUY,
                  up_net_id,
                  dw_net_id,
                  up_net_nr);
   END   
}

void NewDwLevels(){
   START("ADD SELL LEVELS")
      double ThisPrice = nets.Get("PR", "_ID="+(string)dw_net_id);
      NetLevels(  ThisPrice,
                  -1,
                  ENUM_DTY_SELL,
                  dw_net_id,
                  up_net_id,
                  dw_net_nr);
   END   
}

void SendTicket(CSQLiteCursor* pLevels){
   START("========== GET LEVEL INFO FROM pLevel")
   int   level_id = (int)pLevels.GetValue("_ID"); 
   ENUM_DTY dty   = ConvertDTY(pLevels.GetValue("DTY"));
   double   pr    = (double)pLevels.GetValue("PR");
   int      ty    = (int)pLevels.GetValue("TY");
   if(ty==-1){
      ty    = GetOP(pr, dty);
   }   
   DPrint("ty = "+(string)ty);
   double   lot   = (double)pLevels.GetValue("LOT");
   DPrint("lot = "+(string)lot);
   double   tp    = (double)pLevels.GetValue("TP");
   
   DPrint("LID :: "+level_id+" | DTY :: "+dty+" | PR :: "+pr+" | TY :: "+ty+" | LOT :: "+lot+" | TP :: "+tp);
   END
   
   double d[];
   if(ty > 1){
      CArrayKeyVal kv;
      kv.Add("LEVEL_ID",level_id);
      kv.Add("PID",pid);
      START("========== TR_SendPending_array");
      TR_SendPending_array(d,ty,pr,0,lot,tp,0,"pr:"+(string)pr+"|lid:"+(string)level_id,-1,NULL,TR_MODE_PRICE);
      END
      START("========== tickets.UpsertTickets(d,kv)");
      tickets.UpsertTickets(d,kv);
      END
   }
}

ENUM_DTY ConvertDTY(string sDty){
   ENUM_DTY result = ENUM_DTY_BUY;
   if(sDty == "100"){
      result = ENUM_DTY_BUY;
   }
   
   if(sDty == "101"){
      result = ENUM_DTY_SELL;
   }
   
   return(result);
}

int GetOP(double pr, ENUM_DTY dty){
   int result = -1;
   if(dty == ENUM_DTY_BUY){
      if(pr > Ask){
         result = OP_BUYSTOP;
      }else{
         if(pr < Bid){
            result = OP_BUYLIMIT;
         }else{
            result = OP_BUY;
         }
      }     
   }
   
   if(dty == ENUM_DTY_SELL){
      if(pr < Bid){
         result = OP_SELLSTOP;
      }else{
         if(pr > Ask){
            result = OP_SELLLIMIT;
         }else{
            result = OP_SELL;
         }
      }     
   }
   
   return(result);
}

void SetPid(){
   CSQLiteCursor* p = db.RawQuery("SELECT MAX(PID) AS PID FROM table_tickets");
   pid = (int)p.GetValue("PID");
   if(CheckPointer(p) == POINTER_DYNAMIC){
      delete p;
   }
   
   p=db.RawQuery("SELECT COUNT(TI) AS COUNT FROM table_tickets WHERE IT=1 AND PID IS NOT NULL");
   if((int)p.GetValue("COUNT")==0){
      pid++;
      //Чистим таблицы
      db.Exec("BEGIN");
      db.Delete(nets.GetTableName());
      db.Delete(levels.GetTableName());
      tickets.CopyClosedToHistory();
      db.Exec("COMMIT");
      
   }
   
   if(CheckPointer(p)==POINTER_DYNAMIC){
      delete p;
   }
}

void SetNR(){
   
   up_net_nr=0;
   dw_net_nr=0;
   string q="SELECT MAX(NR) AS NR, DTY FROM "+nets.GetTableName()+" WHERE PID = "+(string)pid+" GROUP BY DTY ";
   CSQLiteCursor* p=db.RawQuery(q);
   while(p.Next()){
      ENUM_DTY dty = ConvertDTY(p.GetValue("DTY"));
      if(dty == ENUM_DTY_BUY){
         up_net_nr = (int)p.GetValue("NR");
      }else{
         dw_net_nr = (int)p.GetValue("NR");
      }
   }
   
   if(CheckPointer(p) == POINTER_DYNAMIC){
      delete p;
   }
}

void DeleteTPFrom(ENUM_DTY dty){
   string q = "select * from table_tickets where IT=1 and DTY="+(string)dty;
   CSQLiteCursor* pCursor=db.RawQuery(q);
   while(pCursor.Next()){
      int ti = pCursor.GetValue("TI");
      TR_ModifyTP(ti,0);
   }
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }
}

double GetNetProfit(int net_id){
   double result = 0.0;
   string q = " select SUM(TT.OPR) as OPR from table_tickets as TT \n"
            + " left join table_levels as TL on (TT.level_id = TL._ID)\n"
            + " where TL.NET_ID="+(string)net_id+" and TT.TY<=1 and TT.IT=1 and TL.IS_ADD_LEVEL = 0";
            
   CSQLiteCursor* pCursor=db.RawQuery(q);
   
   if(pCursor.Next()){
      result = pCursor.GetValue("OPR");
   }
   
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }            
   
   return(result);
}

double GetReversProfit(int net_id){
   double result = 0.0;
   string q = " select SUM(TT.OPR) as OPR from table_tickets as TT \n"
            + " left join table_levels as TL on (TT.level_id = TL._ID)\n"
            + " where TL.NET_ID="+(string)net_id+" and TT.TY<=1 and TT.IT=1 and TL.IS_ADD_LEVEL = '1'";
            
   CSQLiteCursor* pCursor=db.RawQuery(q);
   
   if(pCursor.Next()){
      result = pCursor.GetValue("OPR");
   }
   
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }            
   
   return(result);
}

double GetReversWOProfit(ENUM_DTY dty){
   double result = 0.0;
   string q = " select SUM(TT.OPR) as OPR from table_tickets as TT \n"
            + " left join table_levels as TL on (TT.level_id = TL._ID)\n"
            + " where TL.NET_ID in (select net_id from view_nets_closed) and TT.DTY="+dty+" and TT.TY<=1 and TT.IT=1 and TL.IS_ADD_LEVEL = 1";
            
   CSQLiteCursor* pCursor=db.RawQuery(q);
   
   if(pCursor.Next()){
      result = pCursor.GetValue("OPR");
   }
   
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }            
   
   return(result);
}

void FixReversGreatest(int net_id){
   double net_profit = GetNetProfit(net_id);
   double rev_profit = GetReversProfit(net_id);
   double revwo_profit = 0;
   
   ENUM_DTY rev_dty;
   
   bool close_revwo = false;
   
   if(useFixReversWONet){
      if(net_id==up_net_id){
         rev_dty = ENUM_DTY_SELL;
         revwo_profit = GetReversWOProfit(rev_dty);
      }else{
         rev_dty = ENUM_DTY_BUY;
         revwo_profit = GetReversWOProfit(rev_dty);
      }
      
      if(revwo_profit < 0){
         revwo_profit=0;
      }else{
         close_revwo = true;
      }   
   }
   
   double rev_total_profit = rev_profit + revwo_profit;
     
   if(net_profit < 0){
      if(rev_total_profit > 0){
         if(rev_total_profit > -1*net_profit){
            CloseNetTickets(net_id);
            
            if(close_revwo){
               CloseReversWO(rev_dty);
            }
            if(net_id==up_net_id){
               up_net_nr_minus=1;
            }
            
            if(net_id==dw_net_id){
               dw_net_nr_minus=1;
            }
         }
      }
   }
}

void CloseNetTickets(int net_id){
   string q = "select TT.TI from table_tickets as TT \n"
            + "left join table_levels as TL on (TT.LEVEL_ID=TL._ID) \n"
            + "where TT.IT=1 and TL.NET_ID="+(string)net_id;
            
   CSQLiteCursor *pCursor = db.RawQuery(q);
   while(pCursor.Next()){
      TR_CloseByTicket((int)pCursor.GetValue("TI"));
   }    
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }        
}

void CloseReversWO(ENUM_DTY dty){
   string q = " select TT.TI as TI from table_tickets as TT \n"
            + " left join table_levels as TL on (TT.level_id = TL._ID)\n"
            + " where TL.NET_ID in (select net_id from view_nets_closed) and TT.DTY="+dty+" and TT.TY<=1 and TT.IT=1 and TL.IS_ADD_LEVEL = 1";
            
   CSQLiteCursor *pCursor = db.RawQuery(q);
   while(pCursor.Next()){
      TR_CloseByTicket((int)pCursor.GetValue("TI"));
   }    
   if(CheckPointer(pCursor)==POINTER_DYNAMIC){
      delete pCursor;
   }        
}