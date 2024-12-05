#!/bin/bash

# Dotfiles paths configuration
declare -A CONFIG_PATHS=(
    ["nvim,source"]="config/nvim"
    ["nvim,target"]="$HOME/.config/nvim"
    ["nvim,type"]="directory"
    
    ["bat,source"]="config/bat/config"
    ["bat,target"]="$HOME/.config/bat/config"
    ["bat,type"]="file"
    
    ["julia,source"]=".julia/config/startup.jl"
    ["julia,target"]="$HOME/.julia/config/startup.jl"
    ["julia,type"]="file"
    
    ["zsh,source"]=".zshrc"
    ["zsh,target"]="$HOME/.zshrc"
    ["zsh,type"]="file"
    
    ["starship,source"]=".config/starship.toml"
    ["starship,target"]="$HOME/.config/starship.toml"
    ["starship,type"]="file"
)

get_config_path() {
    local component=$1
    local attribute=$2  # source, target, or type
    echo "${CONFIG_PATHS[${component},${attribute}]}"
}

verify_config_paths() {
    local component=$1
    local source_path=$(get_config_path "$component" "source")
    local target_path=$(get_config_path "$component" "target")
    local type=$(get_config_path "$component" "type")
    
    [[ -n "$source_path" && -n "$target_path" && -n "$type" ]]
}