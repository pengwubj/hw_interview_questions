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
#include <deque>
#include <array>
#include <sstream>
#include "Vlinked_list_queue.h"

#define PORTS(__func)                           \
    __func(cmd_pass, bool)                      \
    __func(cmd_push, bool)                      \
    __func(cmd_data, WordT)                     \
    __func(cmd_ctxt, CtxtT)                     \
    __func(cmd_accept, bool)                    \
    __func(resp_pass_r, bool)                   \
    __func(resp_data_w, WordT)                  \
    __func(resp_empty_fault_r, bool)            \
    __func(full_r, bool)                        \
    __func(empty_r, QueueT)                     \
    __func(busy_r, bool)

constexpr int OPT_N = 16;

struct LinkedListQueueTb : libtb::TopLevel
{
    using UUT = Vlinked_list_queue;

    using WordT = uint32_t;
    using CtxtT = uint32_t;
    using QueueT = uint32_t;

    struct Expectation {
        bool was_push;
        CtxtT c;
        WordT w;
    };

    SC_HAS_PROCESS(LinkedListQueueTb);
    LinkedListQueueTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
    {
        SC_METHOD(m_checker);
        sensitive << e_tb_sample();
        dont_initialize();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    bool run_test() {
        LIBTB_REPORT_INFO("Stimulus starts...");

        wait_not_busy();

        for (int i = 0; i < 20; i++) {
//            const CtxtT c = libtb::random_integer_in_range(OPT_N - 1);
            const CtxtT c = 0;
            const WordT w = libtb::random<WordT>();

            bool is_push = true;
            if (fifo_[c].size() != 0 )
                is_push = libtb::random<bool>();

            b_issue_command (c, is_push, w);
        }
        t_wait_posedge_clk(20);

        LIBTB_REPORT_INFO("Stimulus ends.");
        return false;
    }

    void b_issue_idle() {
        cmd_pass_ = false;
        cmd_push_ = false;
        cmd_data_ = WordT();
        cmd_ctxt_ = CtxtT();
    }

    void b_issue_command (const CtxtT & ctxt,
                          bool is_push = true,
                          WordT w = 0) {
        cmd_pass_ = true;
        cmd_push_ = is_push;
        cmd_ctxt_ = ctxt;
        cmd_data_ = w;
        do { t_wait_sync(); } while (!cmd_accept_);

        // Update behavioral model
        {
            if (is_push) {
                fifo_[ctxt].push_back(w);
                Expectation e;
                e.was_push = true;
                expectation_.push_back(e);
            }
            else {
                Expectation e;
                e.c = ctxt;
                e.w = fifo_[ctxt].front();
                fifo_[ctxt].pop_front();
                expectation_.push_back(e);
            }
        }
        t_wait_posedge_clk();
        b_issue_idle();
    }

    void m_checker() {

        if (resp_pass_r_) {

            if (expectation_.size() == 0) {
                LIBTB_REPORT_INFO("Unexpected response");
                return;
            }

            const Expectation expected = expectation_.front();
            expectation_.pop_front();

            if (expected.was_push)
                return;

            const WordT actual = resp_data_w_;
            if (actual != expected.w) {
                std::stringstream ss;

                ss << "Mismatch"
                   << " Expected: " << std::hex << expected.w
                   << " Actual: " << std::hex << actual;
                LIBTB_REPORT_INFO(ss.str());
            }
        }
    }

    void wait_not_busy() {
        do { t_wait_sync(); } while (busy_r_);
        t_wait_posedge_clk();
    }

    const int N{10};
    std::deque<Expectation> expectation_;
    std::array<std::deque<WordT>, OPT_N> fifo_;
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
 public:
    Vlinked_list_queue uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<LinkedListQueueTb>(argc, argv).start();
}
