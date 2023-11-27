#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "CSV2HTMTBL.SH convert a CSV file to an HTML Table"
   echo
   echo "Syntax: csv2htmtbl.sh [-h] -i <input_csv> -t <template_file>"
   echo "options:"
   echo "  h            Print this Help."
   echo " "
   echo "EXAMPLE"
   echo ""
   echo "DIR="/Users/jtur044/Documents/Documents-BN411809/MATLAB/sweep/DATA/EXPERIMENT""
   echo "./csv2htmtbl.sh -i "$DIR/participant_info_lab/summary-rx-group.json" -t "$DIR/report_template.mustache" > "$DIR/participant_info_lab/experiment-report-rx-group.html""
   echo "./csv2htmtbl.sh -i "$DIR/participant_info_lab/summary-norx-group.json" -t "$DIR/report_template.mustache" > "$DIR/participant_info_lab/experiment-report-norx-group.html""

}


################################################################################
# Process the input options. Add options as needed.                            #
################################################################################
# Get the options
while getopts ":i:h:t" option; do
   case $option in
     h) # display Help
         Help
         exit;;

	 i) # inputname  
		 inputfile=$OPTARG
		 ;;

	 t) # template  
		 templatefile=$OPTARG
		 ;;

     *) # unknown options 
         Help
         exit;;
   esac
done


# default output file name 
dn=$(dirname "${inputfile}")
bn=$(basename "${inputfile}" .csv)
outputfile="${dn}/${bn}.json"

echo Writing ... $outputfile


# output file   
cat ${inputfile} | python -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' >$outputfile
