#!/bin/bash

set -e

# Configuration variables
KEYCLOAK_URL="http://localhost:8090"
CONTAINER_NAME="keycloak-extensions-playground"
MAX_HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=2  # seconds between health checks

# Global variables for build tracking
declare -A build_status
declare -A build_times
declare -A build_start_times

# Function to list directories with pom.xml
list_projects() {
    local count=1
    echo "Available projects:"
    echo "------------------------"
    for d in */; do
        if [ -f "${d}pom.xml" ]; then
            echo "[$count] ${d%/}"
            projects[$count]="${d}"
            ((count++))
        fi
    done
    echo "------------------------"
}

# Array to store project directories
declare -A projects

# List available projects
list_projects

# Prompt user for selection
while true; do
    read -p "Select project number to build (1-${#projects[@]}): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#projects[@]}" ]; then
        dir="${projects[$selection]}"
        break
    else
        echo "❌ Invalid selection. Please enter a number between 1 and ${#projects[@]}"
    fi
done

echo "Selected project: 📁 $dir"

echo "Step 1: Building JAR file..."
echo "Building directory: 📁 $dir"

echo "\nStarting build process..."
if [[ ! $dir =~ ^\. ]]; then
    if [ -f "${dir}pom.xml" ]; then
        echo "\n📦 Building $dir..."
        echo "=========================="
        
        # Record build start time
        build_start_times["${dir%/}"]=$(date +%s)
        
        cd "$dir"
        mvn clean package
        build_result=$?
        
        # Calculate build duration
        build_end_time=$(date +%s)
        duration=$((build_end_time - build_start_times["${dir%/}"]))
        
        if [ $build_result -eq 0 ]; then
            echo "✅ JAR build successful for $dir"
            build_status["${dir%/}"]="Success"
            build_times["${dir%/}"]="$(printf "%02d:%02d" $((duration/60)) $((duration%60)))"
        else
            echo "❌ JAR build failed for $dir"
            build_status["${dir%/}"]="Failed"
            build_times["${dir%/}"]="$(printf "%02d:%02d" $((duration/60)) $((duration%60)))"
            exit 1
        fi
        cd ..
        echo "==========================\n"
    else
        echo "⚠️  Skipping $dir - no pom.xml found"
        build_status["${dir%/}"]="Skipped"
        build_times["${dir%/}"]="--:--"
        exit 1
    fi
fi

echo "Step 1.1: Build Summary"
echo "================================================================="
printf "%-30s | %-15s | %-15s | %-15s\n" "Module Name" "Status" "Build Time" "Timestamp"
echo "-----------------------------------------------------------------"
for module in "${!build_status[@]}"; do
    status_icon=""
    case ${build_status[$module]} in
        "Success") status_icon="✅";;
        "Failed") status_icon="❌";;
        "Skipped") status_icon="⚠️";;
    esac
    
    timestamp=$(date "+%H:%M:%S")
    printf "%-30s | %-15s | %-15s | %-15s\n" \
        "$module" \
        "$status_icon ${build_status[$module]}" \
        "${build_times[$module]}" \
        "$timestamp"
done
echo "================================================================="

echo "Step 2: Checking for existing containers..."
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping existing $CONTAINER_NAME container..."
    docker compose down
    if [ $? -eq 0 ]; then
        echo "Successfully stopped existing containers"
    else
        echo "Failed to stop existing containers"
        exit 1
    fi
fi

echo "Step 3: Running Docker Compose..."
docker compose up -d
if [ $? -eq 0 ]; then
    echo "Docker Compose started successfully"
else
    echo "Docker Compose failed to start"
    exit 1
fi

echo "Step 4: Verifying container health..."
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_HEALTH_CHECK_RETRIES ]; do
    if curl -s -f $KEYCLOAK_URL > /dev/null 2>&1; then
        echo "✅ Keycloak is up and running at $KEYCLOAK_URL"
        break
    else
        echo "Waiting for Keycloak to be ready... (Attempt $((RETRY_COUNT+1))/$MAX_HEALTH_CHECK_RETRIES)"
        RETRY_COUNT=$((RETRY_COUNT+1))
        sleep $HEALTH_CHECK_INTERVAL
    fi
done

if [ $RETRY_COUNT -eq $MAX_HEALTH_CHECK_RETRIES ]; then
    echo "❌ Failed to verify Keycloak is running after $MAX_HEALTH_CHECK_RETRIES attempts"
    echo "Please check the logs using: docker compose logs"
    exit 1
fi

echo "✅ Deployment process completed successfully 🚀"
exit 0