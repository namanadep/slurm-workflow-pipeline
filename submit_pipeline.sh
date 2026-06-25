#!/bin/bash
# Submits a 3-step pipeline where each step waits for the previous to COMPLETE
# successfully before starting. Uses --dependency=afterok.
#
# Usage: bash submit_pipeline.sh [workdir]
#   workdir defaults to $PWD

set -euo pipefail

WORKDIR="${1:-$PWD}"
STEPS_DIR="$(cd "$(dirname "$0")/steps" && pwd)"
mkdir -p "$WORKDIR/logs" "$WORKDIR/data"

echo "========================================"
echo " Submitting 3-step Slurm pipeline"
echo " Work directory: $WORKDIR"
echo "========================================"

# Step 1: no dependency
JOB1=$(sbatch --chdir="$WORKDIR" \
              --export=ALL,SLURM_SUBMIT_DIR="$WORKDIR" \
              "$STEPS_DIR/01_generate_data.sh" | awk '{print $NF}')
echo "Step 1 submitted: Job $JOB1 (wf_generate)"

# Step 2: runs only if step 1 succeeded (exit code 0)
JOB2=$(sbatch --dependency=afterok:$JOB1 \
              --chdir="$WORKDIR" \
              --export=ALL,SLURM_SUBMIT_DIR="$WORKDIR" \
              "$STEPS_DIR/02_process_data.sh" | awk '{print $NF}')
echo "Step 2 submitted: Job $JOB2 (wf_process) - depends on $JOB1"

# Step 3: runs only if step 2 succeeded
JOB3=$(sbatch --dependency=afterok:$JOB2 \
              --chdir="$WORKDIR" \
              --export=ALL,SLURM_SUBMIT_DIR="$WORKDIR" \
              "$STEPS_DIR/03_aggregate.sh" | awk '{print $NF}')
echo "Step 3 submitted: Job $JOB3 (wf_aggregate) - depends on $JOB2"

echo ""
echo "========================================"
echo " Pipeline queued. Job chain:"
echo "  $JOB1 --> $JOB2 --> $JOB3"
echo "========================================"
echo ""
echo "Monitor with:"
echo "  watch -n2 squeue --format='%.8i %.12j %.8u %.2t %.10M %R'"
echo ""
echo "Check results when done:"
echo "  sacct --format=JobID,JobName,State,ExitCode,Elapsed -j $JOB1,$JOB2,$JOB3"
