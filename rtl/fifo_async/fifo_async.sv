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

module fifo_async #(
     parameter integer W = 32
   , parameter integer N = 16
) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   wclk
   , input                                   wrst
   //
   , input                                   rclk
   , input                                   rrst

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

   //
   , output logic                            empty_r
   , output logic                            full_r
);

  localparam ADDR_BITS = $clog2(N);
  localparam PTR_BITS  = ADDR_BITS + 1;
`define GRAY_W PTR_BITS
`include "gray.vh"
`undef GRAY_W

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  logic [PTR_BITS-1:0]                  rptr_w;
  logic [PTR_BITS-1:0]                  rptr_r;
  logic                                 rptr_en;
  //
  logic [PTR_BITS-1:0]                  wptr_w;
  logic [PTR_BITS-1:0]                  wptr_r;
  logic                                 wptr_en;
  //
  logic                                 uarch_empty_w;
  logic                                 uarch_empty_r;
  //
  logic                                 full_w;
  //
  logic [PTR_BITS-1:0]                  wptr_gray_w;
  logic [PTR_BITS-1:0]                  wptr_gray_r;
  //
  logic [PTR_BITS-1:0]                  rptr_gray_w;
  logic [PTR_BITS-1:0]                  rptr_gray_r;
  //
  logic [PTR_BITS-1:0]                  wptr_rsync;
  logic [PTR_BITS-1:0]                  rptr_wsync;
  //
  logic [PTR_BITS-1:0]                  wptr_gray_rsync_r;
  logic [PTR_BITS-1:0]                  rptr_gray_wsync_r;
  //
  logic                                 mem_en0;
  logic                                 mem_en1;
  //
  logic [W-1:0]                         read_pipe_mem_rdata;
  logic                                 read_pipe_mem_ren;
  logic                                 read_pipe_read_en;
  logic                                 read_pipe_read_adv;
  logic                                 read_pipe_out_valid_r;
  //
  logic [ADDR_BITS-1:0]                 mem_addr0;
  logic [ADDR_BITS-1:0]                 mem_addr1;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : async_cntrl_PROC

      //
      casez ({wrst, push})
        2'b1_?:  wptr_w = '0;
        2'b0_1:  wptr_w = wptr_r + 'b1;
        default: wptr_w = wptr_r;
      endcase // case ({wrst, push})

      //
      wptr_en        = wrst | push;

      //
      casez ({rrst, read_pipe_read_adv})
        2'b1_?:  rptr_w = '0;
        2'b0_1:  rptr_w = rptr_r + 'b1;
        default: rptr_w = rptr_r;
      endcase // casez ({rrst, read_pipe_read_adv})

      //
      rptr_en        = rrst | read_pipe_read_adv;

      //
      wptr_gray_w    = binary_to_gray(wptr_r);

      //
      rptr_gray_w    = binary_to_gray(rptr_r);

      //
      wptr_rsync     = gray_to_binary(wptr_gray_rsync_r);

      //
      rptr_wsync     = gray_to_binary(rptr_gray_wsync_r);

      //
      mem_en0        = (~full_r) & push;

      //
      mem_en1        = '0;

      //
      uarch_empty_w  = rrst | (wptr_rsync ==  rptr_w);

      //
      casez (wrst)
        1'b0:    full_w =   (    wptr_w [PTR_BITS-1]
                               ^ rptr_wsync [PTR_BITS-1]
                            )
                          & (    wptr_w [ADDR_BITS-1:0]
                              == rptr_wsync [ADDR_BITS-1:0]
                            )
                        ;
        default: full_w = '0;
      endcase

      //
      mem_addr0  = wptr_r [ADDR_BITS-1:0];

      //
      mem_addr1  = rptr_r [ADDR_BITS-1:0];

    end // block: async_cntrl_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : read_pipe_PROC

      //
      read_pipe_read_en  = (~uarch_empty_r);

      //
      empty_r            = (~read_pipe_out_valid_r);

    end // block: read_pipe_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge wclk)
    wptr_gray_r <= wptr_gray_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge rclk)
    rptr_gray_r <= rptr_gray_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge rclk)
    uarch_empty_r <= uarch_empty_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge wclk)
    full_r <= full_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge wclk)
    if (wptr_en)
      wptr_r <= wptr_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge rclk)
    if (rptr_en)
      rptr_r <= rptr_w;

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  sync_ff #(.W(PTR_BITS)) u_sync_rptr (
    //
      .clk               (wclk               )
    , .rst               (wrst               )
    //
    , .d                 (rptr_gray_r        )
    , .q                 (rptr_gray_wsync_r  )
  );

  // ------------------------------------------------------------------------ //
  //
  sync_ff #(.W(PTR_BITS)) u_sync_wptr (
    //
      .clk               (rclk               )
    , .rst               (rrst               )
    //
    , .d                 (wptr_gray_r        )
    , .q                 (wptr_gray_rsync_r  )
  );

  // ------------------------------------------------------------------------ //
  //
  dpsram #(.W(W), .N(N)) u_mem (
    //
      .clk1              (wclk               )
    //
    , .en1               (mem_en0            )
    , .wen1              (1'b1               )
    , .addr1             (mem_addr0          )
    , .din1              (push_data          )
    , .dout1             ()
    //
    , .clk2              (rclk               )
    //
    , .en2               (read_pipe_mem_ren  )
    , .wen2              (1'b0               )
    , .addr2             (mem_addr1          )
    , .din2              ('0                 )
    , .dout2             (read_pipe_mem_rdata)
  );

  // ------------------------------------------------------------------------ //
  //
  mem_egress_pipe #(.W(W)) u_read_pipe (
    //
      .clk               (rclk                 )
    , .rst               (rrst                 )
    //
    , .read_en           (read_pipe_read_en    )
    , .read_adv          (read_pipe_read_adv   )
    //
    , .mem_rdata         (read_pipe_mem_rdata  )
    , .mem_ren           (read_pipe_mem_ren    )
    //
    , .out_accept        (pop                  )
    , .out_valid_r       (read_pipe_out_valid_r)
    , .out_data_r        (pop_data             )
  );

endmodule // fifo_async
