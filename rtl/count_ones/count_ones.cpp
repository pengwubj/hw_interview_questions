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
#include "Vcount_ones.h"

#define PORTS(__func)                           \
    __func(A, WordT)                            \
    __func(fail, bool)

const int TB_N = 10000;

struct CountOnesTb : libtb::TopLevel
{
    using WordT = uint32_t;
    SC_HAS_PROCESS(CountOnesTb);
    CountOnesTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
    {
        SC_METHOD(m_checker);
        sensitive << e_tb_sample();
        dont_initialize();

#define __bind_ports(__name, __type)            \
        uut_.__name(__name##_);
        PORTS(__bind_ports)
#undef __bind_ports
    }

    bool run_test() {

        A_ = 0;
        t_wait_reset_done();

        for (int i = 0; i < TB_N; i++) {
            A_ = libtb::random<WordT>();
            t_wait_posedge_clk();
        }
        return false;
    }

    void m_checker() {
        LIBTB_ASSERT_ERROR(!fail_);
    }

#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    Vcount_ones uut_;
};


int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<CountOnesTb>(argc, argv).start();
}
