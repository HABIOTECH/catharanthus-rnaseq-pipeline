================================================================================
 Catharanthus roseus RNA-seq ANALYSIS PIPELINE  (all codes, arranged in steps)
================================================================================

A complete step-by-step workflow for mapping RNA-seq reads to the
Catharanthus roseus (Madagascar periwinkle) reference genome, generating
gene-level read counts, and extracting sequences for differentially expressed
genes (DEGs). Includes HPC job templates (SGE and Slurm) and a re-mapping
routine against an alternative reference.

Steps are grouped into 3 phases and numbered in order. Replace /path-to-data/...
with your real data directory.


--------------------------------------------------------------------------------
 REQUIREMENTS
--------------------------------------------------------------------------------
  Tool        Version       Purpose
  ----------  ------------  --------------------------------
  HISAT2      2.0.1 / 2.1.0 Read alignment / genome indexing
  SAMtools    1.8           SAM->BAM, sort, index, flagstat
  Subread     2.0.5         featureCounts read counting
  gtftools    latest        Gene length extraction
  Python      3.x           DEG sequence extraction
  Python libs pandas, biopython, openpyxl   (Step 9 script)
  Scheduler   SGE or Slurm  Submitting jobs on the cluster

  Install Python libraries:
    pip install gtftools gffutils pandas biopython openpyxl


================================================================================
 PHASE 1 - HPC JOB SUBMISSION TEMPLATES
================================================================================
These are reusable wrappers for running the pipeline on a cluster. Put your
pipeline commands (Phase 2) inside whichever template matches your scheduler.


--------------------------------------------------------------------------------
 STEP 1 - SGE JOB TEMPLATE (qsub)
--------------------------------------------------------------------------------
Save as sge_template.sh, add your commands where indicated, then submit with:
qsub sge_template.sh
It creates a private scratch directory, initializes environment modules, and
cleans up automatically when the job ends.

#!/bin/sh
## Basic SGE job template (submit with: qsub sge_template.sh)

#$ -S /bin/sh          # interpreting shell
#$ -cwd                # run in current working directory
#$ -j y                # merge stdout + stderr
#$ -o sge_template_stdout
#$ -l h_vmem=16G       # memory per slot
#$ -pe threaded 1      # cores (only for multi-core jobs)
#$ -R y                # reservation for multi-core jobs

echo "** Job Execution on Host: `hostname`"

# --- Set up a private scratch directory ---
TMP=/scratch/${LOGNAME}/job-${JOB_ID}
if [ -z "${JOB_ID}" -o -d "${TMP}" ] ; then
    TMP=/scratch/${LOGNAME}/pid-$$
    if [ -d "${TMP}" ] ; then echo "ABORT: Scratch dir exists."; exit 1; fi
fi
if [ "${TMP}" = "/" ] ; then echo "ABORT: Scratch dir cannot be '/'!"; exit 1; fi
echo " ===> Scratch Directory -> ${TMP}"

# Purge scratch on exit
trap 'if [ -d "${TMP}" ] ; then echo "... Purging scratch"; (rm -rf "${TMP}") & fi' 0 1 3 15

TEMP="${TMP}"; TMPDIR="${TMP}"; export TMP TEMP TMPDIR
mkdir -p "${TMP}" || { echo "ABORT: cannot create ${TMP}"; exit 1; }

# --- Initialize environment modules ---
. /etc/profile.d/00-site.sh
. /etc/profile.d/modules.sh
module load sge
module load samtools/1.8

echo "starting at `date`"

## <<< INSERT YOUR PIPELINE COMMANDS HERE (see Phase 2) >>>

echo "finished at `date`"

# --- Clean up scratch ---
if [ -d "${TMP}" ] ; then echo "... Purging scratch directory"; (rm -rf "${TMP}"); fi


--------------------------------------------------------------------------------
 STEP 2 - SLURM JOB TEMPLATE (sbatch)
