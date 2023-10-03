#!/bin/bash


# OKNRESWEEP  Re-run an OKN detection pipeline on a "experiment" or on a "trial"
# 
# Where "experiment" is a collection of "trials"  
#  
#
#
#  ./experiment 
#		/trial 1
#		...
#		/trial N
#
# Usage: $0 [-t|c] [-i <source_directory>] [-o <output_label>] [-l <re-trial-name>]
#
# Options:
# 
#		-t 	is a flag "trial mode" (present) or "experiment mode" (absent)
#		-c 	is create from <source_directory>
#		-i  is the input "trial" | "experiment" directory 
#		-l  is the re-trial output label [RETRIAL000]
#		-o  is the output label (<source_directory>)
#
#
#
# Examples:
#
# ./oknresweep.sh -i ./DATA/12Sep2023/mtur_12_09_2023_sweep_right_p_1_3_0
#
#  # oknresweep -c -i <source_directory>  -l <output_label>		copy original to new location 
#  oknresweep -r -i <source_directory>  -l <output_label>		re-run the source experiment directory  
#  oknresweep -t -i <source_directory>  -l <output_label>		re-run the source trial directory  
#
#
# Experiment mode : 
# 
# This program will copy the source trials into the output trials directory 
# At present this program requires a directory in which to store data with a 
# "config" directory. 
#
# The config. directory will have the following 
#
#		okn detection configuration 
#		va algorithm parameters 
#
#
# Trial mode : 
# 
# This will change a particular trial specified by the input "trial" directory 
#
#
# Configuration :
#
# Configuration information 
#
#  ./experiment 
#		config/
#			<trial_label>/
#				decide.config.json
#				okndetector.gaze.config
#


# INFORMATION
#
# -i input directory 
# -l trial label  
# -t trial or directory   
# -o output label [OPTIONAL] 


usage() { echo "Usage: $0 [-c] [-i <source_directory>] [-l <output label>] [-t <trial_name>]" 1>&2; exit 1; }

trial_mode=false; # directory mode

while getopts "ci:l:t:" o; do
    case "${o}" in


        i)  # set the input source directory 
            input_directory=${OPTARG}
			echo "Input Directory=${OPTARG}"
            ;;

        t)	# set the trial name  

			trial_name=${OPTARG}
			trial_mode=true
			;;

	
		l)  # set the label  			
			trial_label=${OPTARG}			
			;;
        o)
			output_directory=${OPTARG}
			#echo "Output directory=${OPTARG}"
			;;

        *)
			# called on unknown option
            usage
            ;;
    esac
done

if [ $OPTIND -eq 1 ]; then usage; fi

#if [ -z "${s}" ] || [ -z "${p}" ]; then
#    usage
#fi


# Set the input/output directory 
if [ -z ${input_directory+x} ];  
then 
	input_directory="/Users/jtur044/Documents/MATLAB/va_by_okn/DATA/hgho_15_12_2022_long_2_25";
fi
echo "Input directory is $input_directory"; 
output_directory=$input_directory


# Set the rerun information  
if [ -z ${trial_label+x} ]; 
then 
	trial_label="retrial000" 
fi 

echo "re-run label is '$trial_label'"; 
shift $((OPTIND-1))


function setdirectories () {

		# input locations 
		input_config_dir=$input_directory/config
		trial_directories=$(find $input_directory/trials -type d -mindepth 1 -maxdepth 1);
		files=$(find $input_directory/trials -name "updated*.csv");


		# set output locations  		

		output_dir=$input_directory/$trial_label
		output_config_dir=$output_dir/config		
		input_decide_config=$input_config_dir/$trial_label/decide.config.json
		input_detector_config=$input_config_dir/$trial_label/okndetector.gaze.updated.config

		#echo "input_dir  = $input_directory"
		#echo "output_dir = $output_dir"

}


setdirectories 



# exit

: '
	Create a new instance of "trial_label". Copy with -n to prevent clobbering.

	

if [ "${create_mode}" == true ]; 
then 

	echo "Creating '$trial_label' in '$input_directory'"; 

	mkdir -p "$output_dir"

	# cp all directories over 
	for d in $trial_directories;
	do
		# copy the original directory to RETRIAL001 directory 
		#echo cp -n -r "$d" "$output_dir"
		cp -n -r "$d" "$output_dir"
	done 
	echo "Copied trial directories."

	# cp default config files as well
	cp -n -a "$input_config_dir/." "$output_config_dir"	
	echo "Copied configuration files."

	# cp default okn_detector_summary.csv/png files 

	cp -n "$input_directory/trials/okn_detector_summary.csv" "$output_dir"	
	cp -n "$input_directory/trials/okn_detector_summary.png" "$output_dir"	
	echo "Copied summary files."


	# should probably drop to a full re-run

	exit 0

fi

'



