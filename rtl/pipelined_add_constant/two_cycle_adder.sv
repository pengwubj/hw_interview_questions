module two_cycle_adder #(parameter int W = 32) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk

   , input                                   cin
   , input [W-1:0]                           a
   , input [W-1:0]                           b

   , output logic                            cout
   , output logic [W-1:0]                    y
);

  typedef logic [W-1:0] w_t;
  typedef struct        packed { logic cout; w_t w;} result_t;

  result_t result_0_w, result_0_r;
  always_comb
    begin
      result_0_w  = a + b + w_t'(cin);
      {cout, y} = result_0_r;
    end

  always_ff @(posedge clk) begin
    result_0_r <= result_0_w;
  end

endmodule // two_cycle_adder
