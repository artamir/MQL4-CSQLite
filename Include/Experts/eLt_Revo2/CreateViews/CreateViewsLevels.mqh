//+------------------------------------------------------------------+
//|                                            CreateViewsLevels.mqh |
//|                                          Copyright 2017, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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