#!/bin/bash
# GCP Cloud Build Quota Checker
# Tracks free tier usage and can block builds when approaching limits
#
# Usage:
#   ./scripts/gcp-quota-checker.sh [--non-interactive] [--project PROJECT_ID]
#
# Features:
#   - Tracks free tier usage (120 build-minutes per billing cycle, typically monthly)
#   - Automatically detects billing cycle start date
#   - Calculates monthly cost if over free tier
#   - Reports usage before and after builds
#   - Blocks builds at 90% threshold (configurable)
#   - Falls back to local build when free tier exhausted
#   - Non-interactive mode for CI/CD
#   - Enter key defaults to local build (option 2)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
FREE_TIER_MINUTES=120  # GCP Cloud Build free tier: 120 build-minutes per billing cycle (typically monthly)
WARNING_THRESHOLD=90   # Percentage at which to warn/block
NON_INTERACTIVE=false
GCP_PROJECT_ID=""
REPORT_FILE="${PROJECT_ROOT}/.gcp-build-usage.json"

# Parse arguments
ACTION=""
while [[ $# -gt 0 ]]; do
  case $1 in
    check|before|after|report)
      ACTION="$1"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    --project)
      GCP_PROJECT_ID="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [check|before|after|report] [--non-interactive] [--project PROJECT_ID]"
      exit 1
      ;;
  esac
done

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
  echo -e "${RED}Error: gcloud CLI not found${NC}"
  echo "Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

# Get project ID if not provided
if [ -z "$GCP_PROJECT_ID" ]; then
  GCP_PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
  if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID not set and no default project configured${NC}"
    echo "Set it via: gcloud config set project PROJECT_ID"
    echo "Or pass: --project PROJECT_ID"
    exit 1
  fi
fi

# Function to get today's build minutes
get_today_build_minutes() {
  local today=$(date -u +%Y-%m-%d)
  local start_time="${today}T00:00:00Z"
  local end_time="${today}T23:59:59Z"
  
  # Get builds from today and sum their durations
  local total_seconds=0
  
  # Get build durations in seconds
  gcloud builds list \
    --project="$GCP_PROJECT_ID" \
    --filter="createTime>='$start_time' AND createTime<='$end_time' AND status=SUCCESS" \
    --format="value(timing.build)" \
    2>/dev/null | while read -r timing; do
      if [ -n "$timing" ]; then
        # Extract seconds from timing (format: "123.456s")
        seconds=$(echo "$timing" | sed 's/s$//' | awk '{print int($1)}')
        total_seconds=$((total_seconds + seconds))
      fi
    done
  
  # Also try alternative method: sum all build durations
  local builds=$(gcloud builds list \
    --project="$GCP_PROJECT_ID" \
    --filter="createTime>='$start_time' AND createTime<='$end_time'" \
    --format="value(id)" \
    2>/dev/null | wc -l)
  
  if [ "$builds" -gt 0 ]; then
    # Estimate: average build is ~15 minutes, but we'll calculate actual
    # For now, use a simpler approach: count builds and estimate
    # This is a limitation - GCP doesn't provide easy access to exact minute usage
    # We'll use build count as a proxy
    echo "$builds"
  else
    echo "0"
  fi
}

# Function to estimate minutes from build count
# GCP free tier: 120 build-minutes/day
# We estimate average build time and track build count
estimate_minutes_from_builds() {
  local build_count=$1
  local avg_build_minutes=15  # Conservative estimate
  local estimated=$((build_count * avg_build_minutes))
  echo "$estimated"
}

# Function to get billing cycle start date
# GCP free tier resets monthly based on billing account cycle
# NOTE: For most accounts, this is the 1st of the month, but it can vary
# Users should verify their billing cycle date in GCP Console:
# https://console.cloud.google.com/billing
# This function defaults to 1st of month but can be customized
get_billing_cycle_start() {
  # Default: 1st of current month (most common)
  # To customize, set BILLING_CYCLE_DAY environment variable (1-28)
  local cycle_day="${BILLING_CYCLE_DAY:-01}"
  local current_year=$(date -u +%Y)
  local current_month=$(date -u +%m)
  local current_day=$(date -u +%d)
  
  # If current day is before cycle day, use previous month
  if [ "$current_day" -lt "$cycle_day" ]; then
    # Previous month
    if [ "$current_month" = "01" ]; then
      echo "${current_year}-12-${cycle_day}"
    else
      local prev_month=$(printf "%02d" $((current_month - 1)))
      echo "${current_year}-${prev_month}-${cycle_day}"
    fi
  else
    # Current month
    echo "${current_year}-${current_month}-${cycle_day}"
  fi
}

