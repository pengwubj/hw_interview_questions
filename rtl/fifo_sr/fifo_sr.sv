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

module fifo_sr #(
     parameter integer W = 32
   , parameter integer N = 16
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
   //
   , output logic                            pop_data_valid
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

  typedef logic [W-1:0]       w_t;
  typedef logic [N-1:0]       n_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  n_t                         wr_ptr_1h_r;
  n_t                         wr_ptr_1h_w;
  n_t                         wr_ptr_1h_shift;
  logic                       wr_ptr_1h_en;
  //
  n_t                         rd_ptr_1h_r;
  n_t                         rd_ptr_1h_w;
  n_t                         rd_ptr_1h_shift;
  logic                       rd_ptr_1h_en;
  //
  logic                       empty_w;
  logic                       full_w;
  //
  n_t                         mem_en;
  w_t                         mem_r [N-1:0];
  w_t                         mem_w;
  //
  logic                       pop_data_valid;

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
      pop_data_valid    = pop;

      //
      rd_ptr_1h_en      = pop;
      rd_ptr_1h_w       = pop ? rd_ptr_1h_shift : rd_ptr_1h_r;

      //
      wr_ptr_1h_en      = push;
      wr_ptr_1h_w       = push ? wr_ptr_1h_shift : wr_ptr_1h_r;

      //
      case ({full_r})
        1'b1:    full_w   = (~pop);
        default: full_w   = (wr_ptr_1h_r != rd_ptr_1h_r) &&
                            (wr_ptr_1h_w == rd_ptr_1h_r);
      endcase

      //
      case ({empty_r})
        1'b1:    empty_w  = (~push);
        default: empty_w  = (wr_ptr_1h_r != rd_ptr_1h_r) &&
                            (wr_ptr_1h_r == rd_ptr_1h_w);
      endcase // case ({empty_r})

      //
      mem_en            = push ? wr_ptr_1h_r : '0;
      mem_w             = push_data;

      //
      pop_data          = '0;
      for (int i = 0; i < N; i++)
        pop_data |= ({W{rd_ptr_1h_r[i]}} & mem_r [i]);

    end // block: cntrl_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  rotate #(.W(N)) u_rotate_wr (.x(wr_ptr_1h_r), .n('b1), .y(wr_ptr_1h_shift));
  rotate #(.W(N)) u_rotate_rd (.x(rd_ptr_1h_r), .n('b1), .y(rd_ptr_1h_shift));

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      empty_r <= 'b1;
    else
      empty_r <= empty_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      full_r <= 'b0;
    else
      full_r <= full_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      wr_ptr_1h_r <= 'b1;
    else if (wr_ptr_1h_en)
      wr_ptr_1h_r <= wr_ptr_1h_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      rd_ptr_1h_r <= 'b1;
    else if (rd_ptr_1h_en)
      rd_ptr_1h_r <= rd_ptr_1h_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk) begin

    for (int i = 0; i < N; i++)
      if (mem_en [i])
        mem_r [i] <= mem_w;

  end

endmodule // fifo_sr
