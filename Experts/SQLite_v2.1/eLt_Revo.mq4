//+------------------------------------------------------------------+
//|                                                     eLt_RevO.mq4 |
//|                                          Copyright 2017, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, artamir"
#property link      "https://www.mql5.com"
#property version   "1.2"
#property strict

//#define DEBUG
#define STOP_ON_BAD_ASSERT false
//#define TEST
//#define DB_IN_FILE

int start_testing = 0;
int end_testing=0;
string test_name = "";

string test_print_otstup = "";
bool test_print_assertion = false;

int start_array_timer[];
string start_array_names[];
int testing_last_index;


#define MAX(a,b) ((a>b)?a:b)

#ifdef TEST
#define GET_TEST_OTSTUP test_print_otstup=""; \
                        for(int test_index_counter=0; test_index_counter < LAST(start_array_names); test_index_counter++){ \
                           test_print_otstup+="    ";\
                        } 
#define TPrint(t) Print(test_print_otstup + "PRINT :: " + t); 
#define TPrintIf(t) if(test_print_assertion){TPrint("IF :: "t);}

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
#include <SQLite_v2.1\subsystems\pids.mqh>
#include <SQLite_v2.1\subsystems\nets.mqh>
#include <SQLite_v2.1\subsystems\levels.mqh>

CSQLite SQLiteConnector;
CSQLiteBase db;
CPids pids;
CNets nets;
CLevels levels;
CSQLiteTickets tickets;

int _ThisPidId=0;

#include <Experts\eLt_Revo.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---   
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
   START("========= TICKETS -> START")
      tickets.Start();
   END

   START("========== Проверка или установка ПИД")
      SetPid();
   END
   
   START("========== Чистим таблицы для ускорения тестирования")
      if((tickets._OrdersTotal()==0)){
         //Чистим таблицы
         db.Exec("BEGIN");
         db.Delete(nets.GetTableName());
         db.Delete(levels.GetTableName());
         tickets.CopyClosedToHistory();
         db.Exec("COMMIT");
      }
   END
   
   START("========== FIX PROFIT")
      if(useFixProfit){
         if(FixProfit(FixProfit_Amount)){
            Start();
         }
      }
   END

   //{ --- Получаем таблицу родительских тикетов.
   START("========== Основной блок советника")
      START("========== Получаем поинтер таблицы родительских тикетов")
         CSQLiteCursor* pParents = GetParentsPointer();
      END
      
      START("========== Проверяем сетки для родительских тикетов")
         CheckParentsNets(pParents);
      END
         
      START("========== Удаляем поинтер таблицы родительских тикетов")
         if(CheckPointer(pParents) == POINTER_DYNAMIC){
            delete pParents;
         }
      END
   END
   
   START("========== Блок проверки уровней без тикетов")
      START("========== Получаем поинтер выборки уровней без тикетов")
         CSQLiteCursor* pLevelsWOTickets = GetLevelsWOTickets();
      END
      
      START("========== Устанавливаем тикеты по настройкам уровней")
         SendTicketsByLevels(pLevelsWOTickets);
      END
      
      START("========== Удаляем поинтер выборки уровней без тикетов")
         if(CheckPointer(pLevelsWOTickets) == POINTER_DYNAMIC){
            delete pLevelsWOTickets;
         }
      END
   END
   //}
   
   START("========== Блок проверки тейкпрофитов")
      CheckTP();      
   END
   
   START("========== Проверка удаления тикетов сеток")
      CheckNetsForClose();
   END
   
   START("========== Проверка если нужно выставить родительский бай")
      if(useSendBuySell){
         if(tickets._OrdersTotal() == 0){
            TR_SendBUY(BuySellVol);
            TR_SendSELL(BuySellVol);
         }
      }   
   END
   
   
   START("========== Comments")
      _Comment();
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
      db_file=MQLInfoString(MQL_PROGRAM_PATH)+".TEST."+Symbol()+"."+(string)GetTickCount()+".sqlite3";
      #endif 
   }
   SQLiteConnector.connect(db_file);
   //}
   
   //{ --- Инициализация CSQLiteBase передачей указателя на коннектор
   db.Init(GetPointer(SQLiteConnector));
   db.Exec("PRAGMA journal_mode=WAL");  
   //}
   
   //{ --- Инициализация класса pid передачей указателя на класс CSQLiteBase
   //       CSQLiteBase должен быть инициализирован указателем на коннектор
   pids.Init(GetPointer(db));
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
   START("========== Создание вьюх для совы")
      CreateViews();
   END
   //}
}

void Deinit(){
   
}

void _Comment(){
   Comment("pid="+(string)_ThisPidId+"\n"+
           "profit="+DoubleToStr(GetPidProfit(NULL),2)+"\n"+
           "total market orders="+(string)tickets._OrdersTotal()+"\n"+
           "orders total = "+(string)OrdersTotal()+"\n");
}

