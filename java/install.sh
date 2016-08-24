#!/bin/bash
if [[ ! -e core.jar ]]; then wget -O core.jar http://repo1.maven.org/maven2/com/google/zxing/core/3.2.1/core-3.2.1.jar; fi &&
if [[ ! -e javase.jar ]]; then wget -O javase.jar http://repo1.maven.org/maven2/com/google/zxing/javase/3.2.1/javase-3.2.1.jar; fi
