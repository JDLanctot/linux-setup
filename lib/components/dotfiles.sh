#!/bin/bash

setup_dotfiles() {
    if check_state "dotfiles"; then
        print_status "Dotfiles already configured"
        return 0
    fi
    
    print_status "Setting up dotfiles..."
    
    # Use absolute paths for temp directory
    local temp_path="/tmp/dotfiles_$(date +%s)"
    [ -d "$temp_path" ] && rm -rf "$temp_path"
    
    # Use absolute paths everywhere
    if git clone https://github.com/JDLanctot/dotfiles.git "$temp_path"; then
        local failed=false
        
        for name in "nvim" "bat" "julia" "zsh" "starship"; do
            print_status "Installing $name configuration..."
            if ! install_configuration "$name" "$temp_path"; then
                failed=true
                break
            fi
        done
        
        # Cleanup using absolute path
        rm -rf "$temp_path"
        
        if [ "$failed" = false ]; then
            save_state "dotfiles"
            print_success "Dotfiles setup completed"
            return 0
        fi
        
        return 1
    else
        print_error "Failed to clone dotfiles repository"
        return 1
    fi
}