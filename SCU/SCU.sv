module SCU (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [24:0] CA,
	input      [31:0] CDI,
	output     [31:0] CDO,
	input             CCS1_N,
	input             CCS2_N,
	input             CCS3_N,
	input             CRD_WR_N,
	input       [3:0] CDQM_N,
	input             CRD_N,
	output            CWAIT_N,
	input             CIVECF_N,
	output reg  [3:0] CIRL_N,
	output            CBREQ_N,
	input             CBACK_N,
	
	output     [24:0] ECA,
	input      [31:0] ECDI,
	output     [31:0] ECDO,
	output      [3:0] ECDQM_N,
	output            ECRD_WR_N,
	output            ECCS3_N,
	output            ECRD_N,	//not present in original
	input             ECWAIT_N,//not present in original
	
	output reg [25:0] AA,
	input      [15:0] ADI,
	output reg [15:0] ADO,
	output reg  [1:0] AFC,
	output reg        AAS_N,
	output reg        ACS0_N,
	output reg        ACS1_N,
	output reg        ACS2_N,
	input             AWAIT_N,
	input             AIRQ_N,
	output reg        ARD_N,
	output reg        AWRL_N,
	output reg        AWRU_N,
	output reg        ATIM0_N,
	output reg        ATIM1_N,
	output reg        ATIM2_N,
	
	input      [15:0] BDI,
	output reg [15:0] BDO,
	output reg        BADDT_N,
	output reg        BDTEN_N,
	output reg        BREQ_N,	//not present in original
	output reg        BCS1_N,
	input             BRDY1_N,
	input             IRQ1_N,
	output reg        BCS2_N,
	input             BRDY2_N,
	input             IRQV_N,
	input             IRQH_N,
	input             IRQL_N,
	output reg        BCSS_N,
	input             BRDYS_N,
	input             IRQS_N,
	
	input             MIREQ_N,
	
	output     [ 7:0] DBG_WAIT_CNT,
	output     [ 7:0] DBG_BBUS_WAIT_CNT,
	output reg        ADDR_ERR_DBG,
	output reg        DMA_TN_ERR,
	output            DBG_DMA_RADDR_ERR,
	output            DBG_DMA_WADDR_ERR
);
	import SCU_PKG::*;
	
	DxR_t      DR[3];
	DxW_t      DW[3];
	DxC_t      DC[3];
	DxAD_t     DAD[3];
	DxEN_t     DEN[3];
	DxMD_t     DMD[3];
//	DSTP_t     DSTP;
	DSTA_t     DSTA;
	T0C_t      T0C;
	T1S_t      T1S;
	T1MD_t     T1MD;
	IMS_t      IMS;
	ASR0_t     ASR0;
	ASR1_t     ASR1;
	RSEL_t     RSEL;
	
	bit [26:0] DSP_DR;
	bit [26:0] DSP_DW;
	bit  [2:0] DSP_ADD;
	bit        DSP_HOLD;
	
	bit CDQM_N_OLD;
	bit CRD_N_OLD;
	bit [3:0] IVECF_LVL;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			CDQM_N_OLD <= 1;
			CRD_N_OLD <= 1; 
		end else if (CE_R) begin
			CDQM_N_OLD <= &CDQM_N;
			IVECF_LVL <= CA[3:0];
		end else if (CE_F) begin
			CRD_N_OLD <= CRD_N;
		end
	end
	wire CWE = ~&CDQM_N & CDQM_N_OLD & CE_R;
	wire CRE = ~CRD_N & CRD_N_OLD & CE_F;
	
	wire REG_SEL = ~CCS2_N & CA[24:0] >= 25'h1FE0000 & CA[24:0] <= 25'h1FE00CF;	//25FE0000-25FE00CF
	wire REG_WR = REG_SEL & CWE;
	wire REG_RD = REG_SEL & CRE;
	wire IVECF_RISE = CRD_N & ~CRD_N_OLD & ~CIVECF_N;

	bit        VBIN_INT;
	bit        VBOUT_INT;
	bit        HBIN_INT;
	bit        TM0_INT;
	bit        TM1_INT;
	bit        DSP_INT;
	bit        SCSP_INT;
	bit        SM_INT;
	bit        PAD_INT;
	bit  [3:0] DMA_INT;
	bit        DMAIL_INT;
	bit        VDP1_INT;
	bit [15:0] EXT_INT;
	
	bit [26:0] ABUS_A;
	bit        CPU_ABUS_REQ;
	bit        ABUS_RDY;
	
	bit  [1:0] BBUS_BA;
	bit        CPU_BBUS_REQ;
	wire       BBUS_RDY = ((!BCSS_N && !BRDYS_N) || (!BCS1_N && !BRDY1_N) || (!BCS2_N && !BRDY2_N));
	
	bit [26:0] CBUS_A;
	bit [31:0] CBUS_D;