--------------------------------------------------------------------------------
Save as hisat2_mapping.sh and submit with: sbatch hisat2_mapping.sh
(The full mapping body for this template is given in Step 10.)

#!/bin/bash
#SBATCH --job-name=hisat2_mapping
#SBATCH --output=hisat2_mapping.out
#SBATCH --error=hisat2_mapping.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=24:00:00

module load hisat2/2.1.0
module load samtools/1.8

## <<< mapping commands go here - see Step 10 >>>


================================================================================
 PHASE 2 - CORE RNA-seq WORKFLOW
================================================================================

--------------------------------------------------------------------------------
 STEP 3 - DOWNLOAD THE REFERENCE GENOME
--------------------------------------------------------------------------------
Reference assembly: GCA_024505715.1_ASM2450571v1 (from NCBI).

BASE="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/024/505/715/GCA_024505715.1_ASM2450571v1"

wget "${BASE}/GCA_024505715.1_ASM2450571v1_genomic.fna.gz"   # genome sequence
wget "${BASE}/GCA_024505715.1_ASM2450571v1_genomic.gbff.gz"  # GenBank annotation
wget "${BASE}/GCA_024505715.1_ASM2450571v1_genomic.gff.gz"   # GFF annotation
wget "${BASE}/GCA_024505715.1_ASM2450571v1_genomic.gtf.gz"   # GTF annotation

gunzip *.gz


--------------------------------------------------------------------------------
 STEP 4 - BUILD THE HISAT2 GENOME INDEX
--------------------------------------------------------------------------------
module load hisat2/2.0.1-beta

hisat2-build -p 16 \
    GCA_024505715.1_ASM2450571v1_genomic.fna \
    Cr_GCA_024505715_index

# Produces index files Cr_GCA_024505715_index.*.ht2 used for alignment.


--------------------------------------------------------------------------------
 STEP 5 - ALIGN READS TO THE REFERENCE
--------------------------------------------------------------------------------
Single-end cleaned reads aligned to the index, one SAM per sample.

GENOME_DIR="/path-to-data/bioinformatics/Cr_genome_data/new_genome"
INDEX="${GENOME_DIR}/Cr_GCA_024505715_index"

samples=(SRR122242 SRR122251 SRR122252 SRR122253 SRR122254 SRR122257)

for S in "${samples[@]}"; do
    hisat2 -f -x "$INDEX" \
        -U "${GENOME_DIR}/${S}_1_cleaned.fastq" \
        -S "${GENOME_DIR}/${S}_aligned.sam"
done


--------------------------------------------------------------------------------
 STEP 6 - CONVERT SAM -> SORTED, INDEXED BAM
--------------------------------------------------------------------------------
for S in "${samples[@]}"; do
    samtools view -bS "${GENOME_DIR}/${S}_aligned.sam"  > "${GENOME_DIR}/${S}_aligned.bam"
    samtools sort      "${GENOME_DIR}/${S}_aligned.bam" -o "${GENOME_DIR}/${S}_aligned_sorted.bam"
    samtools index     "${GENOME_DIR}/${S}_aligned_sorted.bam"
done


--------------------------------------------------------------------------------
 STEP 7 - GENERATE GENE-LEVEL READ COUNTS
--------------------------------------------------------------------------------
module load subread/2.0.5

GTF="${GENOME_DIR}/GCA_024505715.1_ASM2450571v1_genomic.gtf"

for S in "${samples[@]}"; do
    featureCounts -T 8 -a "$GTF" \
        -o "${S}_raw_counts.txt" \
        "${S}_aligned_sorted.bam"
done


--------------------------------------------------------------------------------
 STEP 8 - EXTRACT GENE LENGTHS FROM THE GTF
--------------------------------------------------------------------------------
Gene lengths are needed for downstream normalization (TPM/RPKM).

head GCA_024505715.1_ASM2450571v1_genomic.gtf        # inspect the file
gtftools -l Cr_gene_lengths.txt GCA_024505715.1_ASM2450571v1_genomic.gtf


