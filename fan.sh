#!/bin/bash

################################################################################
#  Raspberry Pi 5 fan control script
#  Aggressively fights firmware that automatically resets fan speed
#  Author : Jeremy Noverraz (1988 - 2026 )
#  Date of creation : 14.01.2026
#  Date of last update : 14.01.2026
#  Version : 2026.0114
################################################################################

# Configuration
readonly COOLING_DIR="/sys/class/thermal/cooling_device0"
readonly THERMAL_ZONE="/sys/class/thermal/thermal_zone0"
readonly FAN_CUR_STATE="${COOLING_DIR}/cur_state"
readonly FAN_MAX_STATE="${COOLING_DIR}/max_state"
readonly TEMP_FILE="${THERMAL_ZONE}/temp"
readonly PID_FILE="/tmp/pi5_fan_control.pid"
readonly TARGET_FILE="/tmp/pi5_fan_target_speed"
readonly LOG_FILE="/tmp/pi5_fan_control.log"

# Check interval (in seconds)
readonly CHECK_INTERVAL=0.15

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

################################################################################
# Utility functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_daemon() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        exit 1
    fi
}

check_pi5() {
    if [[ ! -d "$COOLING_DIR" ]]; then
        log_error "Directory $COOLING_DIR not found"
        log_error "Are you running this on a Raspberry Pi 5 with an active fan?"
        exit 1
    fi
}

get_temperature() {
    local temp_milli
    temp_milli=$(cat "$TEMP_FILE" 2>/dev/null || echo "0")
    echo "$((temp_milli / 1000))"
}

get_fan_state() {
    cat "$FAN_CUR_STATE" 2>/dev/null || echo "unknown"
}

get_max_state() {
    cat "$FAN_MAX_STATE" 2>/dev/null || echo "4"
}

validate_speed() {
    local speed="$1"
    local max_state
    max_state=$(get_max_state)
    
    if ! [[ "$speed" =~ ^[0-9]+$ ]]; then
        log_error "Invalid speed: '$speed'"
        return 1
    fi
    
    if [[ $speed -lt 0 || $speed -gt $max_state ]]; then
        log_error "Speed out of range: $speed (must be 0-$max_state)"
        return 1
    fi
    
    return 0
}

is_daemon_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE" 2>/dev/null || true
        fi
    fi
    return 1
}

stop_daemon() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_info "Stopping daemon (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            log_success "Daemon stopped"
        fi
    fi
    rm -f "$PID_FILE" "$TARGET_FILE" 2>/dev/null || true
}

# Force write speed to fan
write_speed() {
    local speed="$1"
    echo "$speed" > "$FAN_CUR_STATE" 2>/dev/null
}

