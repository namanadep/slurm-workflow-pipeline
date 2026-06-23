#!/bin/bash
#SBATCH --job-name=wf_process
#SBATCH --output=logs/02_process_%j.out
#SBATCH --error=logs/02_process_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
#SBATCH --time=00:10:00
#SBATCH --partition=normal

WORKDIR="${SLURM_SUBMIT_DIR:-/opt/pipeline}"

echo "[$(date '+%H:%M:%S')] Step 2: Processing data"
echo "Job ID    : $SLURM_JOB_ID"
echo "Node      : $(hostname)"
echo "Depends on: step 1 (wf_generate)"
echo ""

python3 - <<'EOF'
import json, math, os

WORKDIR = os.environ.get("SLURM_SUBMIT_DIR", "/opt/pipeline")
in_path  = f"{WORKDIR}/data/raw_data.json"
out_path = f"{WORKDIR}/data/processed_data.json"

with open(in_path) as f:
    data = json.load(f)

print(f"Loaded {len(data)} records from {in_path}")

# Compute derived features: distance from origin, angle
processed = []
for rec in data:
    x, y = rec["x"], rec["y"]
    processed.append({
        "id":       rec["id"],
        "x":        x,
        "y":        y,
        "distance": round(math.sqrt(x**2 + y**2), 4),
        "angle":    round(math.degrees(math.atan2(y, x)), 4),
        "quadrant": (1 if x >= 0 and y >= 0 else
                     2 if x < 0  and y >= 0 else
                     3 if x < 0  and y < 0  else 4),
    })

with open(out_path, "w") as f:
    json.dump(processed, f)

# Quick summary
distances = [r["distance"] for r in processed]
mean_d = sum(distances) / len(distances)
max_d  = max(distances)
min_d  = min(distances)
print(f"Distance stats: min={min_d:.4f}  mean={mean_d:.4f}  max={max_d:.4f}")
print(f"Quadrant counts: " +
      ", ".join(f"Q{q}={sum(1 for r in processed if r['quadrant']==q)}" for q in range(1,5)))
print(f"Written {len(processed)} records -> {out_path}")
EOF

echo ""
echo "[$(date '+%H:%M:%S')] Step 2 complete."
