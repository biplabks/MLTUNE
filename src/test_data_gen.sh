#! /bin/bash

function usage() {
    echo "usage: test_data_gen.sh [OPTIONS] FEATURE_LIST PROG_LIST"
    echo "Generate test data based on features in FEATURE_LIST and executable command in PROG_LIST"
    echo ""
    echo "See \${MLTUNE_ROOT}/README.md for FEATURE_LIST and PROG_LIST descriptions"
		echo " "
		echo "Options:"
		echo -e "   --help\t\t  print this help message"
    echo -e "   -o, --outfile FILE\t  name of output file; default is METRIC_train_data.csv"
    echo -e "   -p, --processor PROC\t  PROC can be cpu or gpu; default is cpu"
    echo -e "   -s, --source\t collect source code features"
}

MINARGS=2
if [ $# -lt ${MINARGS} ] || [ "$1" = "--help" ]; then
	usage
  exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -o|--outfile)
			outfile="$2"
      shift # option has parameter
      ;;
    -p|--processor)
			proc="$2"
      shift # option has parameter
      ;;
    -s|--source)
			src="true"
      ;;
    *)
			if [ "$eventfile" = "" ]; then
				eventfile=$1
			elif  [ "$progfile" = "" ]; then 
				progfile=$1
			else
				echo "Unknown option:" $key
				exit 0
			fi
			;;
  esac
  shift
done

# set default values 
[ "$outfile" ] || { outfile=test_data.csv; }
[ "$proc" ] || { proc=cpu; }
[ "$src" ] || { src=""; }

# check input files 
[ -r "$eventfile" ] || { echo "could not read feature list file. exiting ..."; exit 0; }
[ -r "$progfile" ] || { echo "could not read proglist file. exiting ..."; exit 0; }
 
DEBUG=""
if [ $DEBUG ]; then 
	echo $eventfile
	echo $progfile
	echo $metric
	echo $classification
	echo $outfile
	echo $src
fi

# clean up previous train data files 
rm -f $outfile

hdr="test_header.csv"

if [ $src ]; then
#    echo -n "reg blks thrds " > $hdr
    echo -n "reg " > $hdr
fi
          
# create header
while read event
do
  printf "${event}\t" >> $hdr
done < $eventfile
printf "\n" >> $hdr

# conversion of events in eventfile to hexcodes
get_hex_codes_from_names $eventfile > temp_hex_codes

# read each line of prog and prog_args
while read line
do
	meta=`echo $line | awk -F ";;" '{print $1}'`
	build=`echo $line | awk -F ";;" '{print $2}'`
	exec=`echo $line | awk -F ";;" '{print $3}'`
	
	if [ "${meta}" = "" ]; then 
		echo "test_data_gen.sh: proglist file not formatted correctly. Exiting"
		exit 0
	fi
	if [ ${meta} = "+" ]; then 
		if [ $proc = "gpu" ]; then			
        if [ "$build" != "" ]; then
			      $build
        fi
			  echo $exec > gpu_proglist
			  fts=`get_gpu_metrics.sh -i $eventfile -t gpu_proglist` 
			  if [ $src ]; then
				    if [ "$build" != "" ]; then 
					      prog=`echo $build | awk '{print $NF}'`				
                build_str=`echo $build | awk '{ for(i=1; i < NF; i++) printf $i" "}'`                
                build_str=$build_str"-s ""$prog"                
								res=`$build_str`
            fi
			  fi
			  fts=$res" "$fts
			  
			# "bad" inserted as dummy class; satisfy weka
			echo $fts | awk '{ for (i = 1; i <= NF; i++) printf "%3.5f,",$i; printf "bad\n"}' >> $outfile
			rm -rf gpu_proglist
		else 
			perf_counter $outfile temp_hex_codes $exec   
		fi
  fi
done < $progfile

# cleanup tmp files 
rm -f temp_hex_codes

