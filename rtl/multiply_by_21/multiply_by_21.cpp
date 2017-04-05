//========================================================================== //
// Copyright (c) 2016-17, Stephen Henry
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
#include <sstream>
#include "Vmultiply_by_21.h"

using DataT = uint32_t;

#define PORTS(__func)                           \
  __func(a, DataT)                              \
  __func(fail, bool)

struct MultiplyBy21Tb : libtb::TopLevel
{
  SC_HAS_PROCESS(MultiplyBy21Tb);
  MultiplyBy21Tb(sc_core::sc_module_name mn = "t")
    : libtb::TopLevel(mn)
    , uut_("uut")
#define __construct_signals(__name, __type)     \
    , __name##_(#__name)
    PORTS(__construct_signals)
#undef __construct_signals
  {
    SC_METHOD(m_checker);
    sensitive << e_tb_sample();
    dont_initialize();

#define __bind_signals(__name, __type)          \
    uut_.__name(__name##_);
    PORTS(__bind_signals)
#undef __bind_signals
  }

  bool run_test() {
    LIBTB_REPORT_INFO("Stimulus starts");
    int n = N_;
    while (n--) {
      a_ = libtb::random<DataT>();
      wait(10, SC_NS);
    }
    LIBTB_REPORT_INFO("Stimulus ends");
    return false;
  }

  void m_checker()
  {
    LIBTB_ASSERT_FATAL(!fail_);
  }

  const int N_{10000};
#define __declare_signals(__name, __type)       \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signals)
#undef __declare_signals
  Vmultiply_by_21 uut_;
};

int sc_main (int argc, char **argv)
{
  return libtb::LibTbSim<MultiplyBy21Tb>(argc, argv).start();
}
