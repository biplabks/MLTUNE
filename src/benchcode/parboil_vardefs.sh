#!/bin/bash

input_dir=$1

# prog enums 
bfs=0
cutcp=1
histo=2
lbm=3
mrig=4
mriq=5
sad=6
sgemm=7
spmv=8
stencil=9
tpacf=10

# non-parboil programs

bilateral=11
depthvertex=12
integrate=13
halfsample=14
raycast=15
reduce=16
renderdepth=17
rendertrack=18
rendervolume=19
track=20
vertexnorm=21

# prog names 
progs[$bfs]="bfs" 
progs[$cutcp]="cutcp"
progs[$histo]="histo"
progs[$lbm]="lbm"  
progs[$mrig]="mri-gridding"
progs[$mriq]="mri-q"
progs[$sad]="sad"
progs[$sgemm]="sgemm" 
progs[$spmv]="spmv" 
progs[$stencil]="stencil"
progs[$tpacf]="tpacf" 
progs[$bilateral]="bilateral" 
progs[$depthvertex]="depthvertex"
progs[$integrate]="integrate"
progs[$halfsample]="halfsample"
progs[$raycast]="raycast"
progs[$reduce]="reduce"
progs[$renderdepth]="renderdepth"
progs[$rendertrack]="rendertrack"
progs[$rendervolume]="rendervolume"
progs[$track]="track"
progs[$vertexnorm]="vertexnorm"

# main kernel names
kernels_base[$bfs]="BFS_kernel" 
kernels_base[$cutcp]="cuda_cutoff_potential_lattice"
kernels_base[$histo]="histo_main_kernel"
kernels_base[$lbm]="performStreamCollide_kernel"
kernels_base[$mrig]="gridding_GPU"
kernels_base[$mriq]="ComputeQ_GPU"
kernels_base[$sad]="mb_sad_calc"
kernels_base[$sgemm]="mysgemmNT"
kernels_base[$spmv]="spmv_jds_naive" 
kernels_base[$stencil]="naive_kernel"
kernels_base[$tpacf]="gen_hists" 
kernels_base[$bilateral]="bilateralFilterKernel"
kernels_base[$depthvertex]="depth2vertexKernel"
kernels_base[$integrate]="integrateKernel"
kernels_base[$halfsample]="halfSampleRobustImageKernel"
kernels_base[$raycast]="raycastKernel"
kernels_base[$reduce]="reduceKernel"
kernels_base[$renderdepth]="renderDepthKernel"
kernels_base[$rendertrack]="renderTrackKernel"
kernels_base[$rendervolume]="renderVolumeKernel"
kernels_base[$track]="trackKernelBis"
kernels_base[$vertexnorm]="vertex2normalKernel"

# thread geometry
kernels[$bfs]="BFS_in_GPU_kernel" 
kernels[$cutcp]="cuda_cutoff_potential_lattice6overlap"
kernels[$histo]="histo_final_kernel" # "histo_main_kernel"
kernels[$lbm]="performStreamCollide_kernel"
kernels[$mrig]="gridding_GPU"
kernels[$mriq]="ComputeQ_GPU"
kernels[$sad]="mb_sad_calc"
kernels[$sgemm]="mysgemmNT"
kernels[$spmv]="spmv_jds" 
kernels[$stencil]="block2D_hybrid_coarsen_x"
kernels[$tpacf]="gen_hists" 
kernels[$bilateral]="bilateralFilterKernel"
kernels[$depthvertex]="depth2vertexKernel"
kernels[$integrate]="integrateKernel"
kernels[$halfsample]="halfSampleRobustImageKernel"
kernels[$raycast]="raycastKernel"
kernels[$reduce]="reduceKernel"
kernels[$renderdepth]="renderDepthKernel"
kernels[$rendertrack]="renderTrackKernel"
kernels[$rendervolume]="renderVolumeKernel"
kernels[$track]="trackKernelBis"
kernels[$vertexnorm]="vertex2normalKernel"

# default reg allocation (at O3 optimization level)
def_regs[$bfs]=14
def_regs[$cutcp]=21
def_regs[$histo]=21
def_regs[$lbm]=34
def_regs[$mrig]=37
def_regs[$mriq]=21
def_regs[$sad]=44
def_regs[$sgemm]=17
def_regs[$spmv]=29
def_regs[$stencil]=16
def_regs[$tpacf]=30
def_regs[$bilateral]=27
def_regs[$depthvertex]=15
def_regs[$integrate]=37
def_regs[$halfsample]=26
def_regs[$raycast]=45
def_regs[$reduce]=51
def_regs[$renderdepth]=14
def_regs[$rendertrack]=6
def_regs[$rendervolume]=48
def_regs[$track]=43
def_regs[$vertexnorm]=18

