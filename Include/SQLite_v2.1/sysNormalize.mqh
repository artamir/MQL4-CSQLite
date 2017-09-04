	/*
		>Ver	:	0.0.1
		>Date	:	2012.12.24
		>Hist	:
		>Author	:	Morochin <artamir> Artiom
		>Desc	:	Нормализация реальных чисел
	*/
	
double Norm_symb(double d, string sy = "", int add = 0){//..
	/*
		>Ver	:	0.0.2
		>Date	:	2012.07.18
		>Hist:
			@0.0.2@2012.07.18@artamir	[+] добавление новой переменной add 
			@0.0.1@2012.06.25@artamir	[+] Базовый функционал
		>Desc:
			Нормализует значение типа double количеством знаков после запятой для заданного инструмента.
		>VARS:
			d	: Переменная типа доубл
			sy	: Название инструмента
			add	: Добавление количесва значащих цифр после запятой
	*/
	//==================================
	if(sy == ""){
		sy = Symbol();
	}
	//----------------------------------
	if(d == 0){
		return(0);
	}
	//----------------------------------
	int di = (int)MarketInfo(sy,	MODE_DIGITS);
	return(NormalizeDouble(d, di+add));
}//.

double Norm_symb2(double d){
   double tick_size=MarketInfo(Symbol(),MODE_TICKSIZE);
   double norm_d=Norm_symb(d);
   double mod=Norm_symb(MathMod(norm_d,tick_size));
   double res=norm_d-mod+tick_size;
   res=Norm_symb(res);
   return(res);
}

double Norm_vol(double v, string sy = ""){//..
	/*
		>Ver	:	0.0.2
		>Date	:	2012.07.31
		>History:
			@0.0.2@2012.07.31@artamir	[+] Добавил нормализацию объема в зависимости от шага объема.
			@0.0.1@2012.07.25@artamir	[]
		>Description: Нормализация объема по шагу изменения.
	*/
	
	//--------------------------------------------------------------------
	if(sy == ""){
		sy = Symbol();
	}
	
	//--------------------------------------------------------------------
	int d = 2; //
	
	//--------------------------------------------------------------------
	double lotStep = MarketInfo(sy, MODE_LOTSTEP);
	
	//--------------------------------------------------------------------
	if(lotStep == 0.01){
		d = 2;
	}
	//------
	if(lotStep == 0.1){
		d = 1;
	}
	//------
	if(lotStep == 1){
		d = 0;
	}
	//--------------------------------------------------------------------
	return(NormalizeDouble(v, d));
}//.

enum ENUM_PRTPSL{
   PRTPSL_PR,
   PRTPSL_TP,
   PRTPSL_SL
};

double Norm_Add_Points(double pr, int pips, int ty, ENUM_PRTPSL mode = PRTPSL_PR){
   double r=0;
   
   if(mode == PRTPSL_PR){
      if ((ty == OP_BUY) || (ty == OP_BUYSTOP) || (ty == OP_SELLLIMIT)){
         r=Norm_symb(Norm_symb(pr)+pips*_Point);
         r = r - ((int)((r-pr)/_Point) - pips)*_Point; 
      } 
      
      if((ty == OP_SELL) || (ty==OP_SELLSTOP) || (ty == OP_BUYLIMIT)){
        r=Norm_symb(Norm_symb(pr)-pips*_Point);
        r = r + ((int)((pr-r)/_Point) - pips)*_Point; 
      } 
   }else{
      if(mode == PRTPSL_TP){
         if ((ty == OP_BUY) || (ty == OP_BUYSTOP) || (ty == OP_BUYLIMIT)){
            r=Norm_symb(Norm_symb(pr)+pips*_Point);
            r = r - ((r-pr)/_Point - pips)*_Point; 
         } 
         
         if((ty == OP_SELL) || (ty==OP_SELLSTOP) || (ty == OP_SELLLIMIT)){
           r=Norm_symb(Norm_symb(pr)-pips*_Point);
            r = r + ((r-pr)/_Point - pips)*_Point; 
         }   
      }else{
         if ((ty == OP_SELL) || (ty == OP_SELLSTOP) || (ty == OP_SELLLIMIT)){
            r=Norm_symb(Norm_symb(pr)+pips*_Point);
            r = r - ((r-pr)/_Point - pips)*_Point; 
         } 
         
         if((ty == OP_BUY) || (ty==OP_BUYSTOP) || (ty == OP_BUYLIMIT)){
           r=Norm_symb(Norm_symb(pr)-pips*_Point);
            r = r + ((r-pr)/_Point - pips)*_Point; 
         }
      }
   }
   
   
   
   
   
   return(r);
}