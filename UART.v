//FULL DUPLEX UART
module UART(CnSin, CnSout, TxD, RxD, TxData, RxData, clock, reset);
	integer 			i, j, k;
	//Input Output Declarations
	input 	[7:0] 			CnSin, RxData;
	output 	[7:0]			CnSout, TxData;
	input				RxD, reset, clock;
	output 				TxD; 	
	//Reg Declarations
	reg				TxDtemp;
	reg 	[7:0]			TxData, TxDatatemp;
	reg 				Perr, DORerr, Ferr, TxC, RxC, TxNine;
	reg  	[2:0]			Txstate, Rxstate;
	wire 	[2:0] 			CharSize;
	wire				TxE, RxE, Stopbits, PMode, RxNine, NineEn;
	//Input Assignments
	assign TxE 		= 	CnSin[0];
	assign RxE 		=	CnSin[1];
	assign Stopbits 	= 	CnSin[2];
	assign PMode    	=	CnSin[3];
	assign RxNine 		= 	CnSin[4];
	assign CharSize		=	{1'b0,CnSin[6:5]};
	assign NineEn		= 	CnSin[7];
	//Output Assignments
	assign CnSout[0]	=	Perr;
	assign CnSout[1]	=	DORerr;
	assign CnSout[2]        =       Ferr;
	assign CnSout[3]        =       TxC;
	assign CnSout[4]        =       RxC;	
	assign CnSout[5]        =       TxNine;
	assign TxD		= 	TxDtemp;
	//Parameters
	parameter 	TxIDLE 		= 3'b000, 
			TxSEND_start 	= 3'b001,
			TxSEND_data 	= 3'b010,
			TxNINEBIT 	= 3'b011,
			TxPARITY 	= 3'b100,
			TxSTOPBIT 	= 3'b101,
			TxDONE 		= 3'b110;
	parameter 	RxIDLE 		= 3'b000,
			RxSTART		= 3'b001,
			RxRECEIVE 	= 3'b010, 
			RxPARITY 	= 3'b011, 
			RxSTOPBIT 	= 3'b100, 
			RxDONE 		= 3'B101; 
	parameter 	start  		= 1'b0;
	//Operations
	always@(posedge clock or negedge reset)
		//Outer Parallel Block
		fork
			if(!reset) 
			fork//Inner Parallel Block 
				Perr		= 0;
				DORerr		= 0;
				Ferr		= 0;
				TxC		= 0;
				RxC		= 0;
				TxNine		= 0;
				TxDatatemp	= 0;
				TxDtemp    	= 0;
				Txstate 	= TxIDLE;
				Rxstate 	= RxIDLE;
			join//Inner Parallel block Ends
			else 
			fork//Inner Parallel Block 
				if(TxE)//Transmitter Section
				begin
					case(Txstate)
						TxIDLE:		begin
										TxC 		= 0;
										TxDtemp 	= 1; 
										i 		= 0;
										Txstate 	= TxSEND_start;	
								end
						TxSEND_start:	begin
										TxDtemp		= start;
										Txstate		= TxSEND_data;
								end
						TxSEND_data:	begin
										TxDtemp		= RxData[i];
										if(i < CharSize + 5)
										begin  
										Txstate		= TxSEND_data; 
										i 		= i + 1; 
										end
										else if(NineEn) 
										begin
										TxDtemp 	= RxNine;
										Txstate		= TxPARITY;
										end
										else
										Txstate		= TxPARITY;
								end
						TxNINEBIT:	begin
										TxDtemp		= RxNine;
										Txstate		= TxPARITY;			
								end
						TxPARITY:	begin
								if(PMode)  	TxDtemp 	= ^RxData;
								else if(!PMode)	begin TxDtemp 	= ~^RxData; Txstate = TxSTOPBIT; end
								end
						TxSTOPBIT:	begin
										TxDtemp 	= 1;
										Txstate		= TxDONE;
								end
						TxDONE:		begin
										TxC 		= 1;
										Txstate 	= TxIDLE;
								end
						default:			Txstate 	= TxIDLE;
					endcase					
				end
				if(RxE)//Receiver Section
				begin
					case(Rxstate)
                                                RxIDLE:         begin		
										TxNine		= 0;
										TxData		= 0;
										TxDatatemp  	= 0;
										RxC		= 0;										RxC  		= 0;
										j		= 0;
										k 		= 0;
										Rxstate		= RxSTART;
                                                                end
						RxSTART:	begin
										if(RxD == start)
										Rxstate		= RxRECEIVE;
										else Rxstate	= RxIDLE;
								end	
                                                RxRECEIVE:      begin
								if(k < CharSize + 5)
									begin
									       	TxDatatemp[k]	= RxD;
										k 		= k + 1;		
                                                                	end
								else if(NineEn)
									begin
										TxNine		= RxD;
										Rxstate		= RxPARITY;
									end
								else 		Rxstate		= RxPARITY;
								end
						RxPARITY:	begin
								if(PMode && (^TxDatatemp)) Perr = 0;
								else if(PMode && (~^TxDatatemp)) Perr = 1;
								else if(!PMode && (^TxDatatemp)) Perr = 1;
								else if(!PMode && (~^TxDatatemp)) Perr = 0; 
										Rxstate		= RxSTOPBIT; 	
								end
						RxSTOPBIT:	begin
								if (j < 2) 
								begin
									if(RxD == 1) Rxstate 	= RxSTOPBIT; 
									else 	begin 
										Ferr 		= 1;
										Rxstate		= RxIDLE;
										end
								j = j + 1;
								end
								else 		Rxstate		= RxDONE; 	
								end
                                                RxDONE:         begin
										TxData		= TxDatatemp;
										RxC 		= 1;
										Rxstate		= RxIDLE;
                                                                end
                                                default:        		Rxstate 	= RxIDLE;
                                        endcase
				end	
			join//Inner Parallel Block Ends
		join//Outer Parallel Block Ends
	//END of Operations	
endmodule
