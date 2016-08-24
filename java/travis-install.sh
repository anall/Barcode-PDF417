#!/bin/bash
if [[ -e $HOME/.cache/jar/core.jar ]]; then (cp $HOME/.cache/jar/*.jar .); fi &&
if [[ -e core.jar ]]; then
    ./build.sh;
else
    ./install.sh && ./build.sh;
fi
