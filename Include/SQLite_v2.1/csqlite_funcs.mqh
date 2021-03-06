//+------------------------------------------------------------------+
//|                                                csqlite_funcs.mqh |
//|                                                          artamir |
//|                                                  artamir@mail.ru |
//|   																$Revision: 121 $|
//+------------------------------------------------------------------+
#property copyright "artamir"
#property link      "artamir@mail.ru"
#property strict

#ifndef BASE
#include <SQLite_v2.1\msvcrt\memcpy.mqh>
#include <SQLite_v2.1\msvcrt\strlen.mqh>
#include <SQLite_v2.1\msvcrt\strcpy.mqh>
#include <Object.mqh>
#include <SQLite_v2.1\csqlite_defs.mqh>
#endif 

//void DEL(KeyVal &a[], const string k){
//	int _KeyValIdx=GET_IDX(k,a);
//	if(_KeyValIdx>=0){
//	   for(int i=_KeyValIdx+1;i<ROWS(a);i++){
//	      a[i-1].key=a[i].key;a[i-1].val=a[i].val;
//	   } 
//	   ArrayResize(a,(ROWS(a)-1));
//	} 
//}

//void ADD(KeyVal &a[], string k, string v){
//   //sf;
//   StringToUpper(k);
//   ADDROW(a); a[LAST(a)].key=k; a[LAST(a)].val=v;
//   //ef;
//}

////Upsert
//void UPS(KeyVal &a[], string k, string v){
//   //sf;
//   int i = GET_IDX(k,a);
//   
//   if(i>=0){
//      DEL(a,k);
//   }
//   
//   StringToUpper(k);
//   ADDROW(a); a[LAST(a)].key=k; a[LAST(a)].val=v;
//   //ef;
//}

void DELVAL(int &a[], int val){
   int r=ROWS(a)-1;
   while(r>=0){
      if(a[r]==val){
         for(int i=r+1; i<ROWS(a); i++){
            a[i-1]=a[i];
         }
         ArrayResize(a,(ROWS(a)-1));
      }
      r--;
   }
}

bool ISVAL(int &a[], int val){
   bool result = false;
   for(int i=0; i<ROWS(a)&&!result; i++){
      if(a[i]==val){
         result=true;
         break;
      }
   }
   
   return(result);
}

void ADD(double &a[], double v){
	//sf;
   ADDROW(a); a[LAST(a)]=v;
   //ef;
}

void ADD(int &a[], int v){
	//sf;
   ADDROW(a); a[LAST(a)]=v;
   //ef;
}

void ADD(string &a[], string v){
   //sf;
   ADDROW(a); a[LAST(a)]=v;
   //ef;
}

////====================================================================
//string GET(string k,KeyVal &a[])
//  {
//   sf;
//   string r="";
//   StringToUpper(k);
//   for(int i=0;i<ROWS(a);i++)
//     {
//      if(a[i].key==k)
//        {
//         ef; return(a[i].val);
//        }
//     }
//   ef; return(r);
//  }
  
//int GET_IDX(string k, KeyVal &kv[]){
//   sf;
//   int r=-1;
//   StringToUpper(k);
//   for(int i=0; i<ROWS(kv); i++){
//      if(kv[i].key==k){
//         ef; return(i);
//      }
//   }
//   
//   ef; return(r);
//}  

//int GET_IDX(string tbl, structTableColumns &tblcols[]){
//   int r=-1;
//   string _tbl = tbl;
//   StringToUpper(_tbl);
//   for(int i=0; i<ROWS(tblcols); i++){
//      if(tblcols[i].table == _tbl){
//         return(i);
//      }
//   }
//   return(-1);
//}

int GET_IDX(string k, string &a[]){
   int r=-1;
   string _k=k;
   StringToUpper(_k);
   
   for(int i=0; i<ROWS(a); i++){
      
      string v=a[i];
      StringToUpper(v);
      if(v==_k){
         return(i);
      }
   }
   return(r);
}


