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
#include <sstream>
#include "Vfifo_sr.h"

#define PORTS(__func)                           \
    __func(push, bool)                          \
    __func(push_data, DataT)                    \
    __func(pop, bool)                           \
    __func(pop_data_valid_r, bool)              \
    __func(pop_data, DataT)                     \
    __func(empty_r, bool)                       \
    __func(full_r, bool)

struct FifoTb : libtb::TopLevel
{
    using UUT = Vfifo_sr;
    using DataT = uint32_t;
    using FullT = uint32_t;

    SC_HAS_PROCESS(FifoTb);
    FifoTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signals(__name, __type)     \
        , __name##_(#__name)
          PORTS(__construct_signals)
#undef __construct_signals
    {
        SC_METHOD(m_checker);
        sensitive << e_tb_sample();

        SC_METHOD(m_popper);
        sensitive << e_tb_sample();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_ports(__name, __type)            \
        uut_.__name(__name##_);
        PORTS(__bind_ports)
#undef __bind_ports
    }

    void push_idle()
    {
        //
        push_ = false;
        push_data_ = DataT();
    }

    void push_random()
    {
        t_wait_sync();

        int i = libtb::random_integer_in_range(4);

        std::vector<DataT> dat;

        if (full_r_) return;

        const DataT d = libtb::random<DataT>();
        push_ = true;
        push_data_ = d;
        t_wait_posedge_clk();
        expectation_.push_back(d);
        push_idle();
    }

    bool run_test()
    {
        t_wait_reset_done();

        LIBTB_REPORT_INFO("Stimulus starts...");
        int n = 100;
        while (n--)
            push_random();
        LIBTB_REPORT_INFO("Stimulus ends.");
        return 0;
    }

    void  m_popper()
    {
        pop_ = true;
    }

    void m_checker()
    {
        if (pop_data_valid_r_) {
            const DataT actual = pop_data_;

            if (expectation_.size() == 0) {
                LIBTB_REPORT_ERROR("Unexpected data valid");
                return ;
            }

            const DataT expected = expectation_.front();
            expectation_.pop_front();

            if (actual != expected) {
                std::stringstream ss;
                ss << "Mismatch detected"
                   << " Actual: " << std::hex << actual
                   << " Expected: " << std::hex << expected
                    ;
                LIBTB_REPORT_ERROR(ss.str());
            }
        }
    }

    std::deque<DataT> expectation_;

    const int N{1000};
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    UUT uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<FifoTb>(argc, argv).start();
}
