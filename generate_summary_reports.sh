


EXPT_DIR=./DATA/EXPERIMENT


mustache $EXPT_DIR/participant_info_lab/summary-rx-group-Automated.json $EXPT_DIR/report_template.mustache > $EXPT_DIR/participant_info_lab/experiment-report-rx-group-Automated.html    
mustache $EXPT_DIR/participant_info_lab/summary-norx-group-Automated.json $EXPT_DIR/report_template.mustache > $EXPT_DIR/participant_info_lab/experiment-report-norx-group-Automated.html    
mustache $EXPT_DIR/participant_info_lab/summary-rx-group-Manual.json $EXPT_DIR/report_template.mustache > $EXPT_DIR/participant_info_lab/experiment-report-rx-group-Manual.html    
mustache $EXPT_DIR/participant_info_lab/summary-norx-group-Manual.json $EXPT_DIR/report_template.mustache > $EXPT_DIR/participant_info_lab/experiment-report-norx-group-Manual.html    
