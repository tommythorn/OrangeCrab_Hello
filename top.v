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
