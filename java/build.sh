#!/bin/bash
echo "Building local java files" &&
mkdir -p lib &&
javac -cp core.jar:javase.jar:lib -sourcepath src -d lib \
    src/BarcodePDF417Decode.java \
    src/com/google/zxing/pdf417/PDF417ResultMetadata.java src/com/google/zxing/pdf417/decoder/DecodedBitStreamParser.java
