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

module using_full_adders (output logic fail,
                          input logic [6:0] x,
                          input logic       clk,
                          input logic       rst);


  function [1:0] full_adder (input logic a, input logic b, input logic cin);
    logic [1:0] ret  = '0;
    ret [0]          = ^{a, b, cin};
    ret [1]          = (a&b) | (cin & (a | b));
    return ret;
  endfunction // full_adder

  typedef logic [2:0] w_t;
  w_t expected;
  w_t solution_0;
  w_t solution_1;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      fail      = '0;

      //
      expected  = $countones(x);

      // Solution 0 (CSA)

      //
      begin

        logic [2:0] s0_a;
        logic [2:0] s0_b;
        logic       cout;

        // CSA reduction 1
        //
        s0_a                    = '0;
        s0_a [1:0]              = full_adder (x [2], x [1], x [0]);

        // CSA reduction 2
        //
        s0_b                    = '0;
        s0_b [1:0]              = full_adder (x [5], x [4], x [3]);

        // Ripple Carry Adder
        //
        {cout, solution_0 [0]}  = full_adder (s0_a [0], s0_b [0], 1'b0);
        {cout, solution_0 [1]}  = full_adder (s0_a [1], s0_b [1], cout);
        {cout, solution_0 [2]}  = full_adder (s0_a [2], s0_b [2], cout);

      end

      // Solution 1 (Minimal CSA using Cin - 4 FA)
      //
      begin

        logic [1:0] s1_a  = full_adder (x [2], x[1], x[0]);
        logic [1:0] s1_b  = full_adder (x [5], x[4], x[3]);
        logic [1:0] s1_c  = full_adder (s1_a [0], s1_b [0], x [6]);
        logic [1:0] s1_d  = full_adder (s1_a [1], s1_b [1], s1_c [1]);

        solution_1        = {s1_d, s1_c [0]};
      end

      //
      fail     |= (expected != solution_0);
      fail     |= (expected != solution_1);

    end


endmodule
