#!/bin/bash
#SBATCH --job-name=wf_aggregate
#SBATCH --output=logs/03_aggregate_%j.out
#SBATCH --error=logs/03_aggregate_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
#SBATCH --time=00:05:00
#SBATCH --partition=normal

WORKDIR="${SLURM_SUBMIT_DIR:-/opt/pipeline}"

echo "[$(date '+%H:%M:%S')] Step 3: Aggregating results"
echo "Job ID    : $SLURM_JOB_ID"
echo "Node      : $(hostname)"
echo "Depends on: step 2 (wf_process)"
echo ""

python3 - <<'EOF'
import json, math, os

WORKDIR = os.environ.get("SLURM_SUBMIT_DIR", "/opt/pipeline")
in_path  = f"{WORKDIR}/data/processed_data.json"
out_path = f"{WORKDIR}/data/summary_report.json"

with open(in_path) as f:
    data = json.load(f)

def stats(values):
    n    = len(values)
    mean = sum(values) / n
    var  = sum((v - mean) ** 2 for v in values) / n
    return {"n": n, "mean": round(mean, 4), "std": round(math.sqrt(var), 4),
            "min": round(min(values), 4), "max": round(max(values), 4)}

report = {
    "total_records":  len(data),
    "distance_stats": stats([r["distance"] for r in data]),
    "angle_stats":    stats([r["angle"]    for r in data]),
    "x_stats":        stats([r["x"]        for r in data]),
    "y_stats":        stats([r["y"]        for r in data]),
    "quadrant_counts": {
        f"Q{q}": sum(1 for r in data if r["quadrant"] == q)
        for q in range(1, 5)
    },
}

with open(out_path, "w") as f:
    json.dump(report, f, indent=2)

print("=== PIPELINE SUMMARY REPORT ===")
print(f"Total records  : {report['total_records']:,}")
print(f"Distance       : mean={report['distance_stats']['mean']}  "
      f"std={report['distance_stats']['std']}  "
      f"max={report['distance_stats']['max']}")
print(f"X stats        : mean={report['x_stats']['mean']}  std={report['x_stats']['std']}")
print(f"Y stats        : mean={report['y_stats']['mean']}  std={report['y_stats']['std']}")
print(f"Quadrants      : {report['quadrant_counts']}")
print(f"\nFull report written -> {out_path}")
EOF

echo ""
echo "[$(date '+%H:%M:%S')] Step 3 complete. Pipeline finished."
