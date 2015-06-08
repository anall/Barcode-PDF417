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

import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.multi.GenericMultipleBarcodeReader;
import com.google.zxing.multi.MultipleBarcodeReader;

import com.google.zxing.client.j2se.ImageReader;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;

public final class BarcodePDF417Decode {

  private BarcodePDF417Decode() {
  }

  public static void main(String[] args) throws Exception {
    Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
    hints.put(DecodeHintType.POSSIBLE_FORMATS, Arrays.asList(BarcodeFormat.PDF_417));

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
    System.out.println( result.getBarcodeFormat() );
    byte bytes[] = result.getText().getBytes();
    int i = 0;
    for ( byte b : bytes ) {
      System.out.format("%d ",b);
      if ( ++i > 32 ) {
        System.out.print("\n");
        i = 0;
      }
    }
    System.out.print("\n");
  }
}
