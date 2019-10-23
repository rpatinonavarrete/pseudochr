#!/bin/bash


usage()
{
cat << EOF
usage: $0 options

generates a pseudo-chromosome

OPTIONS:
   -h      Show help message
   -f      Reference genome (.fasta) [REQUIRED]
   -b      Bam/sam File [REQUIRED]
   -o      outputfolder
   -v      vcfFile
   -x      min coverage
EOF
}

FASTA=
MPILEUP=
BAM=
OUT=
VCFFILE=
MINCVG=

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN="bin"
PLS="pseudoGenome.pl"
#NORM="picard-tools NormalizeFasta"

while getopts “hf:b:o:v:x:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         f)
             FASTA=$OPTARG
             ;;

         b)
             BAM=$OPTARG
             ;;
         o)
             OUT=$OPTARG
             ;;
         v)
             VCFFILE=$OPTARG
             ;;
         x)
             MINCVG=$OPTARG
             ;;
     esac
done

if [[ -z ${FASTA} ]] || [[ -z ${BAM} ]] || [[ -z ${VCFFILE} ]]
then
     echo "ERROR : Please supply the appropriate input files"
     usage
     exit 1
fi

if [[ -z ${OUT} ]]
then 
OUT="output"
fi


if [[ ! -d ${OUT} ]]
then 
mkdir ${OUT}
fi

if [[ ! -d ${OUT}"/mpileupFiles" ]]
then
mkdir ${OUT}"/mpileupFiles"
fi

if [[ ! -d ${OUT}"/pseudoFasta" ]]
then
mkdir ${OUT}"/pseudoFasta"
fi

if [[ -f ${DIR}"/"${BIN}"/"${PLS} && -x ${DIR}"/"${BIN}"/"${PLS} ]]
then
echo "scripts in bin folder ok"
else
chmod +x ${DIR}"/"${BIN}"/"${PLS}
fi

VCF=$(basename ${VCFFILE})
MPILEUP=${VCF%%.vcf}".mpileup"


# run samtools mpileup


MPILEUPFILES=$OUT"/mpileupFiles"

samtools mpileup -f ${FASTA} -o ${MPILEUPFILES}/${MPILEUP} -Q 0 -A -a ${BAM}

PSEUDOFASTA=$OUT"/pseudoFasta"

${DIR}"/"${BIN}"/./"${PLS} -p ${MPILEUPFILES}/${MPILEUP} -v ${VCFFILE} \
	-o ${PSEUDOFASTA}/${MPILEUP%%.mpileup}.fasta -x ${MINCVG}

picard-tools NormalizeFasta I=${PSEUDOFASTA}/${MPILEUP%%.mpileup}.fasta \
	O=${PSEUDOFASTA}/${MPILEUP%%.mpileup}.norm.fasta LINE_LENGTH=60

rm ${PSEUDOFASTA}/${MPILEUP%%.mpileup}.fasta
mv ${PSEUDOFASTA}/${MPILEUP%%.mpileup}.norm.fasta ${PSEUDOFASTA}/${MPILEUP%%.mpileup}.fasta