void CreateViews(){

   START("========== Вьюхи для таблицы LEVELS")
      CreateViewsLevels();
   END

   START("========== Вьюхи для таблицы NETS")
      CreateViewsNets();
   END
   
   START("========== Вьюхи для таблицы Тикеты")
      CreateViewsTickets();
   END
   
   START("========== view_levels_wo_tickets")
      string q="SELECT * \n" 
              +"  FROM table_levels \n"
              +" WHERE _ID NOT IN ( \n"
              +"           SELECT TT.LEVEL_ID \n"
              +"             FROM table_tickets AS TT \n"
              +"                  LEFT JOIN \n"
              +"                  table_levels AS TL ON (TL._ID = TT.LEVEL_ID) \n"
              +"            WHERE TT.LEVEL_ID NOTNULL \n"
              +"            GROUP BY TT.LEVEL_ID) AND \n"
              +"       _ID NOT IN ( \n"
              +"           SELECT PARENT_LEVEL_ID \n"
              +"             FROM view_levels_parent_level_id \n"
              +"            GROUP BY parent_level_id) AND \n"
              +"       DONT_SEND <> 1 \n";
      db.CreateOrUpdateView("view_levels_wo_tickets",q);
   END
}

void CreateViewsLevels(){
   START("========== view_levels_parent_level_id")
      string q="SELECT PARENT_LEVEL_ID from table_levels \n" 
              +"where PARENT_LEVEL_ID NOTNULL \n"
              +"GROUP BY PARENT_LEVEL_ID \n";
      db.CreateOrUpdateView("view_levels_parent_level_id",q);
   END
   
   START("========== view_first_level_it")
             q="select TL.*, TT.IT from table_levels as TL \n" 
              +"left join table_tickets as TT on (TL._ID=TT.LEVEL_ID) \n"
              +"where TL.NR=1 and TT.IT=1 \n";
      db.CreateOrUpdateView("view_first_level_it",q);
   END
   
   START("========== view_levels_w_market_tickets")
             q="select TL.* FROM table_tickets as TT \n" 
              +"left join table_levels as TL on TL._ID = TT.LEVEL_ID \n"
              +"WHERE TT.IT=1 AND TT.TY<=1 \n";
      db.CreateOrUpdateView("view_levels_w_market_tickets",q);
   END

   START("========== view_levels_w_max_nr_market_tickets")
             q="select max(TT.LEVEL_ID), TL.* from table_tickets as TT \n" 
              +"left join table_levels as TL on TT.LEVEL_ID = TL._ID \n"
              +"where TT.IT=1 \n"
              +"and (TT.TY=0 OR TT.TY=1) \n"
              +"GROUP BY TT.NET_ID \n";
      db.CreateOrUpdateView("view_levels_w_max_nr_market_tickets",q);
   END
}

void CreateViewsNets(){
   
   START("========== view_nets_w_closed_tickets")
      string q="SELECT NET_ID from table_tickets \n" 
              +"where IT=0 \n"
              +"GROUP BY NET_ID \n";
      db.CreateOrUpdateView("view_nets_w_closed_tickets",q);
   END
   
   START("========== view_nets_w_opened_tickets")
             q="SELECT NET_ID from table_tickets \n" 
              +"where IT=1 \n"
              +"GROUP BY NET_ID \n";
      db.CreateOrUpdateView("view_nets_w_opened_tickets",q);
   END
   
   START("========== view_nets_notin_closed_tickets")
             q="SELECT _ID from table_nets \n" 
              +"where _ID NOT IN (SELECT * FROM view_nets_w_closed_tickets) \n"
              +"GROUP BY _ID \n";
      db.CreateOrUpdateView("view_nets_notin_closed_tickets",q);
   END
   
   START("========== view_nets_worked")
             q="select * from table_nets \n" 
              +"WHERE _ID in (SELECT _ID from view_nets_w_opened_tickets) \n"
              +"or _ID in (select _ID from view_nets_notin_closed_tickets) \n";
      db.CreateOrUpdateView("view_nets_worked",q);
   END
   
   START("========== view_nets_closed")
             q="SELECT _ID FROM table_nets \n" 
              +"WHERE _ID not in (SELECT _ID from view_nets_worked) \n";
      db.CreateOrUpdateView("view_nets_closed",q);
   END
   
   START("========== view_nets_must_be_closed")
             q="select TT.NET_ID from table_tickets as TT \n" 
              +"left join table_levels as TL on TT.LEVEL_ID=TL._ID \n"
              +"where (TT.IT = 0 \n"
              +"or (TT.TY > 1)) \n"
              +"and TT.NET_ID NOT IN (select NET_ID from view_levels_w_market_tickets GROUP BY NET_ID) \n"
              +"GROUP BY TT.NET_ID \n";
      db.CreateOrUpdateView("view_nets_must_be_closed",q);
   END
}

void CreateViewsTickets(){
  START("========== view_tickets_to_change_tp")
      string q="select TT.TI, ML.TP from table_tickets as TT \n" 
              +"left join view_levels_w_max_nr_market_tickets as ML on ML.NET_ID=TT.NET_ID \n"
              +"where ML.NET_ID NOTNULL \n"
              +"and (TT.TY=0 OR TT.TY=1) \n"
              +"and (TT.IT=1) \n"
              +"and (TT.TP <> ML.TP) \n";
      db.CreateOrUpdateView("view_tickets_to_change_tp",q);
   END

   START("========== view_tickets_to_change_sl")
             q="select TT.TI, ML.SL from table_tickets as TT \n" 
              +"left join view_levels_w_max_nr_market_tickets as ML on ML.NET_ID=TT.NET_ID \n"
              +"where ML.NET_ID NOTNULL \n"
              +"and (TT.TY=0 OR TT.TY=1) \n"
              +"and (TT.IT=1) \n"
              +"and (TT.SL <> ML.SL) \n";
      db.CreateOrUpdateView("view_tickets_to_change_sl",q);
   END
}

