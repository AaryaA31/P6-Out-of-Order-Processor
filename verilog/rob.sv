/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  rob.sv                                              //
//                                                                     //
//  Description :                                                      //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`define XLEN  32
`define ALU 3'b001
`define LD  3'b010
`define ST  3'b011
`define FP  3'b100


module rob (
    input logic            clock,          // system clock
    input logic            reset,          // system reset
    input logic            valid,
    input logic            value_valid,
    input logic [`ROB_BIT_WIDTH-1:0]      value_tag,
    input logic [2:0]       opcode,
    input logic [4:0]      input_reg_1,
    input logic[4:0]       input_reg_2, 
    input logic[4:0]       dest_reg, 
    input logic [31:0]     value,
    input ROB              rob_table,
    input logic            squash,
    input logic [2:0]      squash_index,
    output ROB             out,
    output logic           retire_out, writeback_valid,
    input logic            retire_in,
    input ID_EX_PACKET     id_packet,
    output logic           squash_rob_command,
    output logic [`XLEN-1:0] squash_branch_target,
    input logic            branch_taken2rob,
    input logic [1:0]          proc2Dmem_command,
    input MEM_SIZE             proc2Dmem_size,
    input logic [`XLEN-1:0]    proc2Dmem_addr,
    input logic [`XLEN-1:0]    proc2Dmem_data,
    input [`XLEN-1:0]           Dmem2proc_data 
//output logic [1:0]          out_proc2Dmem_command,
  //  output MEM_SIZE             out_proc2Dmem_size,
   // output logic [`XLEN-1:0]    out_proc2Dmem_addr,
    //output logic [`XLEN-1:0]    out_proc2Dmem_data,   
); 

    
    

    logic [2:0] temp_tail;
/*always_comb begin
out.Vs[0] = (value_valid && value_tag == 0) ? value : 32'b0;
out.Vs[1] = (value_valid && value_tag == 1) ? value : 32'b0;
out.Vs[2] = (value_valid && value_tag == 2) ? value : 32'b0;
out.Vs[3] = (value_valid && value_tag == 3) ? value : 32'b0;
out.Vs[4] = (value_valid && value_tag == 4) ? value : 32'b0;
out.Vs[5] = (value_valid && value_tag == 5) ? value : 32'b0;
out.Vs[6] = (value_valid && value_tag == 6) ? value : 32'b0;
out.Vs[7] = (value_valid && value_tag == 7) ? value : 32'b0;
			//(retire_in && rob_table.head == 0) ? 32'b0 : 
end*/

/*always_ff @(negedge clock) begin
    if (reset) begin
        for (int i = 0; i < 8; i++) begin
            out.Vs[i] <= 32'b0;
	    
        end
    end else 
        if (value_valid) begin
            out.Vs[value_tag] <= value;
            //out.completed[value_tag] <= 1;
        end else begin
            out.Vs[value_tag] <= 32'b0;
            out.completed[value_tag] <= 0;
        end
end*/
    always_ff @(posedge clock) begin
        if(reset) begin
            out.head <= 0;
            out.tail <= 0;
            for(int i = 0; i < 8; i++) begin
   
               
              out.opcodes[i] <= 3'b0;
              out.input_reg_1s[i] <= 5'b0;
              out.input_reg_2s[i] <= 5'b0;
              out.Rs[i] <= 5'b0;
              out.Vs[i] <= 32'b0;
              out.buffer_full <= 0;
	            out.buffer_completed <= 0;
              out.id_packet[i] <= 0;
               temp_tail = 0;
	     out.completed[i] <= 2'b0;
