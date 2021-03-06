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

module top
  (input  wire      clk48,
   output reg [2:0] led = 0,

   input wire       rx,
   output wire      tx);

   reg [2:0]        led_color = 7;
   reg              led_on    = 1;

   //  48e6 + 40% ~= 2^26
   reg [26:0]       clk_div = 0;

   wire             tx_busy;

   wire             tx_data_valid;
   wire [7:0]       tx_data;

   wire             rx_data_valid;
   wire [7:0]       rx_data;

   assign           tx_data_valid = rx_data_valid;
   assign           tx_data       = rx_data + 1;


   rs232out #(115200, 48000000) tx_inst(clk48, tx, tx_data_valid, tx_data_ready, tx_data);
   rs232in  #(115200, 48000000) rx_inst(clk48, rx, rx_data_valid, rx_data);

   always @(posedge clk48)
     clk_div <= clk_div[26] ? 16000000 - 2 : clk_div - 1; // 3 Hz

   always @(posedge clk48)
     if (clk_div[26]) begin
        led    <= led_on ? ~led_color : ~0;
        led_on <= !led_on;
     end

   always @(posedge clk48)
     if (rx_data_valid)
       led_color <= rx_data[2:0];
endmodule
