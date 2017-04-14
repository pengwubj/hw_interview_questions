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
#include "Vpipelined_add_constant.h"

#define PORTS(__func)                           \
    __func(fail, bool)

class Pipelined_add_constantTb : libtb::TopLevel
{
public:
    SC_HAS_PROCESS(Pipelined_add_constantTb);
    Pipelined_add_constantTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __declare_signals(__name, __type)       \
        , __name##_(#__name)
        PORTS(__declare_signals)
#undef __declare_signals
    {
        SC_METHOD(m_checker);
        dont_initialize();
        sensitive << e_tb_sample();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)       \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    bool run_test()
    {
        t_wait_reset_done();
        reset_complete_ = true;
        LIBTB_REPORT_INFO("Stimulus starts....");
        wait (1, SC_US);
        LIBTB_REPORT_INFO("Stimulus ends.");
        return false;
    }

    void m_checker() {
        if (!reset_complete_)
            return;
        LIBTB_ASSERT_ERROR(!fail_);
    }

    bool reset_complete_{false};
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    Vpipelined_add_constant uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<Pipelined_add_constantTb>(argc, argv).start();
}