bool FixProfit(double amount){
   bool result=false;
   
   //CSQLiteCursor* p=db.RawQuery("SELECT SUM(OPR) AS PROFIT FROM table_tickets WHERE PID_ID="+(string)_ThisPidId);
   //double profit=(double)p.GetValue("PROFIT");
   //if(CheckPointer(p)==POINTER_DYNAMIC){
   //   delete p;
   //}
   
   double profit = GetPidProfit(NULL);
   
   if(((amount > 0)&&(profit >= amount))||((amount < 0)&&(profit<=amount))){
      result=true;
      TR_CloseAll(TR_MN);
   }
   return(result);
}

//+------------------------------------------------------------------+
//|Возвращает поинтер выборки родительских тикетов.                  |
//|Родительский тикет:
//|   Это тикет с типом BUY или SELL <рыночный а не отложенный>
//|   И
//|   (У которого LEVEL_ID = NULL <Выставлен вручную>
//|    ИЛИ
//|    (Принадлежит уровню с признаком IS_PARENT = 1
//|     И 
//|     уровень принадлежит живой сетке <сетка у которой хоть один уровень живой>))
//+------------------------------------------------------------------+
CSQLiteCursor* GetParentsPointer(){
   string s = "SELECT TT.*, \n"
            + "       TN.NR AS NET_NR, \n"
            + "       TL.IS_PARENT AS LEVEL_IS_PARENT, \n"
            + "       TL.CONTINUE_NET_NR, \n"
            + "       TL.PID_ID \n"
            + "  FROM table_tickets AS TT \n"
            + "       LEFT JOIN \n"
            + "       table_levels AS TL ON (TL._ID = TT.LEVEL_ID) \n"
            + "       LEFT JOIN \n"
            + "       table_nets AS TN ON (TN._ID = TT.NET_ID) \n"
            + " WHERE TT.TY <= 1 AND \n"
            + "       TT.IT = 1 AND \n"
            + "       (TT.LEVEL_ID ISNULL OR \n"
            + "        (TL.IS_PARENT = 1 AND \n"
            + "         TL.NET_ID IN ( \n"
            + "             SELECT _ID \n"
            + "               FROM view_nets_worked) AND \n"
            + "         TL._ID NOT IN ( \n"
            + "             SELECT PARENT_LEVEL_ID \n"
            + "               FROM view_levels_parent_level_id))) \n"
            + " \n";
   CSQLiteCursor* pCursor = db.RawQuery(s);
   return(pCursor);
}

CSQLiteCursor* GetLevelsWOTickets(){
   string s="select * from view_levels_wo_tickets";
   CSQLiteCursor* pCursor = db.RawQuery(s);
   return(pCursor);
}

//+------------------------------------------------------------------+
//|Проверка существования сеток для родительских тикетов             |
//+------------------------------------------------------------------+
void CheckParentsNets(CSQLiteCursor *pParents){
   pParents.Reset();
   while(pParents.Next()){
      int      _net_id    = (int)      pParents.GetValue("NET_ID");
      int      _net_nr    = (int)      pParents.GetValue("NET_NR");
      int      _level_id  = (int)      pParents.GetValue("LEVEL_ID");
      int      _level_is_parent = (int) pParents.GetValue("LEVEL_IS_PARENT");
      int      _level_id_if_parent = _level_is_parent==1?_level_id:NULL;
      int      _level_continue_net_nr = (int) pParents.GetValue("CONTINUE_NET_NR");
      if(_level_continue_net_nr==NULL){
         _level_continue_net_nr=0;
      }
      int      _ti        = (int)      pParents.GetValue("TI");
      double   _oop       = (double)   pParents.GetValue("OOP");
      ENUM_DTY _dty       = (ENUM_DTY) pParents.GetValue("DTY");
      double   _lot       = (double)   pParents.GetValue("LOT");
      int      _pid_id    = (int)      pParents.GetValue("PID_ID");
      
      if(_pid_id==NULL){
         _pid_id = _ThisPidId;
      }
      
      if(_net_id==NULL || _level_is_parent == 1){
         START("========== Создаем сетку для родительского тикета "+(string)_ti)
            CArrayKeyVal kv;
            bool needNewNet = true;
            switch(_level_continue_net_nr){
               case 0      :_net_nr=1; //увеличить на 1
                            break;
               
               case 1      :_net_nr++; //установить 1
                            break;
                            
               default     :_net_nr=_net_nr;//оставить родительский 
                            //needNewNet=false;
                            break;
            }
            
            kv.Add("NR",   _net_nr);
            kv.Add("PR",   _oop);
            kv.Add("DTY",  _dty);
            kv.Add("LOT",  _lot);
            kv.Add("PID_ID", _pid_id);
            if(needNewNet){
               _net_id     = NewNet(kv);
            }   
         END
         START("========== Создаем уровни для сетки родительского тикета "+(string)_ti)  
            _level_id   = NewLevels(_net_id, _level_id_if_parent);
         END   
            kv.Shutdown();
            kv.Add("NET_ID",_net_id);
            kv.Add("LEVEL_ID", _level_id);
            kv.Add("PID_ID",_pid_id);
            tickets.UpsertTicket(_ti, kv);
         
      }
      TPrint(pParents.GetRowString());
   }
}

int NewNet(CArrayKeyVal &kv){
   int result = -1;
   nets.Add();
   nets.Set(kv);
   result = nets.GetId();
   return(result);
}

