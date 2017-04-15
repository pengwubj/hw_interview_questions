//========================================================================== //
// Copyright (c) 2017, Stephen Henry
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

module div_by_3 (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // In                                                                      //
   //                                                                         //
   //======================================================================== //

   , input                                   pass
   , input          [15:0]                   x
   //
   , output logic                            busy_r

   //======================================================================== //
   //                                                                         //
   // Out                                                                     //
   //                                                                         //
   //======================================================================== //

   , output logic                            valid_r
   , output logic   [15:0]                   y_r
);

  typedef logic [3:0] state_t;
  typedef logic [31:0] w_t;

  //
  typedef struct packed {
    logic        i;
    logic [14:0] f;
  } Q1_15_t;

  typedef struct packed {
    logic [15:0] i;
    logic [14:0] f;
  } Q16_15_t;
  
  localparam Q1_15_t M1_33333 = 16'b0010_1010_1010_1011;

  //
  state_t                     state_r;
  state_t                     state_w;
  logic                       state_en;
  //
  logic                       busy_w;
  //
  Q16_15_t                    accumulator_inc;
  //
  Q16_15_t                    accumulator_r;
  Q16_15_t                    accumulator_w;
  logic                       accumulator_en;
  //
  logic                       valid_w;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : cntrl_PROC

      Q16_15_t x_ext = Q16_15_t'(x);
      
      //
      case (state_r)
        'd0:     accumulator_inc = Q16_15_t'(x_ext <<  0);
        'd1:     accumulator_inc = Q16_15_t'(x_ext <<  1);
        'd2:     accumulator_inc = Q16_15_t'(x_ext <<  3);
        'd3:     accumulator_inc = Q16_15_t'(x_ext <<  5);
        'd4:     accumulator_inc = Q16_15_t'(x_ext <<  7);
        'd5:     accumulator_inc = Q16_15_t'(x_ext <<  9);
        'd6:     accumulator_inc = Q16_15_t'(x_ext << 11);
        'd7:     accumulator_inc = Q16_15_t'(x_ext << 13);
        default: accumulator_inc = '0;
      endcase // case (state_r)

      //
      case (state_r)
        'd0:     accumulator_w = accumulator_inc;
        default: accumulator_w = accumulator_inc + accumulator_r;
      endcase // case (state_r)

      //
      accumulator_en = busy_r;

      //
      casez ({pass, busy_r})
        2'b1?:   state_w = '0;
        2'b01:   state_w = (state_r == 'd7) ? 'd0 : state_r + 'b1;
        default: state_w = state_r;
      endcase // casez ({pass, busy_r})

      //
      state_en = pass | busy_r;

      //
      busy_w = pass | (busy_r & (state_w != '0));

      //
      case (valid_r)
        1'b1:    valid_w = 1'b0;
        default: valid_w = (state_r != '0) & (state_w == '0);
      endcase // case (valid_r)

      //
      y_r = accumulator_r.i;

    end // block: cntrl_PROC
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      valid_r <= '0;
    else
      valid_r <= valid_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      accumulator_r <= '0;
    else if (accumulator_en)
      accumulator_r <= accumulator_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      state_r <= '0;
    else if (state_en)
      state_r <= state_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      busy_r <= '0;
    else
      busy_r <= busy_w;

endmodule
