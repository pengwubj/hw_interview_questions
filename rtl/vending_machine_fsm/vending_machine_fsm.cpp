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
#include "Vvending_machine_fsm.h"

#define PORTS(__func)                           \
    __func(nickel, bool)                        \
    __func(dime, bool)                          \
    __func(vend, bool)                          \
    __func(change, bool)

struct VendingMachineTb : libtb::TopLevel
{
    SC_HAS_PROCESS(VendingMachineTb);
    VendingMachineTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signals(__name, __type)     \
        , __name##_(#__name)
    PORTS(__construct_signals)
#undef __construct_signals
    {
        SC_METHOD(m_sample_vend);
        sensitive << vend_.posedge_event();
        dont_initialize();

        SC_METHOD(m_sample_change);
        sensitive << change_.posedge_event();
        dont_initialize();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    void m_sample_vend()
    {
        if (vend_)
            vend_n_++;
    }

    void m_sample_change()
    {
        if (change_)
            change_n_++;
    }

    bool run_test()
    {
        LIBTB_REPORT_INFO("Stimulus starts...");
        test_0();
        test_1();
        LIBTB_REPORT_INFO("Stimulus ends");

        return false;
    }

    void test_0()
    {
        clear();

        LIBTB_REPORT_INFO("Test 0");
        insert_nickel(); // 0.05
        insert_nickel(); // 0.10
        insert_nickel(); // 0.15
        insert_nickel(); // 0.20
        insert_nickel(); // 0.25
        insert_nickel(); // 0.30
        insert_nickel(); // 0.35
        insert_nickel(); // 0.40
        wait(10, SC_NS);
        LIBTB_ASSERT_ERROR(vend_n_ == 1);
    }

    void test_1()
    {
        clear();

        LIBTB_REPORT_INFO("Test 1");
        insert_nickel(); // 0.05
        insert_nickel(); // 0.10
        insert_nickel(); // 0.15
        insert_nickel(); // 0.20
        insert_nickel(); // 0.25
        insert_dime();   // 0.35
        insert_dime();   // 0.45
        wait(10, SC_NS);
        LIBTB_ASSERT_ERROR(change_n_ == 1);
        LIBTB_ASSERT_ERROR(vend_n_ == 1);
    }

    void idle()
    {
        nickel_ = false;
        dime_ = false;
    }
    void clear()
    {
        value_ = 0;
        vend_n_ = 0;
        change_n_ = 0;
        t_wait_posedge_clk();
    }
    void insert_nickel()
    {
        nickel_ = true;
        t_wait_posedge_clk();
        value_ += 5;
        idle();
    }
    void insert_dime()
    {
        dime_ = true;
        t_wait_posedge_clk();
        value_ += 10;
        idle();
    }

    unsigned value_{0};
    unsigned vend_n_{0}, change_n_{0};
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals

    Vvending_machine_fsm uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<VendingMachineTb>(argc, argv).start();
}