================================================================================
 PHASE 3 - RE-MAPPING AGAINST ALTERNATIVE GENOMES
================================================================================

--------------------------------------------------------------------------------
 STEP 9 - RE-MAP TO THE NEW CHINESE Cr GENOME (SLURM)
--------------------------------------------------------------------------------
Full body for the Step 2 Slurm template. Handles paired-end and single-end
samples in one job.

# Paths
GENOME_DIR="/path-to-data/bioinformatics/Cr_genome_data/New_chineese_genome"
DATA_DIR="/path-to-data/bioinformatics/Cr_genome_data"
INDEX_PREFIX="${GENOME_DIR}/Cro-Chineese_index"

cd "$DATA_DIR"

paired_ids=(SRR122236 SRR122237 SRR122238)
single_ids=(SRR122242 SRR122243 SRR122245 SRR122251 SRR122252 SRR122253 SRR122254 SRR122257)

# --- Paired-end reads ---
for id in "${paired_ids[@]}"; do
    echo "Processing paired-end: $id"
    hisat2 -p 16 -x "$INDEX_PREFIX" \
        -1 "${id}_1_cleaned.fastq" \
        -2 "${id}_2_cleaned.fastq" \
        -S "${id}.sam"
    samtools view -@ 8 -bS "${id}.sam" | samtools sort -@ 8 -o "${id}_sorted.bam"
    samtools index "${id}_sorted.bam"
    samtools flagstat "${id}_sorted.bam" > "${id}_sorted_flagstat.txt"
done

# --- Single-end reads ---
for id in "${single_ids[@]}"; do
    echo "Processing single-end: $id"
    hisat2 -p 16 -x "$INDEX_PREFIX" \
        -U "${id}_1_cleaned.fastq" \
        -S "${id}.sam"
    samtools view -@ 8 -bS "${id}.sam" | samtools sort -@ 8 -o "${id}_sorted.bam"
    samtools index "${id}_sorted.bam"
    samtools flagstat "${id}_sorted.bam" > "${id}_sorted_flagstat.txt"
done

echo "All HISAT2 alignments completed."


--------------------------------------------------------------------------------
 STEP 10 - POST-PROCESS OS-GENOME ALIGNMENTS (SAM -> BAM -> SORT -> QC)
--------------------------------------------------------------------------------
Batch conversion, sorting, and flagstat QC for the _new alignments under the
bowtie output directory. Run inside the Step 1 SGE template.

ALN_DIR="/path-to-data/bioinformatics/OS_genome_data/bowtie_alignment"
ids=(SRR122236 SRR122237 SRR122238 SRR122242 SRR122243 SRR122245 \
     SRR122251 SRR122252 SRR122253 SRR122254 SRR122257)

for id in "${ids[@]}"; do
    samtools view -bS "${ALN_DIR}/${id}_new.sam"        -o "${ALN_DIR}/${id}_new.bam"
    samtools sort      "${ALN_DIR}/${id}_new.bam"       -o "${ALN_DIR}/${id}_sorted_new.bam"
    samtools flagstat  "${ALN_DIR}/${id}_sorted_new.bam" > "${ALN_DIR}/flagstat_${id}_new.txt"
done


================================================================================
 CLUSTER JOB SUBMISSION - QUICK REFERENCE
================================================================================
# SGE
qsub sge_template.sh
qsub -pe threaded 8 -R y sge_template.sh   # multi-core
qstat -j <job_id>

# Slurm
sbatch hisat2_mapping.sh
squeue -u $USER


================================================================================
 INPUT DATA (cleaned FASTQ files)
================================================================================
  Paired-end : SRR122236, SRR122237, SRR122238
  Single-end : SRR122242, SRR122243, SRR122245, SRR122251,
               SRR122252, SRR122253, SRR122254, SRR122257
================================================================================
