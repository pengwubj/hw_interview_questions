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

module fifo_multi_push #(parameter int W = 32, parameter int N = 8) (

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

   //
   , input                                   push_0
   , input     [W-1:0]                       push_0_data
   //
   , input                                   push_1
   , input     [W-1:0]                       push_1_data
   //
   , input                                   push_2
   , input     [W-1:0]                       push_2_data
   //
   , input                                   push_3
   , input     [W-1:0]                       push_3_data

   //======================================================================== //
   //                                                                         //
   // Pop Interface                                                           //
   //                                                                         //
   //======================================================================== //

   //
   , input  logic                            pop_0
   //
   , output logic                            pop_0_valid_r
   , output logic   [W-1:0]                  pop_0_data_r

   //======================================================================== //
   //                                                                         //
   // Status Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , output logic                            empty_r
   , output logic   [3:0]                    full_r
);

  //
  localparam int FIFO_N  = 4;
  typedef logic [FIFO_N-1:0] fifo_n_t;
  localparam int FIFO_DEC_N = $clog2(FIFO_N);
  typedef logic [FIFO_DEC_N-1:0] fifo_n_dec_t;
  typedef logic [FIFO_DEC_N:0] fifo_n_dec1_t;

  //
  typedef struct packed {
    logic                     b;
    logic [$clog2(N)-1:0]     mem;
  } fifo_ptr_t;
  localparam int FIFO_PTR_W = $bits(fifo_ptr_t);

  //
  typedef logic [W-1:0] w_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  logic                       empty_w;
  fifo_n_t                    full_w;
  //
  fifo_n_t                    push_idx_1h_r;
  fifo_n_t                    push_idx_1h_w;
  logic                       push_idx_1h_en;
  //
  fifo_n_t                    pop_idx_1h_r;
  fifo_n_t                    pop_idx_1h_w;
  logic                       pop_idx_1h_en;
  //
  fifo_n_t                    push_vec;
  fifo_n_dec1_t               push_vec_cnt;

  //
`define FIFO_MEM(__i)                                    \
  logic [W-1:0]               fifo_mem_``__i``_r [N-1:0]; \
  logic [W-1:0]               fifo_mem_``__i``_w; \
  logic                       fifo_mem_``__i``_en

  `FIFO_MEM(0);
  `FIFO_MEM(1);
  `FIFO_MEM(2);
  `FIFO_MEM(3);

`define FIFO_PTRS(__i)                               \
  logic                       fifo_``__i``_empty_w;  \
  logic                       fifo_``__i``_empty_r;  \
  logic                       fifo_``__i``_full_w;   \
  logic                       fifo_``__i``_full_r;   \
  fifo_ptr_t                  fifo_``__i``_rd_ptr_r; \
  fifo_ptr_t                  fifo_``__i``_rd_ptr_w; \
  logic                       fifo_``__i``_rd_ptr_en;\
  fifo_ptr_t                  fifo_``__i``_wr_ptr_r; \
  fifo_ptr_t                  fifo_``__i``_wr_ptr_w; \
  logic                       fifo_``__i``_wr_ptr_en

  `FIFO_PTRS(0);
  `FIFO_PTRS(1);
  `FIFO_PTRS(2);
  `FIFO_PTRS(3);

