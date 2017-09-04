//+------------------------------------------------------------------+
//|                                                     eLt_RevO.mq4 |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property version   "0.1"
#property strict

//#define DEBUG
#define STOP_ON_BAD_ASSERT false
#define TEST
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
#include <SQLite_v2.1\subsystems\pids.mqh>
#include <SQLite_v2.1\subsystems\nets.mqh>
#include <SQLite_v2.1\subsystems\levels.mqh>

CSQLite SQLiteConnector;
CSQLiteBase db;
CPids pids;
CNets nets;
CLevels levels;
CSQLiteTickets tickets;

input string MGP="===== MAIN GRID PROP >>>>>>>>>>>>>>>";
            //Расстояние между уровнями
input int   mgp_Target = 50;
            //Увеличение расстояния между уровнями. Зависит от номера уровня
input int   mgp_TargetPlus = 0;

            //кол. пунктов для выставления тп на родительский ордер, когда нет сработавших дочерних ордеров
input int   mgp_TPOnFirst = 50;
            //кол. пунктов для выставления тп на сработавшие ордера сетки. расчет от последнего сработавшего ордера
input int   mgp_TP = 50;
            //увеличение тп от уровня на заданное количество пунктов.
input int   mgp_TPPlus = 0;

            //Разрешает советнику выставлять сл на всю сетку от последнего ордера или отдельно на каждый ордер
input bool  mgp_needSLToAll = false;
            //зависит от `mgp_needSLToAll` размерность: <i>пункты</i>
input int   mgp_SL = 0;
            //Увеличение сл в зависимости от уровня текущей сетки
input int   mgp_SLPlus = 0;

            //разрешает советнику использовать выставлять ордера лимитной сетки.
input bool  mgp_useLimOrders = true;
            //количество уровней лимитной сетки, включая родительский уровень
input int   mgp_LimLevels = 5;

               //увеличение объема след. уровня в mgp_multiplyVol раз (*)
input double   mgp_multiplyVol = 2;
               //увеличение объема след. уровня на величину mgp_plusVol (+)
input double   mgp_plusVol=0;
input string MGP_END="<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";

input string   ADD_LIMDESC="=========== Adding lim. order as parent";
            //разрешает советнику выставлять добавочный лимитный ордер как родительский.
input bool  add_useAddLimit = false;
               //уровень сетки, от которого будет произведен расчет цены добавочного ордера.
input int      add_LimitLevel = 1;
               //На каком рассотянии в пунктах от уровня будет выставлен добавочный ордер.
input int      add_LimitPip = 0;
               //разрешает советнику использовать настройку add_Limit_multiplyVol иначе будет использоваться add_Limit_fixVol
input bool     add_Limit_useLevelVol = true;
               //коэф. умножения объема уровня add_LimitLevel основной сетки лимитных ордеров.
input double   add_Limit_multiplyVol = 1; 
               //фиксированный объем добавочного ордера.
input double   add_Limit_fixVol = 0.1;

input string ADD_STOPDESC="=========== Adding stop order as parent";
            //разрешает советнику выставлять добавочный стоповый ордер как родительский.
input bool  add_useAddStop = false;
               //уровень сетки, от которого будет произведен расчет цены добавочного ордера.
input int      add_StopLevel = 1;
               //На каком рассотянии в пунктах от уровня будет выставлен добавочный ордер.
input int      add_StopPip = 0;
               //разрешает советнику использовать настройку add_Stop_multiplyVol иначе будет использоваться add_Stop_fixVol
input bool     add_Stop_useLevelVol = true;
               //коэф. умножения объема уровня add_StopLevel основной сетки лимитных ордеров.
input double   add_Stop_multiplyVol = 1; 
               //фиксированный объем добавочного ордера.
input double   add_Stop_fixVol = 0.1;

input string SOP="===== STOP ORDERS PROP >>>>>>>>>>>>>>>";
               //разрешает советнику использовать выставление стоповых ордеров
input bool     SO_useStopLevels=false;  
                  //-1 - количество уровней совпадает с уровнями лимитных ордеров, либо задает количетво стоповых уровней
input int         SO_Levels=-1;
                  //уровень, с которого выставляются стоповые ордера для данного родителя. Родительский ордер имеет индекс 1
input int         SO_StartLevel=2;
                  //разрешает использовать объем текущего уровня лимитной сетки для расчета объема стопового ордера 
input bool        SO_useLimLevelVol=true;
                     //деление объема лим. ордера для вычисления объема стоп. до уровня LevelVolParent. При -1 выставляется объемом родительского
input double         SO_LimLevelVol_Divide=-1.0;
                  //Настройки SO_useLimLevelVol и SO_LimLevelVol_Divide будут использоваться до этого уровня включительно
input int         SO_EndLevel=3;
                  //Включая этот уровень и до SO_Levels будут продолжать выставляться стоповые ордера.
input int         SO_ContinueLevel=5;
                  //Для расчета объема используется значение объема текущего лимитного уровня.
input double      SO_ContLevelVol_Divide=1.0;

input string SOTGP="=========== SO_TARGET, SO_TP, SO_SL ==";
input bool SO_useKoefProp=true;
input double   SO_Target=1.5;
input double   SO_TP=1.5;
input double   SO_TP_on_first=1.5;
input double   SO_SL=1.5;
input string SOP_END="<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";

