#!/bin/bash

# Generate Release Keystore for Nexus Streaming App
# This script creates a keystore file needed for signing APK/AAB builds

set -e

KEYSTORE_DIR="./android/app/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/nexus.jks"
KEYSTORE_ALIAS="nexus_key"
VALIDITY_DAYS=36500  # 100 years

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔑 Nexus Streaming - Release Keystore Generator${NC}"
echo "=================================================="

# Create keystore directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Keystore already exists at $KEYSTORE_FILE${NC}"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
fi

# Prompt for password (if not provided via environment variable)
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo ""
    echo "Enter a strong password for the keystore:"
    echo "(This will be used to sign all releases)"
    read -s -p "Password: " KEYSTORE_PASSWORD
    echo
    read -s -p "Confirm password: " KEYSTORE_PASSWORD_CONFIRM
    echo
    
    if [ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}❌ Passwords do not match!${NC}"
        exit 1
    fi
fi

if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty!${NC}"
    exit 1
fi

# Generate keystore
echo ""
echo "Generating keystore..."

keytool -genkeypair -v \
    -keystore "$KEYSTORE_FILE" \
    -alias "$KEYSTORE_ALIAS" \
    -keyalg RSA \
    -keysize 4096 \
    -validity $VALIDITY_DAYS \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEYSTORE_PASSWORD" \
    -dname "CN=Nexus Streaming, O=Nexus, C=BR"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Keystore created successfully!${NC}"
    echo ""
    echo "Keystore Details:"
    echo "  Location: $KEYSTORE_FILE"
    echo "  Alias: $KEYSTORE_ALIAS"
    echo "  Validity: $VALIDITY_DAYS days"
    echo ""
    echo "To use this keystore for building APK/AAB:"
    echo ""
    echo "Option 1: Using environment variables:"
    echo "  export KEYSTORE_PATH=$(pwd)/$KEYSTORE_FILE"
    echo "  export KEYSTORE_ALIAS=$KEYSTORE_ALIAS"
    echo "  export KEYSTORE_PASSWORD='<password>'"
    echo "  flutter build apk --release"
    echo ""
    echo "Option 2: Update build.gradle.kts directly with the path"
    echo ""
    echo "⚠️  IMPORTANT: Store the password in a safe place!"
    echo "⚠️  Do NOT commit the keystore file to version control!"
else
    echo -e "${RED}❌ Failed to generate keystore!${NC}"
    exit 1
fi
