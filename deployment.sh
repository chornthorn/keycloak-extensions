#!/bin/bash

set -e

# Global variables for build tracking
declare -A build_status
declare -A build_times
declare -A build_start_times

echo "Step 1: Building JAR files..."
echo "Found following directories:"
for dir in */ ; do
    if [[ ! $dir =~ ^\. ]]; then
        echo "📁 $dir"
    fi
done

echo "\nStarting build process..."
for dir in */ ; do
    # Skip directories that start with a dot
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
        fi
    fi
done

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
if [ "$(docker ps -q -f name=keycloak-extensions-playground)" ]; then
    echo "Stopping existing keycloak-extensions-playground container..."
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
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f http://localhost:8090 > /dev/null 2>&1; then
        echo "✅ Keycloak is up and running at http://localhost:8090"
        break
    else
        echo "Waiting for Keycloak to be ready... (Attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
        RETRY_COUNT=$((RETRY_COUNT+1))
        sleep 2
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Failed to verify Keycloak is running after $MAX_RETRIES attempts"
    echo "Please check the logs using: docker compose logs"
    exit 1
fi

echo "✅ Deployment process completed successfully 🚀"
exit 0