input bool useFixProfit=true;
input double FixProfit_Amount=500;

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
         TPrint("ТУДУ: Написать блок установки тикетов")
      END
      
      START("========== Удаляем поинтер выборки уровней без тикетов")
         if(CheckPointer(pLevelsWOTickets) == POINTER_DYNAMIC){
            delete pLevelsWOTickets;
         }
      END
   END
   //}
   
   START("===================== FIX PROFIT")
      if(useFixProfit){
         FixProfit();
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
   START("CreateOrUpdateView(view_levels_wo_tickets")
      string q="select * from table_levels \n" 
              +"WHERE _ID NOT IN ( \n"
              +"    SELECT TT.LEVEL_ID FROM table_tickets as TT \n"
              +"    left join table_levels as TL on (TL._ID=TT.LEVEL_ID) \n"
              +"    where TT.LEVEL_ID NOTNULL \n"
              +"    group by TT.LEVEL_ID \n"
              +")";
      db.CreateOrUpdateView("view_levels_wo_tickets",q);
   END
   //}
}

void Deinit(){
   
}

bool FixProfit(){
   bool result=false;
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
   string s = "select TT.* from table_tickets as TT \n"
            + "left join table_levels as TL on (TL._ID = TT.LEVEL_ID) \n"
            + "where \n"
            + "TT.TY <= 1 \n"
            + "AND \n"
            + "TT.IT = 1 \n"
            + "AND \n"
            + "(TT.LEVEL_ID ISNULL \n"
            + " OR \n"
            + " (TL.IS_PARENT = 1 \n"
            + "  AND \n"
            + "  TL.NET_ID IN (select _ID from view_nets_worked)))";
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
      int      _level_id  = (int)      pParents.GetValue("LEVEL_ID");
      int      _ti        = (int)      pParents.GetValue("TI");
      double   _oop       = (double)   pParents.GetValue("OOP");
      ENUM_DTY _dty       = (ENUM_DTY) pParents.GetValue("DTY");
      double   _lot       = (double)   pParents.GetValue("LOT");
      
      if(_net_id==NULL){
         START("========== Создаем сетку для родительского тикета "+(string)_ti)
            CArrayKeyVal kv;
            kv.Add("NR",   1);
            kv.Add("PR",   _oop);
            kv.Add("DTY",  _dty);
            kv.Add("LOT",  _lot);
            _net_id     = NewNet(kv);
         END
         START("========== Создаем уровни для сетки родительского тикета "+(string)_ti)  
            _level_id   = NewLevels(_net_id);
         END   
            kv.Shutdown();
            kv.Add("NET_ID",_net_id);
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

int NewLevels(int this_net_id, int parent_net_id = -1){
   START("========== Получение начальных переменных из сетки")
      int      TargetToFirstLevel = 0;
      int      NetNr          = (int)      nets.Get("NR",  "_ID="+(string)this_net_id);
      double   FirstLevelPR   = (double)   nets.Get("PR",  "_ID="+(string)this_net_id);
      double   FirstLevelLot  = (double)   nets.Get("LOT", "_ID="+(string)this_net_id);
      ENUM_DTY NetDty         = (ENUM_DTY) nets.Get("DTY", "_ID="+(string)this_net_id);
   END
   
   int      TargetPips     = GetTargetPips(NetNr); 
   int      TargetPlusPips = GetTargetPlusPips(NetNr);
   
   int      MultiplyLots   = GetMultiplyLots(NetNr);
   double   PlusLots       = GetPlusLots(NetNr);
   
   int      SignKoef       = (NetDty==ENUM_DTY_BUY?-1:1); //если сетка вверх, то цены лимитных уровней расчитываем вниз
   
   double   ThisPlusLots       = 0;
   double   ThisLevelLots      = 0;
   int      ThisTargetPlusPips = 0;
   //Цикл по количеству уровней лимитной сетки.
   for(int nr=1; nr<=mgp_LimLevels; nr++){
      if(nr==1){
         TargetToFirstLevel = 0;
         ThisLevelLots = FirstLevelLot;
      }else{
         if(nr>2){
            ThisTargetPlusPips = ThisTargetPlusPips + TargetPlusPips;
            ThisPlusLots = ThisPlusLots + PlusLots;
         }
         TargetToFirstLevel = TargetToFirstLevel + TargetPips + ThisTargetPlusPips;
         ThisLevelLots = ThisLevelLots*MultiplyLots + ThisPlusLots;
      }
      
      double level_pr = FirstLevelPR + SignKoef * TargetToFirstLevel * Point();   
      double level_lot = ThisLevelLots;
      
      TPrint("nr="+(string)nr+" :: TargetToFirstLevel = "+(string)TargetToFirstLevel+" :: pr="+DoubleToStr(level_pr,Digits));
      TPrint("dty="+(string)NetDty+" :: lot="+DoubleToStr(level_lot,2)); 
      
      LevelsStructure ls;
         ls.nr       = nr;
         ls.net_id   = this_net_id;
         ls.pr       = level_pr;
         ls.lot      = level_lot;
         
      levels.Add(ls);   
   }   
   return(NULL);
}

int GetTargetPips(int net_nr){
   int result = mgp_Target;
   if(net_nr > 1){
      if(SO_useKoefProp){
         result = (int)(SO_Target * mgp_Target);
      }else{
         result = (int)SO_Target;
      }
   }
   
   return(result);
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

int GetMultiplyLots(int net_nr){
   int result = mgp_multiplyVol;
   
   return(result);
}

double GetPlusLots(int net_nr){
   double result = mgp_plusVol;
   
   return(result);
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
     // kv.Add("PID",pid);
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