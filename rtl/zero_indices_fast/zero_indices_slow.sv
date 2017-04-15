//========================================================================== //
// Copyright (c) 2017, Stephen Henry
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

`define HAS_FINAL

module zero_indices_slow #(parameter int W = 32) (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst


   //======================================================================== //
   //                                                                         //
   // In                                                                      //
   //                                                                         //
   //======================================================================== //

   , input          [W-1:0]                  in_vector
   , input                                   in_load

   //======================================================================== //
   //                                                                         //
   // Cntrl                                                                   //
   //                                                                         //
   //======================================================================== //

   //
   , input                                   en
   //
   , output                                  done_r
`ifdef HAS_FINAL
   , output logic                            final_r
`endif

   //======================================================================== //
   //                                                                         //
   // Reponse                                                                 //
   //                                                                         //
   //======================================================================== //

   , output logic                            resp_valid
   , output logic   [$clog2(W)-1:0]          resp_index

);

  typedef logic [W-1:0] w_t;
  typedef logic [$clog2(W)-1:0] idx_t;

  function w_t ffs (w_t x);
    begin
      w_t w = '0;
      for (int i = W - 1; i >= 0; i--)
        if (x [i])
          w = 1 << i;
      return w;
    end
  endfunction // ffs

  function idx_t encode (w_t x);
    begin
      idx_t idx = 0;
      for (int i = W - 1; i >= 0; i--)
        if (x [i])
          idx = idx_t'(i);
      return idx;
    end
  endfunction // encode
`ifdef HAS_FINAL
  
  function logic is_1h (w_t x);
    begin
      w_t n_x = (~x);
      return (n_x & (n_x - 'b1)) == '0 ? 1'b1 : 1'b0;
    end
  endfunction // is_1h
`endif
  //
  w_t                                vector_r;
  w_t                                vector_w;
  logic                              vector_en;
  //
  logic                              busy_r;
  logic                              busy_w;
  logic                              busy_en;
  //
  logic                              done_r;
  logic                              done_w;
`ifdef HAS_FINAL
  //
  logic                              final_w;
`endif
  //
  logic                              zeros_present;
  //
  w_t                                first_zero;
  //
  logic                              resp_valid;
  idx_t                              resp_index;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb first_zero = ffs(~vector_r);
  
  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin
      
      //
      casez ({in_load, en})
        2'b1?:   vector_w = in_vector;
        2'b01:   vector_w = vector_r | first_zero;
        default: vector_w = vector_r;
      endcase // casez ({in_start, en})

      //
      vector_en = (in_load | en);

      //
      zeros_present = (vector_w != '1);
      
      //
      busy_w = in_load | busy_r & zeros_present;

      //
      busy_en = in_load | en;

      //
      done_w  = busy_r & (vector_w == '1);

`ifdef HAS_FINAL
      //
      final_w = busy_w & is_1h(vector_w);
`endif

    end

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : resp_PROC

      //
      resp_valid = busy_r & (vector_r != '1);
      resp_index = encode(first_zero);

    end // block: resp_PROC
  
  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      busy_r <= '0;
    else if (busy_en)
      busy_r <= busy_w;
`ifdef HAS_FINAL  

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      final_r <= '0;
    else
      final_r <= final_w;
`endif  

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      done_r <= '0;
    else
      done_r <= done_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (vector_en)
      vector_r <= vector_w;

endmodule // zero_indices_slow
