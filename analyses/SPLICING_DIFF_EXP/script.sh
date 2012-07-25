. ${RESOURCES_SCALA_SHELL_SCRIPT}

SPLICING_PLAN_FILENAME="${SGE_O_WORKDIR}/splicejunctioncoverage-groups.tsv"
function plugin_alignment_analysis_split {
	local SPLICING_PLAN_RESULT=$2
    cp ${SGE_O_WORKDIR}/splicejunctioncoverage-groups.tsv ${SPLICING_PLAN_RESULT}
    # the split plan was already built as the file splicejunctioncoverage-groups.tsv

}

# This function return the number of parts in the slicing plan. It returns zero if the alignments could not be split.
function plugin_alignment_analysis_num_parts {
	local SPLICING_PLAN_FILE=$1

	if [ $? -eq 0 ]; then
		return `wc -l < ${SPLICING_PLAN_FILENAME}`
	fi

	return 0
}

function plugin_alignment_analysis_process {

	local SPLICING_PLAN_FILENAME=$1
	local CURRENT_PART=$2

	#get basenames for this part
	local SOURCE_LINE=`sed -n ${CURRENT_PART}p < ${SPLICING_PLAN_FILENAME}`
	local SOURCE_PATH=`echo ${SOURCE_LINE} |cut -d " " -f 1`  # first token is scp path for Splice file.
	local SOURCE_GROUP=`echo ${SOURCE_LINE} |cut -d " " -f 2` # Second token is the group

	#copy over splice data
	scp "${SOURCE_PATH}" ${TAG}-stats-${CURRENT_PART}.tsv
	#	 ${SGE_O_WORKDIR}/split-results/"${CURRENT_PART}_SpliceJunctionCoverage.tsv"

	if [ $? -eq 0 ]; then
		echo "found splice junction coverage data for sample "
	else

		echo "found splice junction coverage data could not be found"
	fi
}


# This function is called after the analysis parts have finished executing
. ${RESOURCES_R_SHELL_SCRIPT}
. constants.sh
. auto-options.sh
function plugin_alignment_analysis_combine {

   RESULT_FILE=$1
   shift
   PART_RESULT_FILES=$*

    scala ${PLUGIN_NEED_COMBINE_JVM} goby.jar ${SGE_O_WORKDIR}/Process.scala ${PART_RESULT_FILES} > counts.tsv
    dieUponError  "Cannot reformat counts for R pacakage."

    cp ${SGE_O_WORKDIR}/sampleGroups.tsv .
    dieUponError  "Cannot copy sample to group mapping information to local directory."

    SAMPLE_GROUP_MAPPING="sampleGroupMapping=sampleGroups.tsv"
    DESEQ_GENE_INPUT="geneInput=counts.tsv"

    # Run DESeq or EdgeR to estimate p-values:
    DESEQ_OUTPUT="output=junctions.tsv graphOutput=.png"
    run-R -f ${RESOURCES_DESEQ_SCRIPT_R_SCRIPT} --slave --quiet --no-restore --no-save \
           --no-readline --args ${DESEQ_OUTPUT} ${DESEQ_GENE_INPUT} ${SAMPLE_GROUP_MAPPING}
    dieUponError  "Calling statistics with R script failed."

}