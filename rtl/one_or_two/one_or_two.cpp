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
#include "Vone_or_two.h"

constexpr int OPT_W = 32;

#define PORTS(__func)                            \
    __func(x, WordT)                             \
    __func(inv, bool)                            \
    __func(has_set_0, bool)                      \
    __func(has_set_1, bool)                      \
    __func(has_set_more_than_1, bool)

using WordT = uint32_t;

class OneOrTwoTb : libtb::TopLevel
{

public:
    SC_HAS_PROCESS(OneOrTwoTb);
    OneOrTwoTb(sc_core::sc_module_name = "t")
        : uut_("uut") {
#define __bind(__name, __type)                  \
        uut_.__name(__name##_);
        PORTS(__bind)
#undef __bind

        SC_METHOD(m_checker);
        sensitive << e_tb_sample();
        dont_initialize();
    }

private:

    void m_checker()
    {
        const WordT actual = x_;
        const int cnt = libtb::pop_count(actual);

        bool fail = false;
        fail |= ((cnt == 0) && !has_set_0_);
        fail |= ((cnt == 1) && !has_set_1_);
        fail |= ((cnt > 1) && !has_set_more_than_1_);

        std::stringstream ss;
        ss << "Actual: " << std::hex << actual
           << "{"
           << "has_set_0=" << std::boolalpha << has_set_0_ << ","
           << "has_set_1=" << std::boolalpha << has_set_1_ << ","
           << "has_set_more_than_1=" << std::boolalpha << has_set_more_than_1_
           << "}";

        LIBTB_REPORT_DEBUG(ss.str());

        if (fail)
            LIBTB_REPORT_ERROR("Failure");
    }

    WordT by_bits_set(int n = 0)
    {
        // Construct 0b set
        if (n == 0)
            return 0;

        // Construct >2b set
        if (n == -1) {
            WordT w;

            do {
                w = libtb::random<WordT>();
            } while (libtb::pop_count(w) <= 2);

            return w;
        }

        // Construct 1b set
        const WordT one_set = (1 << libtb::random_integer_in_range(30));
        if (n == 1)
            return one_set;

        // Construct 2b set
        if (n == 2) {
            WordT two_set;
            do {
                two_set = one_set | (1 << libtb::random_integer_in_range(30));
            } while (libtb::pop_count(two_set) != 2);

            return two_set;
        }

        // Never reached, hopefully!
        LIBTB_REPORT_FATAL("Unable to construct stimulus");
        return -1;
    }

    WordT get_stimulus()
    {
        const int i = libtb::random_integer_in_range(100);

        if (i < 10)
            return by_bits_set(0);

        if (i < 20)
            return by_bits_set(1);

        if (i < 30)
            return by_bits_set(2);

        return by_bits_set(-1);
    }

    bool run_test() {
        int i = N_;
        while (i--)
        {
            const WordT x = get_stimulus();
            x_ = x;
            std::stringstream ss;
            ss << "Attempting x=" << std::hex << x_;
            LIBTB_REPORT_DEBUG(ss.str());
            t_wait_posedge_clk();
        }
        return false;
    }

private:
#define __signals(__name, __type)               \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__signals)
#undef __signals

    Vone_or_two uut_;
    const int N_{10000};
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;

    OneOrTwoTb t;
    LibTbContext::init(argc, argv);
    return LibTbContext::start();
}
