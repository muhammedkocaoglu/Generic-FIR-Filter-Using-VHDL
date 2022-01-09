// This file infer block ram after reading data from memory file

// initialize block memory from file
// $readmemh("hex_memory_file.mem", memory_array, [start_address], [end_address])
// $readmemb("bin_memory_file.mem", memory_array, [start_address], [end_address])

// 	HEXADECIMAL // hex_memory_file.mem - a text file containing hex values separated by whitespace
//  BINARY      //bin_memory_file.mem - a text file containing binary values separated by whitespace

// memory_array - name of Verilog memory array of the form: reg [n:0] memory_array [0:m]
// start_address - where in the memory array to start loading data (optional)
// end_address - where in the memory array to stop loading data (optional)

`timescale 1ns / 1ps


module InitBramFromFile #(
        parameter FILEADDR   = "xxxxxx.mem",
        parameter DATA_WIDTH = 24,
        parameter ADDR_WIDTH = 8   // DATA_DEPTH = 2**ADDR_WIDTH-1 // in that case 255
    )
    (
        input clk,
        input we,
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] di,
        output [DATA_WIDTH-1:0] dout
    );
    reg [DATA_WIDTH-1:0] ram [0:2**ADDR_WIDTH-1];
    reg [DATA_WIDTH-1:0] doutReg;
    initial
    begin
        $readmemh(FILEADDR, ram, 0, 2**ADDR_WIDTH-1);
    end
    always @(posedge clk)
    begin
        if (we)
            ram[addr]	<= di;
        doutReg	<= ram[addr];
    end
    assign dout = doutReg;
endmodule