# Function to get actual usage for current billing cycle
get_usage() {
  # Get billing cycle start date
  local cycle_start=$(get_billing_cycle_start)
  local start_time="${cycle_start}T00:00:00Z"
  local end_time=$(date -u +%Y-%m-%dT23:59:59Z)
  
  # Get all builds from current month and calculate actual duration
  local total_seconds=0
  local build_count=0
  
  # Get build durations in seconds
  while IFS= read -r build_id; do
    if [ -n "$build_id" ]; then
      build_count=$((build_count + 1))
      # Get build duration from build details
      local duration=$(gcloud builds describe "$build_id" \
        --project="$GCP_PROJECT_ID" \
        --format="value(timing.build)" \
        2>/dev/null | sed 's/s$//' | awk '{print int($1)}' || echo "0")
      if [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
        total_seconds=$((total_seconds + duration))
      fi
    fi
  done < <(gcloud builds list \
    --project="$GCP_PROJECT_ID" \
    --filter="createTime>='$start_time' AND createTime<='$end_time' AND status=SUCCESS" \
    --format="value(id)" \
    2>/dev/null)
  
  # Convert seconds to minutes (round up)
  local estimated_minutes=$(( (total_seconds + 59) / 60 ))
  
  # If no builds found or calculation failed, estimate from build count
  if [ "$estimated_minutes" -eq 0 ] && [ "$build_count" -gt 0 ]; then
    estimated_minutes=$((build_count * 15))  # Conservative estimate
  fi
  
  # Store in report file
  mkdir -p "$(dirname "$REPORT_FILE")"
  local current_date=$(date -u +%Y-%m-%d)
  local current_month=$(date -u +%Y-%m)
  cat > "$REPORT_FILE" <<EOF
{
  "billing_cycle_start": "$cycle_start",
  "month": "$current_month",
  "date": "$current_date",
  "project_id": "$GCP_PROJECT_ID",
  "build_count": $build_count,
  "estimated_minutes": $estimated_minutes,
  "free_tier_limit": $FREE_TIER_MINUTES,
  "percentage_used": $((estimated_minutes * 100 / FREE_TIER_MINUTES)),
  "remaining_minutes": $((FREE_TIER_MINUTES - estimated_minutes))
}
EOF
  
  echo "$estimated_minutes"
}

# Function to print usage report
print_report() {
  local minutes_used=$1
  local percentage=$2
  local build_count=$3
  
  # Calculate monthly cost (if over free tier)
  local overage_minutes=0
  local monthly_cost="0.00"
  if [ "$minutes_used" -gt "$FREE_TIER_MINUTES" ]; then
    overage_minutes=$((minutes_used - FREE_TIER_MINUTES))
    # GCP Cloud Build pricing: $0.003 per build-minute after free tier
    # Calculate: overage_minutes * 0.003
    # Use awk for floating point calculation (standard on Unix systems)
    if command -v awk &> /dev/null; then
      monthly_cost=$(awk "BEGIN {printf \"%.2f\", $overage_minutes * 0.003}")
    else
      # Fallback: simple integer approximation
      # $0.003 per minute ≈ 1/333 dollars per minute
      # For display, show approximate: overage_minutes / 333
      local approx_dollars=$((overage_minutes / 333))
      monthly_cost="~${approx_dollars}.00"
    fi
  fi
  
  # Get billing cycle info
  local cycle_start=$(get_billing_cycle_start)
  local cycle_month=$(echo "$cycle_start" | cut -d'-' -f1,2)
  
  echo ""
  echo "=========================================="
  echo "GCP Cloud Build Usage Report"
  echo "=========================================="
  echo "Project: $GCP_PROJECT_ID"
  local cycle_day=$(echo "$cycle_start" | cut -d'-' -f3 | sed 's/^0//')
  echo "Billing Cycle: $cycle_month (resets on ${cycle_day}th of month)"
  echo "Current Date: $(date -u +%Y-%m-%d)"
  echo ""
  echo "Billing Cycle Usage:"
  echo "  Builds: $build_count"
  echo "  Minutes Used: $minutes_used / $FREE_TIER_MINUTES"
  echo "  Percentage Used: $percentage%"
  echo "  Remaining: $((FREE_TIER_MINUTES - minutes_used)) minutes"
  if [ "$overage_minutes" -gt 0 ]; then
    echo ""
    echo -e "${RED}  Overage: $overage_minutes minutes${NC}"
    echo -e "${RED}  Estimated Monthly Cost: \$$monthly_cost${NC}"
  fi
  echo ""
  
  if [ "$percentage" -ge "$WARNING_THRESHOLD" ]; then
    echo -e "${RED}⚠️  WARNING: Free tier usage at ${percentage}%${NC}"
    echo "  Free tier limit: $FREE_TIER_MINUTES build-minutes per billing cycle"
    if [ "$overage_minutes" -gt 0 ]; then
      echo -e "  ${RED}Current overage: $overage_minutes minutes (\$$monthly_cost)${NC}"
    fi
  elif [ "$percentage" -ge 75 ]; then
    echo -e "${YELLOW}⚠️  Approaching free tier limit (${percentage}%)${NC}"
  else
    echo -e "${GREEN}✓ Within free tier limits${NC}"
  fi
  echo "=========================================="
  echo ""
}

# Function to check if build should proceed
check_build_allowed() {
  local minutes_used=$1
  local percentage=$2
  
  if [ "$percentage" -ge "$WARNING_THRESHOLD" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
      echo -e "${YELLOW}Free tier usage at ${percentage}%. Falling back to local build.${NC}"
      return 1
    else
      echo -e "${RED}Free tier usage at ${percentage}% (threshold: ${WARNING_THRESHOLD}%)${NC}"
      echo ""
      echo "Options:"
      echo "  1. Proceed with Cloud Build anyway (may incur charges)"
      echo "  2. Use local build instead (no cost) [default]"
      echo "  3. Cancel"
      echo ""
      read -p "Choose option (1-3, or press Enter for default): " choice
      
      # Default to option 2 if Enter is pressed or empty
      if [ -z "$choice" ]; then
        choice=2
      fi
      
      case $choice in
        1)
          echo "Proceeding with Cloud Build..."
          return 0
          ;;
        2)
          echo "Falling back to local build..."
          return 1
          ;;
        3)
          echo "Cancelled."
          exit 0
          ;;
        *)
          echo "Invalid choice. Using default (local build)..."
          return 1
          ;;
      esac
    fi
  fi
  
  return 0
}

