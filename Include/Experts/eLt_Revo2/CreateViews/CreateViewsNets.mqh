//+------------------------------------------------------------------+
//|                                              CreateViewsNets.mqh |
//|                                          Copyright 2017, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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
