#!/usr/bin/env sh
wget -O core.jar http://repo1.maven.org/maven2/com/google/zxing/core/3.2.0/core-3.2.0.jar &&
wget -O javase.jar http://repo1.maven.org/maven2/com/google/zxing/javase/3.2.0/javase-3.2.0.jar &&
sh build.sh
