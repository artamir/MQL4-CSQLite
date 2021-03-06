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
            //последний лимитный уровень будет родительским и продолжится выставляться сетка.
input bool  mgp_LastLimLevelIsParent = false;
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

input string   ADD_LIMDESC_2="=========== Adding lim. order as parent";
            //разрешает советнику выставлять добавочный лимитный ордер как родительский.
input bool  add_useAddLimit2 = false;
               //уровень сетки, от которого будет произведен расчет цены добавочного ордера.
input int      add_2LimitLevel = 1;
               //На каком рассотянии в пунктах от уровня будет выставлен добавочный ордер.
input int      add_2LimitPip = 0;
               //разрешает советнику использовать настройку add_Limit_multiplyVol иначе будет использоваться add_Limit_fixVol
input bool     add_2Limit_useLevelVol = true;
               //коэф. умножения объема уровня add_LimitLevel основной сетки лимитных ордеров.
input double   add_2Limit_multiplyVol = 1; 
               //фиксированный объем добавочного ордера.
input double   add_2Limit_fixVol = 0.1;

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

input string ADD_STOPDESC2="=========== Adding stop order as parent";
            //разрешает советнику выставлять добавочный стоповый ордер как родительский.
input bool  add_useAddStop2 = false;
               //уровень сетки, от которого будет произведен расчет цены добавочного ордера.
input int      add_2StopLevel = 1;
               //На каком рассотянии в пунктах от уровня будет выставлен добавочный ордер.
input int      add_2StopPip = 0;
               //разрешает советнику использовать настройку add_Stop_multiplyVol иначе будет использоваться add_Stop_fixVol
input bool     add_2Stop_useLevelVol = true;
               //коэф. умножения объема уровня add_StopLevel основной сетки лимитных ордеров.
input double   add_2Stop_multiplyVol = 1; 
               //фиксированный объем добавочного ордера.
input double   add_2Stop_fixVol = 0.1;


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

           //После инициализации открывает рыночный бай, если такогого не было открыто
input bool useSendBuySell = false;
input double BuySellVol = 0.01;
