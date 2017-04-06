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

module fifo_ptr #(
     parameter integer W = 32
   , parameter integer N = 16

   , parameter logic HAS_REPLAY = 0

   , parameter logic HAS_FLUSH = 0
) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Push Interface                                                          //
   //                                                                         //
   //======================================================================== //

   , input                                   push
   , input [W-1:0]                           push_data

   //======================================================================== //
   //                                                                         //
   // Pop Interface                                                           //
   //                                                                         //
   //======================================================================== //

   , input                                   pop

   , output logic [W-1:0]                    pop_data

   //======================================================================== //
   //                                                                         //
   // Control/Status Interface                                                //
   //                                                                         //
   //======================================================================== //

   , input                                   flush
   , input                                   commit
   , input                                   replay
   //
   , output logic                            empty_r
   , output logic                            full_r
);

  localparam ADDR_BITS = $clog2(N);
  localparam PTR_BITS  = ADDR_BITS + 1;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  logic                                 empty_w;
  logic                                 full_w;
  //
  logic [PTR_BITS - 1:0]                arch_rptr_r;
  logic [PTR_BITS - 1:0]                arch_rptr_w;
  logic                                 arch_rptr_en;
  //
  logic [PTR_BITS - 1:0]                spec_rptr_r;
  logic [PTR_BITS - 1:0]                spec_rptr_w;
  logic                                 spec_rptr_en;
  //
  logic [PTR_BITS - 1:0]                arch_wptr_r;
  logic [PTR_BITS - 1:0]                arch_wptr_w;
  logic                                 arch_wptr_en;
  //
  logic [W - 1:0]                       mem_rdata;
  logic                                 mem_ren;
  logic [ADDR_BITS-1:0]                 mem_ra;
  logic                                 mem_wen;
  logic [W - 1:0]                       mem_wdata;
  logic [ADDR_BITS-1:0]                 mem_wa;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : cntrl_PROC

      //
      arch_wptr_en =   rst
                     | push
                     | (HAS_FLUSH & flush)
                   ;

      //
      casez ({rst, HAS_FLUSH, flush, push})
        4'b1_??_?,
        4'b0_11_?: arch_wptr_w  = '0;
        4'b0_10_1,
        4'b0_0?_1: arch_wptr_w  = arch_wptr_r + 'b1;
        default:   arch_wptr_w  = arch_wptr_r;
      endcase

      //
      arch_rptr_en =   rst
                     | ((~HAS_REPLAY) & pop   )
                     | (  HAS_REPLAY  & commit)
                   ;

      //
      casez ({rst, HAS_REPLAY, commit, pop})
        4'b1_??_?: arch_rptr_w = '0;
        4'b0_11_?,
        4'b0_0?_1: arch_rptr_w = arch_rptr_r + 'b1;
        default:   arch_rptr_w = arch_rptr_r;
      endcase

    end // block: cntrl_PROC

  // ------------------------------------------------------------------------ //
  //
  generate if (HAS_REPLAY)

    always_comb
      begin : cntrl_replay_PROC

        //
        spec_rptr_en  = (rst | pop | replay);

        //
        casez ({rst, replay, pop})
          3'b1_?_?:  spec_rptr_w  = '0;
          3'b0_1_?:  spec_rptr_w  = arch_rptr_r;
          3'b0_0_1:  spec_rptr_w  = spec_rptr_r + 'b1;
          default:   spec_rptr_w  = spec_rptr_r;
        endcase // casez ({rst})

      end // block: cntrl_replay_PROC

  endgenerate

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : status_PROC

       //
       case (HAS_REPLAY)
         1'b0: empty_w = rst | (arch_rptr_w == arch_wptr_w);
         1'b1: empty_w = rst | (spec_rptr_w == arch_wptr_w);
       endcase

       //
       full_w =    (~rst)
                 & (    arch_rptr_w [ADDR_BITS-1:0]
                     == arch_wptr_w [ADDR_BITS-1:0]
                   )
                 & (    arch_rptr_w [ADDR_BITS]
                      ^ arch_wptr_w [ADDR_BITS]
                   )
              ;

    end // block: status_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : mem_PROC

      //
      mem_wdata   = push_data;

      //
      mem_ra      =   HAS_REPLAY
                    ? spec_rptr_r [ADDR_BITS-1:0]
                    : arch_rptr_r [ADDR_BITS-1:0]
                  ;

      //
      mem_ren     = pop;

      //
      mem_wa      = arch_wptr_r [ADDR_BITS-1:0];

      //
      mem_wen     = push & (~full_r);

      //
      pop_data    = mem_rdata;

    end // block: mem_PROC


  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  always_ff @(posedge clk)
    begin : status_reg_PROC
       empty_r <= empty_w;
       full_r <= full_w;
    end

  always_ff @(posedge clk)
    begin : arch_ptr_reg_PROC
      if (arch_wptr_en)
        arch_wptr_r <= arch_wptr_w;
      if (arch_rptr_en)
        arch_rptr_r <= arch_rptr_w;
    end

  generate if (HAS_REPLAY)

    always_ff @(posedge clk)
      begin : spec_ptr_reg_PROC
        if (spec_rptr_en)
          spec_rptr_r <= spec_rptr_w;
      end

  endgenerate


  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  rf #(.W(W), .N(N)) u_mem (
    //
      .clk               (clk                )
    , .rst               (rst                )
    //
    , .ra                (mem_ra             )
    , .ren               (mem_ren            )
    , .rdata             (mem_rdata          )
    //
    , .wa                (mem_wa             )
    , .wen               (mem_wen            )
    , .wdata             (mem_wdata          )
  );

endmodule // fifo
