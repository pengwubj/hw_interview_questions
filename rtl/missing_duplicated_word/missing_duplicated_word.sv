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

module missing_duplicated_word #(parameter int W = 5, parameter int N = 17) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // State                                                                   //
   //                                                                         //
   //======================================================================== //

   //
   , input                                   state_upt
   , input     [$clog2(N)-1:0]               state_id
   , input     [W-1:0]                       state_dat

   //======================================================================== //
   //                                                                         //
   // Control                                                                 //
   //                                                                         //
   //======================================================================== //

   //
   , input                                   cntrl_start
   //
   , output logic                            cntrl_busy_r
   , output logic [W-1:0]                    cntrl_dat_r
);

  typedef logic [W-1:0] w_t;
  typedef logic [(W**2)-1:0] w_dec_t;
  typedef logic [$clog2(N)-1:0] id_t;
  typedef logic [N-1:0] n_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  // Asynchronous SRAM inference
  w_t                         state_r [N-1:0];
  //
  w_dec_t                     set_vector_r;
  w_dec_t                     set_vector_w;
  logic                       set_vector_en;
  //
  id_t                        rd_ptr_r;
  id_t                        rd_ptr_w;
  logic                       rd_ptr_en;
  //
  logic                       cntrl_busy_w;
  //
  w_t                         cntrl_dat_w;
  logic                       cntrl_dat_en;

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
      rd_ptr_en      = cntrl_start | (cntrl_busy_r);
      casez ({cntrl_start, cntrl_busy_r})
        2'b1_?:  rd_ptr_w  = '0;
        2'b0_1:  rd_ptr_w  = rd_ptr_r + 'b1;
        default: rd_ptr_w  = rd_ptr_r;
      endcase

      //
      cntrl_busy_w   = cntrl_start | (cntrl_busy_r & rd_ptr_w != id_t'(N));

      //
      set_vector_en      = cntrl_start | cntrl_busy_r;

      //
      casez ({cntrl_start, cntrl_busy_r})
        2'b1_?:  set_vector_w  = '0;
        2'b0_1:  set_vector_w [state_r [rd_ptr_r]] =
                    (~set_vector_r [state_r [rd_ptr_r]]);
        default: set_vector_w  = set_vector_r;
      endcase // casez ({cntrl_start, cntrl_busy_r})

      //
      cntrl_dat_en  = cntrl_busy_r & (~cntrl_busy_w);

      //
      cntrl_dat_w   = '0;
      for (int i = $bits(w_dec_t) - 1; i >= 0; i--)
        if (set_vector_w [i])
          cntrl_dat_w  = w_t'(i);

    end // block: cntrl_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      cntrl_busy_r <= 'b0;
    else
      cntrl_busy_r <= cntrl_busy_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (cntrl_dat_en)
      cntrl_dat_r <= cntrl_dat_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rd_ptr_en)
      rd_ptr_r <= rd_ptr_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (set_vector_en)
      set_vector_r <= set_vector_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (state_upt)
      state_r [state_id] <= state_dat;

endmodule // missing_duplicated_word
