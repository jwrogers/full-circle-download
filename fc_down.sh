#!/bin/bash

## Variables
flag=true
url=""
url_prefix="http://dl.fullcirclemagazine.org/issue"
url_suffix="_en.pdf"
last_issue="$(tail -n1 .issue_nos)"

### reset counter to the next issue
#if [ -z "$last_issue" ];
#then
	counter=0
#else
#	counter=$last_issue+1
#fi

####
# Download function
####
function download {

wget -q -c $url -P issues/ 2> /dev/null 
ecode=$?

# Depending on wget exit code Log download or exit at end of list
case "$ecode" in
	0)
		echo Issue $counter downloaded >> .sc_log
		echo $counter > .issue_nos
		echo -n " $counter"
		;;
	8) 
		echo  "No more issues available."
		echo
		exit 0
		;;
	*) 
		echo ERROR: $ecode
		echo Issue: $counter ERROR: $ecode >> .sc_log_err
		;;
esac
} 
######
# Main Function
####
echo
echo "##############################################"
echo "# Downloading Issues of Full Circle Magazine #"
echo "##############################################"
echo
echo Downloading Issues

while [ "$counter" -lt 10 ];do
	
	# Create the url
	url=$url_prefix$counter$url_suffix
#	echo $url

	
	# Check if issue has already been downloaded 
	if [ -e "issues/issue"$counter"_en.pdf" ];
      	then 
      		remote_size=$(wget $url --spider -S -O- 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}')
      		local_size=`stat --printf='%s' issues/issue"$counter"_en.pdf`
      		#echo
      		#echo RS: $remote_size
      		#echo LS: $local_size
      		#echo
      		
		# If it has been downloaded but is smaller than remote file -> continue download
		if [ "$local_size" -lt "$remote_size" ];
      		then
			# Call the download function
			download
      		else
      			echo Skipping $counter : Already downloaded >> .sc_log
      		fi
	else
		# If it doesn't exist -> download
		download
	fi

	((counter++))
done
