/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  RS.sv                                               //
//                                                                     //
//  Description :                                                      //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`define XLEN  32

module rs (
    input logic            	            clock,          // system clock
    input logic            	            reset,          // system reset
    input logic            	            rs_valid,
    input logic            	            cdb_valid,
    input logic [`XLEN-1:0]               cdb_value,
    input logic [`TAG_SIZE-1:0]           cdb_tag, // ROB number
    input logic [2:0]                     cdb_unit,

    input Opcode                          opcode,
    input logic [`ROB_BIT_WIDTH-1:0]      	ROB_number,
    input logic [`REG_ADDR_BIT_WIDTH-1:0]      	input_reg_1,
    input logic [`REG_ADDR_BIT_WIDTH-1:0]       	input_reg_2,
    input logic [`REG_ADDR_BIT_WIDTH-1:0]       	dest_reg,  
    input logic [`RS_SIZE-1:0]       	   done_signal,
    input logic [`XLEN-1:0]     	         value_1,
    input logic [`XLEN-1:0]      	      value_2,
    input RS 		   	                  rs_table,
    input logic            	ready_in_rob_valid,
    input logic [`XLEN-1:0]      	ready_in_rob_register,
    input logic [`ROB_BIT_WIDTH-1:0]      	ready_rob_num, squash_index, rob_tail,
    input ID_EX_PACKET	   	id_packet,
    input logic [`RS_SIZE-1:0] 		exec_busy,
    input logic			    squash,   

    input logic            	retire,
    input logic [`REG_ADDR_BIT_WIDTH-1:0]      	retire_register,
    input logic [`ROB_BIT_WIDTH-1:0]      	retire_rob_number,
    input INST             	inst,
    output RS		   	      out,
    output logic [`RS_SIZE-1:0]		exec_run,
    output RS_CDB_PACKET           to_cdb
);

   // assign exec_run[1] = ((rs_table.map_table[input_reg_1] == 0 ||
   //                rs_table.map_table[input_reg_1][0] == 1) && 
   //                (rs_table.map_table[input_reg_2] == 0 || 
   //                rs_table.map_table[input_reg_2][0] == 1) && 
   //                exec_busy[1] == 0 && 
   //                rs_table.busy_signal[1] == 1) ? 1 : 0;
   
   // assign exec_run[2] = ((rs_table.map_table[input_reg_1] == 0 ||
   //                rs_table.map_table[input_reg_1][0] == 1) && 
   //                (rs_table.map_table[input_reg_2] == 0 || 
   //                rs_table.map_table[input_reg_2][0] == 1) && 
   //                exec_busy[2] == 0 && 
   //                rs_table.busy_signal[2] == 1) ? 1 : 0;
   
   // assign exec_run[3] = ((rs_table.map_table[input_reg_1] == 0 ||
   //                rs_table.map_table[input_reg_1][0] == 1) && 
   //                (rs_table.map_table[input_reg_2] == 0 || 
   //                rs_table.map_table[input_reg_2][0] == 1) && 
   //                exec_busy[3] == 0 && 
   //                rs_table.busy_signal[3] == 1) ? 1 : 0;

   // assign exec_run[4] = (opcode == 2 && (rs_table.map_table[input_reg_1] == 0 ||
   //                rs_table.map_table[input_reg_1][0] == 1) && 
   //                (rs_table.map_table[input_reg_2] == 0 || 
   //                rs_table.map_table[input_reg_2][0] == 1) && 
   //                exec_busy[4] == 0 && 
   //                rs_table.busy_signal[4] == 1) ? 1 : 0;

   always_ff @(posedge clock) begin
      
      
      if (reset) begin
			// exec_run = `RS_SIZE'b0;
            for (int i = 0; i < `RS_SIZE; i++) begin 
              out.busy_signal[i] <= 3'b0;
              out.out_opcode[i] <= 0;
              out.T[i] <= 0;
              out.T1[i] <= 0;
              out.T2[i] <= 0;
              out.V1[i] <= 0;
              out.V2[i] <= 0;
              out.inst[i] <= 0;
            end // for loop
            for (int i = 0; i < 32; i++)  out.map_table[i] <= 0;
        end else begin
	out <= rs_table;
      for (int i = 1; i < `RS_SIZE+1; i++) begin
			
			
			exec_run[i] <= ((rs_table.map_table[rs_table.T1[i]][4:1] == 4'b0 ||
				   rs_table.map_table[rs_table.T1[i]][0] == 1) && 
				   (rs_table.map_table[rs_table.T2[i]][4:1] == 4'b0 || 
				   rs_table.map_table[rs_table.T2[i]][0] == 1) && 
				   exec_busy[i] == 0 && rs_table.busy_signal[i] == 1);
			//$display("LS CLEARINGGGG");
			//$display("exec_run[%d] = %b", i, exec_run[i]);
			//$display("LS CLEARINGGGG_DONE");
         		if(exec_run[i] == 1) begin
			    out.busy_signal[i] <= 0;
			    	//$display("LS CLEARINGGGG inside");
				//$display("exec_run[%d] = %b", i, exec_run[i]);
				//$display("out_busy[%d] = %b", i, out.busy_signal[i]);
			//	$display("LS CLEARINGGGG_DONE inside");
			    //out.T[i] <= 0;
			    //out.T1[i] <= 0;
			    //out.T2[i] <= 0;
			    //out.V1[i] <= 0;
			    //out.V2[i] <= 0;
			end
			 
			 /*if ((rs_table.map_table[input_reg_1] == 0 ||
				   rs_table.map_table[input_reg_1][0] == 1) && 
				   (rs_table.map_table[input_reg_2] == 0 || 
				   rs_table.map_table[input_reg_2][0] == 1) && 
				   exec_busy[i] == 0 && rs_table.busy_signal[i] == 1 && i != idx); begin: clear_RS
			    $display("RS_TABLE_busy_signal [%d] = %b and i = %d", i, rs_table.busy_signal[i], i);
			    out.busy_signal[i] <= 0; // next cycle
         	    	 end*/
		    end // for loop
      if (rs_valid && id_packet.inst != 32'h00000013) begin
         //out <= rs_table;
	 if(dest_reg != `ZERO_REG) begin out.map_table[dest_reg] <= {ROB_number, 1'b0}; end
         // if (ROB_number < 7) out.map_table[dest_reg] <= ROB_number+1;
         // else out.map_table[dest_reg] <= 1;
         case (opcode) // dispatch on opcode
               1: process_instr(1, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
               2:  process_instr(4, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
               3:   process_instr(2, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
               4:  process_instr(3, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
               default: process_other_instr(0, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
         endcase
      end 

      
      

            if (cdb_valid) begin
               //$display("Ready Rob NUmber:%d", ready_rob_num);
               if(rs_table.map_table[ready_in_rob_register][4:1] == ready_rob_num) begin out.map_table[ready_in_rob_register][0] <= 1; end
            end // ready_in_rob_valid
            if (cdb_valid) begin
		//$display("RS_CDB_TAG");
               //$display("CDB tag:%d, CDB_unit:%d", cdb_tag, cdb_unit); 
	       for (int j = 1; j < `RS_SIZE + 1; j++) begin
		       if(rs_table.T1[j] == cdb_tag) begin
			//$display("CDB MANIPULATES %d", j);
		          out.V1[j] <= cdb_value;
		          out.T1[j] <= 0;
		        end	else if(rs_table.T2[j] == cdb_tag) begin
						//$display("CDB MANIPULATES %d", j);
		          out.V2[j] <= cdb_value;
		          out.T2[j] <= 0;
		        end
		end
            end // cdb_valid
            if (retire) begin
               //$display("Retire rob num:%d", retire_rob_number);
               if(rs_table.map_table[retire_register][4:1] == retire_rob_number) begin
                  out.map_table[retire_register] <= 33'b0;
               end
            end // retire
            if (squash) begin
                if (rob_tail > squash_index) begin // handle squash index within head and tail
                    squash_entries(0, squash_index, rob_tail, 0);
                end else begin // handle squash index wraparound
                    squash_entries(0, squash_index, rob_tail, 1);
                end
            end // squash
	    end // else: ~reset
      $display("Reservation Stations");
      $display("    +----+------+------+--------+------+-----+----------------------------------+-----+----------------------------------+");
      $display("    | #  | busy | run  |  FU    | ROB# | T1  |                V1                | T2  |                V2                |");
      $display("    +----+------+------+--------+------+-----+----------------------------------+-----+----------------------------------+");
      for (int i = 0; i < `RS_SIZE; i++) begin
         if (i + 1 == rob_tail) begin
            if (i == 0) begin
               $display("T-> | %02d  |  %d  |  %d   |  ????  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 1) begin
               $display("T-> | %02d  |  %d   |  %d   |  ALU   | %02d | %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 2) begin
               $display("T-> | %02d  |  %d   |  %d   | LD/ST  | %02d | %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 3) begin
               $display("    | %02d  |  %d  |  %d   |  BR0   |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 4) begin
               $display("T-> | %02d  |  %d   |  %d   |  MUL0  | %02d | %02d | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 5) begin
               $display("T-> | %02d  |  %d  |  %d   |  MUL1  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end
         end else begin
            if (i == 0) begin
               $display("    | %02d  |  %d  |  %d   |  ????  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 1) begin
               $display("    | %02d  |  %d  |  %d   |  ALU0  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 2) begin
               $display("    | %02d  |  %d  |  %d   |  L/S0  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 3) begin
               $display("    | %02d  |  %d  |  %d   |  BR0   |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 4) begin
               $display("    | %02d  |  %d  |  %d   |  MUL0  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 5) begin
               $display("    | %02d  |  %d  |  %d   |  MUL1  |  %02d  |  %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], exec_run[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end
         end
      end
      $display("    +-----+-----+------+--------+------+-----+----------------------------------+-----+----------------------------------+");
         // $display("Entry %d:", i);
         // $display("  Busy: %b, Op: %b, T: %d, T1: %d, T2: %d, V1: %d, V2: %d", out.busy_signal[i], out.out_opcode[i], out.T[i], out.T1[i], out.T2[i], out.V1[i], out.V2[i]);
         // $display("  Instruction: %p", out.inst[i]);
      $display("\n    Map Table (only non-zero registers are displayed):");
      for (int i = 0; i < 32; i++) begin
         if (out.map_table[i] != 0) begin
            $display("     Register %d: %d, Ready_bit: %b", i, out.map_table[i][4:1], out.map_table[i][0]);
         end
      end
      $display("------------------------");
	end // always_ff

// processes `idx=0,...,4`
task process_instr(
    int idx,
    INST inst,
    logic [31:0] value_1,
    logic [31:0] value_2,
    ID_EX_PACKET id_packet,
    logic [4:0] exec_busy,
    Opcode opcode,
    logic [4:0] input_reg_1,
    logic [4:0] input_reg_2,
    logic [3:0] ROB_number
);
    begin

      /*$display("reg1=%d reg1[0]=%d reg2=%d reg2[0]=%d exec_busy[%d]=%d\n   exec_busy=%b (rs_table.busy[%d]=%b)\n   exec_run=%b",
                  rs_table.map_table[input_reg_1],
                  rs_table.map_table[input_reg_1][0],
                  rs_table.map_table[input_reg_2],
                  rs_table.map_table[input_reg_2][0],
                  idx,
                  exec_busy[idx],
                  exec_busy,
                  idx,
                  rs_table.busy_signal[idx],
                  exec_run);
		//&& rs_table.busy_signal[idx] == 0*/
		if (idx <= 4 && rs_table.busy_signal[idx] == 0) begin
		    out.inst[idx] <= inst;
		    //$display("NEW INSTRUCTION CAME TO out.busy_signal[%d] = %b", idx, out.busy_signal[idx]);
		    out.busy_signal[idx] <= 1;
		    out.out_opcode[idx] <= opcode;
		    out.T[idx] <= ROB_number;
		    
		    //out.V1[idx] <= (rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) ? value_1 : 32'b0;
		    //out.V2[idx] <= (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) ? value_2 : 32'b0;
		    if(rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) out.V1[idx] <= value_1;
		    else if((cdb_valid == 1 && cdb_tag == rs_table.map_table[input_reg_1][4:1])) out.V1[idx] <= cdb_value;
		    else out.V1[idx] <= 32'b0;
	       	    if(rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) out.V2[idx] <= value_2;
		    else if((cdb_valid == 1 && cdb_tag == rs_table.map_table[input_reg_2][4:1])) out.V2[idx] <= cdb_value;
		    else out.V2[idx] <= 32'b0;
		    if(rs_table.map_table[input_reg_1][0] == 0 && (cdb_valid == 1 && cdb_tag != rs_table.map_table[input_reg_1][4:1])) out.T1[idx] <= rs_table.map_table[input_reg_1][4:1];
		    else out.T1[idx] <= 0;
		    if(rs_table.map_table[input_reg_2][0] == 0 && (cdb_valid == 1 && cdb_tag != rs_table.map_table[input_reg_2][4:1])) out.T2[idx] <= rs_table.map_table[input_reg_2][4:1];
		    else out.T2[idx] <= 0;
		    //out.T1[idx] <= rs_table.map_table[input_reg_1][4:1];
		    //out.T2[idx] <= rs_table.map_table[input_reg_2][4:1];
		    out.id_packet[idx] <= id_packet;
		    
		   //  exec_run[idx] <= 1;
          
         // exec_run[idx] <= ((rs_table.map_table[input_reg_1] == 0 ||
                           // rs_table.map_table[input_reg_1][0] == 1) && 
                           // (rs_table.map_table[input_reg_2] == 0 || 
                           // rs_table.map_table[input_reg_2][0] == 1) && 
                           // exec_busy[idx] == 0 && rs_table.busy_signal[idx] == 1);

		end else if (idx == 4 && rs_table.busy_signal[5] == 0) begin
		    out.inst[5] <= inst;
		    out.busy_signal[5] <= 1;
		    out.out_opcode[5] <= opcode;
		    //out.T[5] <= ROB_number;
		    if(ROB_number <= 7) out.T[5] <= ROB_number;
		    else out.T[5] <= 1;
		    out.V1[5] <= (rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) ? value_1 : 32'b0;
		    out.V2[5] <= (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) ? value_2 : 32'b0;
		    if(rs_table.map_table[input_reg_1][0] == 0) out.T1[5] <= rs_table.map_table[input_reg_1][4:1];
		    else out.T1[5] <= 0;
		    if(rs_table.map_table[input_reg_2][0] == 0) out.T2[5] <= rs_table.map_table[input_reg_2][4:1];
		    else out.T2[5] <= 0;
		    out.id_packet[5] <= id_packet;
		    /*for (int i = 0; i <= `RS_SIZE; i++) begin
         		 if(exec_run[i] == 1) begin
			    out.busy_signal[i] <= 0;
			 end
			 exec_run[i] <= ((rs_table.map_table[input_reg_1] == 0 ||
				   rs_table.map_table[input_reg_1][0] == 1) && 
				   (rs_table.map_table[input_reg_2] == 0 || 
				   rs_table.map_table[input_reg_2][0] == 1) && 
				   exec_busy[i] == 0 && rs_table.busy_signal[i] == 1 && i != 5);
			 if ((rs_table.map_table[input_reg_1] == 0 ||
				   rs_table.map_table[input_reg_1][0] == 1) && 
				   (rs_table.map_table[input_reg_2] == 0 || 
				   rs_table.map_table[input_reg_2][0] == 1) && 
				   exec_busy[i] == 0 && rs_table.busy_signal[i] == 1 && i != 5) begin: clear_RS
			    out.busy_signal[i] <= 0; // next cycle
         	    	 end
		    end // for loop*/
		   //  exec_run[idx] <= 1;
         // exec_run[5] <= ((rs_table.map_table[input_reg_1] == 0 ||
         //                   rs_table.map_table[input_reg_1][0] == 1) && 
         //                   (rs_table.map_table[input_reg_2] == 0 || 
         //                   rs_table.map_table[input_reg_2][0] == 1) && 
         //                   exec_busy[5] == 0 && rs_table.busy_signal[5] == 1);
         // exec_run[5] <= ((rs_table.map_table[input_reg_1] == 0 ||
         //                rs_table.map_table[input_reg_1][0] == 1) && 
         //                (rs_table.map_table[input_reg_2] == 0 || 
         //                rs_table.map_table[input_reg_2][0] == 1) && 
         //                exec_busy[5] == 0 && 
         //                rs_table.busy_signal[5] == 1);

		end
	
    end
endtask

task process_other_instr(
    int idx,
    INST inst,
    logic [31:0] value_1,
    logic [31:0] value_2,
    ID_EX_PACKET id_packet,
    logic [4:0] exec_busy,
    Opcode opcode,
    logic [4:0] input_reg_1,
    logic [4:0] input_reg_2,
    logic [3:0] ROB_number
);
    begin
      $display("THIS IS OTHER");
      out.inst[idx] <= inst;
      out.busy_signal[idx] <= 1;
      out.out_opcode[idx] <= opcode;
      out.T[idx] <= ROB_number;
      
      out.V1[idx] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'bx;
      out.V2[idx] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'bx;
      // ROB # = max of 8 (4 bits)
      out.T1[idx] <= rs_table.map_table[input_reg_1][4:1];
      out.T2[idx] <= rs_table.map_table[input_reg_2][4:1];
      out.id_packet[idx] <= id_packet;
         // exec_run[idx] <= 1;
      // exec_run[idx] <= ((rs_table.map_table[input_reg_1] == 0 ||
      //                      rs_table.map_table[input_reg_1][0] == 1) && 
      //                      (rs_table.map_table[input_reg_2] == 0 || 
      //                      rs_table.map_table[input_reg_2][0] == 1) && 
                           // exec_busy[idx] == 0 && rs_table.busy_signal[idx] == 1);
      //   exec_run[idx] <= (rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) && (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) && exec_busy[idx] == 0;
    end
endtask

task squash_entries(
    int start,
    int squash_index,
    int rob_tail,
    bit wrap_around
);
    for (int i = start; i < `RS_SIZE; i++) begin
        if ((wrap_around && ((rs_table.T[i] >= squash_index && rs_table.T[i] < 7) || (rs_table.T[i] <= rob_tail))) ||
            (!wrap_around && (rs_table.T[i] <= squash_index && rs_table.T[i] > rob_tail))) begin
            out.map_table[rs_table.id_packet[i].dest_reg_idx] <= 0;
            out.busy_signal[i] <= 3'b0;
            out.out_opcode[i] <= 0;
            out.T[i] <= 0;
            out.T1[i] <= 0;
            out.T2[i] <= 0;
            out.V1[i] <= 0;
            out.V2[i] <= 0;
            out.inst[i] <= 0;
        end
    end
endtask

endmodule // rs.sv

