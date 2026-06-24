#!/bin/bash

# Get the absolute path of the script directory
script_dir=$(cd "$(dirname "$0")" && pwd)

# Create a virtual environment in the script's directory
python3 -m venv "$script_dir/venv"

# Activate the virtual environment
source "$script_dir/venv/bin/activate"

# Install the required package
pip install open-interpreter

# Run the interpreter
interpreter --local