int NewLevels(int this_net_id, int parent_level_id = NULL){
   
   int result = NULL;
   START("========== Получение начальных переменных из сетки")
      int      TargetToFirstLevel = 0;
      int      NetNr          = (int)      nets.Get("NR",  "_ID="+(string)this_net_id);
      double   FirstLevelPR   = (double)   nets.Get("PR",  "_ID="+(string)this_net_id);
      double   FirstLevelLot  = (double)   nets.Get("LOT", "_ID="+(string)this_net_id);
      ENUM_DTY NetDty         = (ENUM_DTY) nets.Get("DTY", "_ID="+(string)this_net_id);
      int      NetPidId       = (int)      nets.Get("PID_ID", "_ID="+(string)this_net_id);
      
      int      continue_net_nr=NULL;
      int      continue_level_nr=0;
      if(parent_level_id != NULL){
         continue_net_nr = (int)levels.GetValue("CONTINUE_NET_NR","_ID="+(string)parent_level_id);
         if(continue_net_nr == -1){
            //continue_level_nr = (int)levels.GetValue("NR","_ID="+(string)parent_level_id);
         }   
      }   
   END
   
   int      TargetPips     = GetTargetPips(NetNr); 
   int      TargetPlusPips = GetTargetPlusPips(NetNr);
   
   double   MultiplyLots   = GetMultiplyLots(NetNr);
   double   PlusLots       = GetPlusLots(NetNr);
   
   int      SignKoef       = (NetDty==ENUM_DTY_BUY?-1:1); //если сетка вверх, то цены лимитных уровней расчитываем вниз
   
   double   ThisPlusLots       = 0;
   double   ThisLevelLots      = 0;
   int      ThisTargetPlusPips = 0;
   int      ThisPlusTP         = 0;
   int      ThisPlusSL         = 0;
   
   CArrayKeyVal kv;
   //Цикл по количеству уровней лимитной сетки.
   int MaxLevelsNR = GetMaxLevelsNR();
   for(int nr=(1+continue_level_nr); nr<=(MaxLevelsNR+continue_level_nr); nr++){
      if(nr==1+continue_level_nr){
         TargetToFirstLevel = 0;
         ThisLevelLots = FirstLevelLot;
         ThisPlusTP = 0;
         ThisPlusSL = 0;
      }else{
         if(nr>2+continue_level_nr){
            ThisTargetPlusPips = ThisTargetPlusPips + TargetPlusPips;
            ThisPlusLots = ThisPlusLots + PlusLots;
            ThisPlusTP = ThisPlusTP + GetTPPlusPips(nr, NetNr);
            ThisPlusSL = ThisPlusSL + GetSLPlusPips(nr, NetNr);
         }
         TargetToFirstLevel = TargetToFirstLevel + TargetPips + ThisTargetPlusPips;
         ThisLevelLots = ThisLevelLots*MultiplyLots + ThisPlusLots;
      }
      
      double   level_pr = FirstLevelPR + SignKoef * TargetToFirstLevel * Point();   
      double   level_lot = ThisLevelLots;
      
      int      level_tp_pips = GetTPPips(nr, NetNr)+ThisPlusTP;
      double   level_tp_pr = level_pr + GetSignTPByDTY(NetDty) * level_tp_pips * _Point;
      
      int      level_sl_pips = GetSLPips(nr, NetNr)+ThisPlusSL;
      double   level_sl_pr = level_pr + GetSignSLByDTY(NetDty) * level_sl_pips * _Point;
      
      kv.Clear();
      kv.Add("NR",nr);
      kv.Add("NET_ID",this_net_id);
      kv.Add("PID_ID", NetPidId);
      kv.Add("DTY",NetDty);
      kv.Add("PR",level_pr);
      kv.Add("LOT",level_lot);
      kv.Add("TY",DTYToLimitType(NetDty));
      kv.Add("DONT_SEND",(1-mgp_useLimOrders));
      if(nr > mgp_LimLevels){
         kv.Replace("DONT_SEND",1);
      }
      kv.Add("TPPIPS", level_tp_pips);
      kv.Add("TP",level_tp_pr);

      kv.Add("SLPIPS", level_sl_pips);
      kv.Add("SL",level_sl_pr);
       
      if(nr==1){
         if(parent_level_id != NULL){
            kv.Add("PARENT_LEVEL_ID",parent_level_id);
         }
      }else{
         kv.DeleteKey("PARENT_LEVEL_ID");
      }
      
      if(mgp_LastLimLevelIsParent){
         if(nr==mgp_LimLevels){
            kv.Add("IS_PARENT",1);
            kv.Add("CONTINUE_NET_NR",-1);
         }
      }
      
      int level_id = levels.Add(kv);
      kv.Add("_ID",level_id);
      
      START("========== Создание дополнительных уровней для сетки")
         kv.DeleteKey("TP"); //Каждый уровень должен сам расчитывать свой тп
         kv.DeleteKey("TPPIPS");
         kv.DeleteKey("SL"); //Каждый уровень должен сам расчитывать свой тп
         kv.DeleteKey("SLPIPS");
         
         kv.DeleteKey("DONT_SEND");
         
         kv.DeleteKey("IS_PARENT");
         kv.DeleteKey("CONTINUE_NET_NR");
              
         NewAddLevels(kv);
      END
      
      if(nr==1){
         result=level_id;
      }   
   }   
   
   return(result);
}