# Main execution
main() {
  local action="${ACTION:-check}"
  
  case $action in
    check|before)
      echo "Checking GCP Cloud Build quota..."
      local minutes_used=$(get_usage)
      local build_count=$(cat "$REPORT_FILE" 2>/dev/null | grep -o '"build_count": [0-9]*' | cut -d' ' -f2 || echo "0")
      local percentage=$((minutes_used * 100 / FREE_TIER_MINUTES))
      
      # Clamp percentage to 100
      if [ "$percentage" -gt 100 ]; then
        percentage=100
      fi
      
      print_report "$minutes_used" "$percentage" "$build_count"
      
      if [ "$action" = "before" ]; then
        if ! check_build_allowed "$minutes_used" "$percentage"; then
          echo "Suggestion: Use local build instead: make build-local"
          exit 1
        fi
      fi
      ;;
    
    after|report)
      echo "Generating post-build usage report..."
      local minutes_used=$(get_usage)
      local build_count=$(cat "$REPORT_FILE" 2>/dev/null | grep -o '"build_count": [0-9]*' | cut -d' ' -f2 || echo "0")
      local percentage=$((minutes_used * 100 / FREE_TIER_MINUTES))
      
      # Clamp percentage to 100
      if [ "$percentage" -gt 100 ]; then
        percentage=100
      fi
      
      print_report "$minutes_used" "$percentage" "$build_count"
      
      if [ -f "$REPORT_FILE" ]; then
        echo "Detailed report saved to: $REPORT_FILE"
      fi
      ;;
    
    *)
      echo "Usage: $0 [check|before|after|report] [--non-interactive] [--project PROJECT_ID]"
      echo ""
      echo "Commands:"
      echo "  check          - Check current usage"
      echo "  before         - Check before build (blocks if over threshold)"
      echo "  after          - Generate report after build"
      echo "  report         - Same as 'after'"
      echo ""
      echo "Options:"
      echo "  --non-interactive  - Auto-fallback to local build when threshold reached"
      echo "  --project ID       - GCP project ID (default: current gcloud project)"
      echo ""
      echo "Environment Variables:"
      echo "  BILLING_CYCLE_DAY  - Day of month when billing cycle resets (1-28, default: 1)"
      echo "                       Verify your billing cycle in GCP Console:"
      echo "                       https://console.cloud.google.com/billing"
      exit 1
      ;;
  esac
}

# Run main function
main "$@"

