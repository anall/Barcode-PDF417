/*

Copyright 2015 Andrea Nall

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/
import java.util.Arrays;
import java.util.Map;
import java.util.EnumMap;
import java.net.URI;
import java.io.File;

import java.awt.image.BufferedImage;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.DecodeHintType;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.Result;
import com.google.zxing.ResultPoint;
import com.google.zxing.ResultMetadataType;

import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.multi.GenericMultipleBarcodeReader;
import com.google.zxing.multi.MultipleBarcodeReader;

import com.google.zxing.pdf417.PDF417ResultMetadata;

import com.google.zxing.client.j2se.ImageReader;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;

public final class BarcodePDF417Decode {

  private BarcodePDF417Decode() {
  }

  public static void main(String[] args) throws Exception {
    Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
    hints.put(DecodeHintType.POSSIBLE_FORMATS, Arrays.asList(BarcodeFormat.PDF_417));
    hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
    hints.put(DecodeHintType.PURE_BARCODE, Boolean.TRUE);

    if (args.length != 1) {
      System.out.println("FAIL: No arguments");
      System.exit(-1);
    }

    URI uri = new File(args[0]).toURI();
    BufferedImage image = ImageReader.readImage(uri);

    LuminanceSource source = new BufferedImageLuminanceSource(image);
    BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

    MultiFormatReader multiFormatReader = new MultiFormatReader();
    Result[] results;
    try {
      results = new Result[]{multiFormatReader.decode(bitmap, hints)};
    } catch (NotFoundException ignored) {
      System.out.println("FAIL: No barcode found");
      System.exit(-1);
      return;
    }

    if ( results.length != 1 ) {
      System.out.println("FAIL: No barcode found");
      System.exit(-1);
      return;
    }

    Result result = results[0];
    Map<ResultMetadataType,Object> metadata = result.getResultMetadata();
    PDF417ResultMetadata pdfMetadata = (PDF417ResultMetadata)metadata.get(ResultMetadataType.PDF417_EXTRA_METADATA);

    System.out.println( result.getBarcodeFormat() );
    System.out.println( result.getResultMetadata().get(ResultMetadataType.ERROR_CORRECTION_LEVEL) );

    int codewords[] = pdfMetadata.getCodewords();
    for ( int i : codewords ) {
      System.out.format("%d ",i);
    }
    System.out.print("\n");

    byte bytes[] = result.getText().getBytes();
    for ( byte b : bytes ) {
      System.out.format("%02x",b);
    }
    System.out.print("\n");
  }
}
