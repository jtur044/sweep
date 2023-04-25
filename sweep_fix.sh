# SWEEP FIXES 


##  Rebecca

# STEP 1 - re-generate trials 

oknpatch -t trial_data_lost -i "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/trials/trial-2_disk-condition-1-1/trial-2_disk-condition-1-1.csv" -si "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/gaze.csv" 
oknpatch -t trial_data_lost -i "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/trials/trial-4_disk-condition-13-1/trial-4_disk-condition-13-1.csv" -si "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/gaze.csv" 

oknpatch -t trial_data_lost -i "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/trials/trial-4_disk-condition-13-1/trial-4_disk-condition-13-1.csv" -si "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/gaze.csv" 
oknpatch -t trial_data_lost -i "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/trials/trial-2_disk-condition-1-1/trial-2_disk-condition-1-1.csv" -si "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/gaze.csv" 

# STEP 2 - re-generate update files 

oknpatch -t update -i  "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/trials/trial-2_disk-condition-1-1/trial-2_disk-condition-1-1.csv" 
oknpatch -t update -i  "./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/trials/trial-4_disk-condition-13-1/trial-4_disk-condition-13-1.csv" 

oknpatch -t update -i  "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/trials/trial-4_disk-condition-13-1/trial-4_disk-condition-13-1.csv" 
oknpatch -t update -i  "./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len/trials/trial-2_disk-condition-1-1/trial-2_disk-condition-1-1.csv" 


