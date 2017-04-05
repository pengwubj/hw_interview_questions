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

module vending_machine_dp (

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

   , input                                   client_nickel
   , input                                   client_dime
   , input                                   client_quarter
   //
   , input                                   client_dispense
   //
   , output logic                            client_enough_r

   //======================================================================== //
   //                                                                         //
   // Serve Interface                                                         //
   //                                                                         //
   //======================================================================== //

   , input                                   serve_done
   //
   , output logic                            serve_emit_irn_bru_r

   //======================================================================== //
   //                                                                         //
   // Change Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , input                                  change_done
   //
   , output logic                           change_emit_dime_r
);

  // Integer denoting the price per dispense in nickel units.
  //
  localparam int PRICE  = 8;
  typedef logic [7:0] count_t;

  typedef enum [5:0] { FSM_DEPOSIT           = 6'b0_00_000,
                       FSM_DISPENSE          = 6'b1_00_001,
                       FSM_SERVE_IRN_BRU     = 6'b1_01_000,
                       FSM_SERVE_WAIT_DONE   = 6'b1_00_011,
                       FSM_CHANGE_EMIT       = 6'b1_10_100,
                       FSM_CHANGE_WAIT_DONE  = 6'b1_00_101
                     } fsm_t;
  localparam int FSM_BUSY_B = 5;
  localparam int FSM_SERVE_CHANGE_B = 4;
  localparam int FSM_SERVE_IRN_BRU_B = 3;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  fsm_t                       fsm_r;
  fsm_t                       fsm_w;
  logic                       fsm_en;
  //
  count_t                     count_r;
  count_t                     count_w;
  logic                       count_en;
  //
  logic                       count_is_zero;
  //
  logic                       client_enough_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      fsm_w  = fsm_r;

      case (fsm_r)
        FSM_DEPOSIT:
          if (client_enough_r)
            fsm_w  = FSM_DISPENSE;

        FSM_DISPENSE:
          if (client_dispense)
            fsm_w = FSM_SERVE_IRN_BRU;

        FSM_SERVE_IRN_BRU:
          fsm_w  = FSM_SERVE_WAIT_DONE;

        FSM_SERVE_WAIT_DONE:
          if (serve_done)
            fsm_w  = count_is_zero ? FSM_DEPOSIT : FSM_CHANGE_EMIT;

        FSM_CHANGE_EMIT:
          fsm_w  = FSM_CHANGE_WAIT_DONE;

        FSM_CHANGE_WAIT_DONE:
          casez ({count_is_zero, change_done})
            2'b1_?:  fsm_w  = FSM_DEPOSIT;
            2'b0_1:  fsm_w  = FSM_CHANGE_EMIT;
            default: fsm_w  = fsm_r;
          endcase // casez ({count_is_zero, change_done})

        default: fsm_w  = FSM_DEPOSIT;

      endcase // case (fsm_r)

      //
      fsm_en                = (fsm_r [FSM_BUSY_B] | client_enough_r);

      //
      serve_emit_irn_bru_r  = fsm_r [FSM_SERVE_IRN_BRU_B];
      change_emit_dime_r    = fsm_r [FSM_SERVE_CHANGE_B];

    end // always_comb


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : dp_PROC

      logic zero;
      logic transition_to_DEPOSIT;

      //
      transition_to_DEPOSIT  = (fsm_r != FSM_DEPOSIT) && (fsm_w == FSM_DEPOSIT);

      //
      zero                   = (rst | transition_to_DEPOSIT);

      //
      casez ({   zero
               , fsm_r [FSM_SERVE_CHANGE_B]
               , client_nickel
               , client_dime
               , client_quarter
            })
        5'b1_????: count_w  = '0;
        5'b0_1???: count_w  = count_r - 'd1;
        5'b0_01??: count_w  = count_r + 'd1;
        5'b0_001?: count_w  = count_r + 'd2;
        5'b0_0001: count_w  = count_r + 'd5;
        default:   count_w  = count_r;
      endcase // casez ({zero, nickel, dime, quarter})

      //
      count_en         =   zero
                         | fsm_r [FSM_SERVE_CHANGE_B]
                         | client_nickel
                         | client_dime
                         | client_quarter
                       ;

      //
      count_is_zero    = (count_r == '0);

      //
      client_enough_w  = (~rst) & (count_w >= count_t'(PRICE));

    end // block: dp_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (fsm_en)
      fsm_r <= fsm_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (count_en)
      count_r <= count_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    client_enough_r <= client_enough_w;

endmodule
