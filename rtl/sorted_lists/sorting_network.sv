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

`include "sorted_lists_pkg.vh"

module sorting_network
(
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //
   , input                                   unsorted_valid
   , input  sorted_lists_pkg::table_state_t  unsorted
   //
   , output sorted_lists_pkg::table_state_t  sorted_r
);
  import sorted_lists_pkg::*;

  //
  function table_state_t compare_and_swap (input table_state_t x, int a, int b);
    begin
      table_state_t r = x;
      key_t l_key = r.e[a].key;
      key_t r_key = r.e[b].key;
      if (l_key < r_key) begin
        entry_t e  = r.e[a];
        r.e[a]     = r.e[b];
        r.e[b]     = e;
      end
      return r;
    end
  endfunction // table_state_t

  function table_state_t zero_invalid(input table_state_t x);
    begin
      table_state_t r  = x;
      for (int i = 0; i < 4; i++)
        if (!r.e[i].vld)
          r.e[i].key = 0;
      return r;
    end
  endfunction // zero_invalid


  //
  logic [2:0]                         valid_r;
  logic [2:0]                         valid_w;
  //
  table_state_t                       s0_r, s0_w;
  table_state_t                       s1_r, s1_w;
  table_state_t                       s2_r, s2_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : sort_PROC

      //
      valid_w   = {valid_r [1:0], unsorted_valid};

      // This is a unsorting network. For an unordered input, the sequence is
      // sorted based upon decreasing value of key. Therefore, at the output of
      // the module, the 0'th entry is the largest with entries thereafter
      // decreasing.
      //
      // zero_invalid: This is a bit of a hack. For invalid inputs, the key is
      // reset to zero (the smallest value by definition). This is to explicitly
      // disallow large values of KEYS for invalid entries from being considered
      // at the output. If, for some reason, this zero value is largest. The
      // list is by definition empty, therefore this can be easily detected by
      // considering the valid bits.

      // S0
      //
      s0_w      = zero_invalid(unsorted);
      s0_w      = compare_and_swap(s0_w, 1, 3);
      s0_w      = compare_and_swap(s0_w, 0, 2);

      // S1
      //
      s1_w      = s0_r;
      s1_w      = compare_and_swap(s1_w, 2, 3);
      s1_w      = compare_and_swap(s1_w, 0, 1);

      // S2
      //
      s2_w      = s1_r;
      s2_w      = compare_and_swap(s2_w, 1, 2);

      //
      sorted_r  = s2_r;

    end // block: sort_PROC

  // ======================================================================== //
  //                                                                          //
  // Sequential Logic                                                         //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      valid_r <= '0;
    else
      valid_r <= valid_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    begin
      if (valid_w [0])
        s0_r <= s0_w;
      if (valid_w [1])
        s1_r <= s1_w;
      if (valid_w [2])
        s2_r <= s2_w;
    end

endmodule // sorting_network
