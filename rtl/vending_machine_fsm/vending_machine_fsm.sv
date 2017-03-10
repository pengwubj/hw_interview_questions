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

module vending_machine_fsm
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
   // Client Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , input                                   nickel
   , input                                   dime
   //
   , output logic                            vend
   , output logic                            change
);

  typedef enum logic [5:0] {  FSM_IDLE  = 6'b00_0000,
                              FSM__0_05 = 6'b00_0001,
                              FSM__0_10 = 6'b00_0010,
                              FSM__0_15 = 6'b00_0011,
                              FSM__0_20 = 6'b00_0100,
                              FSM__0_25 = 6'b00_0101,
                              FSM__0_30 = 6'b00_0110,
                              FSM__0_35 = 6'b00_0111,
                              FSM__0_40 = 6'b01_1000,
                              FSM__0_45 = 6'b11_1001
                            } fsm_t;
  localparam int FSM_VEND_B  = 4;
  localparam int FSM_CHANGE_B = 5;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  fsm_t                                 fsm_r;
  fsm_t                                 fsm_w;
  logic                                 fsm_en;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : fsm_next_PROC

      logic in_valid  = (nickel | dime);

      //
      vend            = fsm_r [FSM_VEND_B];
      change          = fsm_r [FSM_CHANGE_B];

      //
      fsm_w           = fsm_r;
      fsm_en          = in_valid;

      // nickel = 0.05, dime = 0.10
      case (fsm_r)
        FSM_IDLE:
          if (in_valid)
            fsm_w = nickel ? FSM__0_05 : FSM__0_10;

        FSM__0_05:
          if (in_valid)
            fsm_w = nickel ? FSM__0_10 : FSM__0_15;

        FSM__0_10:
          if (in_valid)
            fsm_w = nickel ? FSM__0_15 : FSM__0_20;

        FSM__0_15:
          if (in_valid)
            fsm_w = nickel ? FSM__0_20 : FSM__0_25;

        FSM__0_20:
          if (in_valid)
            fsm_w = nickel ? FSM__0_25 : FSM__0_30;

        FSM__0_25:
          if (in_valid)
            fsm_w = nickel ? FSM__0_30 : FSM__0_35;

        FSM__0_30:
          if (in_valid)
            fsm_w = nickel ? FSM__0_35 : FSM__0_40;

        FSM__0_35:
          if (in_valid)
            fsm_w = nickel ? FSM__0_40 : FSM__0_45;

        FSM__0_40: begin
          fsm_en  = 1'b1;
          fsm_w   = FSM_IDLE;
        end

        FSM__0_45: begin
          fsm_en  = 1'b1;
          fsm_w   = FSM_IDLE;
        end

        default:
          fsm_w  = 'x;

      endcase // case (fsm_r)

    end // block: fsm_next_PROC


  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      fsm_r <= FSM_IDLE;
    else if (fsm_en)
      fsm_r <= fsm_w;

endmodule // vending_machine_fsm
