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

module pipelined_add_constant #(parameter int W = 32,
                                parameter int C = 2,
                                parameter int INIT = 0)
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

  //
  w_t                              A_0_w;
  w_t                              A_0_r;
  //
  w_t                              A_0_delayed_r;
  //
  logic                            UNUSED_co_0;
  //
  logic                            sel_r;
  logic                            sel_w;

  //
  w_t                              c2__c;
  //
  w_t                              c2__x_r;
  w_t                              c2__x_w;
  logic                            c2__x_en;
  //
  w_t                              c2__y_r;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      {UNUSED_co_0, A_0_w}  = A_0_r + w_t'(C);

      //
      sel_w                 = ~sel_r;

      //
      c2__c                 = sel_r ? w_t'(C) : w_t'(C << 1);

      //
      c2__x_w               = sel_r ? c2__x_r : c2__y_r;
      c2__x_en              = ~sel_r;


      fail                  = '0;

    end


  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      sel_r <= 'b1;
    else
      sel_r <= sel_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      A_0_r <= '0;
    else
      A_0_r <= A_0_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    A_0_delayed_r <= A_0_r;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      c2__x_r <= '0;
    else if (c2__x_en)
      c2__x_r <= c2__x_w;

  // ------------------------------------------------------------------------ //
  //
  two_cycle_adder #(.W(W)) u_two_cycle_adder (.clk(clk),
                                              .cin(1'b0),
                                              .a(c2__x_r),
                                              .b(c2__c),
                                              .cout(),
                                              .y(c2__y_r)
                                              );

endmodule
