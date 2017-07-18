input_dir=$1

# prog enums 
bfs=0
bfs_atomic=1
bfs_wlc=2
bfs_wla=3
bfs_wlw=4


# prog names 
progs[$bfs]="bfs"
progs[${bfs_atomic}]="bfs-atomic"
progs[${bfs_wlc}]="bfs-wlc"
progs[${bfs_wla}]="bfs-wla"
progs[${bfs_wlw}]="bfs-wlw"

# prog names 
progs_main[$bfs]="bfs"
progs_main[${bfs_atomic}]="bfs"
progs_main[${bfs_wlc}]="bfs"
progs_main[${bfs_wla}]="bfs"
progs_main[${bfs_wlw}]="bfs"

# prog names 
kernels_base[$bfs]="drelax"
kernels_base[${bfs_atomic}]="drelax"
kernels_base[${bfs_wlc}]="drelax"
kernels_base[${bfs_wla}]="drelax"
kernels_base[${bfs_wlw}]="drelax"

