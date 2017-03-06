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

## Build Steps
~~~~
git clone https://github.com/stephenry/hw_interview_questions
cd hw_interview_questions
git submodule update --init --recursive
cmake ../
make
~~~

## Run Steps
Upon successful completion of the build process. Tests can be executed by
invoking the generated executable in the RTL directory.

## Answers
* count_ones
* fifo_async
* gates_from_MUX2X1
* increment
* latency
* multi_counter
* one_or_two

## Disclaimer
Contributions are welcome however please consider that the current project
remains very much a work in progress and that ancillary libraries, upon which
this code depends, remain under active development.