# default block size
def_bs[$bfs]=545
def_bs[$cutcp]=128
def_bs[$histo]=512
def_bs[$lbm]=120
def_bs[$mrig]=64
def_bs[$mriq]=256
def_bs[$sad]=61
def_bs[$sgemm]=256
def_bs[$spmv]=32
def_bs[$stencil]=127
def_bs[$tpacf]=256
def_bs[$bilateral]=512
def_bs[$depthvertex]=512
def_bs[$integrate]=512
def_bs[$halfsample]=512
def_bs[$raycast]=512
def_bs[$reduce]=112
def_bs[$renderdepth]=512
def_bs[$rendertrack]=512
def_bs[$rendervolume]=512
def_bs[$track]=512
def_bs[$vertexnorm]=512


# prog command-line args 
args_small[$bfs]="${input_dir}/${progs[$bfs]}/small.dat -o result.dat"
args_small[$cutcp]="${input_dir}/${progs[$cutcp]}/small.dat -o result.dat"
args_small[$histo]="${input_dir}/${progs[$histo]}/small.dat -o result.dat -- 20 4"
args_small[$lbm]="${input_dir}/${progs[$lbm]}/small.dat -o result.dat -- 100"
args_small[$mrig]="${input_dir}/${progs[$mrig]}/small.dat -o result.dat -- 32 0"
args_small[$mriq]="${input_dir}/${progs[$mriq]}/small.dat -o result.dat"
args_small[$sad]="${input_dir}/${progs[$sad]}/small0.dat,${input_dir}/${progs[$sad]}/small1.dat -o result.dat"
args_small[$sgemm]="${input_dir}/${progs[$sgemm]}/small0.dat,${input_dir}/${progs[$sgemm]}/small1.dat,${input_dir}/${progs[$sgemm]}/small2.dat -o result.dat"
args_small[$spmv]="${input_dir}/${progs[$spmv]}/small0.dat,${input_dir}/${progs[$spmv]}/small1.dat -o result.dat"
args_small[$stencil]="${input_dir}/${progs[$stencil]}/small.dat -o result.dat -- 128 128 32 100"
args_small[$bilateral]="${input_dir}/${progs[$bilateral]}/small.dat -o result.dat -- 640 480 4.0000000000 0.1000000015 2"
args_small[$depthvertex]="${input_dir}/${progs[$depthvertex]}/small.dat -o result.dat -- 640 480 481.200012207 480 320 240"
args_small[$integrate]="${input_dir}/${progs[$integrate]}/small0.dat,${input_dir}/${progs[$integrate]}/small1.dat,${input_dir}/${progs[$integrate]}/small2.dat -o result.dat -- 481.2000122070 480.0000000000 320.0000000000 240.0000000000 640 480 0.2000000030 100.0000000000 128 128 128 4.8000001907 4.8000001907 4.8000001907"
args_small[$halfsample]="${input_dir}/${progs[$halfsample]}/small.dat -o result.dat  --  640 480 0.1000000015 1"
args_small[$raycast]="${input_dir}/${progs[$raycast]}/small0.dat,${input_dir}/${progs[$raycast]}/small1.dat -o result.dat -- 640 480 0.4000000060 4.0000000000 0.0375000015 0.1500000060 128 4.8000001907"
args_small[$reduce]="${input_dir}/${progs[$reduce]}/small.dat -o result.dat -- 640 480 640 480"
args_small[$renderdepth]="${input_dir}/${progs[$renderdepth]}/small.dat -o result.dat -- 640 480 0.4000000060 4.0000000000"
args_small[$rendertrack]="${input_dir}/${progs[$rendertrack]}/small.dat -o result.dat --  640 480"
args_small[$rendervolume]="${input_dir}/${progs[$rendervolume]}/small0.dat,${input_dir}/${progs[$rendervolume]}/small1.dat -o result.dat -- 640 480 0.4000000060 4.0000000000 0.0375000015 0.1500000022 0.1000000015 0.1000000015 0.1000000015 1.0000000000 1.0000000000 -1.0000000000 128 128 128 4.8000001907 4.8000001907 4.8000001907"
args_small[$track]="${input_dir}/${progs[$track]}/small0.dat,${input_dir}/${progs[$track]}/small1.dat,${input_dir}/${progs[$track]}/small2.dat,${input_dir}/${progs[$track]}/small3.dat,${input_dir}/${progs[$track]}/small4.dat,${input_dir}/${progs[$track]}/small5.dat,${input_dir}/${progs[$track]}/small6.dat -o result.dat -- 640 480 640 480 0.1000000015 0.8000000119"
args_small[$vertexnorm]="${input_dir}/${progs[$vertexnorm]}/small.dat -o result.dat -- 640 480"


