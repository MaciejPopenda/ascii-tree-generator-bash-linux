#!/bin/bash

# ASCII Tree Generator - Bash version
# Generates directory tree structure with .gitignore support

set -euo pipefail

# Default values
ALL_FILES=false
OUTPUT_NAME="project-ascii-tree.txt"
OUTPUT_PATH="."
DRY_RUN=false
DEBUG=false
MAX_DEPTH=999999
INCLUDE_PATTERN=""
EXCLUDE_PATTERN=""
EXCEPT_DIRS=()
EXCEPT_FILES=()

# Always ignore these
ALWAYS_IGNORE=(".git" "project-ascii-tree.txt")

# Default ignore patterns
DEFAULT_PATTERNS=("node_modules" ".git" "*.log" "dist" "build" ".vscode" ".idea" ".DS_Store" "Thumbs.db" "*.tmp" "*.cache")

# Arrays to store gitignore files
declare -a GITIGNORE_PATHS=()
declare -a GITIGNORE_RELATIVE=()
declare -A GITIGNORE_PATTERNS=()

# Function to show help
show_help() {
    cat << EOF
ascii-tree-generator - Generate ASCII directory tree structure

USAGE:
  ./ascii-tree-generator.sh [OPTIONS]

OPTIONS:
  --all                          Include all files (ignore .gitignore)
  --except-dir "dir1,dir2"       Additional directories to ignore
  --except-file "f1,f2"          Additional files to ignore
  --output-name <filename>       Output filename (default: project-ascii-tree.txt)
  --output-path <path>           Output directory (default: current directory)
  --dry-run                      Preview without creating file
  --debug                        Show debug information
  --max-depth <number>           Maximum directory depth
  --include-pattern <regex>      Only show files matching pattern (grep -E)
  --exclude-pattern <regex>      Exclude files/dirs matching pattern
  --help, -h                     Show this help

EXAMPLES:
  ./ascii-tree-generator.sh
  ./ascii-tree-generator.sh --max-depth 3 --dry-run
  ./ascii-tree-generator.sh --include-pattern '\.js$'
  ./ascii-tree-generator.sh --exclude-pattern 'test|spec'

EOF
}

# Parse comma-separated values
parse_array() {
    local input="$1"
    IFS=',' read -ra ADDR <<< "$input"
    for i in "${ADDR[@]}"; do
        # Remove quotes and whitespace
        i=$(echo "$i" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^['\"]//;s/['\"]$//")
        echo "$i"
    done
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                ALL_FILES=true
                shift
                ;;
            --except-dir)
                if [[ -n "${2:-}" ]]; then
                    mapfile -t EXCEPT_DIRS < <(parse_array "$2")
                    shift 2
                else
                    echo "Error: --except-dir requires a value"
                    exit 1
                fi
                ;;
            --except-file)
                if [[ -n "${2:-}" ]]; then
                    mapfile -t EXCEPT_FILES < <(parse_array "$2")
                    shift 2
                else
                    echo "Error: --except-file requires a value"
                    exit 1
                fi
                ;;
            --output-name)
                OUTPUT_NAME="$2"
                shift 2
                ;;
            --output-path)
                OUTPUT_PATH="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --max-depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            --include-pattern)
                INCLUDE_PATTERN="$2"
                shift 2
                ;;
            --exclude-pattern)
                EXCLUDE_PATTERN="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check if pattern matches
