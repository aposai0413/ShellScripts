#!/bin/bash

################################################################################
##
## Filename: sync_nginx_log_s3.sh
##
## Description: this script copies the nginx access log to the tmp folder and 
## then syncs the same to the S3 bucket 
##
## Version History:
## Version  Date       Description                           Changed By
##     1.0  09/18/2022 Initial version                       Saikat Rakshit
##
################################################################################


# Paths and variables
LOG_DATE=$(date +"%Y%m%d")
LOG_FILE="/var/log/nginx/access.log-${LOG_DATE}"
TMP_ACCESS_DIR="/tmp/access"
AWS_S3_BUCKET="az-ecom-cxp-logs/10.92.1.4/nginx-logs"
LOG_FILE_PATH="/opt/csm/logs/sync_nginx_log_s3.log"

# Function to log messages to the log file
log_message() {
  echo "$(date) - $1" >> "${LOG_FILE_PATH}"
}

# Check if access.log file exists
if [ ! -e "${LOG_FILE}" ]; then
  log_message "Error: ${LOG_FILE} does not exist or is inaccessible. Aborting."
  exit 1
fi

# Step 1: Copy access.log to /tmp/access/
cp -p "${LOG_FILE}" "${TMP_ACCESS_DIR}/access.log-${LOG_DATE}"
if [ $? -ne 0 ]; then
  log_message "Error: Failed to copy ${LOG_FILE} to ${TMP_ACCESS_DIR}. Aborting."
  exit 1
fi

# Step 2: Sync the /tmp/access/ folder to AWS S3 bucket
aws s3 sync "${TMP_ACCESS_DIR}" "s3://${AWS_S3_BUCKET}" >> "${LOG_FILE_PATH}" 2>&1
if [ $? -ne 0 ]; then
  log_message "Error: Failed to sync ${TMP_ACCESS_DIR} to S3 bucket. Aborting."
  exit 1
fi

# Step 3: Delete files older than 30 days
find "${TMP_ACCESS_DIR}" -type f -mtime +30 -exec rm {} \;
if [ $? -ne 0 ]; then
  log_message "Warning: Failed to delete files older than 30 days in ${TMP_ACCESS_DIR}. Continuing."
fi

# Append success message to the log file
log_message "Script executed successfully."

