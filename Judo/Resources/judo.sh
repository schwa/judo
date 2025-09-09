#!/usr/bin/env zsh

# Judo shell script for opening repositories with x-judo URLs
# Version: 1.0.0
# https://github.com/schwa/judo

set -e

# Default values
REPO_PATH="."
MODE=""
SELECTION=""
REVSET=""
LIMIT=""

# Function to show help
show_help() {
    cat << EOF
Usage: judo.sh [COMMAND] [OPTIONS]

Commands:
    open [PATH]           Open a repository in Judo (default)
    show CHANGE_ID        Show a specific change
    log                   Open repository log
    help                  Show this help message

Options:
    -m, --mode MODE      View mode (timeline, change, mixed, log, show)
    -s, --selection ID   Change ID to select
    -r, --revset REVSET  Revset to display (for log command)
    -l, --limit N        Number of commits to show (for log command)
    -p, --path PATH      Path to the repository (default: current directory)

Examples:
    judo.sh                                 # Open current directory (default)
    judo.sh /path/to/repo                   # Open specific repository
    judo.sh -m timeline -s abc123           # Open with mode and selection
    judo.sh open /path/to/repo -m timeline  # Explicit open command
    judo.sh show abc123 -p /path/to/repo
    judo.sh log -r "@" -l 50

EOF
}

# Function to resolve repository path to absolute path
resolve_repo_path() {
    local path="$1"
    
    # Convert to absolute path
    if [[ "$path" = /* ]]; then
        # Already absolute
        RESOLVED_PATH="$path"
    else
        # Relative path
        RESOLVED_PATH="$(cd "$path" 2>/dev/null && pwd)" || {
            echo "Error: Cannot access directory: $path" >&2
            exit 1
        }
    fi
    
    # Check if it's a jj repository
    if [[ ! -d "$RESOLVED_PATH/.jj" ]]; then
        echo "Error: Not a jj repository: $RESOLVED_PATH" >&2
        exit 1
    fi
    
    echo "$RESOLVED_PATH"
}

# Function to build and open URL
open_url() {
    local repo_path="$1"
    local query_params=""
    
    # Build query parameters
    if [[ -n "$MODE" ]]; then
        # Map mode aliases
        case "$MODE" in
            log|timeline)
                MODE="timeline"
                ;;
            show|change)
                MODE="change"
                ;;
            mixed)
                MODE="mixed"
                ;;
            *)
                echo "Error: Unknown mode: $MODE" >&2
                exit 1
                ;;
        esac
        query_params="mode=$MODE"
    fi
    
    if [[ -n "$SELECTION" ]]; then
        if [[ -n "$query_params" ]]; then
            query_params="$query_params&selection=$SELECTION"
        else
            query_params="selection=$SELECTION"
        fi
    fi
    
    if [[ -n "$REVSET" ]]; then
        if [[ -n "$query_params" ]]; then
            query_params="$query_params&revset=$REVSET"
        else
            query_params="revset=$REVSET"
        fi
    fi
    
    if [[ -n "$LIMIT" ]]; then
        if [[ -n "$query_params" ]]; then
            query_params="$query_params&limit=$LIMIT"
        else
            query_params="limit=$LIMIT"
        fi
    fi
    
    # Build the URL
    local url="x-judo://$repo_path"
    if [[ -n "$query_params" ]]; then
        url="$url/?$query_params"
    fi
    
    echo "Opening: $url"
    
    # Open the URL on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url"
    else
        echo "Error: URL opening is only supported on macOS" >&2
        exit 1
    fi
}

# Parse command
COMMAND="open"

# Check if first argument is a command or a path/option
if [[ $# -gt 0 ]]; then
    case "$1" in
        help|--help|-h)
            show_help
            exit 0
            ;;
        open|show|log)
            COMMAND="$1"
            shift
            ;;
        -*)
            # It's an option, keep default command (open)
            ;;
        *)
            # It's likely a path, keep default command (open)
            ;;
    esac
fi

# Parse arguments based on command
case "$COMMAND" in
    open)
        # Check if first argument is a path (not starting with -)
        if [[ $# -gt 0 ]] && [[ "$1" != -* ]]; then
            REPO_PATH="$1"
            shift
        fi
        
        # Parse options
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -m|--mode)
                    MODE="$2"
                    shift 2
                    ;;
                -s|--selection)
                    SELECTION="$2"
                    shift 2
                    ;;
                -p|--path)
                    REPO_PATH="$2"
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown option: $1" >&2
                    show_help
                    exit 1
                    ;;
            esac
        done
        ;;
        
    show)
        if [[ $# -eq 0 ]]; then
            echo "Error: show command requires a change ID" >&2
            show_help
            exit 1
        fi
        
        SELECTION="$1"
        MODE="change"
        shift
        
        # Parse options
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -p|--path)
                    REPO_PATH="$2"
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown option: $1" >&2
                    show_help
                    exit 1
                    ;;
            esac
        done
        ;;
        
    log)
        MODE="timeline"
        
        # Parse options
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -p|--path)
                    REPO_PATH="$2"
                    shift 2
                    ;;
                -r|--revset)
                    REVSET="$2"
                    shift 2
                    ;;
                -l|--limit)
                    LIMIT="$2"
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown option: $1" >&2
                    show_help
                    exit 1
                    ;;
            esac
        done
        ;;
        
    *)
        echo "Error: Unknown command: $COMMAND" >&2
        show_help
        exit 1
        ;;
esac

# Resolve the repository path
RESOLVED_PATH=$(resolve_repo_path "$REPO_PATH")

# Open the URL
open_url "$RESOLVED_PATH"