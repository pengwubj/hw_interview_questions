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

#include "fifo_async_tb.h"
#include <sstream>

fifo_async_tb::fifo_async_tb() : libtb::TopLevel("t"), uut_("uut") {
  SC_METHOD(m_checker);
  sensitive << e_reset_done();
  dont_initialize();
}
fifo_async_tb::~fifo_async_tb() {}

void fifo_async_tb::bind_rtl() {
  uut_.rclk(clk());
  uut_.rrst(rst());
#define __bind_signals(__name, __type) uut_.__name(__name##_);
  FIFO_ASYNC_PORTS(__bind_signals)
#undef __bind_signals
}

void fifo_async_tb::pop_idle() { pop_ = false; }

void fifo_async_tb::m_checker() {
  pop_idle();

  if (!empty_r_) {
    pop_ = true;
    if (queue_.size() == 0) {
        // TODO: Error raised pre-reset. Modify libtb to hold-off e_reset_done
//      LIBTB_REPORT_ERROR("Pop not predicted");
      return;
    }
    const WordT actual = pop_data_;
    const WordT expected = queue_.front();
    queue_.pop_front();

    if (expected != actual) {
      std::stringstream ss;
      ss << "Actual: " << std::hex << actual << " "
         << "Expected: " << std::hex << expected;
      LIBTB_REPORT_ERROR(ss.str());
    }
  }
  next_trigger(e_tb_sample());
}


struct test_0 : public fifo_async_tb {
    SC_HAS_PROCESS(test_0);
    test_0() { bind_rtl(); }
    virtual ~test_0() {}
    bool run_test() {
        LIBTB_REPORT_INFO("Stimulus begins");
        b_reset();

        unsigned N = 10000;
        while (N--) b_push(libtb::random<WordT>());

        LIBTB_REPORT_INFO("Stimulus ends");
        return true;
    }
    void b_reset() {
        wrst_ = false;
        wait(wclk_.posedge_event());
        wrst_ = true;
        wait(wclk_.posedge_event());
        wrst_ = false;
    }
    virtual void bind_rtl() {
        uut_.wclk(wclk_);
        uut_.wrst(wrst_);
        fifo_async_tb::bind_rtl();
    }

    void b_push(WordT w) {
        push_ = true;
        push_data_ = w;
        queue_.push_back(w);
        wait(wclk_.posedge_event());
    }

    sc_core::sc_clock wclk_;
    sc_core::sc_signal<bool> wrst_;
};

int sc_main(int argc, char **argv) {
    using namespace libtb;
    test_0 t;
    LibTbContext::init(argc, argv);
    return LibTbContext::start();
}