int GetMaxLevelsNR(){
   int result = mgp_LimLevels;
   if(SO_useStopLevels){
      if(SO_Levels != -1){ //-1 обозначает, что количество уровней стоп. сетки == количеству уровней лим. сетки
         result = (SO_Levels > result)?(SO_Levels):result;
      }
   }
   return(result);
}

void NewAddLevels(CArrayKeyVal& main_level_kv){
   START("========== Получение данных из основного уровня")
      int main_level_id = (int)main_level_kv.Get("_ID");
      int main_level_nr = (int)main_level_kv.Get("NR");
   END
   
   START("========== Создание нового объекта KV")
   CArrayKeyVal kv;
   
   if(add_useAddLimit){
      if(main_level_nr == add_LimitLevel){
         START("========== Установка добавочного лимитного уровня")
            
            kv.Clear();
            kv.Add(main_level_kv);
            
            SetAddLimitLevel(kv);
         END
      }
   }

   if(add_useAddLimit2){
      if(main_level_nr == add_2LimitLevel){
         START("========== Установка добавочного лимитного уровня 2")
            
            kv.Clear();
            kv.Add(main_level_kv);
            
            SetAddLimitLevel2(kv);
         END
      }
   }
   
   if(add_useAddStop){
      if(main_level_nr == add_StopLevel){
         START("========== Установка добавочного стопового уровня")   
            kv.Clear();
            kv.Add(main_level_kv);
            
            SetAddStopLevel(kv);
         END   
      }
   }
   
   if(add_useAddStop2){
      if(main_level_nr == add_2StopLevel){
         START("========== Установка добавочного стопового уровня 2")   
            kv.Clear();
            kv.Add(main_level_kv);
            
            SetAddStopLevel2(kv);
         END   
      }
   }
   
   if(SO_useStopLevels){
      START("========== Проверка возможности установить стоповую сетку")
         kv.Clear();
         kv.Add(main_level_kv);
         
         if(SO_Levels == -1 || main_level_nr <= SO_Levels){
            
               if(main_level_nr >= SO_StartLevel && main_level_nr <= SO_EndLevel){
                  START("========== Установка стоповой сетки 1")
                     SetStopLevel(kv);
                  END   
               }
               
               if(main_level_nr > SO_EndLevel && main_level_nr >= SO_ContinueLevel){
                  START("========== Установка стоповой сетки 2")
                     SetStopLevel(kv);
                  END   
               }
         }
      END
   }
   
   END
}

void SetAddLimitLevel(CArrayKeyVal& main_level_kv){

   CArrayKeyVal kv;
   kv.Clear();
   kv.Add(main_level_kv);
   
   int      main_level_id  = (int)      main_level_kv.Get("_ID");
   int      main_level_nr  = (int)      main_level_kv.Get("NR");
   double   main_level_pr  = (double)   main_level_kv.Get("PR");
   double   main_level_lot = (double)   main_level_kv.Get("LOT");
   ENUM_DTY main_level_dty = (ENUM_DTY) main_level_kv.Get("DTY");
   
   int      _level_ty      = DTYToLimitType(main_level_dty);      
   double   _level_pr      = main_level_pr + GetSignPRByTY(_level_ty)*add_LimitPip*Point();
   int      _level_tp_pips = GetTPPips(1, 1);
   double   _level_tp_pr   = _level_pr + GetSignTPByDTY(TypeToDTY(_level_ty)) * _level_tp_pips * _Point;

   int      _level_sl_pips = GetSLPips(1, 1);
   double   _level_sl_pr   = _level_pr + GetSignSLByDTY(TypeToDTY(_level_ty)) * _level_sl_pips * _Point;
   double   _level_lot     = main_level_lot;
   
   if(add_Limit_useLevelVol){
      _level_lot*=add_Limit_multiplyVol;
   }else{
      _level_lot=add_Limit_fixVol;
   }
   
   kv.DeleteKey("_ID");
   
   kv.Replace("PR",_level_pr);
   kv.Replace("TY",_level_ty);
   kv.Replace("IS_PARENT",1);
   kv.Replace("LOT",_level_lot);
   kv.Replace("TPPIPS", _level_tp_pips);
   kv.Replace("TP",_level_tp_pr);
   kv.Replace("SLPIPS", _level_tp_pips);
   kv.Replace("SL",_level_tp_pr);
   
   levels.Add(kv);
}

void SetAddLimitLevel2(CArrayKeyVal& main_level_kv){

   CArrayKeyVal kv;
   kv.Clear();
   kv.Add(main_level_kv);
   
   int      main_level_id  = (int)      main_level_kv.Get("_ID");
   int      main_level_nr  = (int)      main_level_kv.Get("NR");
   double   main_level_pr  = (double)   main_level_kv.Get("PR");
   double   main_level_lot = (double)   main_level_kv.Get("LOT");
   ENUM_DTY main_level_dty = (ENUM_DTY) main_level_kv.Get("DTY");
   
   int      _level_ty      = DTYToLimitType(main_level_dty);      
   double   _level_pr      = main_level_pr + GetSignPRByTY(_level_ty)*add_2LimitPip*Point();
   int      _level_tp_pips = GetTPPips(1, 1);
   double   _level_tp_pr   = _level_pr + GetSignTPByDTY(TypeToDTY(_level_ty)) * _level_tp_pips * _Point;
   int      _level_sl_pips = GetSLPips(1, 1);
   double   _level_sl_pr   = _level_pr + GetSignSLByDTY(TypeToDTY(_level_ty)) * _level_sl_pips * _Point;
   double   _level_lot     = main_level_lot;
   
   if(add_2Limit_useLevelVol){
      _level_lot*=add_2Limit_multiplyVol;
   }else{
      _level_lot=add_2Limit_fixVol;
   }
   
   kv.DeleteKey("_ID");
   
   kv.Replace("PR",_level_pr);
   kv.Replace("TY",_level_ty);
   kv.Replace("IS_PARENT",1);
   kv.Replace("LOT",_level_lot);
   kv.Replace("TPPIPS", _level_tp_pips);
   kv.Replace("TP",_level_tp_pr);
   kv.Replace("SLPIPS", _level_tp_pips);
   kv.Replace("SL",_level_tp_pr);
   
   levels.Add(kv);
}