# Only valid configurations are bfs, spmv, tpacf. all others use small for medium
args_medium[$bfs]="${input_dir}/${progs[$bfs]}/medium.dat -o result.dat"
args_medium[$cutcp]="${input_dir}/${progs[$cutcp]}/small.dat -o result.dat"
args_medium[$histo]="${input_dir}/${progs[$histo]}/small.dat -o result.dat -- 20 4"
args_medium[$lbm]="${input_dir}/${progs[$lbm]}/small.dat -o result.dat -- 3000"
args_medium[$mrig]="${input_dir}/${progs[$mrig]}/small.dat -o result.dat -- 32 0"
args_medium[$mriq]="${input_dir}/${progs[$mriq]}/small.dat -o result.dat -- 32 0"
args_medium[$sad]="${input_dir}/${progs[$sad]}/small0.dat,${input_dir}/${progs[$sad]}/small1.dat -o result.dat"
args_medium[$sgemm]="${input_dir}/${progs[$sgemm]}/small0.dat,${input_dir}/${progs[$sgemm]}/small1.dat,${input_dir}/${progs[$sgemm]}/small2.dat -o result.dat"
args_medium[$spmv]="${input_dir}/${progs[$spmv]}/medium0.dat,${input_dir}/${progs[$spmv]}/medium1.dat -o result.dat"
args_medium[$stencil]="${input_dir}/${progs[$stencil]}/small.dat -o result.dat 512 512 64 100"
args_medium[$bilateral]="${input_dir}/${progs[$bilateral]}/small.dat -o result.dat -- 640 480 4.0000000000 0.1000000015 2"
args_small[$raycast]="${input_dir}/${progs[$raycast]}/small0.dat,${input_dir}/${progs[$raycast]}/small1.dat -o result.dat -- 640 480 0.4000000060 4.0000000000 0.0375000015 0.1500000060 128 4.8000001907"

args_large[$bfs]="${input_dir}/${progs[$bfs]}/large.dat -o result.dat"
args_large[$cutcp]="${input_dir}/${progs[$cutcp]}/large.dat -o result.dat"
args_large[$histo]="${input_dir}/${progs[$histo]}/large.dat -o result.dat -- 10000 4"
args_large[$lbm]="${input_dir}/${progs[$lbm]}/large.dat -o result.dat -- 3000"
args_large[$mrig]="${input_dir}/${progs[$mrig]}/large.dat -o result.dat -- 32 0"
args_large[$mriq]="${input_dir}/${progs[$mriq]}/large.dat -o result.dat"
args_large[$sad]="${input_dir}/${progs[$sad]}/large0.dat,${input_dir}/${progs[$sad]}/large1.dat -o result.dat"
args_large[$sgemm]="${input_dir}/${progs[$sgemm]}/large0.dat,${input_dir}/${progs[$sgemm]}/large1.dat,${input_dir}/${progs[$sgemm]}/large2.dat -o result.dat"
args_large[$spmv]="${input_dir}/${progs[$spmv]}/large0.dat,${input_dir}/${progs[$spmv]}/large1.dat -o result.dat"
args_large[$stencil]="${input_dir}/${progs[$stencil]}/large.dat -o result.dat -- 512 512 64 100"
args_large[$bilateral]="${input_dir}/${progs[$bilateral]}/small.dat -o result.dat -- 640 480 4.0000000000 0.1000000015 2"
args_small[$raycast]="${input_dir}/${progs[$raycast]}/small0.dat,${input_dir}/${progs[$raycast]}/small1.dat -o result.dat -- 640 480 0.4000000060 4.0000000000 0.0375000015 0.1500000060 128 4.8000001907"


