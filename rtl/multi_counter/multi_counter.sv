//=========================================================================== //
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
//=========================================================================== //

`include "multi_counter_pkg.vh"

module multi_counter #(
  // ======================================================================== //
  //                                                                          //
  // Parameters                                                               //
  //                                                                          //
  // ======================================================================== //

     parameter int CNTRS_N = 256
   , parameter int CNTRS_W = 32
   //
   , parameter int CNTRS_ID_W = $clog2(CNTRS_N)
)(

  // ======================================================================== //
  //                                                                          //
  // Ports                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  // Misc.                                                                    //
  // ------------------------------------------------------------------------ //

    input                                    clk
  , input                                    rst

  // ------------------------------------------------------------------------ //
  // Command Interface                                                        //
  // ------------------------------------------------------------------------ //

  , input logic                              cntr_pass
  , input logic [CNTRS_ID_W-1:0]             cntr_id
  , input multi_counter_pkg::op_t            cntr_op
  , input logic [CNTRS_W-1:0]                cntr_dat

  // ------------------------------------------------------------------------ //
  // Status Interface                                                         //
  // ------------------------------------------------------------------------ //

  , output logic                             status_pass_r
  , output logic                             status_qry_r
  , output logic [CNTRS_ID_W-1:0]            status_id_r
  , output logic [CNTRS_W-1:0]               status_dat_r
);

  `include "libtb_tb_top_inc.vh"
   // ======================================================================= //
   //                                                                         //
   //  Signals                                                                //
   //                                                                         //
   // ======================================================================= //

   //
   logic                      mem_collision;
   logic                      mem_lkup;
   logic                      mem_wrbk;
   //
   logic                      mem_prt1_en;
   logic                      mem_prt1_wen;
   logic [CNTRS_ID_W-1:0]     mem_prt1_addr;
   logic [CNTRS_W-1:0]        mem_prt1_din;
   logic [CNTRS_W-1:0]        mem_prt1_dout;
   //
   logic                      mem_prt2_en;
   logic                      mem_prt2_wen;
   logic [CNTRS_ID_W-1:0]     mem_prt2_addr;
   logic [CNTRS_W-1:0]        mem_prt2_din;
   logic [CNTRS_W-1:0]        mem_prt2_dout;
   //
   logic                      fwd_4_to_2;
   logic                      fwd_3_to_2;
   logic                      fwd_byp_to_2;
   logic                      fwd_dat_to_2;
   logic [CNTRS_W-1:0]        ucode_byp_2;
   //
   logic                      fwd_4_to_3;
   logic [CNTRS_W-1:0]        ucode_byp_3;
   //
   logic [CNTRS_W-1:0]        ucode_cdat_3;

   // ======================================================================= //
   //                                                                         //
   //  Ucode                                                                  //
   //                                                                         //
   // ======================================================================= //

   typedef logic [CNTRS_ID_W-1:0] id_t;
   typedef logic [CNTRS_W-1:0]    cntr_t;

   typedef struct packed {
      id_t                              id;
      multi_counter_pkg::op_t           op;
      logic                             do_emit;
      //
      cntr_t                            cdat;
      logic                             byp_vld;
   } ucode_t;

   //
   ucode_t [4:1]              ucode_r;
   ucode_t [4:1]              ucode_nxt;
   //
   logic [4:1]                valid_r;
   logic [4:1]                valid_nxt;

   // ======================================================================= //
   //                                                                         //
   //  Combinatorial Logic                                                    //
   //                                                                         //
   // ======================================================================= //

   // ----------------------------------------------------------------------- //
   //
   always_comb
     begin : mem_PROC

        //
        mem_lkup         =   valid_r [1]
                           & ucode_r [1].op [multi_counter_pkg::OP_READ_B]
                         ;

        //
        mem_wrbk         =   valid_r [4]
                           & ucode_r [4].op [multi_counter_pkg::OP_WRITE_B]
                         ;

        //
        mem_collision    =    mem_lkup
                           &  mem_wrbk
                           & (ucode_r [1].id == ucode_r [4].id)
                         ;

        // Prt 0
        mem_prt1_en      =   mem_lkup
                           & (~mem_collision)
                         ;
        mem_prt1_wen     = 1'b0;
        mem_prt1_addr    = ucode_r [1].id;
        mem_prt1_din     = '0;

        // Prt 1
        mem_prt2_en      = mem_wrbk;
        mem_prt2_wen     = 1'b1;
        mem_prt2_addr    = ucode_r [4].id;
        mem_prt2_din     = ucode_r [4].cdat;

     end

   // ----------------------------------------------------------------------- //
   //
   always_comb
     begin : ucode_PROC

        //
        ucode_nxt [1] = 'x;
        ucode_nxt [1].id   = cntr_id;
        ucode_nxt [1].op   = cntr_op;
        ucode_nxt [1].cdat = cntr_dat;

        //
        ucode_nxt [2] = ucode_r [1];
        ucode_nxt [2].byp_vld = mem_collision;
        ucode_nxt [2].cdat    =   (ucode_r [1].op == multi_counter_pkg::OP_INIT)
                                ? ucode_r [1].cdat
                                : mem_prt2_din;
                              ;

        //
        ucode_nxt [3] = ucode_r [2];
        ucode_nxt [3].cdat = ucode_byp_2;

        //
        ucode_nxt [4] = ucode_r [3];
        ucode_nxt [4].do_emit =   valid_r[3]
                                & ucode_r [3].op [multi_counter_pkg::OP_OUTPUT_B]
                              ;
        ucode_nxt [4].cdat    = ucode_cdat_3;

     end

   // ----------------------------------------------------------------------- //
   //
   always_comb
     begin : fwd_PROC

        //
        fwd_dat_to_2 = (ucode_r [2].op == multi_counter_pkg::OP_INIT)
                     ;

        //
        fwd_4_to_2   =   valid_r [4]
                       & (ucode_r [2].id == ucode_r [4].id)
                       & (ucode_r [2].op != multi_counter_pkg::OP_INIT)
                     ;

        //
        fwd_3_to_2   =   valid_r [3]
                       & (ucode_r [2].id == ucode_r [3].id)
                       & (ucode_r [2].op != multi_counter_pkg::OP_INIT)
                     ;

        //
        fwd_byp_to_2 = ucode_r [2].byp_vld
                     ;

        // fwd_2
        case (1'b1)
          fwd_dat_to_2: ucode_byp_2 = ucode_r [2].cdat;
          fwd_3_to_2:   ucode_byp_2 = ucode_cdat_3;
          fwd_4_to_2:   ucode_byp_2 = ucode_r [4].cdat;
          fwd_byp_to_2: ucode_byp_2 = ucode_r [2].cdat;
          default:      ucode_byp_2 = mem_prt1_dout;
        endcase

        //
        fwd_4_to_3 =     valid_r [4]
                       & (ucode_r [3].id == ucode_r [4].id)
                       & (ucode_r [3].op != multi_counter_pkg::OP_INIT)
                     ;

        // fwd_3
        case (1'b1)
          fwd_4_to_3: ucode_byp_3 = ucode_r [4].cdat;
          default:    ucode_byp_3 = ucode_r [3].cdat;
        endcase

     end // block: fwd_PROC

   // ----------------------------------------------------------------------- //
   //
   always_comb
     begin : exe_PROC

        case (ucode_r [3].op)
          multi_counter_pkg::OP_INCR: ucode_cdat_3 = ucode_byp_3 + 'b1;
          multi_counter_pkg::OP_DECR: ucode_cdat_3 = ucode_byp_3 - 'b1;
          default:               ucode_cdat_3 = ucode_byp_3;
        endcase

     end

   // ----------------------------------------------------------------------- //
   //
   always_comb
     valid_nxt = {   valid_r [3:1]
                   , cntr_pass & (~cntr_op != multi_counter_pkg::OP_NOP)
                 }
               ;

   // ======================================================================= //
   //                                                                         //
   //  Sequential Logic                                                       //
   //                                                                         //
   // ======================================================================= //

   // ----------------------------------------------------------------------- //
   //
   always_ff @(posedge clk)
     begin : valid_reg_PROC
        if (rst == 1'b1)
          valid_r <= '0;
        else
          valid_r <= valid_nxt;
     end

   // ----------------------------------------------------------------------- //
   //
   always_ff @(posedge clk)
     begin : ucode_reg_PROC
        ucode_r <= ucode_nxt;
     end

   // ======================================================================= //
   //                                                                         //
   //  Instances                                                              //
   //                                                                         //
   // ======================================================================= //

   // ----------------------------------------------------------------------- //
   //
  dpsram #(.N(CNTRS_N), .W(CNTRS_W)) u_state_table_ram (
      //
        .clk1                  (clk)
      , .en1                   (mem_prt1_en)
      , .wen1                  (mem_prt1_wen)
      , .addr1                 (mem_prt1_addr)
      , .din1                  (mem_prt1_din)
      , .dout1                 (mem_prt1_dout)
      //
      , .clk2                  (clk)
      , .en2                   (mem_prt2_en)
      , .wen2                  (mem_prt2_wen)
      , .addr2                 (mem_prt2_addr)
      , .din2                  (mem_prt2_din)
      , .dout2                 (mem_prt2_dout)
   );

   // ======================================================================= //
   //                                                                         //
   //  Wires                                                                  //
   //                                                                         //
   // ======================================================================= //

   // ----------------------------------------------------------------------- //
   //
   assign status_pass_r = valid_r [4];
   assign status_qry_r = ucode_r [4].do_emit;
   assign status_id_r = ucode_r [4].id;
   assign status_dat_r = ucode_r [4].cdat;

endmodule // multi_counter

// Local Variables:
// verilog-typedef-regexp: "_t$"
// End:
