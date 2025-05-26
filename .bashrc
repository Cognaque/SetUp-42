# .bashrc

# PATH
export PATH="$HOME/.bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"

# Show Date and Time when you executed a command
HISTTIMEFORMAT="%F %T "

# Custom Alias
alias reloadbash="source ~/.bashrc"
alias cook="chmod +x"

# YT-DLP
alias zora='yt-dlp --no-playlist -f "bv*+ba/b" --merge-output-format mp4 --embed-subs --write-auto-sub --sub-lang en --embed-thumbnail --quiet --progress -o "%(title)s.%(ext)s" '
alias zora_plist='yt-dlp -f "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]" --merge-output-format mp4 --embed-subs --write-auto-sub --sub-lang en --embed-thumbnail --quiet --progress -o "%(playlist_title)s/%(title)s.%(ext)s" '



# Running a program as User or with sudo privilege

run() {
    # Execute local script with arguments (handles spaces in paths)
    if [ -z "$1" ]; then
        echo "Usage: exe script [arguments...]"
        return 1
    fi
    bash -- "./$1" "${@:2}"
}

srun() {
    # Execute local script with sudo and arguments (handles spaces)
    if [ -z "$1" ]; then
        echo "Usage: sexe script [arguments...]"
        return 1
    fi
    sudo bash -- "./$1" "${@:2}"
}

# For Asciinema 

rec() {
  local timestamp=$(date +"%d-%m-%Y_%I-%M-%S_%p")
  local logdir=~/Videos/Logs/Atom
  mkdir -p "$logdir"
  local logfile="$logdir/session_${timestamp}.cast"

  # Start recording quietly
  asciinema rec -q "$logfile"

  # Mandatory comment prompt
  local comment
  while :; do
    read -r -p "Enter session comment (required): " comment
    if [[ -n "$comment" ]]; then
      break
    fi
    echo "Error: Comment cannot be empty." >&2
  done

  # Add comment to cast file
  if command -v jq >/dev/null 2>&1; then
    local tmpfile=$(mktemp)
    head -n1 "$logfile" | jq --compact-output --arg cmt "$comment" '.comment = $cmt' > "$tmpfile"
    tail -n +2 "$logfile" >> "$tmpfile"
    mv "$tmpfile" "$logfile"
  else
    echo "Error: jq is required to add comments." >&2
    return 1
  fi
}

playrec() {
    local dir=~/Videos/Logs/Atom
    local search_date
    
    # Prompt for date input
    while true; do
        read -p "Enter date (DD-MM-YYYY or DD/MM/YYYY): " input_date
        # Normalize input to DD-MM-YYYY format
        local cleaned=$(echo "$input_date" | tr -d -c '[:digit:]' | sed -E 's/^([0-9]{2})([0-9]{2})([0-9]{4})$/\1-\2-\3/')
        
        # Validate components
        if [[ "$cleaned" =~ ^([0-9]{2})-([0-9]{2})-([0-9]{4})$ ]]; then
            local day=${BASH_REMATCH[1]}
            local month=${BASH_REMATCH[2]}
            local year=${BASH_REMATCH[3]}
            
            if (( month >= 1 && month <= 12 && day >= 1 && day <= 31 )); then
                search_date=$(printf "%02d-%02d-%04d" "$day" "$month" "$year")
                break
            fi
        fi
        echo -e "\033[31mInvalid date. Use DD-MM-YYYY or DD/MM/YYYY (e.g., 16-04-2025).\033[0m"
    done

    # Find matching files
    local files=($(find "$dir" -name "session_${search_date}_*.cast" -print 2>/dev/null | sort))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No recordings found for $search_date"
        return 1
    fi

    # Prepare descriptions with comments
    local descriptions=()
    for file in "${files[@]}"; do
        # Extract time from filename
        local base=$(basename "$file")
        local time_part=$(echo "$base" | grep -Eo '[0-9]{2}:[0-9]{2}:[0-9]{2}_[AP]M')
        
        # Extract comment
        local comment="no comment"
        if command -v jq >/dev/null 2>&1; then
            local raw_comment=$(jq -r '.comment // empty' "$file" 2>/dev/null)
            [ -n "$raw_comment" ] && comment="$raw_comment"
        fi
        
        descriptions+=("${search_date} ${time_part} - ${comment}")
    done

    # Handle file selection
    if [ ${#files[@]} -gt 1 ]; then
        echo -e "\n\033[33mMultiple recordings found for $search_date:\033[0m"
        PS3=$'\n\033[33mSelect a recording (enter number): \033[0m'
        select desc in "${descriptions[@]}"; do
            [[ -n "$desc" ]] && break
            echo -e "\033[31mInvalid selection. Try again.\033[0m"
        done
        file="${files[$REPLY-1]}"
    else
        file="${files}"
    fi

    # Play selected file
    if [ -f "$file" ]; then
        echo -e "\n\033[1;34mPlaying $file\033[0m"
        asciinema play "$file"
    else
        echo -e "\033[31mFile not found: $file\033[0m"
        return 1
    fi
}





# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


eval "$(starship init bash)"