`undef FIFO_PTRS

  //
  w_t                         pop_0_data_w;
  //
  logic                       pop_0_valid_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : push_PROC

      //
      push_vec        = '0;
      push_vec [0]    = push_0;
      push_vec [1]    = push_1;
      push_vec [2]    = push_2;
      push_vec [3]    = push_3;

      //
      push_idx_1h_en  = (|push_vec);

      case (push_idx_1h_r)
        4'b0001: begin
          //
          fifo_mem_0_en  = push_0;
          fifo_mem_0_w   = push_0_data;
          //
          fifo_mem_1_en  = push_1;
          fifo_mem_1_w   = push_1_data;
          //
          fifo_mem_2_en  = push_2;
          fifo_mem_2_w   = push_2_data;
          //
          fifo_mem_3_en  = push_3;
          fifo_mem_3_w   = push_3_data;
        end
        4'b0010: begin
          //
          fifo_mem_0_en  = push_3;
          fifo_mem_0_w   = push_3_data;
          //
          fifo_mem_1_en  = push_0;
          fifo_mem_1_w   = push_0_data;
          //
          fifo_mem_2_en  = push_1;
          fifo_mem_2_w   = push_1_data;
          //
          fifo_mem_3_en  = push_2;
          fifo_mem_3_w   = push_2_data;
        end
        4'b0100: begin
          //
          fifo_mem_0_en  = push_2;
          fifo_mem_0_w   = push_2_data;
          //
          fifo_mem_1_en  = push_3;
          fifo_mem_1_w   = push_3_data;
          //
          fifo_mem_2_en  = push_0;
          fifo_mem_2_w   = push_0_data;
          //
          fifo_mem_3_en  = push_1;
          fifo_mem_3_w   = push_1_data;
        end
        4'b1000: begin
          //
          fifo_mem_0_en  = push_1;
          fifo_mem_0_w   = push_1_data;
          //
          fifo_mem_1_en  = push_2;
          fifo_mem_1_w   = push_2_data;
          //
          fifo_mem_2_en  = push_3;
          fifo_mem_2_w   = push_3_data;
          //
          fifo_mem_3_en  = push_0;
          fifo_mem_3_w   = push_0_data;
        end
        default: begin
          //
          fifo_mem_0_en  = 'x;
          fifo_mem_0_w   = 'x;
          //
          fifo_mem_1_en  = 'x;
          fifo_mem_1_w   = 'x;
          //
          fifo_mem_2_en  = 'x;
          fifo_mem_2_w   = 'x;
          //
          fifo_mem_3_en  = 'x;
          fifo_mem_3_w   = 'x;
        end
      endcase

      //
      pop_idx_1h_en   = pop_0 & (~empty_r);

      //
      unique case (pop_idx_1h_r)
        4'b0001: pop_0_data_w  = fifo_mem_0_r [fifo_0_rd_ptr_r.mem];
        4'b0010: pop_0_data_w  = fifo_mem_1_r [fifo_1_rd_ptr_r.mem];
        4'b0100: pop_0_data_w  = fifo_mem_2_r [fifo_2_rd_ptr_r.mem];
        4'b1000: pop_0_data_w  = fifo_mem_3_r [fifo_3_rd_ptr_r.mem];
        default: pop_0_data_w  = 'x;
      endcase

`define FIFO_PTRS(__i)\
      fifo_``__i``_rd_ptr_en = pop_idx_1h_r [__i] & pop_idx_1h_en;\
      fifo_``__i``_wr_ptr_en = fifo_mem_``__i``_en;\
      fifo_``__i``_rd_ptr_w =\
        fifo_``__i``_rd_ptr_en ? fifo_``__i``_rd_ptr_r + 'b1 :\
                                 fifo_``__i``_rd_ptr_r;\
      fifo_``__i``_wr_ptr_w =\
        fifo_``__i``_wr_ptr_en ? fifo_``__i``_wr_ptr_r + 'b1 :\
                                 fifo_``__i``_wr_ptr_r;\
      fifo_``__i``_full_w =\
         (fifo_``__i``_rd_ptr_w.b ^ fifo_``__i``_wr_ptr_w.b) &\
         (fifo_``__i``_rd_ptr_w.mem == fifo_``__i``_wr_ptr_w.mem);\
      fifo_``__i``_empty_w = (fifo_``__i``_rd_ptr_w == fifo_``__i``_wr_ptr_w)

      //
      `FIFO_PTRS(0);
      `FIFO_PTRS(1);
      `FIFO_PTRS(2);
      `FIFO_PTRS(3);