tpacf_args_small="${input_dir}/tpacf/small/Datapnts.1,${input_dir}/tpacf/small/Randompnts.1,${input_dir}/tpacf/small/Randompnts.10,${input_dir}/tpacf/small/Randompnts.100,${input_dir}/tpacf/small/Randompnts.11,${input_dir}/tpacf/small/Randompnts.12,${input_dir}/tpacf/small/Randompnts.13,${input_dir}/tpacf/small/Randompnts.14,${input_dir}/tpacf/small/Randompnts.15,${input_dir}/tpacf/small/Randompnts.16,${input_dir}/tpacf/small/Randompnts.17,${input_dir}/tpacf/small/Randompnts.18,${input_dir}/tpacf/small/Randompnts.19,${input_dir}/tpacf/small/Randompnts.2,${input_dir}/tpacf/small/Randompnts.20,${input_dir}/tpacf/small/Randompnts.21,${input_dir}/tpacf/small/Randompnts.22,${input_dir}/tpacf/small/Randompnts.23,${input_dir}/tpacf/small/Randompnts.24,${input_dir}/tpacf/small/Randompnts.25,${input_dir}/tpacf/small/Randompnts.26,${input_dir}/tpacf/small/Randompnts.27,${input_dir}/tpacf/small/Randompnts.28,${input_dir}/tpacf/small/Randompnts.29,${input_dir}/tpacf/small/Randompnts.3,${input_dir}/tpacf/small/Randompnts.30,${input_dir}/tpacf/small/Randompnts.31,${input_dir}/tpacf/small/Randompnts.32,${input_dir}/tpacf/small/Randompnts.33,${input_dir}/tpacf/small/Randompnts.34,${input_dir}/tpacf/small/Randompnts.35,${input_dir}/tpacf/small/Randompnts.36,${input_dir}/tpacf/small/Randompnts.37,${input_dir}/tpacf/small/Randompnts.38,${input_dir}/tpacf/small/Randompnts.39,${input_dir}/tpacf/small/Randompnts.4,${input_dir}/tpacf/small/Randompnts.40,${input_dir}/tpacf/small/Randompnts.41,${input_dir}/tpacf/small/Randompnts.42,${input_dir}/tpacf/small/Randompnts.43,${input_dir}/tpacf/small/Randompnts.44,${input_dir}/tpacf/small/Randompnts.45,${input_dir}/tpacf/small/Randompnts.46,${input_dir}/tpacf/small/Randompnts.47,${input_dir}/tpacf/small/Randompnts.48,${input_dir}/tpacf/small/Randompnts.49,${input_dir}/tpacf/small/Randompnts.5,${input_dir}/tpacf/small/Randompnts.50,${input_dir}/tpacf/small/Randompnts.51,${input_dir}/tpacf/small/Randompnts.52,${input_dir}/tpacf/small/Randompnts.53,${input_dir}/tpacf/small/Randompnts.54,${input_dir}/tpacf/small/Randompnts.55,${input_dir}/tpacf/small/Randompnts.56,${input_dir}/tpacf/small/Randompnts.57,${input_dir}/tpacf/small/Randompnts.58,${input_dir}/tpacf/small/Randompnts.59,${input_dir}/tpacf/small/Randompnts.6,${input_dir}/tpacf/small/Randompnts.60,${input_dir}/tpacf/small/Randompnts.61,${input_dir}/tpacf/small/Randompnts.62,${input_dir}/tpacf/small/Randompnts.63,${input_dir}/tpacf/small/Randompnts.64,${input_dir}/tpacf/small/Randompnts.65,${input_dir}/tpacf/small/Randompnts.66,${input_dir}/tpacf/small/Randompnts.67,${input_dir}/tpacf/small/Randompnts.68,${input_dir}/tpacf/small/Randompnts.69,${input_dir}/tpacf/small/Randompnts.7,${input_dir}/tpacf/small/Randompnts.70,${input_dir}/tpacf/small/Randompnts.71,${input_dir}/tpacf/small/Randompnts.72,${input_dir}/tpacf/small/Randompnts.73,${input_dir}/tpacf/small/Randompnts.74,${input_dir}/tpacf/small/Randompnts.75,${input_dir}/tpacf/small/Randompnts.76,${input_dir}/tpacf/small/Randompnts.77,${input_dir}/tpacf/small/Randompnts.78,${input_dir}/tpacf/small/Randompnts.79,${input_dir}/tpacf/small/Randompnts.8,${input_dir}/tpacf/small/Randompnts.80,${input_dir}/tpacf/small/Randompnts.81,${input_dir}/tpacf/small/Randompnts.82,${input_dir}/tpacf/small/Randompnts.83,${input_dir}/tpacf/small/Randompnts.84,${input_dir}/tpacf/small/Randompnts.85,${input_dir}/tpacf/small/Randompnts.86,${input_dir}/tpacf/small/Randompnts.87,${input_dir}/tpacf/small/Randompnts.88,${input_dir}/tpacf/small/Randompnts.89,${input_dir}/tpacf/small/Randompnts.9,${input_dir}/tpacf/small/Randompnts.90,${input_dir}/tpacf/small/Randompnts.91,${input_dir}/tpacf/small/Randompnts.92,${input_dir}/tpacf/small/Randompnts.93,${input_dir}/tpacf/small/Randompnts.94,${input_dir}/tpacf/small/Randompnts.95,${input_dir}/tpacf/small/Randompnts.96,${input_dir}/tpacf/small/Randompnts.97,${input_dir}/tpacf/small/Randompnts.98,${input_dir}/tpacf/small/Randompnts.99 -o result.dat -- -n 100 -p 487"