//out.proc2Dmem_command[i] <= 0;
//out.proc2Dmem_size[i] <= 0;
//out.proc2Dmem_addr[i]<=0;
//out.proc2Dmem_data[i] <=0;
//out.Dmem2proc_data[i]<=0;
            end
 
       
        
            
	end else begin
	    out <= rob_table;
	    if(rob_table.completed[rob_table.head] == 2'b11) begin

		if(rob_table.branch_taken[rob_table.head] == 1) begin
			//$display("Branch taken in %d", rob_table.head);
			squash_rob_command <= 1;
			squash_branch_target <= rob_table.Vs[rob_table.head];
			out.tail <= rob_table.head;
			out.branch_taken[rob_table.head] <= 0;
		end else squash_rob_command <= 0;
		retire_out <= 1;
		out.completed[rob_table.head] <= 2'b00;
		if (rob_table.Rs[rob_table.head] != 0) begin
               		writeback_valid <= 1;
		end else writeback_valid <= 0;
            end else if(rob_table.completed[rob_table.head] == 2'b01) begin
			out.completed[rob_table.head] <= 2'b11;
			retire_out <= 0;
	    end else retire_out <= 0;

            
            
            if(valid == 1 ) begin

                if(rob_table.head == 0 && rob_table.tail == 0) begin
                  out.head            <= 1;
                  out.tail            <= 1;
                  out.opcodes[0]      <= opcode;
                  out.input_reg_1s[0] <= input_reg_1;
                  out.input_reg_2s[0] <= input_reg_2;
                  out.Rs[0]           <= dest_reg;
		  out.id_packet[0]    <= id_packet;
		  out.Dmem2proc_data[0]<=Dmem2proc_data;
               end else begin
		if(id_packet.inst != 32'h00000013 && (opcode == 3'b001 || opcode == 3'b010 || opcode == 3'b011 || opcode == 3'b100)) begin
                  if(rob_table.tail == 7) begin
			            out.opcodes[7] <= opcode;
                     out.input_reg_1s[7] <= input_reg_1;
                     out.input_reg_2s[7] <= input_reg_2;
                     out.Rs[7] <= dest_reg;
		     out.completed[7] <= 0;
			            out.id_packet[7]    <= id_packet;
		               out.tail <= 1;
	out.Dmem2proc_data[7]<=Dmem2proc_data;
		            end else begin	
				out.completed[rob_table.tail] <= 0;
			            out.opcodes[rob_table.tail] <= opcode;
		               out.input_reg_1s[rob_table.tail] <= input_reg_1;
		               out.input_reg_2s[rob_table.tail] <= input_reg_2;
		               out.Rs[rob_table.tail] <= dest_reg;
			            out.id_packet[rob_table.tail]    <= id_packet;
out.Dmem2proc_data[rob_table.tail]<=Dmem2proc_data;
                     if (rob_table.tail == 6) begin
				            if (rob_table.head == 1) begin
				               out.buffer_full <= 1;
                           out.tail <= 7;
		                  end else begin
				               out.tail <= 7;
				            end
		               end else begin
		                  if(rob_table.head != (rob_table.tail + 2)) begin
		                     out.tail <= rob_table.tail + 1;
		                  end else begin
		                     out.tail <= rob_table.tail + 1;
				               out.buffer_full <= 1;
				            end
			            end
		            end
		end
               end
            end

      if (value_valid == 1) begin
         //$display("   ```value_tag: %d     value: %d", value_tag, value);
		   out.Vs [value_tag] <= value;
		   out.completed[value_tag] <= 2'b01;
		   out.branch_taken[value_tag] <= branch_taken2rob;
            	   //out.proc2Dmem_command[value_tag] <= proc2Dmem_command;
		   //out.proc2Dmem_size[value_tag] <= proc2Dmem_size;
		   //out.proc2Dmem_addr[value_tag]<=proc2Dmem_addr;
		   //out.proc2Dmem_data[value_tag] <=proc2Dmem_data;
		   out.Rs[value_tag] <= (branch_taken2rob) ? 0 : rob_table.Rs[value_tag];
      end
      if(retire_in == 1) begin
	//$display("Retire INNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
	//$display("Retiring %d", rob_table.head);
	//$display("Retiring value %d", rob_table.Vs[rob_table.head]);
	//$display("Retiring index %d", rob_table.Rs[rob_table.head]);
         out.opcodes[rob_table.head] <= 3'b0;
         out.input_reg_1s[rob_table.head] <= 5'b0;
         out.input_reg_2s[rob_table.head] <= 5'b0;
         out.Rs[rob_table.head] <= 5'b0;
         out.Vs[rob_table.head] <= 32'b0;
         out.buffer_full <= 0;
	//out.proc2Dmem_command[rob_table.head] <= 0;
		   //out.proc2Dmem_size[rob_table.head] <= 0;
		   //out.proc2Dmem_addr[rob_table.head]<=0;
		   //out.proc2Dmem_data[rob_table.head] <=0;
		   out.id_packet[rob_table.head]    <= 0;
out.Dmem2proc_data[rob_table.head]<=0;
         if (rob_table.head == 7) begin
            out.head <= 1;
         end else begin
            out.head <= rob_table.head + 1;
         end
      end
      if(rob_table.branch_taken[rob_table.head] == 1) begin
	if(rob_table.tail > rob_table.head) begin
            for (int i = rob_table.head+1; i < rob_table.tail; i++) begin
               out.tail <= rob_table.head;
               out.opcodes[i] <= 3'b0;
               out.input_reg_1s[i] <= 5'b0;
               out.input_reg_2s[i] <= 5'b0;
               out.Rs[i] <= 5'b0;
               out.Vs[i] <= 32'b0;
               out.buffer_full <= 0;
               out.buffer_completed <= 0;
               out.id_packet[i] <= 0;
	//out.proc2Dmem_command[i] <= 0;
		   //out.proc2Dmem_size[i] <= 0;
		   //out.proc2Dmem_addr[i]<=0;
		   //out.proc2Dmem_data[i] <=0;
		   
out.Dmem2proc_data[i]<=0;
		    end
		end else begin
		    for (int i = rob_table.head+1; i < 8; i++) begin
			out.tail <= rob_table.head;
			out.opcodes[i] <= 3'b0;
              		out.input_reg_1s[i] <= 5'b0;
              		out.input_reg_2s[i] <= 5'b0;
              		out.Rs[i] <= 5'b0;
              		out.Vs[i] <= 32'b0;
              		out.buffer_full <= 0;
	      		out.buffer_completed <= 0;
              		out.id_packet[i] <= 0;
	//out.proc2Dmem_command[i] <= 0;
		   //out.proc2Dmem_size[i] <= 0;
		   //out.proc2Dmem_addr[i]<=0;
		   //out.proc2Dmem_data[i] <=0;
		   
out.Dmem2proc_data[i]<=0;

		    end
		    for (int j = 0; j < rob_table.tail; j++) begin
			out.tail <= rob_table.head;
			out.opcodes[j] <= 3'b0;
              		out.input_reg_1s[j] <= 5'b0;
              		out.input_reg_2s[j] <= 5'b0;
              		out.Rs[j] <= 5'b0;
              		out.Vs[j] <= 32'b0;
              		out.buffer_full <= 0;
	      		out.buffer_completed <= 0;
              		out.id_packet[j] <= 0;
	//out.proc2Dmem_command[j] <= 0;
		   //out.proc2Dmem_size[j] <= 0;
		   //out.proc2Dmem_addr[j]<=0;
		   //out.proc2Dmem_data[j] <=0;
		   
out.Dmem2proc_data[j]<=0;

		    end
		end
	
	    end


	    end
        $display("ROB Contents:");
        $display("Head: %d, Tail: %d, Buffer Full: %d", out.head, out.tail, out.buffer_full);
	$display("-----------------------------------------------------------------------------------");
	$display("Operation codes: 001 - ALU, 010 - MULT, 011 - LD/ST, 100 - BRANCH");
	$display("|  Instruction          | RS1          | RS2          | DEST          | V          |");
        for (int i = 0; i < 8; i++) begin
            $display("  %b                  | %d          | %d          | %d          | %d          |", out.opcodes[i], out.input_reg_1s[i], out.input_reg_2s[i], out.Rs[i], out.Vs[i]);
        end
        $display("-----------------------------------------------------------------------------------");
   end //ALWAYS
endmodule 
