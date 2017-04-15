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
   , input                                   in_start
   //
   , output                                  in_busy_r

   //======================================================================== //
   //                                                                         //
   // Reponse                                                                 //
   //                                                                         //
   //======================================================================== //

   , output logic                            resp_valid_r
   , output logic   [$clog2(W)-1:0]          resp_index_r

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

  //
  w_t                                vector_r;
  w_t                                vector_w;
  logic                              vector_en;
  //
  logic                              in_busy_w;
  logic                              zeros_present;
  //
  w_t                                first_zero;
  //
  logic                              resp_valid_w;
  idx_t                              resp_index_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      first_zero = ffs(~vector_r);
      
      //
      casez ({in_start, in_busy_r})
        2'b1?:   vector_w = in_vector;
        2'b01:   vector_w = vector_r | first_zero;
        default: vector_w = vector_r;
      endcase // casez ({in_start})

      //
      vector_en = (in_start | in_busy_r);

      //
      zeros_present = (vector_w != '1);
      
      //
      in_busy_w = in_start | (in_busy_r & zeros_present);

      //
      resp_valid_w = in_busy_r;
      resp_index_w = encode(first_zero);
      
    end
  
  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      resp_valid_r <= '0;
    else
      resp_valid_r <= resp_valid_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (resp_valid_w)
      resp_index_r <= resp_index_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      in_busy_r <= '0;
    else
      in_busy_r <= in_busy_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (vector_en)
      vector_r <= vector_w;

endmodule // zero_indices_slow
