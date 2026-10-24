#!/bin/bash
# v2 pipeline from features onward. Every step skips work whose output already exists (resumable).
set -e
D="/content/drive/MyDrive/MLC'26"
cd /content/ber/src
export BER_WORK=/content/work BER_OUT=/content/out BER_DATA="$D/student_resource/dataset"
SYNC="$D/work_v2"; mkdir -p "$SYNC" "$D/code_v2"
sync_code() { cp /content/ber/src/*.py /content/run_rest.sh "$D/code_v2/"; }
sync_code
echo "== features $(date)"
for s in train test; do
  python s3_features.py $s prep
  for j in 0 1 2 3 4 5 6 7; do python s3_features.py $s $j; done
done
cp /content/work/*_feat2_*.parquet "$SYNC/" || true
echo "== stage1 $(date)"; python s4_train.py 1
cp /content/work/xgb_s1_* /content/work/val_stage1.json /content/work/p1_*.parquet "$SYNC/" || true
echo "== write stage1 submission $(date)"; BER_OUT=/content/out_s1 python s6_write.py 1
python "$D/student_resource/utils/validate_submission.py" --matching /content/out_s1/matching_results.tsv \
  --candidate /content/out_s1/candidate_pairs.tsv --test-dir "$D/student_resource/dataset/test" || true
mkdir -p "$D/output_s1"; cp /content/out_s1/*.tsv "$D/output_s1/"
echo "== comp $(date)"; python s5_comp.py
echo "== stage2 $(date)"; python s4_train.py 2
cp /content/work/xgb_s2_* /content/work/val_stage2.json /content/work/p2_*.parquet "$SYNC/" || true
echo "== write $(date)"; python s6_write.py 2
python "$D/student_resource/utils/validate_submission.py" --matching /content/out/matching_results.tsv \
  --candidate /content/out/candidate_pairs.tsv --test-dir "$D/student_resource/dataset/test"
mkdir -p "$D/output_v2"; cp /content/out/*.tsv "$D/output_v2/"; sync_code
echo "== ALL DONE $(date)"