void SetAddStopLevel(CArrayKeyVal& main_level_kv){

   CArrayKeyVal kv;
   kv.Clear();
   kv.Add(main_level_kv);
   
   int      main_level_id  = (int)      main_level_kv.Get("_ID");
   int      main_level_nr  = (int)      main_level_kv.Get("NR");
   double   main_level_pr  = (double)   main_level_kv.Get("PR");
   double   main_level_lot = (double)   main_level_kv.Get("LOT");
   ENUM_DTY main_level_dty = (ENUM_DTY) main_level_kv.Get("DTY");
   
   int      _level_ty      = DTYToReversStopType(main_level_dty);      
   double   _level_pr      = main_level_pr + GetSignPRByTY(_level_ty)*add_StopPip*Point();
   int      _level_tp_pips = GetTPPips(1, 1);
   double   _level_tp_pr   = _level_pr + GetSignTPByDTY(TypeToDTY(_level_ty)) * _level_tp_pips * _Point;
   int      _level_sl_pips = GetSLPips(1, 1);
   double   _level_sl_pr   = _level_pr + GetSignSLByDTY(TypeToDTY(_level_ty)) * _level_sl_pips * _Point;
   double   _level_lot     = main_level_lot;
   
   if(add_Stop_useLevelVol){
      _level_lot*=add_Stop_multiplyVol;
   }else{
      _level_lot=add_Stop_fixVol;
   }
   
   kv.DeleteKey("_ID");
   
   kv.Replace("PR",_level_pr);
   kv.Replace("TY",_level_ty);
   kv.Replace("IS_PARENT",1);
   kv.Replace("LOT", _level_lot);
   kv.Replace("TPPIPS", _level_tp_pips);
   kv.Replace("TP",_level_tp_pr);
   kv.Replace("SLPIPS", _level_tp_pips);
   kv.Replace("SL",_level_tp_pr);
   
   levels.Add(kv);
}

void SetAddStopLevel2(CArrayKeyVal& main_level_kv){

   CArrayKeyVal kv;
   kv.Clear();
   kv.Add(main_level_kv);
   
   int      main_level_id  = (int)      main_level_kv.Get("_ID");
   int      main_level_nr  = (int)      main_level_kv.Get("NR");
   double   main_level_pr  = (double)   main_level_kv.Get("PR");
   double   main_level_lot = (double)   main_level_kv.Get("LOT");
   ENUM_DTY main_level_dty = (ENUM_DTY) main_level_kv.Get("DTY");
   
   int      _level_ty      = DTYToReversStopType(main_level_dty);      
   double   _level_pr      = main_level_pr + GetSignPRByTY(_level_ty)*add_2StopPip*Point();
   int      _level_tp_pips = GetTPPips(1, 1);
   double   _level_tp_pr   = _level_pr + GetSignTPByDTY(TypeToDTY(_level_ty)) * _level_tp_pips * _Point;
   int      _level_sl_pips = GetSLPips(1, 1);
   double   _level_sl_pr   = _level_pr + GetSignSLByDTY(TypeToDTY(_level_ty)) * _level_sl_pips * _Point;
   double   _level_lot     = main_level_lot;
   
   if(add_2Stop_useLevelVol){
      _level_lot*=add_2Stop_multiplyVol;
   }else{
      _level_lot=add_2Stop_fixVol;
   }
   
   kv.DeleteKey("_ID");
   
   kv.Replace("PR",_level_pr);
   kv.Replace("TY",_level_ty);
   kv.Replace("IS_PARENT",1);
   kv.Replace("LOT", _level_lot);
   kv.Replace("TPPIPS", _level_tp_pips);
   kv.Replace("TP",_level_tp_pr);
   kv.Replace("SLPIPS", _level_sl_pips);
   kv.Replace("SL",_level_sl_pr);
   
   levels.Add(kv);
}

