//+------------------------------------------------------------------+
//|                                           CreateViewsTickets.mqh |
//|                                          Copyright 2017, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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
         if(!mgp_needSLToAll){
             q="select TT.TI, TL.SL from table_tickets as TT \n" 
              +"left join table_levels as TL on TL._ID=TT.LEVEL_ID \n"
              +"WHERE (TT.SL <> TL.SL) \n"
              +"AND (TT.IT = 1) \n";
         }else{
            q="select TT.TI, TL.SL from table_tickets as TT \n" 
              +"left join ( \n"
              +"   SELECT MAX(NR), * from table_levels \n"
              +"   WHERE _ID not in (select _ID from table_levels where DONT_SEND = 1 OR IS_PARENT=1) \n"
              +"   GROUP BY NET_ID \n"
              +") as TL on TL.NET_ID=TT.NET_ID \n"
              +"WHERE (TT.SL <> TL.SL) \n"
              +"AND (TT.IT = 1) \n";
         }     
      db.CreateOrUpdateView("view_tickets_to_change_sl",q);
   END
}
