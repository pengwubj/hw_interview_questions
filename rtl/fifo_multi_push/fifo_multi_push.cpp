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
#include "Vfifo_multi_push.h"

#define PORTS(__func)                           \
    __func(push_0, bool)                        \
    __func(push_0_data, DataT)                  \
    __func(push_1, bool)                        \
    __func(push_1_data, DataT)                  \
    __func(push_2, bool)                        \
    __func(push_2_data, DataT)                  \
    __func(push_3, bool)                        \
    __func(push_3_data, DataT)                  \
    __func(pop_0, bool)                         \
    __func(pop_0_data_r, DataT)                 \
    __func(pop_0_valid_r, bool)                 \
    __func(empty_r, bool)                       \
    __func(full_r, FullT)

struct FifoMultiPushTb : libtb::TopLevel
{
    using UUT = Vfifo_multi_push;
    using DataT = uint32_t;
    using FullT = uint32_t;

    SC_HAS_PROCESS(FifoMultiPushTb);
    FifoMultiPushTb(sc_core::sc_module_name mn = "t")
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
        push_0_ = false;
        push_0_data_ = DataT();
        //
        push_1_ = false;
        push_1_data_ = DataT();
        //
        push_2_ = false;
        push_2_data_ = DataT();
        //
        push_3_ = false;
        push_3_data_ = DataT();
    }

    void push_random()
    {
        t_wait_sync();
      
        int i = libtb::random_integer_in_range(4);

        std::vector<DataT> dat;

        if (full_r_) goto __end;
        
        DataT d;
        switch (i)
        {
        case 4:
            d = libtb::random<DataT>();
            push_3_ = true;
            push_3_data_ = d;
            dat.push_back(d);

        case 3:
            d = libtb::random<DataT>();
            push_2_ = true;
            push_2_data_ = d;
            dat.push_back(d);

        case 2:
            d = libtb::random<DataT>();
            push_1_ = true;
            push_1_data_ = d;
            dat.push_back(d);

        case 1:
            d = libtb::random<DataT>();
            push_0_ = true;
            push_0_data_ = d;
            dat.push_back(d);
        }

        std::reverse(std::begin(dat), std::end(dat));
        std::copy(std::begin(dat),
                  std::end(dat),
                  std::back_inserter(expectation_));

    __end:
        t_wait_posedge_clk();
        push_idle();
    }

    bool run_test()
    {
        t_wait_reset_done();

        LIBTB_REPORT_INFO("Stimulus starts...");

        int n = 100;
        while (n--)
            push_random();

//        wait (empty_r_.posedge_event());

        LIBTB_REPORT_INFO("Stimulus ends.");
        return 0;
    }

    void  m_popper()
    {
        pop_0_ = true;
    }

    void m_checker()
    {
        if (pop_0_valid_r_) {
            const DataT actual = pop_0_data_r_;

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
    return LibTbSim<FifoMultiPushTb>(argc, argv).start();
}
