#!/bin/bash

input_dir=$1

# prog enums 
blackscholes=0
mm=1
vadd=2
qsort=3
sobol=4

# prog names 
progs[$blackscholes]="BlackScholes" 
progs[$mm]="matrixMul" 
progs[$vadd]="vectorAdd" 
progs[$qsort]="cdpSimpleQuicksort"
progs[$sobol]="SobolQRNG"

# main kernels 
kernels[$blackscholes]="BlackScholesGPU" 
kernels[$mm]="matrixMulCUDA" 
kernels[$vadd]="vectorAdd"
kernels[$qsort]="cdp_simple_quicksort"
kernels[$sobol]="sobolGPU_kernel"

# default reg allocation 
def_regs[$blackscholes]=18
def_regs[$mm]=29
def_regs[$vadd]=10
def_regs[$qsort]=16
def_regs[$sobol]=19

# default block size
def_bs[$blackscholes]=128
def_bs[$mm]=1024
def_bs[$vadd]=32
def_bs[$qsort]=16
def_bs[$sobol]=64

# prog command-line args 
args_small[$blackscholes]=""
args_small[$mm]=""
args_small[$vadd]=""
args_small[$qsort]=""
args_small[$sobol]=""

args_large[$blackscholes]=""
args_large[$mm]=""
args_large[$vadd]=""
args_large[$qsort]=""
args_large[$sobol]=""
