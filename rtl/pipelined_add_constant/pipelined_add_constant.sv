//========================================================================== //
// Copyright (c) 2016, Stephen Henry
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//========================================================================== //

module pipelined_add_constant #(parameter int W = 32)
(
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Result                                                                  //
   //                                                                         //
   //======================================================================== //

   , output logic                            fail
);

  typedef logic [W-1:0] w_t;

  localparam w_t INIT = '0;
  localparam w_t INCR = 'd2;
  

  // A
  w_t                        A_y_w;
  w_t                        A_y_r;

  // B
  w_t                        B_y_r;

  //
  logic                      valid_r;

  //
  logic                      init_r;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    fail = (A_y_r != B_y_r);

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      valid_r <= '0;
    else
      valid_r <= '1;
    
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      A_y_r <= '0;
    else
      A_y_r <= A_y_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      init_r <= '1;
    else
      init_r <= '0;

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  A #(.W(W)) u_A (.clk(clk), .rst(rst), .a_init(INIT), .i(INCR), .init(init_r), .y_w(A_y_w));
  B #(.W(W)) u_B (.clk(clk), .rst(rst), .a_init(INIT), .i(INCR), .init(init_r), .y_r(B_y_r));

endmodule