//void COPY(KeyVal &from[], KeyVal &to[]){
//   for(int i=0; i<ROWS(from); i++){
//      string k=from[i].key;
//      string v=from[i].val;
//      
//      ADD(to,k,v);
//   }
//}
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//void PrintKV(KeyVal &kv[])
//  {
//  	sf;
//   for(int i=0;i<ROWS(kv);i++)
//     {
//      Print(kv[i].key+"|"+kv[i].val);
//     }
//   ef;  
//  }
  
//void PrintTC(structTableColumns &tc[]){
//   for(int i=0; i<ROWS(tc); i++){
//      for(int j=0; j<ROWS(tc[i].cols); j++){
//         Print(tc[i].table+" | "+tc[i].cols[j]);
//      }
//   }
//}  
  
void GetProgramInfo(ProgramInfo &r)
  {
	sf;
   r.path=MQLInfoString(MQL_PROGRAM_PATH);
   r.name=MQLInfoString(MQL_PROGRAM_NAME);
	ef;
  }
  
void stop_executing(){
   int array_to_use_for_stop_hack[]; 
   array_to_use_for_stop_hack[7]=4;
}  
  
//----------------------------------------------------------------------
class CKeyVal_v2 : public CObject{
   
   private:
      string   m_keys[];
      string   m_vals[];
      bool     m_is_queries[];
      string   m_types[];
      string   m_key;
      string   m_val;
      string   m_type;
      bool     m_is_query;
      
      int      m_size;
      int      m_index; //если индекс выходит за диапазон правильных значений
                        //если индекс < 0 и размер > 0 тогда индекс будет установлен в 0 и произведена инициализация переменных
                        //если индекс > размера и размер > 0 тогда индекс будет установлен в размер-1 и произведена инициализация переменных
                        //если размер <= 0 тогда индекс будет установлен в -1      
      bool     m_isNextStarted; //при первом вызове Next, если не было вызова First, тогда вызывается First                  
   public:
      bool  break_on_get_not_existing_key;
      bool  break_on_delete_if_next;
      CKeyVal_v2(){
         ArrayResize(m_keys,0);
         ArrayResize(m_vals,0);
         ArrayResize(m_types,0);
         ArrayResize(m_is_queries,0);
         m_key=NULL;
         m_val=NULL;
         m_type=NULL;
         m_is_query=false;
         
         m_size=0;
         m_index=-1;
         m_isNextStarted=false;
         
         break_on_get_not_existing_key=false;
         break_on_delete_if_next=true;
      };
      ~CKeyVal_v2(){};
      
   public:
      int   NewRow(){
               m_size++;
               m_index=m_size-1;
               ArrayResize(m_keys,m_size);
               ArrayResize(m_vals,m_size);
               ArrayResize(m_types,m_size);
               ArrayResize(m_is_queries, m_size);
               return(m_index);
            };
      
      void  Drop(){
               ArrayResize(m_keys,0);
               ArrayResize(m_vals,0);
               ArrayResize(m_types,0);
               ArrayResize(m_is_queries,0);
               SetDefaultValues();
            }
            
      void  SetDefaultValues(){
               m_key=NULL;
               m_val=NULL;
               m_type=NULL;
               m_is_query=NULL;
               m_index=-1;
               m_size=0;
               
            }
      
      
      template<typename TVal>
      int   Add(const string key, const TVal val, bool is_query = false){
               NewRow();
               m_types[m_index] = typename(val);
               m_keys[m_index] = key;
               m_vals[m_index] = (string)val;
               m_is_queries[m_index] = is_query;
               
               Get();
               return(m_index);
            };
      
