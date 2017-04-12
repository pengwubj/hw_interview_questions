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

#include <libtb.h>
//
#include "Vsorted_lists.h"

#define PORTS(__func)                           \
    __func(upt_vld, bool)                       \
    __func(upt_id, IdT)                         \
    __func(upt_op, OpT)                         \
    __func(upt_key, KeyT)                       \
    __func(upt_size, SizeT)                     \
    __func(upt_error_vld_r, bool)               \
    __func(upt_error_id_r, IdT)                 \
    __func(qry_vld, bool)                       \
    __func(qry_id, IdT)                         \
    __func(qry_level, LevelT)                   \
    __func(qry_resp_vld_r, bool)                \
    __func(qry_key_r, KeyT)                     \
    __func(qry_size_r, SizeT)                   \
    __func(qry_error_r, bool)                   \
    __func(qry_listsize_r, ListSizeT)           \
    __func(ntf_vld_r, bool)                     \
    __func(ntf_id_r, IdT)                       \
    __func(ntf_key_r, KeyT)                     \
    __func(ntf_size_r, SizeT)

enum Op {
  OP_CLEAR = 0, OP_ADD = 1, OP_DELETE = 2, OP_REPLACE = 3
};


struct SortedListsTb : libtb::TopLevel
{
  using IdT = uint32_t;
  using OpT = uint32_t;
  using KeyT = vluint64_t;
  using SizeT = uint32_t;
  using ListSizeT = uint32_t;
  using LevelT = uint32_t;
  //
  using UUT = Vsorted_lists;
  SC_HAS_PROCESS(SortedListsTb);
  SortedListsTb(sc_core::sc_module_name mn = "t")
    : uut_("uut")
#define __construct_signal(__name, __type)      \
      , __name##_(#__name)
      PORTS(__construct_signal)
#undef __construct_signal
  {
    uut_.clk(clk());
    uut_.rst(rst());
#define __bind_signal(__name, __type)           \
    uut_.__name(__name##_);
    PORTS(__bind_signal)
#undef __bind_signals
  }

  void upt_idle() {
    upt_vld_ = false;
    upt_id_ = IdT();
    upt_op_ = OpT();
    upt_key_ = KeyT();
    upt_size_ = SizeT();
  }

  void b_issue_upt(IdT id, OpT op, KeyT k = KeyT(), SizeT s = SizeT())
  {
    upt_vld_ = true;
    upt_id_ = id;
    upt_op_ = op;
    upt_key_ = k;
    upt_size_ = s;
    t_wait_posedge_clk(1);
    upt_idle();
    t_wait_posedge_clk();
    t_wait_posedge_clk();
    t_wait_posedge_clk();
    t_wait_posedge_clk();
  }

  void qry_idle()
  {
    qry_vld_ = false;
    qry_id_ = IdT();
    qry_level_ = LevelT();
  }

  void b_issue_qry(IdT id, LevelT l)
  {
    qry_vld_ = true;
    qry_id_ = id;
    qry_level_ = l;
    t_wait_posedge_clk();
    qry_idle();
  }

  bool run_test() {
    LIBTB_REPORT_INFO("Stimulus starts...");

    b_issue_upt(5, OP_CLEAR);
    b_issue_upt(5, OP_ADD, 1, 100);
    b_issue_upt(5, OP_ADD, 2, 200);
    b_issue_upt(5, OP_ADD, 3, 300);
    b_issue_upt(5, OP_ADD, 4, 400);

    b_issue_qry(5, 2);
    b_issue_qry(5, 2);
    b_issue_qry(5, 2);
    b_issue_qry(5, 0);
    b_issue_qry(5, 1);
    b_issue_qry(5, 2);
    b_issue_qry(5, 3);

    wait (1000, SC_NS);
    LIBTB_REPORT_INFO("Stimulus ends...");
    return false;
  }
#define __declare_signal(__name, __type)        \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signal)
#undef __declare_signal
  UUT uut_;
};

int sc_main(int argc, char **argv)
{
  using namespace libtb;
  return LibTbSim<SortedListsTb>(argc, argv).start();
}
