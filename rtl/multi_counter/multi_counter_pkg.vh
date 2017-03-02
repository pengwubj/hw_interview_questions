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

`ifndef MULTI_COUNTER_PKG_VH
`define MULTI_COUNTER_PKG_VH

package multi_counter_pkg;

  // ------------------------------------------------------------------------ //
  //
  parameter int OP_OUTPUT_B = 4;
  //
  parameter int OP_READ_B = 3;
  //
  parameter int OP_WRITE_B = 2;

  // ------------------------------------------------------------------------ //
  // <output>_<read><write>_<op>
  //
  typedef enum  logic [4:0] {
                             // No Operation
                             OP_NOP  = 5'b0_00_00,

                             // Initialize CMD
                             OP_INIT = 5'b0_01_00,

                             // Increment CMD
                             OP_INCR = 5'b0_11_00,

                             // Decrement CMD
                             OP_DECR = 5'b0_11_01,

                             // Query CMD
                             OP_QRY  = 5'b1_10_00

                             } op_t /* verilator public */;

endpackage // multi_counter_pkg

`endif