      void  Delete(int index){
         if(break_on_delete_if_next){
            if(m_isNextStarted){
               DPrint("CAN NOT DELETE IF Next() used");
               STOP_HACK
            }
         }
         if(Size()>1){
            ArrayCopy(m_types,m_types,index,index+1);
            ArrayCopy(m_keys,m_keys,index,index+1);
            ArrayCopy(m_vals,m_vals,index,index+1);
            ArrayCopy(m_is_queries,m_is_queries,index,index+1);
         }
         m_size--;
         ArrayResize(m_types,m_size);
         ArrayResize(m_keys,m_size);
         ArrayResize(m_vals,m_size);
         ArrayResize(m_is_queries,m_size);
      }      
      void  Get(void){
               if(m_index<0 || m_index>=m_size){
                  DPrint("index is out of range")
                  SetDefaultValues();
               }else{
                  m_key = m_keys[m_index];
                  m_val = m_vals[m_index];
                  m_type = m_types[m_index];
                  m_is_query = m_is_queries[m_index];
               }
            }; 
      
      string   Get(const string key){
         string r="";
         bool isFound=false;
         for(int i=0; i<Size() && !isFound; i++){
            Index(i);
            DPrint("["+(string)i+"] :: KEY : "+Key());
            if(Key() == key){
               isFound=true;
            }
         }
         
         if(isFound){
            r=Val();
         }else{
            DPrint("KEY : <"+key+"> is not existing");
            if(break_on_get_not_existing_key){
               STOP_HACK
            }
         }
         
         return(r);
      }
            
      int   Size(){
               return(m_size);
            };
            
      void  Index(int i){
               m_index=i;
               Get();
            };
            
      int   Index(void){
               return(m_index);
            };
            
      string   Key(void){
                  return(m_key);
               }; 
      
      int      Key(const string key){
                  //return index of the key, else -1
                  bool isFound=false;
                  for(int i=0; i<Size() && !isFound; i++){
                     if(m_keys[i] == key){
                        isFound=true;
                        Index(i);
                        return(i);
                     }
                  }
                  return(-1);
               }
               
      string   Val(){
                  return(m_val);
               };
               
      void     Val(const string v){
                  //Устанавливает новое значение в val.
                  m_vals[m_index]=v;
                  Get();
               }               
               
      bool     IsQuery(){
                  return(m_is_query);
               };
      
      void     First(){
                  if(!m_isNextStarted){
                     m_isNextStarted=true;
                  }
                  if(Size()<=0){
                     m_index=-1;
                  }else{
                     m_index=0;
                     Get();
                  }   
               };
      
      bool     Next(){
                  if(!m_isNextStarted){
                     m_isNextStarted=true;
                     First();
                     if(m_index<0){
                        m_isNextStarted=false; //как будто и не начинали цикл
                        return(false);
                     }else{
                        return(true);
                     }
                  }
                  m_index++;
                  if(m_index<m_size){
                     Get();
                     return(true);
                  }
                  m_isNextStarted=false; //цикл закончен
                  return(false);
               };
                     
      string   toString(){
                  string s="";
                  while(Next()){
                     s+="["+Key()+":"+Val()+"]";
                  }
                  return(s);
               };
               
      string   Join(const string op="="){
         //объединяет в строку ключ и значение через op
         string result = Key()+op+Val();
         return(result);
      }
      
      string   JoinKeys(const string separator=","){
         string s="";
         while(Next()){
            s+=Key();
            if(Index()<Size()-1){
               s+=separator;
            }
         }
         return(s);
      }
      
      void  DeleteNotExistsKey(CKeyVal_v2 &keys){
         for(int i=Size()-1; i>=0; i--){
            Index(i);
            if(keys.Key(Key()) < 0){
               Delete(i);
            }
         }
      }                                                                                                                         
};


string ptr2str(uint ptr){
   int len=::strlen(ptr);             // length of string
   uchar str[];
   ArrayResize(str,len+1);            // prepare buffer
   strcpy(str,ptr);                  // read string to buffer
   return(CharArrayToString(str));    // return string
}