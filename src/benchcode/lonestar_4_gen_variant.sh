#!/bin/bash


if [ $# -lt 1 ] || [ $1 == "--help" ]; then
    echo "Usage: "
    echo "       lone_star_gen_variant.sh <options> prog_num"
		echo "Script to build lonestar executables with specified regs, blocksizes etc."
		echo ""
    echo "Options: "
    echo "      -v, --verify; check output agains reference"
		echo "      -i, --input <index>; input graph index; input graphs are numbered from 0-32 (see lonestar_vardefs.sh)"
		echo "      -l, --launch, get launch configuration"
		echo "      -s, --showregs, show register allocation"
    echo "      -c, --codetype [cuda_base, cuda]"
    echo "      -r, --regs REGS; REGS legal values, {16..512}" 
    echo "      -d, --dataset [small, medium, large]"
    echo "      -b, --blocksize BLOCKSIZE; BLOCKSIZE legal values {32..1024}" 
		echo "      -g, --debug"
    exit 0
fi

while [ $# -gt 0 ]; do
  key="$1"
  case $key in
		--full-rebuild)
			rebuild=true
			;;
    -r|--regs)
      maxreg="$2"
      shift 
      ;;
    --reps)
      reps="$2"
      shift 
      ;;
		-i|--input)
			input_index="$2"
			shift
			;;
    -a|--ra)
      ra_level="$2"
      shift 
      ;;
    -v|--verify)
      check=true
      ;;
    -p|--profile)
      profile="$2"
			shift
      ;;
		--opts)
			opts="$2"
			shift
			;;
		--ptx_opts)
			ptx_opts="$2"
			shift
			;;
    -g|--debug)
      debug=true
      ;;
    -d|--dataset)
      dataset="$2"
      shift 
      ;;
    -b|--blocksize)
      blocksize="$2"
      shift 
      ;;
    -m|--max_thrds)
      max_thrds="$2"
      shift 
      ;;
    -n|--min_blks)
      min_blks="$2"
      shift 
      ;;
    -c|--codetype)
      ver="$2"
      shift 
      ;;
    -l|--launch)
      launch=true
      ;;
    --mem)
      placement="$2"
			shift
      ;;
    --embed)
      embed=true
      ;;
    -s|--showregs)
      showregs=true
      ;;
    --showspills)
      showspills=true
      ;;
    *)
      # unknown option
      if [ "$prog" = "" ]; then
        prog=$1
      else
        echo "Unknown option:" $key
        exit 0
      fi
      ;;
  esac
  shift 
done

[ "$prog" ] || { echo "no program specified. exiting ..."; exit 0; }

# enviornment specific variables; needs to be set at install time 
LONESTAR_HOME=${HOME}/Lonestar4
MAKEFILE_DIR=${LONESTAR_HOME}
RT_DIR=${LONESTAR_HOME}/rt/src

MAKEFILE="arch.mk"

[ -x ${LONESTAR_HOME} ] || { "unable to find Lonestar home directory; exiting ..." ; exit 1; }  


[ "${opts}" ] || { opts="default"; }
[ "${placement}" ] || { placement="dev"; }
[ "${ptx_opts}" ] || { ptx_opts="default"; }

if [ "${maxreg}" = "" ]; then 
	maxreg=default
fi
if [ "${blocksize}" = "" ]; then 
	blocksize=default
fi

if [ ! "${max_thrds}" ]; then 
	if [ ! "${min_blks}" ]; then 
		max_thrds=default
		min_blks=default
	else 
		max_thrds=1024
	fi
else 
	if [ ! "${min_blks}" ]; then 
		min_blks=1
	fi
fi 

#DEBUG=1
if [ $DEBUG ]; then 
   echo $prog
   echo $maxreg
   echo ${max_thrds}
   echo ${min_blks}
   echo $blocksize
	 exit 
fi

source ${HOME}/code/MLTUNE/src/benchcode/lonestar_vardefs.sh ${input_dir}

