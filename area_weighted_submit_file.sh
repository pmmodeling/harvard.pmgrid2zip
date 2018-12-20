#!/bin/bash

#SBATCH -p serial_requeue
#SBATCH -o ../output/allyrs_%a.out
#SBATCH -e ../output/allyrs_%a.err
#SBATCH --array=1-440
#SBATCH --mem=8000
#SBATCH -t 20
#SBATCH -J allyrs

export R_LIBS_USER=$HOME/apps/R:$R_LIBS_USER
module load R/3.4.2-fasrc01

R CMD BATCH --quiet --no-restore --no-save areawdt.R ../output/allyrs_${SLURM_ARRAY_TASK_ID}.Rout
