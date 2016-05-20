#!/bin/bash

## Setup Variables
flag=true
url=""
url_prefix="http://dl.fullcirclemagazine.org/issue"
url_suffix="_en.pdf"

## If issue list doesn't exist -> create it
if [ -e .issue_nos ];
then
	last_issue="$(tail -n1 .issue_nos)"
else
	touch .issue_nos
fi

## If the prefix file doesn't exist -> create it
prefix="issues/"
if [ ! -d "$prefix" ];
then
	mkdir issues
fi

## reset counter to the next issue
if [ -z "$last_issue" ];
then
	counter=0
else
	counter=$last_issue
fi

########################################
# Check if remote file exists function #
########################################
function remote_exists {

# Check if file exists with wget
wget $url --spider -O- 2>/dev/null
ecode=$?

if [ "$ecode" -eq 8 ];
then
	return 1
else
	return 0
fi
}

#####################
# Download function #
#####################
function download {

printf "Downloading Issue %s\n" "$counter"

# Download File
file_output=$prefix"issue"$counter"_en.pdf"
curl -# -C- $url -o $file_output

# Check if curl completed successfully
if [ $? -eq 0 ];
then
	echo Issue $counter downloaded >> .sc_log
	echo $counter > .issue_nos
	echo Issue $counter downloaded
else
	echo ERROR: $ecode
	echo Issue: $counter ERROR: $ecode >> .sc_log_err
fi
}
#################
# Main Function #
#################
echo
echo "##############################################"
echo "# Downloading Issues of Full Circle Magazine #"
echo "##############################################"
echo

# Add the date and time to the log files to seperate logs
echo $(date) >> .sc_log
echo >> .sc_log
echo $(date) >> .sc_log_err
echo >> .sc_log_err

while [ true ];do
	
	# Create the url
	url=$url_prefix$counter$url_suffix
	
	# Check if a remote file exists
	exist=$(remote_exists)
	
	if [ $exist ];
	then
		echo No more issues available >> .sc_log
		echo No more issues available
		exit 0
	fi
	
	# Check if issue has already been downloaded 
	if [ -e "issues/issue"$counter"_en.pdf" ];
      	then 
      		remote_size=$(wget $url --spider -S -O- 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}')
      		local_size=`stat --printf='%s' issues/issue"$counter"_en.pdf`

		# If it has been downloaded but is smaller than remote file -> continue download
		if [ "$local_size" -lt "$remote_size" ];
      		then
			download
			echo
			echo
      		else
      			echo Skipping $counter : Already downloaded >> .sc_log
      		fi
	else
		# If it doesn't exist -> download
		download
		echo
		echo
	fi

	((counter++))
done