tpacf_args_medium="${input_dir}/tpacf/medium/Datapnts.1,${input_dir}/tpacf/medium/Randompnts.1,${input_dir}/tpacf/medium/Randompnts.10,${input_dir}/tpacf/medium/Randompnts.100,${input_dir}/tpacf/medium/Randompnts.11,${input_dir}/tpacf/medium/Randompnts.12,${input_dir}/tpacf/medium/Randompnts.13,${input_dir}/tpacf/medium/Randompnts.14,${input_dir}/tpacf/medium/Randompnts.15,${input_dir}/tpacf/medium/Randompnts.16,${input_dir}/tpacf/medium/Randompnts.17,${input_dir}/tpacf/medium/Randompnts.18,${input_dir}/tpacf/medium/Randompnts.19,${input_dir}/tpacf/medium/Randompnts.2,${input_dir}/tpacf/medium/Randompnts.20,${input_dir}/tpacf/medium/Randompnts.21,${input_dir}/tpacf/medium/Randompnts.22,${input_dir}/tpacf/medium/Randompnts.23,${input_dir}/tpacf/medium/Randompnts.24,${input_dir}/tpacf/medium/Randompnts.25,${input_dir}/tpacf/medium/Randompnts.26,${input_dir}/tpacf/medium/Randompnts.27,${input_dir}/tpacf/medium/Randompnts.28,${input_dir}/tpacf/medium/Randompnts.29,${input_dir}/tpacf/medium/Randompnts.3,${input_dir}/tpacf/medium/Randompnts.30,${input_dir}/tpacf/medium/Randompnts.31,${input_dir}/tpacf/medium/Randompnts.32,${input_dir}/tpacf/medium/Randompnts.33,${input_dir}/tpacf/medium/Randompnts.34,${input_dir}/tpacf/medium/Randompnts.35,${input_dir}/tpacf/medium/Randompnts.36,${input_dir}/tpacf/medium/Randompnts.37,${input_dir}/tpacf/medium/Randompnts.38,${input_dir}/tpacf/medium/Randompnts.39,${input_dir}/tpacf/medium/Randompnts.4,${input_dir}/tpacf/medium/Randompnts.40,${input_dir}/tpacf/medium/Randompnts.41,${input_dir}/tpacf/medium/Randompnts.42,${input_dir}/tpacf/medium/Randompnts.43,${input_dir}/tpacf/medium/Randompnts.44,${input_dir}/tpacf/medium/Randompnts.45,${input_dir}/tpacf/medium/Randompnts.46,${input_dir}/tpacf/medium/Randompnts.47,${input_dir}/tpacf/medium/Randompnts.48,${input_dir}/tpacf/medium/Randompnts.49,${input_dir}/tpacf/medium/Randompnts.5,${input_dir}/tpacf/medium/Randompnts.50,${input_dir}/tpacf/medium/Randompnts.51,${input_dir}/tpacf/medium/Randompnts.52,${input_dir}/tpacf/medium/Randompnts.53,${input_dir}/tpacf/medium/Randompnts.54,${input_dir}/tpacf/medium/Randompnts.55,${input_dir}/tpacf/medium/Randompnts.56,${input_dir}/tpacf/medium/Randompnts.57,${input_dir}/tpacf/medium/Randompnts.58,${input_dir}/tpacf/medium/Randompnts.59,${input_dir}/tpacf/medium/Randompnts.6,${input_dir}/tpacf/medium/Randompnts.60,${input_dir}/tpacf/medium/Randompnts.61,${input_dir}/tpacf/medium/Randompnts.62,${input_dir}/tpacf/medium/Randompnts.63,${input_dir}/tpacf/medium/Randompnts.64,${input_dir}/tpacf/medium/Randompnts.65,${input_dir}/tpacf/medium/Randompnts.66,${input_dir}/tpacf/medium/Randompnts.67,${input_dir}/tpacf/medium/Randompnts.68,${input_dir}/tpacf/medium/Randompnts.69,${input_dir}/tpacf/medium/Randompnts.7,${input_dir}/tpacf/medium/Randompnts.70,${input_dir}/tpacf/medium/Randompnts.71,${input_dir}/tpacf/medium/Randompnts.72,${input_dir}/tpacf/medium/Randompnts.73,${input_dir}/tpacf/medium/Randompnts.74,${input_dir}/tpacf/medium/Randompnts.75,${input_dir}/tpacf/medium/Randompnts.76,${input_dir}/tpacf/medium/Randompnts.77,${input_dir}/tpacf/medium/Randompnts.78,${input_dir}/tpacf/medium/Randompnts.79,${input_dir}/tpacf/medium/Randompnts.8,${input_dir}/tpacf/medium/Randompnts.80,${input_dir}/tpacf/medium/Randompnts.81,${input_dir}/tpacf/medium/Randompnts.82,${input_dir}/tpacf/medium/Randompnts.83,${input_dir}/tpacf/medium/Randompnts.84,${input_dir}/tpacf/medium/Randompnts.85,${input_dir}/tpacf/medium/Randompnts.86,${input_dir}/tpacf/medium/Randompnts.87,${input_dir}/tpacf/medium/Randompnts.88,${input_dir}/tpacf/medium/Randompnts.89,${input_dir}/tpacf/medium/Randompnts.9,${input_dir}/tpacf/medium/Randompnts.90,${input_dir}/tpacf/medium/Randompnts.91,${input_dir}/tpacf/medium/Randompnts.92,${input_dir}/tpacf/medium/Randompnts.93,${input_dir}/tpacf/medium/Randompnts.94,${input_dir}/tpacf/medium/Randompnts.95,${input_dir}/tpacf/medium/Randompnts.96,${input_dir}/tpacf/medium/Randompnts.97,${input_dir}/tpacf/medium/Randompnts.98,${input_dir}/tpacf/medium/Randompnts.99 -o result.dat -- -n 100 -p 4096"

