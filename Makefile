KERNEL_NAME := dabi2-test

.PHONY: all

all: init kernel

init: 
	@uv sync 

kernel: 
	@uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=$(KERNEL_NAME)

jupyter:
	@uv run --with jupyter jupyter lab 
