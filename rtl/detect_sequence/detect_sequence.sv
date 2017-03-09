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

module detect_sequence (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // I/O                                                                     //
   //                                                                         //
   //======================================================================== //

   , input                                   in
   //
   , output logic                            fail
);

  localparam int W = 8;
  typedef logic [W-1:0] w_t;

  localparam w_t SEQUENCE = 'b10011010;

  typedef enum logic [3:0] {  STATE_S0  = 4'b0000,
                              STATE_S1  = 4'b0001,
                              STATE_S2  = 4'b0010,
                              STATE_S3  = 4'b0011,
                              STATE_S4  = 4'b0100,
                              STATE_S5  = 4'b0101,
                              STATE_S6  = 4'b0110,
                              STATE_S7  = 4'b0111,
                              STATE_S8  = 4'b1000
                            } fsm_t;

  //
  w_t               shift_w;
  w_t               shift_r;
  //
  fsm_t             fsm_w;
  fsm_t             fsm_r;
  //
  logic             detect_fsm;
  logic             detect_shift;

  // 10001010

// FSM
// SHIFT REGISTER


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : fsm_PROC

`define TRANSITION(S, S_A, S_B)\
      STATE_S``S: fsm_w = (~in) ? STATE_S``S_A : STATE_S``S_B

      // 76543210
      // 10001010
      case (fsm_r)//   0  1
        `TRANSITION(0, 0, 1); // 1
        `TRANSITION(1, 2, 1); // 0
        `TRANSITION(2, 3, 1); // 0
        `TRANSITION(3, 0, 4); // 1
        `TRANSITION(4, 2, 5); // 1
        `TRANSITION(5, 6, 1); // 0
        `TRANSITION(6, 3, 7); // 1
        `TRANSITION(7, 8, 1); // 0
        `TRANSITION(8, 0, 1);
        default: fsm_w   = 'x;
      endcase // case (fsm_r)
`undef TRANSITION

      //
      detect_fsm = (fsm_r == STATE_S8);

    end // block: fsm_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : shift_reg_PROC

      //
      shift_w       = { shift_r [W-2:0], in };

      //
      detect_shift  = (shift_r == SEQUENCE);

    end // block: shift_reg_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb fail = (detect_fsm ^ detect_shift);

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    fsm_r <= rst ? '0 : fsm_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    shift_r <= rst ? '0 : shift_w;

endmodule // detect_sequence
