//+------------------------------------------------------------------+
//|                                                  CreateViews.mqh |
//|                                          Copyright 2017, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Experts\eLt_Revo2\CreateViews\CreateViewsLevels.mqh>
#include <Experts\eLt_Revo2\CreateViews\CreateViewsNets.mqh>
#include <Experts\eLt_Revo2\CreateViews\CreateViewsTickets.mqh>
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
   
   START("========== view_levels_on_worked_nets")
      q  ="SELECT TL.*, TN.NR as NET_NR FROM table_levels as TL \n"
         +"LEFT JOIN table_nets as TN on TL.NET_ID = TN._ID \n"
         +"WHERE NET_ID IN (SELECT _ID FROM view_nets_worked) \n";
         
      db.CreateOrUpdateView("view_levels_on_worked_nets",q);   
   END
}