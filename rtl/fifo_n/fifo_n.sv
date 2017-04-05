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

module fifo_n #(parameter int N = 8,
                parameter int VQ_N = 8,
                parameter int W = 32) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

   //
     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Push Interface                                                          //
   //                                                                         //
   //======================================================================== //

   //
   , input                                   push
   , input     [$clog2(VQ_N)-1:0]            push_vq
   , input     [W-1:0]                       push_data

   //======================================================================== //
   //                                                                         //
   // Pop Interface                                                           //
   //                                                                         //
   //======================================================================== //

   //
   , input                                   pop
   , input        [$clog2(VQ_N)-1:0]         pop_vq
   //
   , output logic                            pop_data_valid_r
   , output logic [$clog2(VQ_N)-1:0]         pop_data_vq_r
   , output logic [W-1:0]                    pop_data_w

   //======================================================================== //
   //                                                                         //
   // Status Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , output logic [VQ_N-1:0]                 empty_r
   , output logic [VQ_N-1:0]                 full_r
);

  //
  typedef logic [W-1:0] w_t;
  localparam int FIFO_N = VQ_N * N;

  localparam int VQ_W = $clog2(VQ_N);
  typedef logic [VQ_W-1:0] vq_t;
  
  localparam int FIFO_MEM_PTR_W = $clog2(N);
  typedef logic [FIFO_MEM_PTR_W-1:0] fifo_mem_ptr_t;

  typedef logic [VQ_N-1:0]           vq_d_t;
    
  typedef struct packed {
    logic          dis;
    fifo_mem_ptr_t mem;
  } fifo_ptr_t;

  typedef struct packed {
    logic        full;
    logic        empty;
    fifo_ptr_t   rd_ptr;
    fifo_ptr_t   wr_ptr;
  } fifo_state_t;

  typedef struct packed {
    vq_t           vq;
    fifo_mem_ptr_t ptr;
  } mem_addr_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  mem_addr_t                  rd_addr;
  mem_addr_t                  wr_addr;
  //
  fifo_state_t                fifo_state_r [VQ_N-1:0];
  fifo_state_t                fifo_state_w [VQ_N-1:0];
  vq_d_t                      fifo_state_en;
  //
  logic                       en1;
  logic                       en2;
  //
  vq_t                        pop_data_vq_w;
  logic                       pop_data_valid_w;

  function logic is_empty (fifo_state_t upt);
    return (upt.rd_ptr == upt.wr_ptr);
  endfunction

  function logic is_full (fifo_state_t upt);
    return (upt.rd_ptr.dis ^ upt.wr_ptr.dis) &
      (upt.rd_ptr.mem == upt.wr_ptr.mem);
  endfunction

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : upt_PROC

      for (int i = 0; i < VQ_N; i++) begin

        // Defaults
        fifo_state_w [i] = fifo_state_r [i];

        if (push && (push_vq == vq_t'(i)))
          fifo_state_w [i].wr_ptr = fifo_state_r [i].wr_ptr + 'b1;

        if (pop && (pop_vq == vq_t'(i)))
          fifo_state_w [i].rd_ptr = fifo_state_r [i].rd_ptr + 'b1;

        fifo_state_w [i].empty = is_empty(fifo_state_w [i]);
        fifo_state_w [i].full = is_full(fifo_state_w [i]);

      end

      fifo_state_en = '0;
      if (push)
        fifo_state_en |= (1 << push_vq);
      if (pop)
        fifo_state_en |= (1 << pop_vq);

      rd_addr = { pop_vq, fifo_state_r [pop_vq].rd_ptr.mem};
      wr_addr = { push_vq, fifo_state_r [push_vq].wr_ptr.mem};

      en1 = push;
      en2 = pop;

      for (int i = 0; i < VQ_N; i++) begin
        empty_r [i] = fifo_state_r [i].empty;
        full_r [i] = fifo_state_r [i].full;
      end

      //
      pop_data_vq_w = pop_vq;
      pop_data_valid_w = pop;
      
    end // block: upt_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      pop_data_valid_r <= 'b0;
    else
      pop_data_valid_r  <= pop_data_valid_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    pop_data_vq_r <= pop_data_vq_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      begin
        for (int i = 0; i < VQ_N; i++)
          fifo_state_r [i] <= '{'b0, 'b1, 'b0, 'b0};
      end
    else
      begin
        for (int i = 0; i < VQ_N; i++)
          if (fifo_state_en [i])
            fifo_state_r [i] <= fifo_state_w [i];
      end
      

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  dpsrams #(.W(W), .N(FIFO_N)) u_fifo_mem (
    //
      .clk                    (clk                )
    // 
    , .en1                    (en1                )
    , .wen1                   (1'b1               )
    , .addr1                  (wr_addr            )
    , .din1                   (push_data          )
    , .dout1                  (                   )
    //
    , .en2                    (en2                )
    , .wen2                   (1'b0               )
    , .addr2                  (rd_addr            )
    , .din2                   (                   )
    , .dout2                  (pop_data_w         )
  );                          

endmodule
