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
             q="select TT.TI, ML.SL from table_tickets as TT \n" 
              +"left join view_levels_w_max_nr_market_tickets as ML on ML.NET_ID=TT.NET_ID \n"
              +"where ML.NET_ID NOTNULL \n"
              +"and (TT.TY=0 OR TT.TY=1) \n"
              +"and (TT.IT=1) \n"
              +"and (TT.SL <> ML.SL) \n";
      db.CreateOrUpdateView("view_tickets_to_change_sl",q);
   END
}
