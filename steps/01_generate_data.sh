#!/bin/bash
#SBATCH --job-name=wf_generate
#SBATCH --output=logs/01_generate_%j.out
#SBATCH --error=logs/01_generate_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
#SBATCH --time=00:05:00
#SBATCH --partition=normal

WORKDIR="${SLURM_SUBMIT_DIR:-/opt/pipeline}"
mkdir -p "$WORKDIR/data" "$WORKDIR/logs"

echo "[$(date '+%H:%M:%S')] Step 1: Generating input dataset"
echo "Job ID   : $SLURM_JOB_ID"
echo "Node     : $(hostname)"
echo ""

python3 - <<'EOF'
import random, json, os

WORKDIR = os.environ.get("SLURM_SUBMIT_DIR", "/opt/pipeline")
N = 10000

random.seed(42)
data = [
    {"id": i, "x": round(random.gauss(0, 1), 4), "y": round(random.gauss(0, 1), 4)}
    for i in range(N)
]

out_path = f"{WORKDIR}/data/raw_data.json"
with open(out_path, "w") as f:
    json.dump(data, f)

print(f"Generated {N} data points -> {out_path}")
print(f"Sample: {data[:3]}")
EOF

echo ""
echo "[$(date '+%H:%M:%S')] Step 1 complete."
