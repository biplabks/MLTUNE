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


args_bfs[0]=adjnoun_adjacency_adjacency.gr
args_bfs[1]=as-skitter.gr
args_bfs[2]=ego-twitter.gr
args_bfs[3]=flickr-links.gr
args_bfs[4]=flixster.gr
args_bfs[5]=lasagne-yahoo.gr
args_bfs[6]=linux.gr
args_bfs[7]=livejournal-links.gr
args_bfs[8]=livemocha.gr
args_bfs[9]=maayan-faa.gr
args_bfs[10]=maayan-figeys.gr
args_bfs[11]=maayan-foodweb.gr
args_bfs[12]=maayan-pdzbase.gr
args_bfs[13]=maayan-Stelzl.gr
args_bfs[14]=moreno_innovation_innovation.gr
args_bfs[15]=moreno_propro_propro.gr
args_bfs[16]=opsahl-powergrid.gr
args_bfs[17]=orkut-links.gr
args_bfs[18]=patentcite.gr
args_bfs[19]=petster-carnivore.gr
args_bfs[20]=petster-friendships-cat-uniq.gr
args_bfs[21]=petster-friendships-dog-uniq.gr
args_bfs[22]=soc-LiveJournal1.gr
args_bfs[23]=soc-pokec-relationships.gr
args_bfs[24]=subelj_euroroad_euroroad.gr
args_bfs[25]=tntp-ChicagoRegional.gr
args_bfs[26]=wikipedia_link_de.gr
args_bfs[27]=wikipedia_link_fr.gr
args_bfs[28]=wikipedia_link_it.gr
args_bfs[29]=wikipedia_link_ja.gr
args_bfs[30]=wikipedia_link_pl.gr
args_bfs[31]=wikipedia_link_pt.gr
args_bfs[32]=wikipedia_link_ru.gr

args_eps[0]="out.adjnoun_adjacency_adjacency_beg_pos.bin out.adjnoun_adjacency_adjacency_csr.bin"
args_eps[1]="out.as-skitter_beg_pos.bin out.as-skitter_csr.bin"
args_eps[2]="out.ego-twitter_beg_pos.bin out.ego-twitter_csr.bin"
args_eps[3]="out.flickr-links_beg_pos.bin out.flickr-links_csr.bin"
args_eps[4]="out.flixster_beg_pos.bin out.flixster_csr.bin"
args_eps[5]="out.lasagne-yahoo_beg_pos.bin out.lasagne-yahoo_csr.bin"
args_eps[6]="out.linux_beg_pos.bin out.linux_csr.bin"
args_eps[7]="out.livejournal-links_beg_pos.bin out.livejournal-links_csr.bin"
args_eps[8]="out.livemocha_beg_pos.bin out.livemocha_csr.bin"
args_eps[9]="out.maayan-faa_beg_pos.bin out.maayan-faa_csr.bin"
args_eps[10]="out.maayan-figeys_beg_pos.bin out.maayan-figeys_csr.bin"
args_eps[11]="out.maayan-foodweb_beg_pos.bin out.maayan-foodweb_csr.bin"
args_eps[12]="out.maayan-pdzbase_beg_pos.bin out.maayan-pdzbase_csr.bin"
args_eps[13]="out.maayan-Stelzl_beg_pos.bin out.maayan-Stelzl_csr.bin"
args_eps[14]="out.moreno_innovation_innovation_beg_pos.bin out.moreno_innovation_innovation_csr.bin"
args_eps[15]="out.moreno_propro_propro_beg_pos.bin out.moreno_propro_propro_csr.bin"
args_eps[16]="out.opsahl-powergrid_beg_pos.bin out.opsahl-powergrid_csr.bin"
args_eps[17]="out.orkut-links_beg_pos.bin out.orkut-links_csr.bin"
args_eps[18]="out.patentcite_beg_pos.bin out.patentcite_csr.bin"
args_eps[19]="out.petster-carnivore_beg_pos.bin out.petster-carnivore_csr.bin"
args_eps[20]="out.petster-friendships-cat-uniq_beg_pos.bin out.petster-friendships-cat-uniq_csr.bin"
args_eps[21]="out.petster-friendships-dog-uniq_beg_pos.bin out.petster-friendships-dog-uniq_csr.bin"
args_eps[22]="out.soc-LiveJournal1_beg_pos.bin out.soc-LiveJournal1_csr.bin"
args_eps[23]="out.soc-pokec-relationships_beg_pos.bin out.soc-pokec-relationships_csr.bin"
args_eps[24]="out.subelj_euroroad_euroroad_beg_pos.bin out.subelj_euroroad_euroroad_csr.bin"
args_eps[25]="out.tntp-ChicagoRegional_beg_pos.bin out.tntp-ChicagoRegional_csr.bin"
args_eps[26]="out.wikipedia_link_de_beg_pos.bin out.wikipedia_link_de_csr.bin"
args_eps[27]="out.wikipedia_link_fr_beg_pos.bin out.wikipedia_link_fr_csr.bin"
args_eps[28]="out.wikipedia_link_it_beg_pos.bin out.wikipedia_link_it_csr.bin"
args_eps[29]="out.wikipedia_link_ja_beg_pos.bin out.wikipedia_link_ja_csr.bin"
args_eps[30]="out.wikipedia_link_pl_beg_pos.bin out.wikipedia_link_pl_csr.bin"
args_eps[31]="out.wikipedia_link_pt_beg_pos.bin out.wikipedia_link_pt_csr.bin"
args_eps[32]="out.wikipedia_link_ru_beg_pos.bin out.wikipedia_link_ru_csr.bin"


