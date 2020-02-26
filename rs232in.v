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

module rs232in
   (input  wire        clock,
    input  wire        rx,
    output reg         rx_data_valid = 0,
    output reg   [7:0] rx_data       = 0);

   parameter           bps        =     57_600;
   parameter           frequency  = 25_000_000;
   parameter           period     = (frequency + bps/2) / bps;

   reg  [16:0] ttyclk       = 0;
   wire [31:0] ttyclk_bit   = period - 2;
   wire [31:0] ttyclk_start = (3 * period) / 2 - 2;
   reg  [ 7:0] shift_in     = 0;
   reg  [ 4:0] count        = 0;

   reg         rxd          = 0;
   reg         rxd2         = 0;

   /*
    * The theory: look for a negedge, then wait 1.5 bit period to skip
    * start bit and center in first bit.  Keep shifting bits until a full
    * byte is collected.
    *
    *        Start                        Stop
    * data   ~\__ B0 B1 B2 B3 B4 B5 B6 B7 ~~
    * count        8  7  6  5  4  3  2  1
    */
   always @(posedge clock) begin
      rx_data_valid <= 0;

      // Get rid of meta stability.
      {rxd2,rxd} <= {rxd,rx};

      if (~ttyclk[16]) begin
         ttyclk <= ttyclk - 1'd1;
      end else if (count) begin
         if (count == 1) begin
            rx_data       <= {rxd2, shift_in[7:1]};
            rx_data_valid <= 1;
         end

         count       <= count - 1'd1;
         shift_in    <= {rxd2, shift_in[7:1]}; // Shift in from the left
         ttyclk      <= ttyclk_bit[16:0];
      end else if (~rxd2) begin
         // Just saw the negedge of the start bit
         ttyclk      <= ttyclk_start[16:0];
         count       <= 8;
      end
   end
endmodule
