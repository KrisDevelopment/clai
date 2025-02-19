#!/bin/bash

# Exit on any error
set -e

# Some welcoming dialogue

echo "This script will install the Ollama AI model on your system -locally-."
echo "It will make a command-line AI assistant available through the command:"
echo "helpwith <your question or prompt>"
read -p "Press Enter to continue or Ctrl+C to cancel."

# Start the install

echo "Starting Ollama setup..."

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script as root (use sudo)"
    exit 1
fi

# Ensure curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed. Install it using your package manager (e.g., apt install curl)."
    exit 1
fi

# Install Ollama if not already installed

is_ollama_installed() {
    if command -v ollama &> /dev/null; then
        return 0
    else
        return 1
    fi
}

install_ollama(){
    echo "Installing Ollama..."
    if ! curl -fsSL https://ollama.ai/install.sh | sh; then
        echo "Error: Failed to install Ollama. Please check your connection or the installation script."
        exit 1
    fi
}

if [ is_ollama_installed ]; then
    echo "Ollama is already installed."
    read -p "Do you want to reinstall Ollama? (y/n): " confirm

    if [ "$confirm" == "y" ]; then
        install_ollama
    fi
else
    install_ollama
fi


# Pick model to use
select_model()
{
    echo "Select the model to use:"
    options=("Mistral" "Codellama" "Custom")
    select model in "${options[@]}"; do
        case $model in
            "Mistral")
                model="mistral"
                break
                ;;
            "Codellama")
                model="codellama"
                break
                ;;
            "Custom")
                read -p "Enter the custom model name: " model
                break
                ;;
            *)
                echo "Invalid option. Please select a valid model."
                ;;
        esac
    done

}

select_model
echo "Selected model: $model"

# Check if the model is installed and download it if not
if ! ollama list | grep -q "$model"; then
    echo "Model not found. Downloading..."
    if ! ollama pull "$model"; then
        echo "Error: Failed to download the model. Please check your connection or the model name."
        exit 1
    fi
fi

# Create the helper script
script_content="""
#!/bin/bash

# Check if a prompt was provided
if [ \$# -eq 0 ]; then
    echo \"Usage: helpwith <your question or prompt>\"
    exit 1
fi

# Combine all arguments into a single prompt
prompt=\"\$*\"

# Check stdin for input
if [ -p /dev/stdin ]; then
    prompt=\"\$prompt \$(cat)\"
fi


# Send prompt to Ollama
if ! ollama run $model \"\$prompt\"; then
    echo \"Error: Failed to process the request. Ensure the Ollama service is running.\"
    exit 1
fi
"""

echo "Creating helper script..."

if [ -f /usr/local/bin/helpwith ]; then
    echo "A script with the name 'helpwith' already exists in /usr/local/bin."
    read -p "Do you want to overwrite it? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "Operation cancelled."
        exit 1
    fi

    rm /usr/local/bin/helpwith
fi

cat > /usr/local/bin/helpwith << EOF
$script_content
EOF

# Make the helper script executable
chmod +x /usr/local/bin/helpwith


# install openinterpreter - allows AI to run code
read -p "Do you want to install openinterpreter to enable AI code execution? (y/n): " confirm
if [ "$confirm" == "y" ]; then
    echo "Installing openinterpreter..."
    
    # run the openinterpreter setup script
    local_script_path=$(dirname "$0")
    
    if ! bash "$local_script_path/openinterpreter.sh"; then
        echo "Error: Failed to install openinterpreter. Please check the logs for more information."
        exit 1
    fi  
fi

echo " === DONE ==="
echo "Setup complete! You can now use 'helpwith' followed by your question."
echo "Example: helpwith how do I list files in a directory?"
echo " =========== "
echo " You can run this script again in the future to change the model or update the helper."