//	bit [31:0] CBUS_BUF;
	bit        CBUS_RD;
	bit  [3:0] CBUS_WR;
	bit        CBUS_CS;
	bit        CBUS_REQ;
	bit        CBUS_REL;
	
	//DSP
	bit [31:0] DSP_DMA_DO;
	bit [31:0] DSP_DMA_DI;
	bit        DSP_DMA_WE;
	bit        DSP_DMA_REQ;
	bit        DSP_DMA_ACK;
	bit        DSP_DMA_RUN;
	bit        DSP_DMA_END;
	bit        DSP_DMA_LAST;
	bit        DSP_IRQ;
	
	//DMA
	bit [26:0] DMA_IA;
	bit [26:0] DMA_RA;
	bit [26:0] DMA_WA;
	bit [19:0] DMA_RTN;
	bit [19:0] DMA_WTN;
	bit        DMA_EC;
	bit        DMA_RADD;
	bit [ 2:0] DMA_WADD;
	bit  [1:0] DMA_CH;
	bit        DMA_RUN[3];
	bit        DMA_END;
	
	typedef enum bit [3:0] {
		ABUS_IDLE,  
		ABUS_ADDR, 
		ABUS_ACCESS, 
		ABUS_WAIT,
		ABUS_DMA_READ,
		ABUS_DMA_WAIT,
		ABUS_DMA_END
	} ABUSState_t;
	ABUSState_t ABUS_ST;
	
	typedef enum bit [3:0] {
		BBUS_IDLE,  
		BBUS_ADDR1, 
		BBUS_ADDR2, 
		BBUS_READ,
		BBUS_READ_WAIT,
		BBUS_WRITE,
		BBUS_WRITE_END,
		BBUS_DMA_RADDR1,
		BBUS_DMA_RADDR2,
		BBUS_DMA_READ,
		BBUS_DMA_WADDR1,
		BBUS_DMA_WADDR2,
		BBUS_DMA_WRITE,
		BBUS_DMA_END
	} BBUSState_t;
	BBUSState_t BBUS_ST;
	
	typedef enum bit [3:0] {
		CBUS_IDLE,  
		CBUS_REQUEST, 
		CBUS_READ, 
		CBUS_WRITE,
		CBUS_END
	} CBUSState_t;
	CBUSState_t CBUS_ST;
	
	typedef enum bit [4:0] {
		DMA_IDLE,
		DMA_SELECT,
		DMA_IND_START, 
		DMA_IND_READ, 
		DMA_IND_END, 
		DMA_START,
		DMA_ABUS_BBUS,
		DMA_ABUS_CBUS,
		DMA_BBUS_CBUS,
		DMA_CBUS_BBUS,
		DMA_ABUS_DSP,
		DMA_BBUS_DSP,
		DMA_CBUS_DSP,
		DMA_DSP_BBUS,
		DMA_DSP_CBUS,
		DMA_DSP_INIT, 
		DMA_DSP_START,
		DMA_STOP
	} DMAState_t;
	DMAState_t DMA_ST;
	
	parameter bit [19:0] DMA_TN_MASK[3] = '{20'hFFFFF,20'h00FFF,20'h00FFF};
	
	//Extern request
	bit IRQV_N_OLD, IRQH_N_OLD;
	bit IRQS_N_OLD;
	bit IRQ1_N_OLD;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			IRQV_N_OLD <= 1;
			IRQH_N_OLD <= 1;
			IRQS_N_OLD <= 1;
			IRQ1_N_OLD <= 1;
		end
		else begin
			if (!RES_N) begin
				IRQV_N_OLD <= 1;
				IRQH_N_OLD <= 1;
			end else if (CE_R) begin
				IRQH_N_OLD <= IRQH_N;
				IRQV_N_OLD <= IRQV_N;
				IRQS_N_OLD <= IRQS_N;
				IRQ1_N_OLD <= IRQ1_N;
			end
		end
	end
	wire VBL_IN   = !IRQV_N &  IRQV_N_OLD;
	wire VBL_OUT  =  IRQV_N & !IRQV_N_OLD;
	wire HBL_IN   = !IRQH_N &  IRQH_N_OLD;
	wire SCSP_REQ = !IRQS_N &  IRQS_N_OLD;
	wire VDP1_REQ = !IRQ1_N &  IRQ1_N_OLD;
	
	//DMA & CPU access
	wire ABUS_SEL = (~CCS1_N | (CA[24:20] < 5'h19 & ~CCS2_N)) & (~CRD_N | ~&CDQM_N);				//02000000-058FFFFF
	wire BBUS_SEL = CA[24:16] >= 9'h1A0 & CA[24:16] < 9'h1FE & ~CCS2_N & (~CRD_N | ~&CDQM_N);	//05A00000-05FDFFFF
	bit         CBUS_WAIT;
	
	bit DMA_FACT[3];
	always_comb begin
		for (int i=0; i<3; i++) begin
			case (DMD[i].FT)
				3'b000: DMA_FACT[i] = VBL_IN;
				3'b001: DMA_FACT[i] = VBL_OUT;
				3'b010: DMA_FACT[i] = HBL_IN;
				3'b011: DMA_FACT[i] = TM0_INT;
				3'b100: DMA_FACT[i] = TM1_INT;
				3'b101: DMA_FACT[i] = SCSP_REQ;
				3'b110: DMA_FACT[i] = VDP1_REQ;
				3'b111: DMA_FACT[i] = DEN[i].GO;
			endcase
		end
	end
	
	bit  [31:0] AB_BUF;
	
	bit         DMA_PEND[4];
	bit   [7:0] DMA_BUF[8];
	bit   [2:0] DMA_BUF_WPOS;
	bit   [2:0] DMA_BUF_RPOS;
	bit   [2:0] DMA_BUF_SIZE;
	bit   [3:0] DMA_WBE;
	bit         DMA_IND;
	
	bit        DMA_READ_A;
	bit        DMA_READ_B;
	bit        DMA_READ_C;
	bit        DMA_WRITE_A;
	bit        DMA_WRITE_B;
	bit        DMA_WRITE_C;
	bit        DMA_READ_DSP;
	bit        DMA_WRITE_DSP;
	always @(posedge CLK or negedge RST_N) begin
		bit   [2:0] DMA_RTN_DEC;
		bit   [2:0] DMA_WTN_DEC;
		bit  [19:0] DMA_RTN_NEXT;
		bit  [19:0] DMA_WTN_NEXT;
		bit   [1:0] DMA_IND_REG;
		bit         DMA_LAST;
		bit         DMA_DSP;
		bit         DSP_DMA_RUN_OLD;
		bit         ABBUS_SEL_OLD;
		bit         ABUS_WORD;
		bit   [1:0] BBUS_WORD;
		bit         BBUS_RD;
		bit   [2:0] DMA_ABUS_PAUSE;
		
		bit         ABUS_DMA_START;
		bit         ABUS_DMA_OUT;
		bit         BBUS_DMA_START;
		bit         BBUS_DMA_OUT;
		bit         ABUS_READ_ACK;
		bit         BBUS_READ_ACK;
		bit         BBUS_WRITE_DONE;
		bit         BBUS_DATA_ACK;
		bit         BBUS_CBUS_DONE;
		bit         CBUS_READ_ACK;
		bit         CBUS_WRITE_DONE;
		bit         CBUS_DATA_ACK;
		bit         CBUS_BBUS_DONE;
		bit         BBUS_DSP_DONE;
		bit         CBUS_DSP_DONE;
				
		if (!RST_N) begin
			AA <= '0;
			ADO <= '0;
			AAS_N <= 1;
			ARD_N <= 1;
			AWRL_N <= 1;
			AWRU_N <= 1;
			ACS0_N <= 1;
			ACS1_N <= 1;
			ACS2_N <= 1;
			AFC <= '1;
			ATIM0_N <= 1;
			ATIM1_N <= 1;
			ATIM2_N <= 1;
			
			BDO <= '0;
			BADDT_N <= 1;
			BDTEN_N <= 1;
			BCS1_N <= 1;
			BCS2_N <= 1;
			BCSS_N <= 1;
			
			DSTA <= DSTA_INIT;
			
			ABUS_ST <= ABUS_IDLE;
			ABUS_DMA_START <= 0;
			CPU_ABUS_REQ <= 0;
			ABBUS_SEL_OLD <= 0;
			ABUS_A <= '0;
			
			BBUS_ST <= BBUS_IDLE;
			BBUS_DMA_START <= 0;
			CPU_BBUS_REQ <= 0;
			BBUS_BA <= '0;
			
			CBUS_ST <= CBUS_IDLE;
			CBUS_A <= '0;
			CBUS_D <= '0;
			CBUS_REQ <= 0;
			CBUS_REL <= 0;
			CBUS_WAIT <= 0;
			
			DMA_ST <= DMA_IDLE;
			DMA_RA <= '0;
			DMA_WA <= '0;
			DMA_IA <= '0;
			DMA_RTN <= '0;
			DMA_WTN <= '0;
			DMA_EC <= 0;
			DMA_CH <= '0;
			DMA_PEND <= '{4{0}};
			DMA_DSP <= 0;
			DMA_IND <= 0;
			DMA_RUN <= '{3{0}};
			DMA_END <= 0;
			DMA_INT <= '0;
			DMAIL_INT <= 0;
			
			DMA_READ_A <= 0;
			DMA_READ_B <= 0;
			DMA_READ_C <= 0;
			DMA_WRITE_A <= 0;
			DMA_WRITE_B <= 0;
			DMA_WRITE_C <= 0;
			DMA_READ_DSP <= 0;
			DMA_WRITE_DSP <= 0;
		end else if (!RES_N) begin
			DSTA <= DSTA_INIT;
			
			ABUS_ST <= ABUS_IDLE;
			ABUS_DMA_START <= 0;
			CPU_ABUS_REQ <= 0;
			ABBUS_SEL_OLD <= 0;
			ABUS_A <= '0;
			
			BBUS_ST <= BBUS_IDLE;
			BBUS_DMA_START <= 0;
			CPU_BBUS_REQ <= 0;
			BBUS_BA <= '0;
			
			CBUS_ST <= CBUS_IDLE;
			CBUS_A <= '0;
			CBUS_D <= '0;
			CBUS_REQ <= 0;
			CBUS_REL <= 0;
			CBUS_WAIT <= 0;
			
			DMA_ST <= DMA_IDLE;
			DMA_RA <= '0;
			DMA_WA <= '0;
			DMA_IA <= '0;
			DMA_RTN <= '0;
			DMA_WTN <= '0;
			DMA_EC <= 0;
			DMA_CH <= '0;
			DMA_PEND <= '{4{0}};
			DMA_DSP <= 0;
			DMA_IND <= 0;
			DMA_RUN <= '{3{0}};
			DMA_END <= 0;
			DMA_INT <= '0;
			DMAIL_INT <= 0;
			
			DMA_READ_A <= 0;
			DMA_READ_B <= 0;
			DMA_READ_C <= 0;
			DMA_WRITE_A <= 0;
			DMA_WRITE_B <= 0;
			DMA_WRITE_C <= 0;
			DMA_READ_DSP <= 0;
			DMA_WRITE_DSP <= 0;
		end else begin
			BREQ_N <= 1;
			
			if (CE_F) begin
				if (CBUS_REL) CBUS_REL <= 0;
				if (DSP_DMA_END) DSP_DMA_END <= 0;
			end
			if (CE_R) begin
				ABBUS_SEL_OLD <= ABUS_SEL | BBUS_SEL;
				if ((ABUS_SEL || BBUS_SEL) && !ABBUS_SEL_OLD && !CBUS_WAIT) CBUS_WAIT <= 1;
				if (!ABUS_SEL && CPU_ABUS_REQ) CPU_ABUS_REQ <= 0;
				if (!BBUS_SEL && CPU_BBUS_REQ) CPU_BBUS_REQ <= 0;
				if (CBUS_REQ) CBUS_REQ <= 0;
				
				DMAIL_INT <= 0;
				if (DSP_DMA_ACK) DSP_DMA_ACK <= 0;
				
				if (DMA_FACT[0] && DEN[0].EN && !DMA_PEND[0]) begin DMA_PEND[0] <= 1; DSTA.D0WT <= 1; end
				if (DMA_FACT[1] && DEN[1].EN && !DMA_PEND[1]) begin DMA_PEND[1] <= 1; DSTA.D1WT <= 1; end
				if (DMA_FACT[2] && DEN[2].EN && !DMA_PEND[2]) begin DMA_PEND[2] <= 1; DSTA.D2WT <= 1; end
				DSP_DMA_RUN_OLD <= DSP_DMA_REQ;
				if (DSP_DMA_REQ && !DSP_DMA_RUN_OLD) begin DMA_PEND[3] <= 1; DSTA.DDWT <= 1; end
				
				DMA_END <= 0;
			end
			
			ABUS_READ_ACK = (ABUS_ST == ABUS_DMA_WAIT && ABUS_DMA_OUT);
			BBUS_READ_ACK = (BBUS_ST == BBUS_DMA_READ && BBUS_DMA_OUT);
			CBUS_READ_ACK = (CBUS_ST == CBUS_READ && ECWAIT_N);
			DMA_RTN_DEC = 3'd4;
			if (((DMA_ST == DMA_ABUS_BBUS || DMA_ST == DMA_ABUS_CBUS) && ABUS_READ_ACK) || 
				 (DMA_ST == DMA_BBUS_CBUS && BBUS_READ_ACK) || 
				 (DMA_ST == DMA_CBUS_BBUS && CBUS_READ_ACK)) begin
				DMA_RTN_DEC = 3'd4;
				if (DMA_RA[1:0]) begin
					case (DMA_RA[1:0])
						2'b00: ;
						2'b01: DMA_RTN_DEC = 3'd3;
						2'b10: DMA_RTN_DEC = 3'd2;
						2'b11: DMA_RTN_DEC = 3'd1;
					endcase
				end else if (!DMA_RTN[19:2] && DMA_RTN[1:0]) begin
					DMA_RTN_DEC = {1'b0,DMA_RTN[1:0]};
				end
			end
			DMA_RTN_NEXT = (DMA_RTN - DMA_RTN_DEC) & (DMA_TN_MASK[DMA_CH] | {20{DMD[DMA_CH].MOD}});
			
			if (DMA_ST == DMA_ABUS_CBUS || DMA_ST == DMA_BBUS_CBUS) begin
				DMA_WTN_DEC = 3'd4;
				if (!DMA_WTN[19:2] && DMA_WTN[1:0]) begin
					DMA_WTN_DEC = {1'b0,DMA_WTN[1:0]};
				end
			end else begin
				DMA_WTN_DEC = 3'd2;
				if (!DMA_WTN[19:1] && DMA_WTN[0]) begin
					DMA_WTN_DEC = {2'b00,DMA_WTN[0]};
				end
			end
			DMA_WTN_NEXT = (DMA_WTN - DMA_WTN_DEC) & (DMA_TN_MASK[DMA_CH] | {20{DMD[DMA_CH].MOD}});
			
			//A-BUS 02000000-058FFFFF
			if (DSTA.DACSA && ABUS_DMA_START && CE_R) ABUS_DMA_START <= 0;
			case (ABUS_ST)
				ABUS_IDLE : if (CE_R) begin
					if (ABUS_SEL && !CPU_ABUS_REQ) begin
						ABUS_A <= !CCS1_N ? {2'b01,CA[24:0]} : {2'b10,CA[24:0]};
						CPU_ABUS_REQ <= 1;
						ABUS_ST <= ABUS_ACCESS;
					end
					else if (DMA_READ_A && DMA_DSP) begin
						if (!DSP_DMA_WE) begin
							ABUS_A <= DMA_RA[26:0];
							ABUS_DMA_START <= 1;
							ABUS_ST <= ABUS_DMA_READ;
						end else begin
							
						end
					end
					else if (DMA_READ_A && !DMA_DSP && (!CBRLS || !DMA_WRITE_C)) begin
						ABUS_A <= DMA_RA[26:0];
						ABUS_DMA_START <= 1;
						ABUS_DMA_OUT <= 0;
						ABUS_ST <= ABUS_DMA_READ;
					end
				end
				
				ABUS_ACCESS: if (CE_R) begin
					casez (ABUS_A[26:24])
						3'b0??: ACS0_N <= 0;
						3'b100: ACS1_N <= 0;
						default: ACS2_N <= 0;
					endcase
					AA <= ABUS_A[25:0];
					AAS_N <= 0;
					if ((!(&CDQM_N[3:2]) || !CRD_N) && !ABUS_WORD) begin
						ADO <= CDI[31:16];
						ARD_N <= CRD_N;
						AWRL_N <= CDQM_N[2];
						AWRU_N <= CDQM_N[3];
						ABUS_WORD <= ~&CDQM_N[1:0] | (CA[24:20] == 5'h18 & ~CA[19] & ~CCS2_N & ~CRD_N);
					end else begin
						ADO <= CDI[15:0];
						ARD_N <= CRD_N;
						AWRL_N <= CDQM_N[0];
						AWRU_N <= CDQM_N[1];
						ABUS_WORD <= 0;
					end
					ABUS_ST <= ABUS_WAIT;
				end
				
				ABUS_WAIT: if (CE_R) begin
					AAS_N <= 1;
					if (AWAIT_N) begin
						ARD_N <= 1;
						AWRL_N <= 1;
						AWRU_N <= 1;
						ACS0_N <= 1;
						ACS1_N <= 1;
						ACS2_N <= 1;
						if (!ABUS_A[1]) AB_BUF[31:16] <= ADI;
						else            AB_BUF[15: 0] <= ADI;
						if (ABUS_WORD) begin
							ABUS_A[1] <= 1;
							ABUS_ST <= ABUS_ACCESS;
						end else begin
							CBUS_WAIT <= 0;
							ABUS_ST <= ABUS_IDLE;
						end
					end
				end
				
				ABUS_DMA_READ: if (CE_R) begin
					if (!DMA_BUF_SIZE) begin
						casez (ABUS_A[26:24])
							3'b0??: ACS0_N <= 0;
							3'b100: ACS1_N <= 0;
							default: ACS2_N <= 0;
						endcase
						AA <= ABUS_A[25:0];
						AAS_N <= 0;
						ARD_N <= 0;
						AWRL_N <= 1;
						AWRU_N <= 1;
						DMA_ABUS_PAUSE <= 3'd7;
						ABUS_ST <= ABUS_DMA_WAIT;
					end
				end
					
				ABUS_DMA_WAIT: if (CE_F) begin
					if (ABUS_DMA_OUT) begin
						ABUS_DMA_OUT <= 0;
						if ((!DMA_DSP && !DMA_RTN_NEXT) || (DMA_DSP && DSP_DMA_LAST)) begin
							ABUS_ST <= ABUS_DMA_END;
						end
					end
				end else if (CE_R) begin
					AAS_N <= 1;
					DMA_ABUS_PAUSE <= DMA_ABUS_PAUSE - 3'd1;
					if (AWAIT_N && !DMA_ABUS_PAUSE) begin
						ARD_N <= 1;
						AWRL_N <= 1;
						AWRU_N <= 1;
						ACS0_N <= 1;
						ACS1_N <= 1;
						ACS2_N <= 1;
						
						if (!ABUS_A[1]) begin
							AB_BUF[31:16] <= ADI;
						end else begin
							AB_BUF[15: 0] <= ADI;
							ABUS_DMA_OUT <= 1;
						end
						ABUS_A[1] <= ~ABUS_A[1];
						ABUS_ST <= ABUS_DMA_READ;
					end
				end
					
				ABUS_DMA_END: if (CE_R) begin
					if (!DMA_READ_A)
						ABUS_ST <= ABUS_IDLE;
				end
			endcase
			
			//B-BUS 05A00000-05FDFFFF
			if (DSTA.DACSB && BBUS_DMA_START && CE_R) BBUS_DMA_START <= 0;
			BBUS_WRITE_DONE = 0;
			BBUS_DATA_ACK = 0;
			case (BBUS_ST)
				BBUS_IDLE : if (CE_R) begin
					if (BBUS_SEL && !CPU_BBUS_REQ) begin
						BBUS_BA <= {CA[1],1'b0};
						BBUS_RD <= ~CRD_N;
						BBUS_WORD <= {~&CDQM_N[3:2],~&CDQM_N[1:0]} | {2{~CRD_N}};
						CPU_BBUS_REQ <= 1;
						BBUS_ST <= BBUS_ADDR1;
					end else if (DMA_READ_B && ((!DMA_DSP && (!CBRLS || !DMA_WRITE_C)) || (DMA_DSP && !DSP_DMA_WE))) begin
						case (DMA_RA[22:21])
							2'b01: BCSS_N <= 0;
							2'b10: BCS1_N <= 0;
							2'b11: BCS2_N <= 0;
						endcase
						BDO <= {1'b0,1'b1,2'b11,DMA_RA[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						
						BBUS_BA <= 2'b00;
//						BBUS_RD <= 1;
						BBUS_WORD <= 2'b11;
						BBUS_DMA_START <= 1;
						BBUS_DMA_OUT <= 0;
						BBUS_ST <= BBUS_DMA_RADDR1;
					end else if (DMA_WRITE_B && ((!DMA_DSP && (!CBRLS || !DMA_READ_C)) || (DMA_DSP && DSP_DMA_WE))) begin
						case (DMA_WA[22:21])
							2'b01: BCSS_N <= 0;
							2'b10: BCS1_N <= 0;
							2'b11: BCS2_N <= 0;
						endcase
						BDO <= {1'b0,1'b0,2'b11,DMA_WA[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						
						BBUS_BA <= 2'b00;
//						BBUS_RD <= 0;
						BBUS_WORD <= 2'b11;
						BBUS_DMA_START <= 1;
						BBUS_DMA_OUT <= 0;
						BBUS_ST <= BBUS_DMA_WADDR1;
					end
				end
				
				BBUS_ADDR1: if (CE_R) begin
					case (CA[22:21])
						2'b01: BCSS_N <= 0;
						2'b10: BCS1_N <= 0;
						2'b11: BCS2_N <= 0;
					endcase
					BDO <= {1'b0,&CDQM_N,2'b00,CA[20:9]};
					BDTEN_N <= 1;
					BADDT_N <= 1;
					BBUS_ST <= BBUS_ADDR2;
				end
				
				BBUS_ADDR2: if (CE_R) begin
					if (!CRD_N) 
						BDO <= {2'b10,2'b00,4'b0000,CA[8:2],BBUS_BA[1]};
					else if (!(&CDQM_N[3:2])) 
						BDO <= {2'b10,CDQM_N[3:2],4'b0000,CA[8:2],BBUS_BA[1]};
					else
						BDO <= {2'b10,CDQM_N[1:0],4'b0000,CA[8:2],BBUS_BA[1]};
					BDTEN_N <= 1;
					BADDT_N <= 1;
					BBUS_ST <= BBUS_RD ? BBUS_READ : BBUS_WRITE;
				end
				
				BBUS_WRITE: if (CE_R) begin
					if (BBUS_RDY) begin
						if (BBUS_WORD[1]) begin
							BDO <= CDI[31:16];
						end else begin
							BDO <= CDI[15:0];
						end
						BDTEN_N <= 0;
						BADDT_N <= 0;
						BREQ_N <= 0;

						BBUS_ST <= BBUS_WRITE_END;
//						DBG_BBUS_WAIT_CNT <= '0;
					end
				end
				
				BBUS_WRITE_END: if (CE_R) begin
					if (BBUS_RDY) begin
						BDTEN_N <= 1;
						
						BBUS_WORD[1] <= 0;
						if (BBUS_WORD[1] && BBUS_WORD[0]) begin
							BBUS_BA[1] <= 1;
							BBUS_ST <= BBUS_ADDR1;
						end else begin
							BCSS_N <= 1;
							BCS1_N <= 1;
							BCS2_N <= 1;
							CBUS_WAIT <= 0;
							BBUS_ST <= BBUS_IDLE;
						end
					end
				end
				
				BBUS_READ: if (CE_R) begin
					BADDT_N <= 0;
					BREQ_N <= 0;
					
					BBUS_ST <= BBUS_READ_WAIT;
//					DBG_BBUS_WAIT_CNT <= '0;
				end
					
				BBUS_READ_WAIT: if (CE_R) begin
					if (BBUS_RDY) begin
						BCSS_N <= 1;
						BCS1_N <= 1;
						BCS2_N <= 1;
						if (BBUS_WORD[1]) AB_BUF[31:16] <= BDI;
						else              AB_BUF[15: 0] <= BDI;
						
						BBUS_WORD[1] <= 0;
						if (BBUS_WORD[1] && BBUS_WORD[0]) begin
							BBUS_BA[1] <= 1;
							BBUS_ST <= BBUS_ADDR1;
						end else begin
							CBUS_WAIT <= 0;
							BBUS_ST <= BBUS_IDLE;
						end
					end
//					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
				end
				
				BBUS_DMA_RADDR1: if (CE_R) begin
					BDO <= {4'b1000,4'b0000,DMA_RA[8:1]};
					BBUS_ST <= BBUS_DMA_RADDR2;
					DBG_BBUS_WAIT_CNT <= '0;
				end
				
				BBUS_DMA_RADDR2: if (CE_R) begin
					BADDT_N <= 0;
					if (!DMA_BUF_SIZE) begin
						BREQ_N <= 0;
						BBUS_ST <= BBUS_DMA_READ;
					end
				end
					
				BBUS_DMA_READ: if (CE_F) begin
					if (BBUS_DMA_OUT) begin
						BBUS_DMA_OUT <= 0;
						if ((!DMA_DSP && !DMA_RTN_NEXT) || (DMA_DSP && DSP_DMA_LAST)) begin
							BBUS_ST <= BBUS_DMA_END;
						end
					end
				end else if (CE_R) begin
					if (BBUS_RDY) begin
						BREQ_N <= 0;
						if (BBUS_WORD[1]) begin
							AB_BUF[31:16] <= BDI;
							BBUS_WORD[1] <= 0;
						end else begin
							AB_BUF[15: 0] <= BDI;
							BBUS_WORD[1] <= 1;
							BBUS_DMA_OUT <= 1;
						end
					end
				end
				
				BBUS_DMA_WADDR1: if (CE_R) begin
					BDO <= {4'b1000,4'b0000,DMA_WA[8:1]};
					BBUS_ST <= BBUS_DMA_WADDR2;
					DBG_BBUS_WAIT_CNT <= '0;
				end
				
				BBUS_DMA_WADDR2: if (CE_R) begin
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
					BADDT_N <= 0;
					if (DMA_BUF_SIZE >= 3'd2) begin
						BBUS_DATA_ACK = 1;
						BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
						BDTEN_N <= 0;
						BREQ_N <= 0;
						BBUS_ST <= BBUS_DMA_WRITE;
						DBG_BBUS_WAIT_CNT <= '0;
					end
				end
					
				BBUS_DMA_WRITE: if (CE_R) begin
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
					BDTEN_N <= 1;
					if (BBUS_RDY && (DMA_BUF_SIZE >= 3'd2 || !DMA_WTN_NEXT)) begin
						BBUS_WRITE_DONE = 1;
						BBUS_DATA_ACK = 1;
						if ((!DMA_DSP && !DMA_WTN_NEXT) || (DMA_DSP && DMA_LAST && DMA_WA[1])) begin
							BBUS_ST <= BBUS_DMA_END;
						end else begin
							BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
							BDTEN_N <= 0;
							BREQ_N <= 0;
						end
						DBG_BBUS_WAIT_CNT <= '0;
					end
				end
					
				BBUS_DMA_END: if (CE_R) begin
					BCSS_N <= 1;
					BCS1_N <= 1;
					BCS2_N <= 1;
					if (!DMA_READ_B && !DMA_WRITE_B)
						BBUS_ST <= BBUS_IDLE;
				end
			endcase
		
			//CBUS 06000000-06FFFFFF
			CBUS_RD <= 0;
			CBUS_WR <= '0;
			CBUS_DATA_ACK = 0;
			CBUS_WRITE_DONE = 0;
			case (CBUS_ST)
				CBUS_IDLE: if (CE_R) begin
					if (DMA_READ_C || DMA_WRITE_C) begin
						CBUS_REQ <= 1;
						CBUS_ST <= CBUS_REQUEST;
					end
				end
				
				CBUS_REQUEST: if (CE_F) begin
					if (DMA_READ_C && !CBRLS) begin
//						CBUS_A <= DMA_IND ? DMA_IA : DMA_RA;
						CBUS_RD <= 1;
						CBUS_ST <= CBUS_READ;
						CBUS_CS <= 1;
					end
				end else if (CE_R) begin
					if (DMA_WRITE_C && DMA_BUF_SIZE && !CBRLS) begin
//						CBUS_A <= DMA_WA;
						CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2],DMA_BUF[DMA_BUF_RPOS+3]};
						CBUS_WR <= DMA_WBE;
						CBUS_ST <= CBUS_WRITE;
						CBUS_CS <= 1;
						CBUS_DATA_ACK = 1;
					end
				end
				
				CBUS_READ: if (CE_F) begin
					if (CBUS_READ_ACK && (!DMA_BUF_SIZE || DMA_IND)) begin
						CBUS_RD <= 1;
						if ((DMA_IND && DMA_IND_REG == 2'd2) || (!DMA_IND && ((DMA_DSP && DSP_DMA_LAST) || (!DMA_DSP && !DMA_RTN_NEXT)))) begin
							CBUS_RD <= 0;
							CBUS_CS <= 0;
							CBUS_REL <= 1;
							CBUS_ST <= CBUS_END;
						end
					end
				end
				
				CBUS_WRITE: if (CE_R) begin
					if (ECWAIT_N) begin
						if ((!DMA_DSP && !DMA_WTN_NEXT) || (DMA_DSP && DMA_LAST)) begin
							CBUS_CS <= 0;
							CBUS_REL <= 1;
							CBUS_WRITE_DONE = 1;
							CBUS_ST <= CBUS_END;
						end
						else if (DMA_BUF_SIZE) begin
//							CBUS_A <= DMA_WA;
							CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2],DMA_BUF[DMA_BUF_RPOS+3]};
							CBUS_WR <= DMA_WBE;
							CBUS_DATA_ACK = 1;
							CBUS_WRITE_DONE = 1;
						end
					end
				end
				
				CBUS_END: if (CE_R) begin
					if (!DMA_READ_C && !DMA_WRITE_C && CBRLS) begin
						CBUS_ST <= CBUS_IDLE;
					end
				end
			endcase
			
			//DMA
			BBUS_CBUS_DONE = 0;
			CBUS_BBUS_DONE = 0;
			BBUS_DSP_DONE = 0;
			CBUS_DSP_DONE = 0;
			case (DMA_ST)
				DMA_IDLE: if (CE_R) begin
					DSTA.D0MV <= 0;//?
					DSTA.D1MV <= 0;//?
					DSTA.D2MV <= 0;//?
					DSTA.DDMV <= 0;//?
					if (DMA_PEND[3]) begin
						DMA_PEND[3] <= 0;
						DMA_RA <= DSP_DR;
						DMA_WA <= DSP_DW;
						DMA_RADD <= DSP_ADD[0];
						DMA_WADD <= DSP_ADD;
							
						DMA_DSP <= 1;
						DMA_IND <= 0;
						DMA_CH <= 2'd3;
						DMA_ST <= DMA_SELECT;
						DSTA.DDWT <= 0;
						DSTA.DDMV <= 1;
					end else if (DMA_PEND[0]) begin
						DMA_PEND[0] <= 0;
						if (!DMD[0].MOD) begin
							DMA_RA <= DR[0];
							DMA_WA <= DW[0];
							DMA_RTN <= DC[0];
							DMA_WTN <= DC[0];
							DMA_RADD <= DAD[0].DRA;
							DMA_WADD <= DAD[0].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[0][26:2],2'b00};
							DMA_IND <= 1;
							DMA_IND_REG <= 2'd0;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd0;
						DMA_RUN[0] <= 1;
						DSTA.D0WT <= 0;
						DSTA.D0MV <= 1;
					end else if (DMA_PEND[1]) begin
						DMA_PEND[1] <= 0;
						if (!DMD[1].MOD) begin
							DMA_RA <= DR[1];
							DMA_WA <= DW[1];
							DMA_RTN <= DC[1];
							DMA_WTN <= DC[1];
							DMA_RADD <= DAD[1].DRA;
							DMA_WADD <= DAD[1].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[1][26:2],2'b00};
							DMA_IND <= 1;
							DMA_IND_REG <= 2'd0;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd1;
						DMA_RUN[1] <= 1;
						DSTA.D1WT <= 0;
						DSTA.D1MV <= 1;
					end else if (DMA_PEND[2]) begin
						DMA_PEND[2] <= 0;
						if (!DMD[2].MOD) begin
							DMA_RA <= DR[2];
							DMA_WA <= DW[2];
							DMA_RTN <= DC[2];
							DMA_WTN <= DC[2];
							DMA_RADD <= DAD[2].DRA;
							DMA_WADD <= DAD[2].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[2][26:2],2'b00};
							DMA_IND <= 1;
							DMA_IND_REG <= 2'd0;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd2;
						DMA_RUN[2] <= 1;
						DSTA.D2WT <= 0;
						DSTA.D2MV <= 1;
					end
					DBG_WAIT_CNT <= '0;
				end
				
				DMA_IND_START: if (CE_R) begin
					if (CBUS_ST == CBUS_IDLE) begin
						ADDR_ERR_DBG <= 1;//debug
//						if (DMA_IA[26:24] == 3'h6) begin	//C-BUS 06000000-06FFFFFF
							DMA_READ_C <= 1;
							DMA_ST <= DMA_IND_READ;
							ADDR_ERR_DBG <= 0;//debug
//						end;
					end
				end
				
				DMA_IND_READ: if (CE_F) begin
					if (CBUS_READ_ACK) begin
						case (DMA_IND_REG)
							2'd0: {DMA_RTN,DMA_WTN} <= {2{ECDI[19:0]}};
							2'd1: DMA_WA <= ECDI[26:0];
							2'd2: {DMA_EC,DMA_RA} <= {ECDI[31],ECDI[26:0]};
						endcase
						
						DMA_IND_REG <= DMA_IND_REG + 2'd1;
						if (DMA_IND_REG == 2'd2) begin
							DMA_IND_REG <= 2'd0;
							DMA_RADD <= DAD[DMA_CH].DRA;
							DMA_WADD <= DAD[DMA_CH].DWA;
							DMA_IND <= 0;
							DMA_READ_C <= 0;
							DMA_ST <= DMA_IND_END;
						end
					end
				end
				
				DMA_IND_END: if (CE_R) begin
					if (CBRLS) begin
						DMA_ST <= DMA_SELECT;
					end
				end
				
				DMA_SELECT: if (CE_R) begin
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
					if (DMA_RA[26:20] >= 7'h20 && DMA_RA[26:20] < 7'h59 && (!DMA_DSP || !DSP_DMA_WE)) begin
						DMA_READ_A <= 1;
						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
					end
					else if (DMA_RA[26:16] >= 11'h5A0 && DMA_RA[26:16] < 11'h5FE && (!DMA_DSP || !DSP_DMA_WE)) begin
						DMA_READ_B <= 1;
						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
					end
					else if (/*DMA_RA[26:24] == 3'h6 &&*/ (!DMA_DSP || !DSP_DMA_WE)) begin
						DMA_READ_C <= 1;
						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
					end
					
					if (DMA_WA[26:20] >= 7'h20 && DMA_WA[26:20] < 7'h59 && (!DMA_DSP || DSP_DMA_WE)) begin
						DMA_WRITE_A <= 1;
						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
					end
					else if (DMA_WA[26:16] >= 11'h5A0 && DMA_WA[26:16] < 11'h5FE && (!DMA_DSP || DSP_DMA_WE)) begin
						DMA_WRITE_B <= 1;
						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
					end
					else if (/*DMA_WA[26:24] == 3'h6 &&*/ (!DMA_DSP || DSP_DMA_WE)) begin
						DMA_WRITE_C <= 1;
						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
					end
					DMA_ST <= !DMA_DSP ? DMA_START : DMA_DSP_START;
				end
				
				DMA_START: if (CE_R) begin
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
					if (DMA_READ_A && DMA_WRITE_B) begin
						if (ABUS_DMA_START && BBUS_DMA_START) begin
							DSTA.DACSA <= 1;
							DSTA.DACSB <= 1;
							DBG_WAIT_CNT <= '0;
							DMA_ST <= DMA_ABUS_BBUS;
						end
					end else if (DMA_READ_A && DMA_WRITE_C) begin
						if (ABUS_DMA_START && !CBRLS) begin
							DSTA.DACSA <= 1;
							DBG_WAIT_CNT <= '0;
							DMA_ST <= DMA_ABUS_CBUS;
						end
//					end else if (DMA_READ_A && !DMA_WRITE_B && !DMA_WRITE_C) begin
//						if (ABUS_DMA_START) begin
//							DBG_WAIT_CNT <= '0;
//							DMA_ST <= DMA_UNUSED_READ;
//						end
					end else if (DMA_READ_B && DMA_WRITE_C) begin
						if (BBUS_DMA_START && !CBRLS) begin
							DSTA.DACSB <= 1;
							DBG_WAIT_CNT <= '0;
							DMA_ST <= DMA_BBUS_CBUS;
						end
//					end else if (DMA_READ_B && !DMA_WRITE_A && !DMA_WRITE_C) begin
//						if (BBUS_DMA_START) begin
//							DBG_WAIT_CNT <= '0;
//							DMA_ST <= DMA_UNUSED_READ;
//						end
					end else if (DMA_READ_C && DMA_WRITE_B) begin
						if (BBUS_DMA_START && !CBRLS) begin
							DSTA.DACSB <= 1;
							DBG_WAIT_CNT <= '0;
							DMA_ST <= DMA_CBUS_BBUS;
						end
					end 
					DMA_BUF_WPOS <= 3'd0;
					DMA_BUF_RPOS <= 3'd0;
					DMA_BUF_SIZE <= 3'd0;
				end
				
				DMA_ABUS_BBUS,
				DMA_ABUS_CBUS,
				DMA_CBUS_BBUS,
				DMA_BBUS_CBUS: if (CE_R) begin
					if (BBUS_WRITE_DONE || CBUS_WRITE_DONE) begin
						DMA_WTN <= DMA_WTN_NEXT;
						if (!DMA_WTN_NEXT) begin
							DMA_ST <= DMA_STOP;
						end
					end
					if (BBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd2;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd2;
					end
					if (CBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd4;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd4;
					end
				end else if (CE_F) begin
					if ((ABUS_READ_ACK || BBUS_READ_ACK || CBUS_READ_ACK) && DMA_BUF_SIZE < 3'd2) begin
						{DMA_BUF[DMA_BUF_WPOS-{1'b0,DMA_RA[1:0]}+3'd0],
						 DMA_BUF[DMA_BUF_WPOS-{1'b0,DMA_RA[1:0]}+3'd1],
						 DMA_BUF[DMA_BUF_WPOS-{1'b0,DMA_RA[1:0]}+3'd2],
						 DMA_BUF[DMA_BUF_WPOS-{1'b0,DMA_RA[1:0]}+3'd3]} <= CBUS_READ_ACK ? ECDI : AB_BUF;
						case (DMA_RA[1:0])
							2'b00: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd4; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd4; end
							2'b01: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd3; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd3; end
							2'b10: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd2; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd2; end
							2'b11: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd1; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd1; end
						endcase
							
						BBUS_CBUS_DONE = BBUS_READ_ACK;
						CBUS_BBUS_DONE = CBUS_READ_ACK;
						DMA_WBE <= 4'b1111;
						if (DMA_RA[1:0]) begin
							case (DMA_RA[1:0])
								2'b00: ;
								2'b01: begin DMA_WBE <= 4'b0111; end
								2'b10: begin DMA_WBE <= 4'b0011; end
								2'b11: begin DMA_WBE <= 4'b0001; end
							endcase
						end else if (!DMA_RTN[19:2]) begin
							case (DMA_RTN[1:0])
								2'b00: DMA_WBE <= 4'b1111;
								2'b01: DMA_WBE <= 4'b1000;
								2'b10: DMA_WBE <= 4'b1100;
								2'b11: DMA_WBE <= 4'b1110;
							endcase
						end
						DMA_RTN <= DMA_RTN_NEXT;
						
						DMA_TN_ERR <= DMA_RTN_NEXT[0];//debug
					end
				end
				
				//DSP
				DMA_DSP_START: if (CE_R) begin
					if (DMA_READ_A && ABUS_DMA_START && !ABUS_SEL) begin
						DSTA.DACSA <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_ABUS_DSP;
					end else if (DMA_READ_B && !DSP_DMA_WE && BBUS_DMA_START) begin
						DSTA.DACSB <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_BBUS_DSP;
					end else if (DMA_WRITE_B && DSP_DMA_WE && BBUS_DMA_START) begin
						DSTA.DACSB <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_DSP_BBUS;
					end else if (DMA_READ_C && !DSP_DMA_WE && !CBRLS) begin
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_CBUS_DSP;
					end else if (DMA_WRITE_C && DSP_DMA_WE && !CBRLS) begin
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_DSP_CBUS;
					end
					DMA_BUF_WPOS <= 3'd0;
					DMA_BUF_RPOS <= 3'd0;
					DMA_BUF_SIZE <= 3'd0;

					DBG_WAIT_CNT <= '0;
				end
				
				DMA_ABUS_DSP,
				DMA_BBUS_DSP,
				DMA_CBUS_DSP: if (CE_F) begin
					if (BBUS_READ_ACK || CBUS_READ_ACK) begin
						{DMA_BUF[0],DMA_BUF[1],DMA_BUF[2],DMA_BUF[3]} <= CBUS_READ_ACK ? ECDI : AB_BUF;
						DMA_WBE <= 4'b1111;
						
						BBUS_DSP_DONE = BBUS_READ_ACK;
						CBUS_DSP_DONE = CBUS_READ_ACK;
						DSP_DMA_ACK <= 1;
						if (DSP_DMA_LAST) begin
							DSP_DMA_END <= 1;
							DMA_ST <= DMA_STOP;
						end
					end
				end
				
				DMA_DSP_BBUS,
				DMA_DSP_CBUS: if (CE_F) begin
					if (DSP_DMA_REQ && !DMA_BUF_SIZE) begin
						{DMA_BUF[DMA_BUF_WPOS+3'd0],
						 DMA_BUF[DMA_BUF_WPOS+3'd1],
						 DMA_BUF[DMA_BUF_WPOS+3'd2],
						 DMA_BUF[DMA_BUF_WPOS+3'd3]} <= DSP_DMA_DO;
						DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd4;
						DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd4;
						DMA_WBE <= 4'b1111;
						DSP_DMA_ACK <= 1;
						if (DSP_DMA_LAST) begin
							DSP_DMA_END <= 1;
						end
					end
				end else if (CE_R) begin
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
					if (BBUS_WRITE_DONE) begin
						if (DMA_LAST && DMA_WA[1]) begin
							DMA_LAST <= 0;
							DMA_ST <= DMA_STOP;
						end
						DBG_WAIT_CNT <= '0;
					end
					if (BBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd2;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd2;
					end
					
					if (CBUS_WRITE_DONE) begin
						if (DMA_LAST) begin
							DMA_LAST <= 0;
							DMA_ST <= DMA_STOP;
						end
						DBG_WAIT_CNT <= '0;
					end
					if (CBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd4;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd4;
					end
					
					if (DSP_DMA_ACK && DSP_DMA_LAST) begin
						DMA_LAST <= 1;
					end
				end
				
				DMA_STOP: if (CE_R) begin
					if ((DMA_WRITE_B && BBUS_ST == BBUS_DMA_END) || 
					    (DMA_WRITE_C && CBUS_ST == CBUS_END && CBRLS) || 
						 (DMA_READ_A && DMA_DSP && ABUS_ST == ABUS_DMA_END) ||
						 (DMA_READ_B && DMA_DSP && BBUS_ST == BBUS_DMA_END) ||
						 (DMA_READ_C && DMA_DSP && CBUS_ST == CBUS_END && CBRLS)) begin
						DMA_READ_A <= 0;
						DMA_READ_B <= 0;
						DMA_READ_C <= 0;
						DMA_WRITE_A <= 0;
						DMA_WRITE_B <= 0;
						DMA_WRITE_C <= 0;
						DMA_READ_DSP <= 0;
						DMA_WRITE_DSP <= 0;
						DSTA.DACSA <= 0;
						DSTA.DACSB <= 0;
						DSTA.DACSD <= 0;
						if (DMA_DSP) begin
							DMA_DSP <= 0;
							DMA_END <= 1;
							DMA_ST <= DMA_IDLE;
						end else if (!DMD[DMA_CH].MOD || DMA_EC) begin
							DMA_END <= 1;
							DMA_RUN[DMA_CH] <= 0;
							DMA_INT[DMA_CH] <= 1;
							DMA_ST <= DMA_IDLE;
						end else begin
							DMA_IND <= 1;
							DMA_ST <= DMA_IND_START;
						end 
					end
				end
			endcase
			
			if (CE_F) begin
				if (CBUS_READ_ACK && DMA_IND)
					DMA_IA <= DMA_IA + 27'd4;
				else if ((BBUS_CBUS_DONE || CBUS_BBUS_DONE) && DMA_RADD) 
					DMA_RA <= DMA_RA + DMA_RTN_DEC;
				else if ((BBUS_DSP_DONE || CBUS_DSP_DONE) && DMA_WADD) 
					DMA_RA <= DMA_RA + (27'd1 << DMA_WADD);
					
				if (ABUS_READ_ACK) begin
					if (DMA_DSP && DMA_WADD)
						DMA_RA <= DMA_RA + 27'd4;
					else if (!DMA_DSP && DMA_RADD) 
						DMA_RA <= DMA_RA + 27'd4;
				end
			end
			
			if (CE_R) begin
				if ((BBUS_WRITE_DONE || CBUS_WRITE_DONE) && DMA_WADD) begin
					DMA_WA <= DMA_WA + (27'd1 << DMA_WADD);
				end
			end
			
			AFC <= '1;
			ATIM0_N <= 1;
			ATIM1_N <= 1;
			ATIM2_N <= 1;
			
			if (CE_R) begin
				if (REG_WR && CA[7:2] == 8'h60>>2) begin				//DSTP
					if (CDI[0]) begin
						DMA_END <= 0;
						DMA_RUN[0] <= 0;
						DMA_RUN[1] <= 0;
						DMA_RUN[2] <= 0;
						DMA_INT <= '0;
						DMA_ST <= DMA_IDLE;
					end
				end else if (REG_WR && CA[7:2] == 8'hA4>>2) begin	//IST
					if (!CDI[9] && DMA_INT[2])  DMA_INT[2] <= 0;
					if (!CDI[10] && DMA_INT[1]) DMA_INT[1] <= 0;
					if (!CDI[11] && DMA_INT[0]) DMA_INT[0] <= 0;
				end
				
				if (IVECF_RISE) begin	
					case (IVECF_LVL)
						4'h6: begin 
							if (DMA_INT[1]) DMA_INT[1] <= 0; 
							if (DMA_INT[2]) DMA_INT[2] <= 0; 
						end
						4'h5: begin 
							if (DMA_INT[0]) DMA_INT[0] <= 0; 
						end
						default:;
					endcase
				end
			end
		end
	end
	assign DBG_DMA_RADDR_ERR = |DMA_RA[7:0];
	assign DBG_DMA_WADDR_ERR = |DMA_WA[7:0];

	
	bit CBRLS;
	bit CBREQ;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			CBREQ <= 0;
			CBRLS <= 1;
		end
		else if (!RES_N) begin
			CBREQ <= 0;
			CBRLS <= 1;
		end
		else begin
			if (!RES_N) begin
				CBREQ <= 0;
				CBRLS <= 1;
			end
			else if (CE_F) begin
				if (CBUS_REQ && !CBREQ && CBRLS) begin
					CBREQ <= 1;
				end
				else if (CBREQ && !CBACK_N && CBRLS) begin
					CBRLS <= 0;
				end
				else if (CBREQ && CBUS_REL && !CBRLS) begin
					CBREQ <= 0;
				end
				else if (!CBREQ && !CBRLS) begin
					CBRLS <= 1;
				end
			end
		end
	end
	assign CBREQ_N = ~CBREQ;
	
				
	assign ECA = CBUS_ST == CBUS_WRITE ? DMA_WA[24:0] : (DMA_IND ? DMA_IA[24:0] : DMA_RA[24:0]);//CBUS_A[24:0];
	assign ECDO = CBUS_D;
	assign ECDQM_N = ~CBUS_WR;
	assign ECRD_WR_N = ~|CBUS_WR;
	assign ECRD_N = ~CBUS_RD;
	assign ECCS3_N = ~CBUS_CS;
	
	//DSP
	bit DSP_CE;
	always @(posedge CLK) if (CE_R) DSP_CE <= ~DSP_CE;
	
	wire DSP_SEL = ~CCS2_N & CA[24:0] >= 25'h1FE0080 & CA[24:0] <= 25'h1FE008F;	//25FE0080-25FE008F
	
	bit [31:0] DSP_DSO;
	bit        DSP_RA0_SET;
	bit        DSP_WA0_SET;
	bit        DSP_DMA_SET;
	bit [31:0] DSP_DO;
	SCU_DSP dsp(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(DSP_CE & CE_R),
		
		.CE_R(CE_R),
		.CE_F(CE_F),
		.A(CA[3:2]),
		.DI(CDI),
		.DO(DSP_DO),
		.WE(DSP_SEL & CWE),
		.RE(DSP_SEL & CRE),
		
		.DSO(DSP_DSO),
		.RA0W(DSP_RA0_SET),
		.WA0W(DSP_WA0_SET),
		.DMAW(DSP_DMA_SET),
		
		.DMA_DI(DSP_DMA_DI),
		.DMA_DO(DSP_DMA_DO),
		.DMA_WE(DSP_DMA_WE),
		.DMA_REQ(DSP_DMA_REQ),
		.DMA_ACK(DSP_DMA_ACK),
		.DMA_RUN(DSP_DMA_RUN),
		.DMA_LAST(DSP_DMA_LAST),
		.DMA_END(DSP_DMA_END),
		
		.IRQ(DSP_IRQ)
	);
	assign DSP_DMA_DI = {DMA_BUF[0],DMA_BUF[1],DMA_BUF[2],DMA_BUF[3]};

	
	//Timers
	bit [9:0] TM0;
	bit [8+2:0] TM1;
	always @(posedge CLK or negedge RST_N) begin
		bit TM0_OCCUR;
		
		if (!RST_N) begin
			TM0 <= '0;
			TM1 <= '0;
			TM0_INT <= 0;
			TM1_INT <= 0;
			TM0_OCCUR <= 0;
		end
		else if (!RES_N) begin
			TM0 <= '0;
			TM1 <= '0;
			TM0_INT <= 0;
			TM1_INT <= 0;
		end else if (CE_R) begin				
			if (T1MD.ENB) begin
				TM1 <= TM1 - 11'd1;
				if (!TM1 && TM0_OCCUR)  begin
					TM1_INT <= 1;
					TM0_OCCUR <= 0;
				end
			end
			
			if (HBL_IN) begin
				TM0 <= TM0 + 10'd1;
				TM0_OCCUR <= ~T1MD.MD;
				if (TM0 == T0C) begin
					TM0_INT <= 1;
					TM0_OCCUR <= 1;
				end
				TM1 <= {T1S,2'b11};
			end
			
			if (VBL_OUT) begin
				TM0 <= '0;
			end
			
			if (REG_WR && CA[7:2] == 8'hA4>>2) begin
				if (!CDI[3] && TM0_INT) TM0_INT <= 0;
				if (!CDI[4] && TM1_INT) TM1_INT <= 0;
			end
	
			if (IVECF_RISE) begin
				case (IVECF_LVL)
					4'hC: if (TM0_INT) TM0_INT <= 0;
					4'hB: if (TM1_INT) TM1_INT <= 0;
					default:;
				endcase
			end
		end
	end
				
	//Interrupts
	always @(posedge CLK or negedge RST_N) begin
		bit DSP_IRQ_OLD;
		bit MIREQ_N_OLD;
		if (!RST_N) begin
			VBIN_INT <= 0;
			VBOUT_INT <= 0;
			HBIN_INT <= 0;
			DSP_INT <= 0;
			SCSP_INT <= 0;
			EXT_INT <= '0;
			PAD_INT <= 0;
			DSP_IRQ_OLD <= 0;
		end else if (!RES_N) begin
			VBIN_INT <= 0;
			VBOUT_INT <= 0;
			HBIN_INT <= 0;
			DSP_INT <= 0;
			SCSP_INT <= 0;
		end else if (CE_R) begin
			if (VBL_IN /*&& !VBIN_INT*/) VBIN_INT <= 1;
			if (VBL_OUT /*&& !VBOUT_INT*/) VBOUT_INT <= 1;
			if (HBL_IN /*&& !HBIN_INT*/) HBIN_INT <= 1;
			if (SCSP_REQ /*&& !SCSP_INT*/) SCSP_INT <= 1;
			if (VDP1_REQ /*&& !VDP1_INT*/) VDP1_INT <= 1;
			
			DSP_IRQ_OLD <= DSP_IRQ;
			if (DSP_IRQ && !DSP_IRQ_OLD /*&& !DSP_INT*/) DSP_INT <= 1;
			
			MIREQ_N_OLD <= MIREQ_N;
			if (!MIREQ_N && MIREQ_N_OLD /*&& !SM_INT*/) SM_INT <= 1;
			
			if (REG_WR && CA[7:2] == 8'hA4>>2) begin
				if (!CDI[0] && VBIN_INT) VBIN_INT <= 0;
				if (!CDI[1] && VBOUT_INT) VBOUT_INT <= 0;
				if (!CDI[2] && HBIN_INT) HBIN_INT <= 0;
				if (!CDI[5] && DSP_INT) DSP_INT <= 0;
				if (!CDI[6] && SCSP_INT) SCSP_INT <= 0;
				if (!CDI[7] && SM_INT) SM_INT <= 0;
				if (!CDI[13] && VDP1_INT) VDP1_INT <= 0;
			end 

			if (IVECF_RISE) begin
				case (IVECF_LVL)
					4'hF: if (VBIN_INT) VBIN_INT <= 0;
					4'hE: if (VBOUT_INT) VBOUT_INT <= 0;
					4'hD: if (HBIN_INT) HBIN_INT <= 0;
					4'hA: if (DSP_INT) DSP_INT <= 0;
					4'h9: if (SCSP_INT) SCSP_INT <= 0;
					4'h8: if (SM_INT) SM_INT <= 0;//??
					4'h2: if (VDP1_INT) VDP1_INT <= 0;
					default:;
				endcase
			end
			EXT_INT <= '0;
			PAD_INT <= 0;
		end
	end
	
	wire [31:0] INT_STAT = {EXT_INT,2'b00,VDP1_INT,DMAIL_INT,DMA_INT[0],DMA_INT[1],DMA_INT[2],PAD_INT,SM_INT,SCSP_INT,DSP_INT,TM1_INT,TM0_INT,HBIN_INT,VBOUT_INT,VBIN_INT};
	
	bit [3:0] INT_LVL;
	always_comb begin
				if      (VBIN_INT      && !IMS.MS0)  begin INT_LVL <= 4'hF; end	//F
				else if (VBOUT_INT     && !IMS.MS1)  begin INT_LVL <= 4'hE; end	//E
				else if (HBIN_INT      && !IMS.MS2)  begin INT_LVL <= 4'hD; end	//D
				else if (TM0_INT       && !IMS.MS3)  begin INT_LVL <= 4'hC; end	//C
				else if (TM1_INT       && !IMS.MS4)  begin INT_LVL <= 4'hB; end	//B
				else if (DSP_INT       && !IMS.MS5)  begin INT_LVL <= 4'hA; end	//A
				else if (SCSP_INT      && !IMS.MS6)  begin INT_LVL <= 4'h9; end	//9
				else if (SM_INT        && !IMS.MS7)  begin INT_LVL <= 4'h8; end	//8
				else if (PAD_INT       && !IMS.MS8)  begin INT_LVL <= 4'h8; end	//8
				else if ((EXT_INT[0] ||
							 EXT_INT[1] ||
							 EXT_INT[2] ||
							 EXT_INT[3])  && !IMS.MS15) begin INT_LVL <= 4'h7; end	//7
				else if (DMA_INT[2]    && !IMS.MS9)  begin INT_LVL <= 4'h6; end	//6
				else if (DMA_INT[1]    && !IMS.MS10) begin INT_LVL <= 4'h6; end	//6
				else if (DMA_INT[0]    && !IMS.MS11) begin INT_LVL <= 4'h5; end	//5
				else if ((EXT_INT[4] ||
							 EXT_INT[5] ||
							 EXT_INT[6] ||
							 EXT_INT[7])  && !IMS.MS15) begin INT_LVL <= 4'h4; end	//4
				else if (DMAIL_INT     && !IMS.MS12) begin INT_LVL <= 4'h3; end	//3
				else if (VDP1_INT      && !IMS.MS13) begin INT_LVL <= 4'h2; end	//2
				else if ((EXT_INT[8]  ||
							 EXT_INT[9]  ||
							 EXT_INT[10] ||
							 EXT_INT[11] ||
							 EXT_INT[12] ||
							 EXT_INT[13] ||
							 EXT_INT[14] ||
							 EXT_INT[15]) && !IMS.MS15) begin INT_LVL <= 4'h1; end	//1
				else                                       INT_LVL <= 4'h0;			//0
	end
	assign CIRL_N = ~INT_LVL;
	
	bit [7:0] IVEC;
	always_comb begin
		case (CA[3:0])
			4'hF: IVEC = 8'h40;
			4'hE: IVEC = 8'h41;
			4'hD: IVEC = 8'h42;
			4'hC: IVEC = 8'h43;
			4'hB: IVEC = 8'h44;
			4'hA: IVEC = 8'h45;
			4'h9: IVEC = 8'h46;
			4'h8: IVEC = /*SM_INT      ?*/ 8'h47 /*: 8'h48*/;
			4'h7: IVEC = EXT_INT[0]  ? 8'h50 : 
			             EXT_INT[1]  ? 8'h51 : 
							 EXT_INT[2]  ? 8'h52 : 8'h53;
			4'h6: IVEC = DMA_INT[1]  ? 8'h4A : 8'h49;
			4'h5: IVEC = 8'h4B;
			4'h4: IVEC = EXT_INT[4]  ? 8'h54 : 
			             EXT_INT[5]  ? 8'h54 : 
							 EXT_INT[6]  ? 8'h56 : 8'h57;
			4'h3: IVEC = 8'h4C;
			4'h2: IVEC = 8'h4D;
			4'h1: IVEC = EXT_INT[8]  ? 8'h58 : 
			             EXT_INT[9]  ? 8'h59 : 
							 EXT_INT[10] ? 8'h5A : 
							 EXT_INT[11] ? 8'h5B :
							 EXT_INT[12] ? 8'h5C :
							 EXT_INT[13] ? 8'h5D :
							 EXT_INT[14] ? 8'h5E : 8'h5F;
			4'h0: IVEC = 8'h00;
		endcase
	end
	
	bit [7:0] IVEC_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			IVEC_DO <= '0;
		end
		else if (!RES_N) begin
			IVEC_DO <= '0;
		end 
		else begin
			if (!CIVECF_N && !CRD_N && CE_R) begin
				IVEC_DO <= IVEC;
			end
		end
	end
	
	
	//Registers
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		
		if (!RST_N) begin
			DR <= '{'0,'0,'0};
			DW <= '{'0,'0,'0};
			DC <= '{'0,'0,'0};
			DAD <= '{'0,'0,'0};
			DEN <= '{'0,'0,'0};
			DMD <= '{'0,'0,'0};
//			DSTP <= DSTP_INIT;
			T0C <= RSEL_INIT;
			T1S <= RSEL_INIT;
			T1MD <= T1MD_INIT;
			IMS <= IMS_INIT;
			RSEL <= RSEL_INIT;
			
			REG_DO <= '0;
		end
		else if (!RES_N) begin
			DR <= '{'0,'0,'0};
			DW <= '{'0,'0,'0};
			DC <= '{'0,'0,'0};
			DAD <= '{'0,'0,'0};
			DEN <= '{'0,'0,'0};
			DMD <= '{'0,'0,'0};
//			DSTP <= DSTP_INIT;
			T0C <= RSEL_INIT;
			T1S <= RSEL_INIT;
			T1MD <= T1MD_INIT;
			IMS <= IMS_INIT;
			RSEL <= RSEL_INIT;
		end else if (CE_R) begin
			DEN[0].GO <= 0;
			DEN[1].GO <= 0;
			DEN[2].GO <= 0;
			if (REG_WR) begin
				case ({CA[7:2],2'b00})
					8'h00: begin
						if (!CDQM_N[0]) DR[0][ 7: 0] <= CDI[ 7: 0] & DxR_WMASK[ 7: 0];
						if (!CDQM_N[1]) DR[0][15: 8] <= CDI[15: 8] & DxR_WMASK[15: 8];
						if (!CDQM_N[2]) DR[0][23:16] <= CDI[23:16] & DxR_WMASK[23:16];
						if (!CDQM_N[3]) DR[0][26:24] <= CDI[26:24] & DxR_WMASK[26:24];
					end
					8'h04: begin
						if (!CDQM_N[0]) DW[0][ 7: 0] <= CDI[ 7: 0] & DxW_WMASK[ 7: 0];
						if (!CDQM_N[1]) DW[0][15: 8] <= CDI[15: 8] & DxW_WMASK[15: 8];
						if (!CDQM_N[2]) DW[0][23:16] <= CDI[23:16] & DxW_WMASK[23:16];
						if (!CDQM_N[3]) DW[0][26:24] <= CDI[26:24] & DxW_WMASK[26:24];
					end
					8'h08: begin
						if (!CDQM_N[0]) DC[0][ 7: 0] <= CDI[ 7: 0] & D0C_WMASK[ 7: 0];
						if (!CDQM_N[1]) DC[0][15: 8] <= CDI[15: 8] & D0C_WMASK[15: 8];
						if (!CDQM_N[2]) DC[0][19:16] <= CDI[19:16] & D0C_WMASK[19:16];
					end
					8'h0C: begin
						if (!CDQM_N[0] && !DMA_RUN[0]) DAD[0][ 7: 0] <= CDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[0]) DAD[0][15: 8] <= CDI[15: 8] & DxAD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[0]) DAD[0][23:16] <= CDI[23:16] & DxAD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[0]) DAD[0][31:24] <= CDI[31:24] & DxAD_WMASK[31:24];
					end
					8'h10: begin
						if (!CDQM_N[0]) DEN[0][ 7: 0] <= CDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						if (!CDQM_N[1]) DEN[0][15: 8] <= CDI[15: 8] & DxEN_WMASK[15: 8];
						if (!CDQM_N[2]) DEN[0][23:16] <= CDI[23:16] & DxEN_WMASK[23:16];
						if (!CDQM_N[3]) DEN[0][31:24] <= CDI[31:24] & DxEN_WMASK[31:24];
					end
					8'h14: begin
						if (!CDQM_N[0] && !DMA_RUN[0]) DMD[0][ 7: 0] <= CDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[0]) DMD[0][15: 8] <= CDI[15: 8] & DxMD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[0]) DMD[0][23:16] <= CDI[23:16] & DxMD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[0]) DMD[0][31:24] <= CDI[31:24] & DxMD_WMASK[31:24];
					end
					8'h20: begin
						if (!CDQM_N[0]) DR[1][ 7: 0] <= CDI[ 7: 0] & DxR_WMASK[ 7: 0];
						if (!CDQM_N[1]) DR[1][15: 8] <= CDI[15: 8] & DxR_WMASK[15: 8];
						if (!CDQM_N[2]) DR[1][23:16] <= CDI[23:16] & DxR_WMASK[23:16];
						if (!CDQM_N[3]) DR[1][26:24] <= CDI[26:24] & DxR_WMASK[26:24];
					end
					8'h24: begin
						if (!CDQM_N[0]) DW[1][ 7: 0] <= CDI[ 7: 0] & DxW_WMASK[ 7: 0];
						if (!CDQM_N[1]) DW[1][15: 8] <= CDI[15: 8] & DxW_WMASK[15: 8];
						if (!CDQM_N[2]) DW[1][23:16] <= CDI[23:16] & DxW_WMASK[23:16];
						if (!CDQM_N[3]) DW[1][26:24] <= CDI[26:24] & DxW_WMASK[26:24];
					end
					8'h28: begin
						if (!CDQM_N[0]) DC[1][ 7: 0] <= CDI[ 7: 0] & D0C_WMASK[ 7: 0];
						if (!CDQM_N[1]) DC[1][11: 8] <= CDI[11: 8] & D0C_WMASK[11: 8];
					end
					8'h2C: begin
						if (!CDQM_N[0] && !DMA_RUN[1]) DAD[1][ 7: 0] <= CDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[1]) DAD[1][15: 8] <= CDI[15: 8] & DxAD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[1]) DAD[1][23:16] <= CDI[23:16] & DxAD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[1]) DAD[1][31:24] <= CDI[31:24] & DxAD_WMASK[31:24];
					end
					8'h30: begin
						if (!CDQM_N[0]) DEN[1][ 7: 0] <= CDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						if (!CDQM_N[1]) DEN[1][15: 8] <= CDI[15: 8] & DxEN_WMASK[15: 8];
						if (!CDQM_N[2]) DEN[1][23:16] <= CDI[23:16] & DxEN_WMASK[23:16];
						if (!CDQM_N[3]) DEN[1][31:24] <= CDI[31:24] & DxEN_WMASK[31:24];
					end
					8'h34: begin
						if (!CDQM_N[0] && !DMA_RUN[1]) DMD[1][ 7: 0] <= CDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[1]) DMD[1][15: 8] <= CDI[15: 8] & DxMD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[1]) DMD[1][23:16] <= CDI[23:16] & DxMD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[1]) DMD[1][31:24] <= CDI[31:24] & DxMD_WMASK[31:24];
					end
					8'h40: begin
						if (!CDQM_N[0]) DR[2][ 7: 0] <= CDI[ 7: 0] & DxR_WMASK[ 7: 0];
						if (!CDQM_N[1]) DR[2][15: 8] <= CDI[15: 8] & DxR_WMASK[15: 8];
						if (!CDQM_N[2]) DR[2][23:16] <= CDI[23:16] & DxR_WMASK[23:16];
						if (!CDQM_N[3]) DR[2][26:24] <= CDI[26:24] & DxR_WMASK[26:24];
					end
					8'h44: begin
						if (!CDQM_N[0]) DW[2][ 7: 0] <= CDI[ 7: 0] & DxW_WMASK[ 7: 0];
						if (!CDQM_N[1]) DW[2][15: 8] <= CDI[15: 8] & DxW_WMASK[15: 8];
						if (!CDQM_N[2]) DW[2][23:16] <= CDI[23:16] & DxW_WMASK[23:16];
						if (!CDQM_N[3]) DW[2][26:24] <= CDI[26:24] & DxW_WMASK[26:24];
					end
					8'h48: begin
						if (!CDQM_N[0]) DC[2][ 7: 0] <= CDI[ 7: 0] & D0C_WMASK[ 7: 0];
						if (!CDQM_N[1]) DC[2][11: 8] <= CDI[11: 8] & D0C_WMASK[11: 8];
					end
					8'h4C: begin
						if (!CDQM_N[0] && !DMA_RUN[2]) DAD[2][ 7: 0] <= CDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[2]) DAD[2][15: 8] <= CDI[15: 8] & DxAD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[2]) DAD[2][23:16] <= CDI[23:16] & DxAD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[2]) DAD[2][31:24] <= CDI[31:24] & DxAD_WMASK[31:24];
					end
					8'h50: begin
						if (!CDQM_N[0]) DEN[2][ 7: 0] <= CDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						if (!CDQM_N[1]) DEN[2][15: 8] <= CDI[15: 8] & DxEN_WMASK[15: 8];
						if (!CDQM_N[2]) DEN[2][23:16] <= CDI[23:16] & DxEN_WMASK[23:16];
						if (!CDQM_N[3]) DEN[2][31:24] <= CDI[31:24] & DxEN_WMASK[31:24];
					end
					8'h54: begin
						if (!CDQM_N[0] && !DMA_RUN[2]) DMD[2][ 7: 0] <= CDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						if (!CDQM_N[1] && !DMA_RUN[2]) DMD[2][15: 8] <= CDI[15: 8] & DxMD_WMASK[15: 8];
						if (!CDQM_N[2] && !DMA_RUN[2]) DMD[2][23:16] <= CDI[23:16] & DxMD_WMASK[23:16];
						if (!CDQM_N[3] && !DMA_RUN[2]) DMD[2][31:24] <= CDI[31:24] & DxMD_WMASK[31:24];
					end
					
//					8'h60: begin
//						if (!CDQM_N[0]) DSTP[ 7: 0] <= CDI[ 7: 0] & DSTP_WMASK[ 7: 0];
//						if (!CDQM_N[1]) DSTP[15: 8] <= CDI[15: 8] & DSTP_WMASK[15: 8];
//						if (!CDQM_N[2]) DSTP[23:16] <= CDI[23:16] & DSTP_WMASK[23:16];
//						if (!CDQM_N[3]) DSTP[31:24] <= CDI[31:24] & DSTP_WMASK[31:24];
//					end
					
					8'h90: begin
						if (!CDQM_N[0]) T0C[ 7: 0] <= CDI[ 7: 0] & T0C_WMASK[ 7: 0];
						if (!CDQM_N[1]) T0C[ 9: 8] <= CDI[ 9: 8] & T0C_WMASK[ 9: 8];
					end
					8'h94: begin
						if (!CDQM_N[0]) T1S[ 7: 0] <= CDI[ 7: 0] & T1S_WMASK[ 7: 0];
						if (!CDQM_N[1]) T1S[ 8: 8] <= CDI[ 8: 8] & T1S_WMASK[ 8: 8];
					end
					8'h98: begin
						if (!CDQM_N[0]) T1MD[ 7: 0] <= CDI[ 7: 0] & T1MD_WMASK[ 7: 0];
						if (!CDQM_N[1]) T1MD[15: 8] <= CDI[15: 8] & T1MD_WMASK[15: 8];
						if (!CDQM_N[2]) T1MD[23:16] <= CDI[23:16] & T1MD_WMASK[23:16];
						if (!CDQM_N[3]) T1MD[31:24] <= CDI[31:24] & T1MD_WMASK[31:24];
					end
					8'hA0: begin
						if (!CDQM_N[0]) IMS[ 7: 0] <= CDI[ 7: 0] & IMS_WMASK[ 7: 0];
						if (!CDQM_N[1]) IMS[15: 8] <= CDI[15: 8] & IMS_WMASK[15: 8];
						if (!CDQM_N[2]) IMS[23:16] <= CDI[23:16] & IMS_WMASK[23:16];
						if (!CDQM_N[3]) IMS[31:24] <= CDI[31:24] & IMS_WMASK[31:24];
					end
					
					8'hB0: begin
						if (!CDQM_N[0]) ASR0[ 7: 0] <= CDI[ 7: 0] & ASR0_WMASK[ 7: 0];
						if (!CDQM_N[1]) ASR0[15: 8] <= CDI[15: 8] & ASR0_WMASK[15: 8];
						if (!CDQM_N[2]) ASR0[23:16] <= CDI[23:16] & ASR0_WMASK[23:16];
						if (!CDQM_N[3]) ASR0[31:24] <= CDI[31:24] & ASR0_WMASK[31:24];
					end
					8'hB4: begin
						if (!CDQM_N[0]) ASR1[ 7: 0] <= CDI[ 7: 0] & ASR1_WMASK[ 7: 0];
						if (!CDQM_N[1]) ASR1[15: 8] <= CDI[15: 8] & ASR1_WMASK[15: 8];
						if (!CDQM_N[2]) ASR1[23:16] <= CDI[23:16] & ASR1_WMASK[23:16];
						if (!CDQM_N[3]) ASR1[31:24] <= CDI[31:24] & ASR1_WMASK[31:24];
					end
					8'hC4: begin
						if (!CDQM_N[0]) RSEL <= CDI[0] & RSEL_WMASK[0];
					end
					default:;
				endcase
			end
			
			if (DSP_RA0_SET) begin
				DSP_DR <= {DSP_DSO[24:0],2'b00};
			end
			if (DSP_WA0_SET) begin
				DSP_DW <= {DSP_DSO[24:0],2'b00};
			end
			if (DSP_DMA_SET) begin
				DSP_ADD <= DSP_DSO[17:15];
				DSP_HOLD <= DSP_DSO[14];
			end
			
			if (DMA_END && DMA_CH != 3) begin
				if (DMD[DMA_CH].RUP) DR[DMA_CH] <= DMA_RA;
				if (DMD[DMA_CH].WUP) DW[DMA_CH] <= DMA_WA;
			end
			
			if (DMA_END && DMA_CH == 3) begin
				if (!DSP_HOLD) DSP_DR <= DMA_RA;
				if (!DSP_HOLD) DSP_DW <= DMA_WA;
			end
		end else if (CE_F) begin
			if (REG_RD) begin
				case ({CA[7:2],2'b00})
					8'h00: REG_DO <= {5'h00,DR[0]} & DxR_RMASK;
					8'h04: REG_DO <= {5'h00,DW[0]} & DxW_RMASK;
					8'h08: REG_DO <= {12'h000,DC[0]} & D0C_RMASK;
					8'h20: REG_DO <= {5'h00,DR[1]} & DxR_RMASK;
					8'h24: REG_DO <= {5'h00,DW[1]} & DxW_RMASK;
					8'h28: REG_DO <= {12'h000,DC[1]} & D12C_RMASK;
					8'h40: REG_DO <= {5'h00,DR[2]} & DxR_RMASK;
					8'h44: REG_DO <= {5'h00,DW[2]} & DxW_RMASK;
					8'h48: REG_DO <= {12'h000,DC[2]} & D12C_RMASK;
					8'h7C: REG_DO <= DSTA & DSTA_RMASK;
					
					8'hA4: REG_DO <= INT_STAT & IST_RMASK;
					
					8'hB0: REG_DO <= ASR0 & ASR0_RMASK;
					8'hB4: REG_DO <= ASR1 & ASR1_RMASK;
					
					8'hC4: REG_DO <= {31'h00000000,RSEL} & RSEL_RMASK;
					
					default: REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign CDO = ABUS_SEL || BBUS_SEL ? AB_BUF : 
	             !CIVECF_N            ? {24'h000000,IVEC_DO} :
					 DSP_SEL              ? DSP_DO : 
					 REG_DO;
	assign CWAIT_N = ~CBUS_WAIT;
	
endmodule