void SetStopLevel(CArrayKeyVal& main_level_kv){

   CArrayKeyVal kv;
   kv.Clear();
   kv.Add(main_level_kv);
   
   int      main_level_id  = (int)      main_level_kv.Get("_ID");
   int      main_level_nr  = (int)      main_level_kv.Get("NR");
   double   main_level_pr  = (double)   main_level_kv.Get("PR");
   double   main_level_lot = (double)   main_level_kv.Get("LOT");
   ENUM_DTY main_level_dty = (ENUM_DTY) main_level_kv.Get("DTY");
   int      main_level_net_id = (int)   main_level_kv.Get("NET_ID");
   int      main_level_net_nr = (int)  nets.Get("NR","_ID="+(string)main_level_net_id);
   
   int      _level_ty      = DTYToReversStopType(main_level_dty);      
   double   _level_pr      = main_level_pr; //+ GetSignPRByTY(_level_ty)*add_StopPip*Point();
   int      _level_tp_pips = GetTPPips(1, main_level_net_nr+1);
   double   _level_tp_pr   = _level_pr + GetSignTPByDTY(TypeToDTY(_level_ty)) * _level_tp_pips * _Point;
   int      _level_sl_pips = GetSLPips(1, main_level_net_nr+1);
   double   _level_sl_pr   = _level_pr + GetSignSLByDTY(TypeToDTY(_level_ty)) * _level_sl_pips * _Point;
   double   _level_lot     = main_level_lot;
   
   if(main_level_nr < SO_ContinueLevel){
      if(SO_useLimLevelVol){
         _level_lot /= SO_LimLevelVol_Divide;
      }
   }else{
      _level_lot /= SO_ContLevelVol_Divide;
   }
   
   kv.DeleteKey("_ID");
   
   kv.Replace("PR",_level_pr);
   kv.Replace("TY",_level_ty);
   kv.Replace("IS_PARENT",1);
   kv.Replace("LOT", _level_lot);
   kv.Replace("TPPIPS", _level_tp_pips);
   kv.Replace("TP",_level_tp_pr);
   kv.Replace("SLPIPS", _level_tp_pips);
   kv.Replace("SL",_level_tp_pr);
   kv.Replace("CONTINUE_NET_NR",1);
   levels.Add(kv);
   
   kv.DeleteKey("CONTINUE_NET_NR");
}

int GetSignPRByTY(int ty){
   int result = NULL;
   if(ty == OP_BUYSTOP || ty == OP_SELLLIMIT){
      result = 1;
   }
   
   if(ty == OP_BUYLIMIT || ty == OP_SELLSTOP){
      result = -1;
   }
   
   return(result);
}

int GetSignTPByDTY(ENUM_DTY dty){
   int result = NULL;
   
   if(dty == ENUM_DTY_BUY){
      result = 1;
   }
   
   if(dty == ENUM_DTY_SELL){
      result = -1;
   }
   
   return(result);
}

int GetSignSLByDTY(ENUM_DTY dty){
   int result = NULL;
   
   if(dty == ENUM_DTY_BUY){
      result = -1;
   }
   
   if(dty == ENUM_DTY_SELL){
      result = 1;
   }
   return(result);
}

ENUM_DTY TypeToDTY(int ty){
   ENUM_DTY result = -1;
   if(ty==OP_BUY || ty==OP_BUYLIMIT || ty==OP_BUYSTOP){
      result = ENUM_DTY_BUY;
   }
   
   if(ty==OP_SELL || ty==OP_SELLLIMIT || ty==OP_SELLSTOP){
      result = ENUM_DTY_SELL;
   }
   
   return(result);
}

int DTYToLimitType(ENUM_DTY dty){
   int result = -1;
   if(dty==ENUM_DTY_BUY){
      result = OP_BUYLIMIT;
   }else{
      if(dty==ENUM_DTY_SELL){
         result = OP_SELLLIMIT;
      }   
   }
   return(result);
}

int DTYToReversStopType(ENUM_DTY dty){
   int result = -1;
   if(dty==ENUM_DTY_BUY){
      result = OP_SELLSTOP;
   }else{
      if(dty==ENUM_DTY_SELL){
         result = OP_BUYSTOP;
      }   
   }
   return(result);
}


int GetTargetPips(int net_nr){
   double result = mgp_Target;
   if(net_nr > 1){
      if(SO_useKoefProp){
         for(int i=2;i<=net_nr;i++){
            result *= SO_Target;
         }
         
      }else{
         result = SO_Target;
      }
   }
   
   return((int)result);
}

int GetTargetPlusPips(int net_nr){
   int result = mgp_TargetPlus;
   if(net_nr > 1){
      if(SO_useKoefProp){
         result = (int)(SO_Target * mgp_TargetPlus);
      }else{
         result = (int)mgp_TargetPlus;
      }
   }
   
   return(result);
}

double GetMultiplyLots(int net_nr){
   double result = mgp_multiplyVol;
   
   return(result);
}

double GetPlusLots(int net_nr){
   double result = mgp_plusVol;
   
   return(result);
}

int GetMGPTP(int level_nr){
   int result = mgp_TP;
   
   if(level_nr==1){
      result = mgp_TPOnFirst;
   }
   
   return(result);
}

double GetSOTP(int level_nr){
   double result = SO_TP;
   
   if(level_nr == 1){
      result = SO_TP_on_first;
   }
   
   return(result);
}

int GetTPPips(int level_nr, int net_nr){
   double result = GetMGPTP(level_nr);
   
   if(net_nr > 1){
      double _so_tp = GetSOTP(level_nr);
      if(SO_useKoefProp){
         for(int i=2; i<=net_nr; i++){
            result *= _so_tp;
         }
      }else{
         result = _so_tp;
      }
   }
   
   return((int)result);
}

int GetTPPlusPips(int level_nr, int net_nr){
   int result = mgp_TPPlus;
   if(level_nr == 1){
      result = 0;
   }
   return(result);
}

//=======================================================================
int GetMGPSL(int level_nr){
   int result = mgp_SL;
   
   return(result);
}

double GetSOSL(int level_nr){
   double result = SO_SL;
   
   return(result);
}

int GetSLPips(int level_nr, int net_nr){
   double result = GetMGPSL(level_nr);
   
   if(net_nr > 1){
      double _so_sl = GetSOSL(level_nr);
      if(SO_useKoefProp){
         for(int i=2; i<=net_nr; i++){
            result *= _so_sl;
         }
      }else{
         result = _so_sl;
      }
   }
   
   return((int)result);
}