function build {
  i=$1
  prog=${progs[$i]}
	kernel=${kernels_base[$i]}

  srcdir="${LONESTAR_HOME}/apps/${prog}"
	[ -x ${srcdir} ] || { "unable to find src directory for $prog; exiting ..." ; exit 1; }  

  pushd ${MAKEFILE_DIR} > /dev/null
	
	# create copy of original makefile 
  cp ${MAKEFILE} ${MAKEFILE}.orig
  
	sed -i "s/RALEVEL=/RALEVEL=${ra_level}/" ${MAKEFILE}
  if [ ${opts} != "default" ]; then
    sed -i "s/CC_OPTLEVEL=-O3/CC_OPTLEVEL=-O${opts}/" ${MAKEFILE}
  fi
  if [ ${ptx_opts} != "default" ]; then
    sed -i "s/PTX_OPTLEVEL=-O3/PTX_OPTLEVEL=-O${ptx_opts}/" ${MAKEFILE}
  fi
  if [ ${maxreg} != "default" ]; then
    sed -i "s/REGCAP=/REGCAP=--maxrregcount=${maxreg}/" ${MAKEFILE}
  fi
  if [ ${blocksize} != "default" ]; then
    sed -i "s/ML=/ML=-DML/" ${MAKEFILE}
    sed -i "s/__BLOCKSIZE=/__BLOCKSIZE=-D__BLOCKSIZE=${blocksize}/" ${MAKEFILE}
	fi  
	if [ "${embed}" ]; then 
		sed -i "s/TILED=/TILED=-DTILED/" ${MAKEFILE}
	fi

	# placement 
	if [ ${placement} = "host" ]; then
		sed -i "s/HOST=/HOST=-DHOST/" ${MAKEFILE}
	fi
	if [ ${placement} = "in" ]; then
		sed -i "s/IN=/IN=-DIN/" ${MAKEFILE}
	fi
	if [ ${placement} = "out" ]; then
		sed -i "s/OUT=/OUT=-DOUT/" ${MAKEFILE}
	fi
	if [ ${placement} = "select" ]; then
		sed -i "s/SELECT=/SELECT=-DSELECT/" ${MAKEFILE}
	fi
	if [ ${placement} = "dev" ]; then
		sed -i "s/DEV=/DEV=-DDEV/" ${MAKEFILE}
	fi

  if [ ${max_thrds} != "default" ] || [ ${min_blks} != "default" ]; then 
		sed -i "s/LAUNCH=/LAUNCH=-DLAUNCH/" ${MAKEFILE}
		sed -i "s/ML_MAX_THRDS_PER_BLK=/ML_MAX_THRDS_PER_BLK=-DML_MAX_THRDS_PER_BLK=${max_thrds}/" ${MAKEFILE}
		sed -i "s/ML_MIN_BLKS_PER_MP=/ML_MIN_BLKS_PER_MP=-DML_MIN_BLKS_PER_MP=${min_blks}/" ${MAKEFILE}
	fi

	# clean RT because we need sharedptr to be re-built
	if [ "${rebuild}" ]; then 
			pushd ${RT_DIR}  > /dev/null
			make clean  &> /dev/null
			popd  > /dev/null

			# back in top-level directory 
			make rt # &> /dev/null
	fi
	
  pushd $srcdir > /dev/null

	# commented out for pr experiment; only need to re-compile the srcfile
	# full recompilation takes a long time 
	make clean &> /dev/null
	
  if [ ${blocksize} != "default" ]; then
			case ${prog} in 
				"pr") 
					srcfile=kernel.cu
					;;
				*)
					srcfile=kernel.cu
					;;
			esac
			#commented out because we want to copy the src to src.orig only once, upon install
			#otherwise the .orig will become corrupted if this .sh file terminates before restore
			#and impact all future runs. Can be easily fixed, but users may not notice.
			#			cp ${srcfile} ${srcfile}.orig
  fi  
	
	# touch $srcfile
  (make 2>&1) # > tmp
  spills=`cat tmp | grep "spill" | awk '{print $5 + $9}'`
	regs=`cat tmp | grep ${kernel} -A 2 | grep "registers" | awk '{ print $5 }'`
		#				regs=`cat tmp | grep "registers" | awk '{ print $5 }'`
  if [ "${debug}" ]; then 
			cp tmp regs.dbg
  fi
  
  if [ "${showspills}" ]; then
			echo $spills
  fi
  
  # deprecated (bundled with launch configuration)
  if [ "${showregs}" ]; then 
			echo $regs
  fi
	
  # notify if build failed 
  if [ ! -x ${prog} ]; then 
			echo "FAIL: could not generate variant; make failed for $prog"
			popd > /dev/null
      # back in makefile dir
			cp ${MAKEFILE}.orig ${MAKEFILE}
			popd > /dev/null
			exit 1
  fi
	popd  > /dev/null

	# build successfull back in top-level directory 

	# save a copy of the altered makefile
	cp ${MAKEFILE} ${MAKEFILE}.tmp

  # restore original 
  cp ${MAKEFILE}.orig ${MAKEFILE}
  popd > /dev/null
	# back in directory where script was called from 
}

build $prog


