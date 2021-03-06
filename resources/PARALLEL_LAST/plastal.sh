
JOB_DIR=$1
ALIGN_COMMAND=$2
READS_FOR_SPLIT=$3
OUTPUT=$4
NUM_THREADS=`grep physical  /proc/cpuinfo |grep id|wc -l`
NUM_THREADS=$((${NUM_THREADS} - 2))
if [ ${NUM_THREADS} -lt 2 ]; then
   # Make sure we use at least two threads:
   NUM_THREADS=2
fi

# Grab the variables and functions we need:
. ${JOB_DIR}/constants.sh
. ${JOB_DIR}/auto-options.sh
. ${RESOURCES_GOBY_SHELL_SCRIPT}

# This script splits a compact-reads file in num-parts (n) and executes ALIGN_COMMAND on each bit. It concatenates alignments that result to produce OUTPUT
java ${GRID_JVM_FLAGS} -Dlog4j.debug=true -Dlog4j.configuration=file:${JOB_DIR}/goby/log4j.properties \
                       -Dgoby.configuration=file:${TMPDIR}/goby.properties \
                       -jar ${RESOURCES_GOBY_GOBY_JAR} \
                       --mode run-parallel -i "${READS_FOR_SPLIT}" -n "${NUM_THREADS}" -o "${OUTPUT}"  ${ALIGN_COMMAND} ${READS_FOR_SPLIT} %read.fastq% %tmp1% %output% ${JOB_DIR}
