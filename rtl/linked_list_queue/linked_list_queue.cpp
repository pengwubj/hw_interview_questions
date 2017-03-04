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

struct LinkedListQueueTb : libtb::TopLevel
{
    using UUT = Vlinked_list_queue;

    using WordT = uint32_t;
    using CtxtT = uint32_t;
    using QueueT = uint32_t;

    SC_HAS_PROCESS(LinkedListQueueTb);
    LinkedListQueueTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
    {
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

        b_issue_command(0, true, 0x1);
        b_issue_command(0, true, 0x2);
        b_issue_command(0, true, 0x3);
        b_issue_command(1, true, 0x11);
        b_issue_command(1, true, 0x12);
        b_issue_command(1, true, 0x13);
        t_wait_posedge_clk(10);
        b_issue_command(0, false);
        b_issue_command(1, false);
        b_issue_command(0, false);
        b_issue_command(1, false);
        b_issue_command(0, false);
        b_issue_command(1, false);
        t_wait_posedge_clk(10);

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
        t_wait_posedge_clk();
        b_issue_idle();
    }

    void wait_not_busy() {
        do { t_wait_sync(); } while (busy_r_);
        t_wait_posedge_clk();
    }

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