matches_pattern() {
    local pattern="$1"
    local name="$2"
    local rel_path="$3"
    
    # Handle wildcards
    if [[ "$pattern" == *"*"* ]] || [[ "$pattern" == *"?"* ]]; then
        # Convert gitignore pattern to bash glob
        if [[ "$name" == $pattern ]] || [[ "$rel_path" == $pattern ]]; then
            return 0
        fi
        # Check path components
        IFS='/' read -ra PARTS <<< "$rel_path"
        for part in "${PARTS[@]}"; do
            if [[ "$part" == $pattern ]]; then
                return 0
            fi
        done
        return 1
    fi
    
    # Exact match
    if [[ "$name" == "$pattern" ]] || [[ "$rel_path" == "$pattern" ]]; then
        return 0
    fi
    
    # Check if pattern is in path
    if [[ "$pattern" == *"/"* ]]; then
        if [[ "$rel_path" == "$pattern"* ]]; then
            return 0
        fi
    else
        if [[ "$rel_path" == *"/$pattern"* ]] || [[ "$rel_path" == "$pattern"* ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Find all .gitignore files recursively
find_gitignores() {
    local dir="$1"
    local rel_path="${2:-.}"
    local index=0
    
    if [[ "$ALL_FILES" == true ]]; then
        echo "Using --all flag: including all files except system files"
        return
    fi
    
    # Check for .gitignore in current directory
    if [[ -f "$dir/.gitignore" ]]; then
        GITIGNORE_PATHS+=("$dir")
        GITIGNORE_RELATIVE+=("$rel_path")
        
        local patterns=""
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # Skip empty lines and comments
            [[ -z "$line" ]] && continue
            [[ "$line" == "#"* ]] && continue
            
            # Handle negation
            local is_negation=false
            if [[ "$line" == "!"* ]]; then
                is_negation=true
                line="${line:1}"
            fi
            
            # Clean up
            line="${line%/}"
            line="${line#/}"
            
            if [[ "$is_negation" == true ]]; then
                patterns+="!$line"$'\n'
            else
                patterns+="$line"$'\n'
            fi
        done < "$dir/.gitignore"
        
        GITIGNORE_PATTERNS["$rel_path"]="$patterns"
    fi
    
    # Recursively search subdirectories
    while IFS= read -r -d '' subdir; do
        local name=$(basename "$subdir")
        local sub_rel=""
        
        if [[ "$rel_path" == "." ]]; then
            sub_rel="$name"
        else
            sub_rel="$rel_path/$name"
        fi
        
        # Skip if directory is ignored
        local skip=false
        for pattern in "${ALWAYS_IGNORE[@]}"; do
            if [[ "$name" == "$pattern" ]]; then
                skip=true
                break
            fi
        done
        
        [[ "$skip" == true ]] && continue
        
        find_gitignores "$subdir" "$sub_rel"
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# Check if item should be ignored
should_ignore() {
    local name="$1"
    local rel_path="$2"
    
    [[ "$DEBUG" == true ]] && echo "Checking: $rel_path" >&2
    
    # Check against all gitignore patterns
    local should_ignore_item=false
    
    for idx in "${!GITIGNORE_RELATIVE[@]}"; do
        local gi_path="${GITIGNORE_RELATIVE[$idx]}"
        local patterns="${GITIGNORE_PATTERNS[$gi_path]}"
        
        # Check if this gitignore applies
        if [[ "$gi_path" == "." ]] || [[ "$rel_path" == "$gi_path"* ]]; then
            while IFS= read -r pattern; do
                [[ -z "$pattern" ]] && continue
                
                local is_negation=false
                if [[ "$pattern" == "!"* ]]; then
                    is_negation=true
                    pattern="${pattern:1}"
                fi
                
                if matches_pattern "$pattern" "$name" "$rel_path"; then
                    if [[ "$is_negation" == true ]]; then
                        should_ignore_item=false
                    else
                        should_ignore_item=true
                    fi
                    [[ "$DEBUG" == true ]] && echo "  Matched: $pattern (ignore=$should_ignore_item)" >&2
                fi
            done <<< "$patterns"
        fi
    done
    
    [[ "$should_ignore_item" == true ]] && return 0
    return 1
}

# Check pattern filters
check_patterns() {
    local name="$1"
    local rel_path="$2"
    local is_dir="$3"
    
    # Exclude pattern applies to both files and dirs
    if [[ -n "$EXCLUDE_PATTERN" ]]; then
        if echo "$name" | grep -qE "$EXCLUDE_PATTERN" || echo "$rel_path" | grep -qE "$EXCLUDE_PATTERN"; then
            return 1
        fi
    fi
    
    # Include pattern only for files
    if [[ "$is_dir" == false ]] && [[ -n "$INCLUDE_PATTERN" ]]; then
        if ! echo "$name" | grep -qE "$INCLUDE_PATTERN" && ! echo "$rel_path" | grep -qE "$INCLUDE_PATTERN"; then
            return 1
        fi
    fi
    
    return 0
}

# Generate tree recursively
generate_tree() {
    local dir="$1"
    local prefix="$2"
    local rel_path="$3"
    local depth="$4"
    
    [[ "$depth" -gt "$MAX_DEPTH" ]] && return
    
    local items=()
    local dirs=()
    local files=()
    
    # Read directory contents
    while IFS= read -r -d '' item; do
        local name=$(basename "$item")
        local item_rel=""
        
        if [[ "$rel_path" == "." ]]; then
            item_rel="$name"
        else
            item_rel="$rel_path/$name"
        fi
        
        # Check if should be included
        if should_ignore "$name" "$item_rel"; then
            continue
        fi
        
        if [[ -d "$item" ]]; then
            if check_patterns "$name" "$item_rel" true; then
                dirs+=("$name")
            fi
        else
            if check_patterns "$name" "$item_rel" false; then
                files+=("$name")
            fi
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
    
    # Combine and sort (directories first)
    items=("${dirs[@]}" "${files[@]}")
    
    # Print items
    local total=${#items[@]}
    for i in "${!items[@]}"; do
        local name="${items[$i]}"
        local is_last=false
        [[ $((i + 1)) -eq $total ]] && is_last=true
        
        if [[ "$is_last" == true ]]; then
            echo "${prefix}└── $name"
            local new_prefix="${prefix}    "
        else
            echo "${prefix}├── $name"
            local new_prefix="${prefix}│   "
        fi
        
        # Recurse into directories
        local item_path="$dir/$name"
        local item_rel=""
        if [[ "$rel_path" == "." ]]; then
            item_rel="$name"
        else
            item_rel="$rel_path/$name"
        fi
        
        if [[ -d "$item_path" ]]; then
            generate_tree "$item_path" "$new_prefix" "$item_rel" $((depth + 1))
        fi
    done
}

# Main function
main() {
    parse_args "$@"
    
    local project_name=$(basename "$(pwd)")
    
    echo "Generating ASCII tree for: $project_name"
    
    # Find gitignore files
    if [[ "$ALL_FILES" == false ]]; then
        find_gitignores "." "."
        
        if [[ ${#GITIGNORE_PATHS[@]} -eq 0 ]]; then
            echo "No .gitignore files found, using default ignore patterns"
            # Add default patterns
            GITIGNORE_RELATIVE+=(".")
            local default_patterns=""
            for pattern in "${ALWAYS_IGNORE[@]}" "${DEFAULT_PATTERNS[@]}" "${EXCEPT_DIRS[@]}" "${EXCEPT_FILES[@]}"; do
                default_patterns+="$pattern"$'\n'
            done
            GITIGNORE_PATTERNS["."]="$default_patterns"
        else
            local total_patterns=0
            for gi_path in "${!GITIGNORE_PATTERNS[@]}"; do
                local count=$(echo "${GITIGNORE_PATTERNS[$gi_path]}" | grep -c '^' || echo 0)
                total_patterns=$((total_patterns + count))
            done
            echo "Found ${#GITIGNORE_PATHS[@]} .gitignore file(s) with $total_patterns total patterns"
        fi
    fi
    
    [[ -n "$INCLUDE_PATTERN" ]] && echo "Include pattern: $INCLUDE_PATTERN"
    [[ -n "$EXCLUDE_PATTERN" ]] && echo "Exclude pattern: $EXCLUDE_PATTERN"
    echo ""
    
    # Generate tree
    local output="$project_name/"$'\n'
    output+=$(generate_tree "." "" "." 0)
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "=== DRY RUN ==="
        echo "Would generate:"
        echo "$output"
        echo "Would save to: $OUTPUT_PATH/$OUTPUT_NAME"
        return
    fi
    
    # Create output directory if needed
    mkdir -p "$OUTPUT_PATH"
    
    # Write output
    echo "$output" > "$OUTPUT_PATH/$OUTPUT_NAME"
    
    echo "Project structure saved to: $OUTPUT_PATH/$OUTPUT_NAME"
}

main "$@"