# DAEMON - Infinite loop that maintains fan speed
daemon_loop() {
    local target_speed="$1"
    
    # Register PID
    echo $$ > "$PID_FILE"
    
    # Initialize log
    echo "=========================================" > "$LOG_FILE"
    log_daemon "Daemon started (PID: $$)"
    log_daemon "Target speed: $target_speed"
    log_daemon "========================================="
    
    local iteration=0
    local corrections=0
    local last_speed="$target_speed"
    
    # Infinite loop
    while true; do
        # Check for target change
        if [[ -f "$TARGET_FILE" ]]; then
            local new_target
            new_target=$(cat "$TARGET_FILE" 2>/dev/null || echo "$target_speed")
            if [[ "$new_target" != "$target_speed" ]]; then
                log_daemon "Speed change: $target_speed -> $new_target"
                target_speed="$new_target"
                corrections=0
            fi
        fi
        
        # Read current speed
        local current_speed
        current_speed=$(cat "$FAN_CUR_STATE" 2>/dev/null || echo "-1")
        
        # Correct if necessary
        if [[ "$current_speed" != "$target_speed" ]]; then
            write_speed "$target_speed"
            ((corrections++))
            
            if [[ "$current_speed" != "$last_speed" ]]; then
                log_daemon "⚠️  Firmware changed: $last_speed -> $current_speed, restoring to $target_speed"
            fi
        fi
        
        # Preventive rewrite every 20 iterations
        if [[ $((iteration % 20)) -eq 0 ]]; then
            write_speed "$target_speed"
        fi
        
        last_speed="$current_speed"
        ((iteration++))
        
        # Periodic log
        if [[ $((iteration % 200)) -eq 0 ]]; then
            local temp
            temp=$(get_temperature)
            log_daemon "✓ Active - ${iteration} cycles, ${temp}°C, ${corrections} corrections"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Start the daemon
start_daemon() {
    local speed="$1"
    
    # Stop existing daemon
    if is_daemon_running; then
        log_info "Stopping existing daemon..."
        stop_daemon
        sleep 1
    fi
    
    # Clean up old files
    rm -f "$PID_FILE" "$TARGET_FILE" "$LOG_FILE" 2>/dev/null || true
    
    # Save target
    echo "$speed" > "$TARGET_FILE"
    
    # Aggressive initial write
    log_info "Initial speed write..."
    for i in {1..10}; do
        write_speed "$speed"
        sleep 0.05
    done
    
    log_info "Starting daemon..."
    
    # Launch daemon in background
    (
        # Completely detach from terminal
        exec </dev/null
        exec >/dev/null 2>&1
        
        # Ignore terminal signals
        trap '' HUP
        
        # Start the loop
        daemon_loop "$speed"
    ) &
    
    local daemon_pid=$!
    
    # Wait a bit
    sleep 1.5
    
    # Verify daemon is running
    if kill -0 "$daemon_pid" 2>/dev/null && is_daemon_running; then
        log_success "Daemon started (PID: $daemon_pid)"
        log_info "Logs: $LOG_FILE"
        return 0
    else
        log_error "Daemon failed to start"
        # Try to see why
        if [[ -f "$LOG_FILE" ]]; then
            echo "Last log lines:"
            tail -5 "$LOG_FILE"
        fi
        return 1
    fi
}

show_status() {
    local temp current_speed max_state
    
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Raspberry Pi 5 Fan Status${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
    
    temp=$(get_temperature)
    echo -e "🌡️  Temperature:            ${YELLOW}${temp}°C${NC}"
    
    current_speed=$(get_fan_state)
    max_state=$(get_max_state)
    echo -e "💨 Current speed:           ${GREEN}${current_speed}${NC} / ${max_state}"
    
    if [[ "$current_speed" != "unknown" ]]; then
        local percentage
        percentage=$((current_speed * 100 / max_state))
        echo -e "📊 Percentage:              ${GREEN}${percentage}%${NC}"
    fi
    
    if is_daemon_running; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        echo -e "🔧 Daemon:                  ${GREEN}Active${NC} (PID: $pid)"
        
        if [[ -f "$TARGET_FILE" ]]; then
            local target
            target=$(cat "$TARGET_FILE")
            echo -e "🎯 Target speed:            ${BLUE}${target}${NC}"
        fi
        
        if [[ -f "$LOG_FILE" ]]; then
            echo -e "\n${BLUE}📋 Recent events:${NC}"
            tail -n 3 "$LOG_FILE" | sed 's/^/   /'
        fi
    else
        echo -e "🔧 Daemon:                  ${RED}Inactive${NC}"
        echo -e "⚠️  ${YELLOW}Firmware is in automatic control${NC}"
    fi
    
    echo -e "\n${BLUE}════════════════════════════════════════${NC}\n"
}

show_logs() {
    local lines="${1:-30}"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        log_error "No logs found"
        return 1
    fi
    
    echo -e "${BLUE}📋 Logs (last ${lines} lines):${NC}\n"
    tail -n "$lines" "$LOG_FILE"
}

show_help() {
    cat << EOF
Usage: $0 [OPTION]

Commands:
  --speed N             Maintain fan speed at N (0-4)
  --stop                Stop daemon and return to auto mode
  --status              Show current fan status
  --logs [N]            Show logs (default: 30 lines)
  --help                Show this help

Examples:
  $0 --speed 3          # Maintain speed at 3 permanently
  $0 --status           # Show current status
  $0 --logs 50          # Show 50 log lines
  $0 --stop             # Stop and return to automatic mode

Notes:
  - Check interval: ${CHECK_INTERVAL}s
  - Daemon survives SSH disconnections
  - Aggressively fights firmware resets
  - Logs: $LOG_FILE

Speed levels (typical):
  0 = Off (silent, CPU up to ~60°C)
  1 = Low (quiet, CPU ~50-60°C)
  2 = Medium (moderate, CPU ~40-50°C)
  3 = High (audible, CPU ~35-45°C)
  4 = Max (loud, maximum cooling)

EOF
}

################################################################################
# Main
################################################################################

main() {
    check_root
    check_pi5
    
    if [[ $# -eq 0 ]]; then
        show_status
        exit 0
    fi
    
    case "${1:-}" in
        --speed)
            if [[ -n "${2:-}" ]]; then
                validate_speed "$2" || exit 1
                start_daemon "$2"
                sleep 2
                show_status
                exit $?
            else
                log_error "--speed requires an argument (0-4)"
                exit 1
            fi
            ;;
        --stop)
            stop_daemon
            show_status
            exit 0
            ;;
        --status)
            show_status
            exit 0
            ;;
        --logs)
            show_logs "${2:-30}"
            exit 0
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