tpacf_args_large="${input_dir}/tpacf/large/Datapnts.1,${input_dir}/tpacf/large/Randompnts.1,${input_dir}/tpacf/large/Randompnts.2,${input_dir}/tpacf/large/Randompnts.3,${input_dir}/tpacf/large/Randompnts.4,${input_dir}/tpacf/large/Randompnts.5,${input_dir}/tpacf/large/Randompnts.6,${input_dir}/tpacf/large/Randompnts.7,${input_dir}/tpacf/large/Randompnts.8,${input_dir}/tpacf/large/Randompnts.9,${input_dir}/tpacf/large/Randompnts.10,${input_dir}/tpacf/large/Randompnts.11,${input_dir}/tpacf/large/Randompnts.12,${input_dir}/tpacf/large/Randompnts.13,${input_dir}/tpacf/large/Randompnts.14,${input_dir}/tpacf/large/Randompnts.15,${input_dir}/tpacf/large/Randompnts.16,${input_dir}/tpacf/large/Randompnts.17,${input_dir}/tpacf/large/Randompnts.18,${input_dir}/tpacf/large/Randompnts.19,${input_dir}/tpacf/large/Randompnts.20,${input_dir}/tpacf/large/Randompnts.21,${input_dir}/tpacf/large/Randompnts.22,${input_dir}/tpacf/large/Randompnts.23,${input_dir}/tpacf/large/Randompnts.24,${input_dir}/tpacf/large/Randompnts.25,${input_dir}/tpacf/large/Randompnts.26,${input_dir}/tpacf/large/Randompnts.27,${input_dir}/tpacf/large/Randompnts.28,${input_dir}/tpacf/large/Randompnts.29,${input_dir}/tpacf/large/Randompnts.30,${input_dir}/tpacf/large/Randompnts.31,${input_dir}/tpacf/large/Randompnts.32,${input_dir}/tpacf/large/Randompnts.33,${input_dir}/tpacf/large/Randompnts.34,${input_dir}/tpacf/large/Randompnts.35,${input_dir}/tpacf/large/Randompnts.36,${input_dir}/tpacf/large/Randompnts.37,${input_dir}/tpacf/large/Randompnts.38,${input_dir}/tpacf/large/Randompnts.39,${input_dir}/tpacf/large/Randompnts.40,${input_dir}/tpacf/large/Randompnts.41,${input_dir}/tpacf/large/Randompnts.42,${input_dir}/tpacf/large/Randompnts.43,${input_dir}/tpacf/large/Randompnts.44,${input_dir}/tpacf/large/Randompnts.45,${input_dir}/tpacf/large/Randompnts.46,${input_dir}/tpacf/large/Randompnts.47,${input_dir}/tpacf/large/Randompnts.48,${input_dir}/tpacf/large/Randompnts.49,${input_dir}/tpacf/large/Randompnts.50,${input_dir}/tpacf/large/Randompnts.51,${input_dir}/tpacf/large/Randompnts.52,${input_dir}/tpacf/large/Randompnts.53,${input_dir}/tpacf/large/Randompnts.54,${input_dir}/tpacf/large/Randompnts.55,${input_dir}/tpacf/large/Randompnts.56,${input_dir}/tpacf/large/Randompnts.57,${input_dir}/tpacf/large/Randompnts.58,${input_dir}/tpacf/large/Randompnts.59,${input_dir}/tpacf/large/Randompnts.60,${input_dir}/tpacf/large/Randompnts.61,${input_dir}/tpacf/large/Randompnts.62,${input_dir}/tpacf/large/Randompnts.63,${input_dir}/tpacf/large/Randompnts.64,${input_dir}/tpacf/large/Randompnts.65,${input_dir}/tpacf/large/Randompnts.66,${input_dir}/tpacf/large/Randompnts.67,${input_dir}/tpacf/large/Randompnts.68,${input_dir}/tpacf/large/Randompnts.69,${input_dir}/tpacf/large/Randompnts.70,${input_dir}/tpacf/large/Randompnts.71,${input_dir}/tpacf/large/Randompnts.72,${input_dir}/tpacf/large/Randompnts.73,${input_dir}/tpacf/large/Randompnts.74,${input_dir}/tpacf/large/Randompnts.75,${input_dir}/tpacf/large/Randompnts.76,${input_dir}/tpacf/large/Randompnts.77,${input_dir}/tpacf/large/Randompnts.78,${input_dir}/tpacf/large/Randompnts.79,${input_dir}/tpacf/large/Randompnts.80,${input_dir}/tpacf/large/Randompnts.81,${input_dir}/tpacf/large/Randompnts.82,${input_dir}/tpacf/large/Randompnts.83,${input_dir}/tpacf/large/Randompnts.84,${input_dir}/tpacf/large/Randompnts.85,${input_dir}/tpacf/large/Randompnts.86,${input_dir}/tpacf/large/Randompnts.87,${input_dir}/tpacf/large/Randompnts.88,${input_dir}/tpacf/large/Randompnts.89,${input_dir}/tpacf/large/Randompnts.90,${input_dir}/tpacf/large/Randompnts.91,${input_dir}/tpacf/large/Randompnts.92,${input_dir}/tpacf/large/Randompnts.93,${input_dir}/tpacf/large/Randompnts.94,${input_dir}/tpacf/large/Randompnts.95,${input_dir}/tpacf/large/Randompnts.96,${input_dir}/tpacf/large/Randompnts.97,${input_dir}/tpacf/large/Randompnts.98,${input_dir}/tpacf/large/Randompnts.99,${input_dir}/tpacf/large/Randompnts.100  -o result.dat -- -n 100 -p 10391"

args_small[$tpacf]="${tpacf_args_small}"
args_medium[$tpacf]="${tpacf_args_medium}"
args_large[$tpacf]="${tpacf_args_large}"
