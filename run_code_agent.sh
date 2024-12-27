#!/bin/bash

# create a virtual environment and run open-interpreter in it

python3 -m venv venv
source venv/bin/activate

pip install open-interpreter

interpreter --local