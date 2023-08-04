# SWEEP FIXES 

CONFIG_DIR="/Users/jtur044/Documents/Documents-BN411809/MATLAB/sweep/DATA/BROOKS.PROCESSED/config"

INPUT_DIR="/Users/jtur044/Documents/Documents-BN411809/MATLAB/sweep/DATA/BROOKS.PROCESSED/kj_4_18_23"


vinset -i "$INPUT_DIR/video.mp4" -o "$INPUT_DIR/result/eyetracker/video.graph.mp4" -t graph -c  "$CONFIG_DIR/vinset-graph-overlay.json" -d "$INPUT_DIR/result/eyetracker/results.updated.csv" -tl "$INPUT_DIR/timeline.json"


vinset -i "$INPUT_DIR/result/eyetracker/video.graph.mp4" -o "$INPUT_DIR/result/eyetracker/video.final.mp4" -t text -c  "$CONFIG_DIR/vinset-text-overlay.json" -tl "$INPUT_DIR/timeline.json"