`undef FIFO_PTRS

       //
       pop_0_valid_w = pop_idx_1h_en;

    end // block: push_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      case (push_idx_1h_w)
        4'b0001: full_w = {   fifo_3_full_w
                            , fifo_2_full_w
                            , fifo_1_full_w
                            , fifo_0_full_w
                          };
        4'b0010: full_w = {   fifo_0_full_w
                            , fifo_3_full_w
                            , fifo_2_full_w
                            , fifo_1_full_w
                          };
        4'b0100: full_w = {   fifo_1_full_w
                            , fifo_0_full_w
                            , fifo_3_full_w
                            , fifo_2_full_w
                          };
        4'b1000: full_w = {   fifo_2_full_w
                            , fifo_1_full_w
                            , fifo_0_full_w
                            , fifo_3_full_w
                          };
        default: full_w = 'x;
      endcase

      //
      case (pop_idx_1h_w)
        4'b0001: empty_w = fifo_0_empty_w;
        4'b0010: empty_w = fifo_1_empty_w;
        4'b0100: empty_w = fifo_2_empty_w;
        4'b1000: empty_w = fifo_3_empty_w;
        default: empty_w = 'x;
      endcase

    end // block: push_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
`define FIFO_PTRS(__i)\
  always_ff @(posedge clk)\
    if (rst)\
      fifo_``__i``_rd_ptr_r <= '0;\
    else if (fifo_``__i``_rd_ptr_en)\
      fifo_``__i``_rd_ptr_r <= fifo_``__i``_rd_ptr_w;\
  always_ff @(posedge clk)\
    if (rst)\
      fifo_``__i``_wr_ptr_r <= '0;\
    else if (fifo_``__i``_wr_ptr_en)\
      fifo_``__i``_wr_ptr_r <= fifo_``__i``_wr_ptr_w;\
  always_ff @(posedge clk)\
    fifo_``__i``_empty_r <= fifo_``__i``_empty_w;\
  always_ff @(posedge clk)\
    fifo_``__i``_full_r <= fifo_``__i``_full_w

  `FIFO_PTRS(0);
  `FIFO_PTRS(1);
  `FIFO_PTRS(2);
  `FIFO_PTRS(3);

`undef FIFO_PTRS

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      push_idx_1h_r <= 'b1;
    else if (push_idx_1h_en)
      push_idx_1h_r <= push_idx_1h_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      pop_idx_1h_r <= 'b1;
    else if (pop_idx_1h_en)
      pop_idx_1h_r <= pop_idx_1h_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      empty_r <= '1;
    else
      empty_r <= empty_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      full_r <= '0;
    else
      full_r <= full_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    pop_0_data_r <= pop_0_data_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
       pop_0_valid_r <= '0;
    else
       pop_0_valid_r <= pop_0_valid_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    begin
      if (fifo_mem_0_en)
        fifo_mem_0_r [fifo_0_wr_ptr_r.mem] <= fifo_mem_0_w;
      if (fifo_mem_1_en)
        fifo_mem_1_r [fifo_1_wr_ptr_r.mem] <= fifo_mem_1_w;
      if (fifo_mem_2_en)
        fifo_mem_2_r [fifo_2_wr_ptr_r.mem] <= fifo_mem_2_w;
      if (fifo_mem_3_en)
        fifo_mem_3_r [fifo_3_wr_ptr_r.mem] <= fifo_mem_3_w;
    end

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  popcnt #(.W(FIFO_N)) u_popcnt (
    //
      .x                 (push_vec           )
    //
    , .y                 (push_vec_cnt       )
  );

  // ------------------------------------------------------------------------ //
  //
  rotate #(.W(FIFO_N)) u_rotate_push (
    //
      .x                 (push_idx_1h_r                )
    , .n                 (fifo_n_dec_t'(push_vec_cnt)  )
    //
    , .y                 (push_idx_1h_w                )
  );

  // ------------------------------------------------------------------------ //
  //
  rotate #(.W(FIFO_N)) u_rotate_pop (
    //
      .x                 (pop_idx_1h_r       )
    , .n                 ('b1                )
    //
    , .y                 (pop_idx_1h_w       )
  );

endmodule // fifo_multi_push
