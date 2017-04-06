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

#include <libtb.h>
#include <deque>
#include <sstream>
#include "Vfifo_ptr.h"

#define FIFO_PORTS(__func)                      \
    __func(push, bool)                          \
    __func(push_data, T)                        \
    __func(pop, bool)                           \
    __func(pop_data, T)                         \
    __func(flush, bool)                         \
    __func(commit, bool)                        \
    __func(replay, bool)                        \
    __func(empty_r, bool)                       \
    __func(full_r, bool)

template <typename T = vluint32_t>
struct FifoTb : public libtb::TopLevel {
  FifoTb() : libtb::TopLevel("t"), uut_("uut") {
    bind_rtl();
//    wave_on("foo.vcd", uut_);
  }
  virtual ~FifoTb() {}

 protected:
  void bind_rtl() {
    uut_.clk(clk());
    uut_.rst(rst());
#define __connect_ports(__name, __type) uut_.__name(__name##_);
    FIFO_PORTS(__connect_ports)
#undef __connect_ports
  }

  void idle_push() {
    push_ = 0;
    push_data_ = T{};
  }
  void idle_pop() { pop_ = 0; }
  void idle_cntrl() { commit_ = false; replay_ = false; }
  void b_push(const T& d) {
    idle_push();
    do {
      t_wait_sync();
    } while (full_r_);
    push_ = true;
    push_data_ = d;
    t_wait_posedge_clk();
    idle_push();
  }

  T b_pop() {
    idle_pop();
    do {
      t_wait_sync();
    } while (empty_r_);
    pop_ = true;;
    commit_ = true;
    t_wait_posedge_clk();
    const T ret = pop_data_;
    idle_pop();
    return ret;
  }
  Vfifo_ptr uut_;

#define __declare_signals(__name, __type) sc_core::sc_signal<__type> __name##_;
  FIFO_PORTS(__declare_signals)
#undef __declare_signals
};

template <typename T = vluint32_t>
struct test_0 : public FifoTb<T> {
  SC_HAS_PROCESS(test_0);
  test_0() : N_(10000) { SC_THREAD(t_pop); }

  bool run_test() {
    LIBTB_REPORT_INFO("Test START");
    while (N_--) {
      const T t = libtb::random<T>();
      this->b_push(t);
      beh_model_.push_back(t);
    }
    LIBTB_REPORT_INFO("Test END");
    return true;
  }

  void t_pop() {
    while (true) {
      const T actual = this->b_pop();
      const T expected = beh_model_.front();
      beh_model_.pop_front();

      std::stringstream ss;
      ss << "Expected " << std::hex << expected << " Actual " << std::hex
         << actual;

      if (actual != expected)
        LIBTB_REPORT_ERROR(ss.str());
      else
        LIBTB_REPORT_DEBUG(ss.str());
    }
  }

  int N_;
  std::deque<T> beh_model_;
};

int sc_main(int argc, char **argv) {
  using namespace libtb;
  test_0<> t;
  LibTbContext::init(argc, argv);
  return LibTbContext::start();
}
