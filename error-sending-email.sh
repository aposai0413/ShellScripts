#!/bin/bash

################################################################################
##
## Filename: error-sending-email.sh
##
## Description: this script checks for the previous days catalina log file to 
## search for the string when an email notification send fails. It pulls the 
## User email id, Order number and Process number in a report format and sends
## an email to the CSM team for further investigation
##
## Version History:
## Version  Date       Description                           Changed By
##     1.0  06/12/2023 Initial version                       Saikat Rakshit
##
################################################################################


# Define the variables
search_string="Error in sending mail for Order Number"

prev_date=$(date -d "yesterday" +"%Y%m%d")
today_date=$(date +"%Y%m%d")

log_location="/opt/tomcat/logs/"
tmp_location="/tmp/"

log_file="catalina.out-$today_date.gz"
tmp_file="tmp_email_send_error_$today_date.txt"

report="<html><body><table><tr><th>User</th><th>Order Number</th><th>Process No</th><th>Error Line</th></tr>"

from_email="alerts@phasezero.ai"
to_email="pz-cxops@phasezeroventures.com"
cc_email="saikat.rakshit@phasezero.ai,prasad.kulkarni@phasezero.ai"
email_subject="Mid Market | Prod | Error in sending email | $(hostname -I)";

# Check if the log file exists
if [ -f "$log_location$log_file" ]; then
    # Search the string
	zgrep -A2 "$search_string" "$log_location$log_file" > "$tmp_location$tmp_file"
	
    # Search for the string and extract the required information
    while read -r line; do
	user=$(echo "$line" | grep -oP "(?<=user=)[^ ]+" | sed 's/[][]//g')
        order_number=$(echo "$line" | grep -oP "(?<=Order Number )[^ ]+" | sed 's/[][]//g')
        process_no=$(echo "$line" | grep -oP "(?<=process no )[^ ]+" | sed 's/[][]//g')

	# Get the next two lines after the search string
        error_line=$(grep -A2 "$user" "$tmp_location$tmp_file" | grep -A2 $order_number | tail -n 2)

	# Append the extracted information to the report
        report+="<tr><td>$user</td><td>$order_number</td><td>$process_no</td><td>$error_line</td></tr>"

    done < "$tmp_location$tmp_file"

    # Remove the tmp log file
    #rm "$tmp_location$tmp_file"

    # Check if there are any matching records
    if [ "$report" != "<html><body><table><tr><th>User</th><th>Order Number</th><th>Process No</th><th>Error Line</th></tr>" ]; then
		report+="</table></body></html>"
        # Send the report via email
		(
			echo "From:$from_email";
			echo "To:$to_email";
			echo "Subject:$email_subject";
			echo "CC:$cc_email";
			echo "Content-type:text/html";
			echo "<br>";
			echo "<br>";
			echo "$report"
			echo "<br>";

			echo "<br>Thanks</br>";
			echo "<br>CSM Team</br>";
		) | sendmail -t

        echo "Report sent successfully!"
    else
        echo "No matching records found."
    fi
else
    echo "Log file $log_file does not exist."
fi

