#!/usr/bin/env sh

#This simple driver should be run from the base directory of the repo, i.e. one
#level up from the scripts directory.

while true
do
	julia src/repl.jl
	sleep 2
done
