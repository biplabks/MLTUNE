input_dir=$1

# prog enums 
backprop=0
bfsc=1
btree=2
cfd=3
dwt2d=4
gaussian=5
heartwall=6
hotspot=7
hotspot3d=8
huffaman=9
hybridsort=10
kmeans=11
lavaMD=12
leukocyte=13
lud=14
mummergpu=15
myocyte=16
nn=17
nw=18
particleFilter=19
pathfinder=20
srad=21
streamcluster=22


 
# prog names 
progs[${backprop}]="0"
progs[${bfs}]="1"
progs[${btree}]="2"
progs[${cfd}]="3"
progs[${dwt2d}]="4"
progs[${gaussian}]="gaussian"
progs[${heartwall}]="heartwall"
progs[${hotspot}]="7"
progs[${hotspot3d}]="8"
progs[${huffaman}]="9"
progs[${hybridsort}]="10"
progs[${kmeans}]="11"
progs[${lavaMD}]="lavaMD"
progs[${leukocyte}]="13"
progs[${lud}]="14"
progs[${mummergpu}]="15"
progs[${myocyte}]="16"
progs[${nn}]="17"
progs[${nw}]="18"
progs[${particleFilter}]="19"
progs[${pathfinder}]="pathfinder"
progs[${srad}]="srad"
progs[${streamcluster}]="22"

kernels_base[${backprop}]="0"
kernels_base[${bfs}]="1"
kernels_base[${btree}]="2"
kernels_base[${cfd}]="3"
kernels_base[${dwt2d}]="4"
kernels_base[${gaussian}]="Fan2"
kernels_base[${heartwall}]="kernel"
kernels_base[${hotspot}]="7"
kernels_base[${hotspot3d}]="8"
kernels_base[${huffaman}]="9"
kernels_base[${hybridsort}]="10"
kernels_base[${kmeans}]="11"
kernels_base[${lavaMD}]="kernel_gpu_cuda"
kernels_base[${leukocyte}]="13"
kernels_base[${lud}]="14"
kernels_base[${mummergpu}]="15"
kernels_base[${myocyte}]="16"
kernels_base[${nn}]="17"
kernels_base[${nw}]="18"
kernels_base[${particleFilter}]="19"
kernels_base[${pathfinder}]="dynproc_kernel"
kernels_base[${srad}]="srad"
kernels_base[${streamcluster}]="22"

args_small[${backprop}]="0"
args_small[${bfs}]="1"
args_small[${btree}]="2"
args_small[${cfd}]="3"
args_small[${dwt2d}]="4"
args_small[${gaussian}]="-s 256"
args_small[${heartwall}]="${input_dir}/heartwall/test.avi 20"
args_small[${hotspot}]="7"
args_small[${hotspot3d}]="8"
args_small[${huffaman}]="9"
args_small[${hybridsort}]="10"
args_small[${kmeans}]="11"
args_small[${lavaMD}]="-boxes1d 10"
args_small[${leukocyte}]="13"
args_small[${lud}]="14"
args_small[${mummergpu}]="15"
args_small[${myocyte}]="16"
args_small[${nn}]="17"
args_small[${nw}]="18"
args_small[${particleFilter}]="19"
args_small[${pathfinder}]="100000 100 20"
args_small[${srad}]="100 0.5 502 458"
args_small[${streamcluster}]="22"


args_large[${backprop}]="0"
args_large[${bfs}]="1"
args_large[${btree}]="2"
args_large[${cfd}]="3"
args_large[${dwt2d}]="4"
args_large[${gaussian}]="-s 512"
args_large[${heartwall}]="${input_dir}/heartwall/test.avi 20"
args_large[${hotspot}]="7"
args_large[${hotspot3d}]="8"
args_large[${huffaman}]="9"
args_large[${hybridsort}]="10"
args_large[${kmeans}]="11"
args_large[${lavaMD}]="-boxes1d 10"
args_large[${leukocyte}]="13"
args_large[${lud}]="14"
args_large[${mummergpu}]="15"
args_large[${myocyte}]="16"
args_large[${nn}]="17"
args_large[${nw}]="18"
args_large[${particleFilter}]="19"
args_large[${pathfinder}]="20"
args_large[${srad}]="100 0.5 502 458"
args_large[${streamcluster}]="22"

			

