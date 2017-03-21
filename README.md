# Hardware Interview Questions

[![Build Status](https://travis-ci.org/stephenry/hw_interview_questions.svg?branch=master)](https://travis-ci.org/stephenry/hw_interview_questions)

## Introduction

This project presents solutions to common hardware design/VLSI interview
questions. Presented are SystemVerilog implementations alongside self-checking
verification environments. Thorough discussion on the elements saught by
interviewer in a candidates solution provided.

## System Requirements
* cmake >= 3.2
* systemc >= 2.3.1
* verilator >= 3.9
* clang >= 3.9

## Build Steps (SIM)
~~~~
git clone https://github.com/stephenry/hw_interview_questions
cd hw_interview_questions
git submodule update --init --recursive
mkdir build
cd build
cmake ../
make
~~~~

## PD (VIVADO)

A standard Vivado flow is supported for each answer. PD libaries must
be explicitly selected during configuration (below). Within each answer,
a new target 'vivado' is present that invokes a standard Vivado flow.

~~~~
cmake ../ -DTARGET_VIVADO
make vivado
~~~~

## Run Steps
Upon successful completion of the build process. Tests can be executed by
invoking the generated executable in the RTL directory.

## Answers
* __count_ones__ Answer to compute the population count of an input vector.
* __fifo_async__ Answer to demonstrate the construction of a standard
  asynchronous FIFO.
* __gates_from_MUX2X1__ Answer to derive AND, OR, XOR and INV logic gates from a
  MUX2X standard cell.
* __increment__ Answer to derive logic to compute an increment function.
* __latency__ Answer to compute the average latency of a command stream to and
  from some external agent.
* __multi_counter__ Answer to demonstrate basic forwarding and pipeline
  concepts. Multiple counters are retained in a central state table. They are
  then randomly incremented or decremented on demand.
* __multi_counter_variant__ Alternate solutions to multi_counter problem.
* __one_or_two__ Answer to detect whether for an arbitrary input vector, 0-bits
  are set, 1-bit is set, or greater than 1 bit is set.
* __mcp_formulation (Multi-Cycle Path Formulation)__ Answer to pass a vector
  between two clock domains using a multi-cycle path.
* __detect_sequence__ Answer to detect a given sequence within an input
  serial stream.
* __vending_machine_fsm__ Answer to design a FSM to emulate the behavior of a
  simple vending machine.
* __vending_machine_dp__ Variant of FSM solution whereby some accumulation of a
  running count is required before an IRN-BRU shall be emitted.

## Disclaimer
Contributions are welcome however please consider that the current project
remains very much a work in progress and that ancillary libraries, upon which
this code depends, remain under active development.
