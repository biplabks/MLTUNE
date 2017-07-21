input_dir=$1

# prog enums 
bfs=0
bfs_atomic=1
bfs_wlc=2
bfs_wla=3
bfs_wlw=4
bfs_eps=5

# base algm enum
bfs=0
eps=1
 
# prog names 
progs[$bfs]="bfs"
progs[${bfs_atomic}]="bfs-atomic"
progs[${bfs_wlc}]="bfs-wlc"
progs[${bfs_wla}]="bfs-wla"
progs[${bfs_wlw}]="bfs-wlw"
progs[${bfs_eps}]="eps"

# prog names 
progs_main[$bfs]="bfs"
progs_main[${bfs_atomic}]="bfs"
progs_main[${bfs_wlc}]="bfs"
progs_main[${bfs_wla}]="bfs"
progs_main[${bfs_wlw}]="bfs"
progs_main[${bfs_eps}]="eps"

# prog names 
kernels_base[$bfs]="drelax"
kernels_base[${bfs_atomic}]="drelax"
kernels_base[${bfs_wlc}]="drelax"
kernels_base[${bfs_wla}]="drelax"
kernels_base[${bfs_wlw}]="drelax"
kernels_base[${bfs_eps}]="eps"


args[0,0]=as-skitter.gr
args[0,1]=ego-twitter.gr
args[0,2]=flickr-links.gr
args[0,3]=flixster.gr
args[0,4]=lasagne-yahoo.gr
args[0,5]=linux.gr
args[0,6]=livejournal-links.gr
args[0,7]=livemocha.gr
args[0,8]=maayan-faa.gr
args[0,9]=maayan-figeys.gr
args[0,10]=maayan-foodweb.gr
args[0,11]=maayan-pdzbase.gr
args[0,12]=maayan-Stelzl.gr
args[0,13]=moreno_innovation_innovation.gr
args[0,14]=moreno_propro_propro.gr
args[0,15]=opsahl-powergrid.gr
args[0,16]=orkut-links.gr
args[0,17]=patentcite.gr
args[0,18]=petster-carnivore.gr
args[0,19]=petster-friendships-cat-uniq.gr
args[0,20]=petster-friendships-dog-uniq.gr
args[0,21]=soc-LiveJournal1.gr
args[0,22]=soc-pokec-relationships.gr
args[0,23]=subelj_euroroad_euroroad.gr
args[0,24]=tntp-ChicagoRegional.gr
args[0,25]=wikipedia_link_de.gr
args[0,26]=wikipedia_link_fr.gr
args[0,27]=wikipedia_link_it.gr
args[0,28]=wikipedia_link_ja.gr
args[0,29]=wikipedia_link_pl.gr
args[0,30]=wikipedia_link_pt.gr
args[0,31]=wikipedia_link_ru.gr

args[1,0]="out.adjnoun_adjacency_adjacency_beg_pos.bin out.adjnoun_adjacency_adjacency_csr.bin"
args[1,1]="out.as-skitter_beg_pos.bin out.as-skitter_csr.bin"
args[1,2]="out.ego-twitter_beg_pos.bin out.ego-twitter_csr.bin"
args[1,3]="out.flickr-links_beg_pos.bin out.flickr-links_csr.bin"
args[1,4]="out.flixster_beg_pos.bin out.flixster_csr.bin"
args[1,5]="out.lasagne-yahoo_beg_pos.bin out.lasagne-yahoo_csr.bin"
args[1,6]="out.linux_beg_pos.bin out.linux_csr.bin"
args[1,7]="out.livejournal-links_beg_pos.bin out.livejournal-links_csr.bin"
args[1,8]="out.livemocha_beg_pos.bin out.livemocha_csr.bin"
args[1,9]="out.maayan-faa_beg_pos.bin out.maayan-faa_csr.bin"
args[1,10]="out.maayan-figeys_beg_pos.bin out.maayan-figeys_csr.bin"
args[1,11]="out.maayan-foodweb_beg_pos.bin out.maayan-foodweb_csr.bin"
args[1,12]="out.maayan-pdzbase_beg_pos.bin out.maayan-pdzbase_csr.bin"
args[1,13]="out.maayan-Stelzl_beg_pos.bin out.maayan-Stelzl_csr.bin"
args[1,14]="out.moreno_innovation_innovation_beg_pos.bin out.moreno_innovation_innovation_csr.bin"
args[1,15]="out.moreno_propro_propro_beg_pos.bin out.moreno_propro_propro_csr.bin"
args[1,16]="out.opsahl-powergrid_beg_pos.bin out.opsahl-powergrid_csr.bin"
args[1,17]="out.orkut-links_beg_pos.bin out.orkut-links_csr.bin"
args[1,18]="out.patentcite_beg_pos.bin out.patentcite_csr.bin"
args[1,19]="out.petster-carnivore_beg_pos.bin out.petster-carnivore_csr.bin"
args[1,20]="out.petster-friendships-cat-uniq_beg_pos.bin out.petster-friendships-cat-uniq_csr.bin"
args[1,21]="out.petster-friendships-dog-uniq_beg_pos.bin out.petster-friendships-dog-uniq_csr.bin"
args[1,22]="out.soc-LiveJournal1_beg_pos.bin out.soc-LiveJournal1_csr.bin"
args[1,23]="out.soc-pokec-relationships_beg_pos.bin out.soc-pokec-relationships_csr.bin"
args[1,24]="out.subelj_euroroad_euroroad_beg_pos.bin out.subelj_euroroad_euroroad_csr.bin"
args[1,25]="out.tntp-ChicagoRegional_beg_pos.bin out.tntp-ChicagoRegional_csr.bin"
args[1,26]="out.wikipedia_link_de_beg_pos.bin out.wikipedia_link_de_csr.bin"
args[1,27]="out.wikipedia_link_fr_beg_pos.bin out.wikipedia_link_fr_csr.bin"
args[1,28]="out.wikipedia_link_it_beg_pos.bin out.wikipedia_link_it_csr.bin"
args[1,29]="out.wikipedia_link_ja_beg_pos.bin out.wikipedia_link_ja_csr.bin"
args[1,30]="out.wikipedia_link_pl_beg_pos.bin out.wikipedia_link_pl_csr.bin"
args[1,31]="out.wikipedia_link_pt_beg_pos.bin out.wikipedia_link_pt_csr.bin"
args[1,32]="out.wikipedia_link_ru_beg_pos.bin out.wikipedia_link_ru_csr.bin"


