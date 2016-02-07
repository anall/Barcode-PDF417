#!/bin/bash
if [[ -e $HOME/.cache/jar ]]; then cp $HOME/.cache/jar/*.jar java; fi &&
if [[ -e core.jar ]]; then
    ./build.sh;
else
    ./install.sh;
fi
