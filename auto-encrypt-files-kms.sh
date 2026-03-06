#!/bin/bash
# =============================================================================
# Script Name  : auto-encrypt-files-kms.sh
# Description  : Monitors a directory for new files and automatically encrypts
#                them using AWS KMS. Original files are removed after encryption.
# Author       : Ahmed Hussain Shaikh
# Usage        : ./auto-encrypt-files-kms.sh
# Requirements : inotify-tools, aws-cli, appropriate KMS key permissions
# =============================================================================

# Directory to monitor for new files
DIRECTORY="/home/ec2-user/testscript"

# AWS KMS Key ID or ARN
# Replace with your actual KMS Key ID or ARN
KMS_KEY="<YOUR_KMS_KEY_ID_OR_ARN>"

# Validate that the directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "❌ Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

# Validate that inotifywait is installed
if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: inotify-tools is not installed."
    echo "Install it using: sudo yum install inotify-tools -y"
    exit 1
fi

# Validate that AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed."
    exit 1
fi

echo "✅ Monitoring directory: $DIRECTORY"
echo "🔐 Encrypting new files using AWS KMS..."
echo "----------------------------------------------"

# Monitor the directory for newly created files
inotifywait -m -r -e create --format '%w%f' "$DIRECTORY" | while read NEWFILE
do
    # Skip files that are already encrypted
    if [[ "$NEWFILE" != *.kms.enc ]]; then

        echo "📄 New file detected: $NEWFILE"

        # Encrypt the file using AWS KMS
        aws kms encrypt \
            --key-id "$KMS_KEY" \
            --plaintext "fileb://$NEWFILE" \
            --output text \
            --query CiphertextBlob > "$NEWFILE.kms.enc" 2>/dev/null

        # Check if encryption was successful
        if [ $? -eq 0 ]; then
            echo "✅ File encrypted successfully: $NEWFILE.kms.enc"
            # Remove the original unencrypted file
            rm -f "$NEWFILE"
            echo "🗑️  Original file removed: $NEWFILE"
        else
            echo "❌ Encryption failed for: $NEWFILE"
        fi

        echo "----------------------------------------------"
    fi
done