int GetSLPlusPips(int level_nr, int net_nr){
   int result = mgp_SLPlus;
   if(level_nr == 1){
      result = 0;
   }
   return(result);
}

void SendTicket(CSQLiteCursor* pLevels){
   START("========== GET LEVEL INFO FROM pLevel")
      int   level_id = (int)pLevels.GetValue("_ID"); 
      int   level_nr = (int)pLevels.GetValue("NR");
      int   net_id   = (int)pLevels.GetValue("NET_ID");
      int   net_nr   = (int)nets.Get("NR","_ID="+(string)net_id);
      int   pid_id   = (int)pLevels.GetValue("PID_ID");
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
      double   sl    = (double)pLevels.GetValue("SL");   
   
      DPrint("LID :: "+level_id+" | DTY :: "+dty+" | PR :: "+pr+" | TY :: "+ty+" | LOT :: "+lot+" | TP :: "+tp+" | SL :: "+sl);
   END
   
   double d[];
   if(ty > 1){
      CArrayKeyVal kv;
      kv.Add("LEVEL_ID",level_id);
      kv.Add("NET_ID",net_id);
      kv.Add("PID_ID",pid_id);
      START("========== TR_SendPending_array");
      TR_SendPending_array(d,ty,pr,0,lot,tp,sl,"nid:"+(string)net_id+"|nnr:"+(string)net_nr+"|lnr:"+(string)level_nr+"|lid:"+(string)level_id+"|pr:"+(string)pr,-1,NULL,TR_MODE_PRICE);
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

void SendTicketsByLevels(CSQLiteCursor* pLevels){
   while(pLevels.Next()){
      SendTicket(pLevels);
   }
}

void CheckNetsForClose(){
   START("========== Получение поинтера выборки тикетов сеток, которые должны быть закрыты")
      CSQLiteCursor* pTicketForClose = GetTicketsForClosePointer();
   END   
   
   START("========== Закрытие тикетов")
      CloseTicketsByPointer(pTicketForClose);
   END
   
   START("========== Удаление поинтера выборки тикетов сеток, которые должны быть закрыты")
      if(CheckPointer(pTicketForClose) == POINTER_DYNAMIC){
         delete pTicketForClose;
      }
   END
}

CSQLiteCursor* GetTicketsForClosePointer(){
   string q = "select TI from table_tickets \n"
            + "where NET_ID IN (select NET_ID from view_nets_must_be_closed) \n";
            
   CSQLiteCursor* p=db.RawQuery(q);
   return(p);            
}

void CloseTicketsByPointer(CSQLiteCursor* p){
   p.Reset();
   while(p.Next()){
      TR_CloseByTicket((int)p.GetValue("TI"));
   }
}

void CheckTP(){
   START("========== Получение поинтера выборки тикетов для которых нужно заменить ТП")
      CSQLiteCursor* pTicketsToChangeTP = GetTicketsToChangeTPPointer();
   END
   
   START("========== Обработка тикетов, которым нужно изменить ТП")
      ChangeTP(pTicketsToChangeTP);
   END
   
   START("========== Удаление поинтера выборки тикетов для которых нужно заменить ТП")
      if(CheckPointer(pTicketsToChangeTP) == POINTER_DYNAMIC){
         delete pTicketsToChangeTP;
      }
   END
}

CSQLiteCursor* GetTicketsToChangeTPPointer(){
   string s = "select * from view_tickets_to_change_tp";
   CSQLiteCursor* p = db.RawQuery(s);
   return(p);
}

void ChangeTP(CSQLiteCursor* p){
   p.Reset();
   while(p.Next()){
      int ti = (int)p.GetValue("TI");
      double tp = (double)p.GetValue("TP");
      TR_ModifyTP(ti, tp);
   }
}

//===============================================================
void CheckSL(){
   START("========== Получение поинтера выборки тикетов для которых нужно заменить СЛ")
      CSQLiteCursor* pTicketsToChangeSL = GetTicketsToChangeSLPointer();
   END
   
   START("========== Обработка тикетов, которым нужно изменить СЛ")
      ChangeSL(pTicketsToChangeSL);
   END
   
   START("========== Удаление поинтера выборки тикетов для которых нужно заменить СЛ")
      if(CheckPointer(pTicketsToChangeSL) == POINTER_DYNAMIC){
         delete pTicketsToChangeSL;
      }
   END
}



CSQLiteCursor* GetTicketsToChangeSLPointer(){
   string s = "select * from view_tickets_to_change_sl";
   CSQLiteCursor* p = db.RawQuery(s);
   return(p);
}

void ChangeSL(CSQLiteCursor* p){
   p.Reset();
   while(p.Next()){
      int ti = (int)p.GetValue("TI");
      double sl = (double)p.GetValue("SL");
      TR_ModifySL(ti, sl);
   }
}

//===============================================================

void SetPid(){
   if(tickets._OrdersTotal() == 0){
      _ThisPidId=pids.Add();
   }else{
      if(_ThisPidId==0){
         _ThisPidId=(int)pids.Get("MAX(_ID)");
      }   
   }
}

double GetPidProfit(int pid){
   if(pid==NULL || pid<=0){
      pid = _ThisPidId;
   }
   double result = (double)db.Get("SUM(OPR) AS PROFIT","table_tickets","PID_ID="+(string)pid);
   return(result);
}