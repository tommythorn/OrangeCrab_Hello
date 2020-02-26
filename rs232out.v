/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/

`timescale 1ns/10ps

module rs232out
   (input wire         clock,
    output wire        tx,
    input  wire        tx_data_valid,
    output wire        tx_data_ready,
    input  wire  [7:0] tx_data);

   parameter           bps         =     9600;
   parameter           frequency   = 50000000;
`ifndef __ICARUS__
   parameter           period      = (frequency + bps/2) / bps;
`else
   // One of the very few simulation artifacts we have to deal with at the source level.
   parameter           period      = 0;
`endif
   parameter           TTYCLK_SIGN = 16; // 2^TTYCLK_SIGN > period * 2
   parameter           COUNT_SIGN  = 4;

   reg  [TTYCLK_SIGN:0] ttyclk      = 0; // [-4096; 4095]
   wire [31:0]          ttyclk_bit  = period - 2;
   reg  [8:0]           shift_out   = 0;
   reg  [COUNT_SIGN:0]  count       = 0; // [-16; 15]

   assign               tx          = shift_out[0];
   assign               tx_data_ready=count[COUNT_SIGN] & ttyclk[TTYCLK_SIGN];

   always @(posedge clock)
      if (~ttyclk[TTYCLK_SIGN]) begin
         ttyclk     <= ttyclk - 1'd1;
      end else if (~count[COUNT_SIGN]) begin
         ttyclk     <= ttyclk_bit[TTYCLK_SIGN:0];
         count      <= count - 1'd1;
         shift_out  <= {1'b1, shift_out[8:1]};
      end else if (tx_data_valid) begin
         ttyclk     <= ttyclk_bit[TTYCLK_SIGN:0];
         count      <= 9; // 1 start bit + 8 data + 1 stop - 1 due to SIGN trick
         shift_out  <= {tx_data, 1'b0};
      end
endmodule