function runtrial () {

	: '

		This will run 

				1 - okndetector   run OKN detection on a trial   
				2 - okntool   	  export a graph for the trial  
				3 - oknconvert 	  convert result.json to result.CSV  
				4 - okndecide     generate an OKN decision 

	'


	basename=$(basename -- "$1")

	okn_output_dir=${output_dir}/$basename
	okn_input=$input_directory/trials/$basename/updated_$basename.csv 
	okn_retrial_file=$input_directory/$trial_label/$basename/updated_$basename.csv 

	echo cp -f "$okn_input" "$okn_retrial_file"
	cp -f "$okn_input" "$okn_retrial_file"

	okn_input_plot_config=$input_directory/config/${trial_label}/oknserver_graph_plot_config.json

	echo "$okn_input"

	# run OKN detector 
	echo okndetector -i "$okn_input" -o "$okn_output_dir/result" -c "$input_detector_config"	
	okndetector -i "$okn_input" -o "$okn_output_dir/result" -c "$input_detector_config"


	# create new per trial diagrams 
	echo okntool -c "${okn_input_plot_config}" -d "$okn_output_dir" -t "trial"
	okntool -c "${okn_input_plot_config}" -d "$okn_output_dir" -t "trial"


	# rerun the result.json format converter 
	okn_result_json=$okn_output_dir/result/result.json 
	okn_result_csv=$okn_output_dir/result/result.csv 
	echo oknconvert -i "$okn_result_json" -o "$okn_result_csv" 
	oknconvert -i "$okn_result_json" -o "$okn_result_csv"


	# rerun the OKN DECISION maker

	okn_signal_data=$okn_output_dir/result/signal.csv
	okn_decision_data=$okn_output_dir/result/decision.json
	okn_decide_config=$input_decide_config


	echo okndecide -i "$okn_signal_data" -c "$okn_decide_config" > "$okn_decision_data"
	okndecide -i "$okn_signal_data" -c "$okn_decide_config" > "$okn_decision_data"



}


: '
#############################################
#
# Regenerate the OKN_DETECTOR_SUMMARY.CSV 
#
#
# Assumes that a VALID one is already present 
#				
#############################################
'


function runpost () {



# output file  

okn_input_plot_config=$input_directory/config/${trial_label}/oknserver_graph_plot_config.json


# copy the okn_detector_summary from original to RETRIAL

output_okn_summary_data=$output_dir/okn_detector_summary.csv
cp -f $input_directory/trials/okn_detector_summary.csv  $output_okn_summary_data
echo "Copying okn_detector_summary to ${output_okn_summary_data}"

# input file 

okn_summary_data=$(mktemp)
echo "TEMPFILE = ${okn_summary_data}"
cat $output_okn_summary_data>$okn_summary_data
trap "rm -f $okn_summary_data" EXIT


# find index of header fields 

okn_flag='okn_matlab'
trial_id='trial_id'
disk_condition='disk_condition'	

i_okn_flag=$(head -1 $okn_summary_data | tr ',' '\n' | nl |grep -w "$okn_flag" | tr -d " " | awk -F " " '{print $1}')-1
i_trial_id=$(head -1 $okn_summary_data | tr ',' '\n' | nl |grep -w "$trial_id" | tr -d " " | awk -F " " '{print $1}')-1
i_disk_condition=$(head -1 $okn_summary_data | tr ',' '\n' | nl |grep -w "$disk_condition" | tr -d " " | awk -F " " '{print $1}')-1


# read in a complete file 

exec < $okn_summary_data
read header 


echo "Writing ... $output_okn_summary_data"
echo "$header" > "$output_okn_summary_data"

while IFS= read line 
do


	# read in each line 

    IFS=, read -ra my_array <<< "$line" 

	# load in relevant decision.json file 

	result=0

	trial_id=${my_array[$i_trial_id]}
	disk_condition=${my_array[$i_disk_condition]}


	# read in generated decision.json file

	decision_file="$output_dir/${trial_id}_${disk_condition}/result/decision.json"
	okn_present=$(jq ".okn_present" < "$decision_file")
	okn_present=`echo $okn_present | sed -e 's/^[[:space:]]*//'`

	if [[ "$okn_present" == "true" ]];
	then 
		okn_present=1
	elif [[ "$okn_present" == "false" ]]; 
	then
		okn_present=0
	else 
		okn_present=null
		echo "Null Error!"
	fi
	

	# change the read in fields 

	my_array[$i_okn_flag]=$okn_present

	# output the fields to a file 

	IFS=,
	output_line="${my_array[*]}"

	echo "$output_line"


	# output the line to the final file	
	echo "$output_line" >> "$output_okn_summary_data"
done 


# create new summary diagrams 

echo "SUMMARY GRAPH"
echo okntool -c "${okn_input_plot_config}" -d "$output_dir" -t "summary"
okntool -c "${okn_input_plot_config}" -d "$output_dir" -t "summary"



}




# Trial mode re-run for a single valid trial.

if [ "${trial_mode}" == true ]; 
then 

	echo "Running trial '$trial_name' ('$trial_label') in '$input_directory'"; 
	runtrial "$trial_name"

	# regenerate final summary across all trials
	runpost 
	exit 0

fi


# Directory mode 

#for d in $trial_directories;
#do
#	runtrial $d
#done

runpost
exit 0
