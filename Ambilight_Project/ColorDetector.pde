class ColorDetector {
  protected int nbOfXLed, nbOfYLed;
  protected int qualityLevel;
  protected float tvScreenRatio; // height/width
  protected Tetragon tvScreen;
  protected ArrayList<Duo> reshapeParam;
  protected int reshapeW, reshapeH; // The width and height of the reshaped TV screen
  protected float reshapedImageDisplayWidthToFit, reshapedImageDisplayHeightToFit, reshapedImageDisplayDeltaXToFit, reshapedImageDisplayDeltaYToFit;


  // Constructor
  ColorDetector(int p_nbOfXLed, int p_nbOfYLed, int p_qualityLevel, float p_tvScreenRatio) {
    nbOfXLed = p_nbOfXLed;
    nbOfYLed = p_nbOfYLed;
    qualityLevel = p_qualityLevel;
    tvScreenRatio = p_tvScreenRatio;
    reshapeParam = new ArrayList<Duo>();
  }


  // Display the picture "campic" with a semi-transparent red mask on top that represent the part of the image selected using the treshold parameter
  // THe selection is made by choosing all the pixels for wich the color distance to the color of the centered pixel is less than the threshold
  void displayTvScreenSelectiondMap(PImage camPic, float threshold, float[] displayParameters) {
    PImage tempImage = createImage(camPic.width, camPic.height, ARGB);
    color refColor;

    refColor = camPic.get((int)(camPic.width/2), (int)(camPic.height/2));

    tempImage.loadPixels();
    camPic.loadPixels();
    for (int i = 0; i < camPic.width * camPic.height; i++) {
      if (getColorDistance(refColor, camPic.pixels[i]) < threshold) {
        tempImage.pixels[i] = color(255, 0, 0, 100);
      } else {
        tempImage.pixels[i] = color(0, 0, 0, 0);
      }
    }
    tempImage.updatePixels();

    background(20);
    image(camPic, displayParameters[0], displayParameters[1], displayParameters[2], displayParameters[3]);
    image(tempImage, displayParameters[0], displayParameters[1], displayParameters[2], displayParameters[3]);
  }


  // Compute the distance between two colors
  // Minimum is 0, maximum is 195075
  int getColorDistance(color ref, color target) {
    int deltaR = (target >> 16 & 0xFF) - (ref >> 16 & 0xFF);
    int deltaG = (target >> 8 & 0xFF) - (ref >> 8 & 0xFF);
    int deltaB = (target & 0xFF) - (ref & 0xFF);

    return deltaR * deltaR + deltaG * deltaG + deltaB * deltaB;
  }


  // Detect part of "camPic" where the tvScreenIs
  // It works by displaying a unique color image on the tv screen (full green pic for example) and then using that color to detect where the TV screen is (by using the color distance and the threshold)
  void bake(PImage camPic, float threshold) {
    PImage tvScreenMask = getTvScreenMask(camPic, threshold);
    tvScreen = getTvScreen(tvScreenMask, 20);

    // Get render size of the reshaped tv screen
    reshapeW = (int)(max(tvScreen.getCorner("tr").x, tvScreen.getCorner("br").x) - max(tvScreen.getCorner("tl").x, tvScreen.getCorner("bl").x));
    reshapeH = (int)(reshapeW * tvScreenRatio);
    bakeReshapedImageParametersToFit();

    // Bake the reshaping parameters
    Tetragon reshapedTvScreen = new Tetragon(new PVector(0, 0), new PVector(reshapeW, 0), new PVector(reshapeW, reshapeH), new PVector(0, reshapeH)); // A rectangle with the same ratio as the TV
    ArrayList<Tetragon> tvScreenGrid = tvScreen.subdivide(qualityLevel);
    ArrayList<Tetragon> reshapedTvScreenGrid = reshapedTvScreen.subdivide(qualityLevel);

    int lowI = (int)((reshapeW / (float)nbOfXLed) * 1.1); // Those 4 variables are used to limit the reshaping to only the interested areas
    int highI = reshapeW - lowI;
    int lowJ = (int)((reshapeH / (float)nbOfYLed) * 1.1);
    int highJ = reshapeH - lowJ;

    reshapeParam.clear();
    for (int n = 0; n < reshapedTvScreenGrid.size(); n++) {
      PVector tlc, trc, blc, tlc2, trc2, brc2, blc2;
      tlc = reshapedTvScreenGrid.get(n).getCorner("tl");
      trc = reshapedTvScreenGrid.get(n).getCorner("tr");
      blc = reshapedTvScreenGrid.get(n).getCorner("bl");

      tlc2 = tvScreenGrid.get(n).getCorner("tl");
      trc2 = tvScreenGrid.get(n).getCorner("tr");
      brc2 = tvScreenGrid.get(n).getCorner("br");
      blc2 = tvScreenGrid.get(n).getCorner("bl");

      for (int i = (int)tlc.x; i < (int)trc.x; i++) {
        for (int j = (int)tlc.y; j < (int)blc.y; j++) {

          if ((i < lowI || i > highI) || (j < lowJ || j > highJ)) {
            float xPercentage = (float)(i - tlc.x) / (float)(trc.x - tlc.x);
            float yPercentage = (float)(j - tlc.y) / (float)(blc.y - tlc.y);

            float xTarget = tlc2.x * (1.0-yPercentage) * (1.0-xPercentage) + trc2.x * (1.0-yPercentage) * xPercentage + brc2.x * yPercentage * xPercentage + blc2.x * yPercentage * (1.0-xPercentage);
            float yTarget = tlc2.y * (1.0-yPercentage) * (1.0-xPercentage) + trc2.y * (1.0-yPercentage) * xPercentage + brc2.y * yPercentage * xPercentage + blc2.y * yPercentage * (1.0-xPercentage);

            reshapeParam.add(new Duo(getIndex(i, j, reshapeW), getIndex((int)xTarget, (int)yTarget, camPic.width)));
          }
        }
      }
    }
    
    println("Done");
  }


  // Return the reshaped tv Screen
  PImage getReshapedTvScreen(PImage camPic) {
    PImage result = new PImage(reshapeW, reshapeH, RGB);

    camPic.loadPixels();
    result.loadPixels();

    for (int i = 0; i < reshapeParam.size(); i++) {
      result.pixels[reshapeParam.get(i).getV1()] = camPic.pixels[reshapeParam.get(i).getV2()];
    }

    result.updatePixels();
    
    background(255,0,0);
    image(result, reshapedImageDisplayDeltaXToFit, reshapedImageDisplayDeltaYToFit, reshapedImageDisplayWidthToFit, reshapedImageDisplayHeightToFit);
    
    println(reshapeW, reshapeH);
    println(reshapedImageDisplayDeltaXToFit, reshapedImageDisplayDeltaYToFit, reshapedImageDisplayWidthToFit, reshapedImageDisplayHeightToFit);
    
    return result;
  }


  // Compute the display parameters to fit the screen
  void bakeReshapedImageParametersToFit() {
    if ( (reshapeW / reshapeH) < (width / height) ) {
      reshapedImageDisplayHeightToFit = height;
      reshapedImageDisplayWidthToFit = (reshapedImageDisplayHeightToFit * ((float)reshapeW / (float)reshapeH));
      reshapedImageDisplayDeltaYToFit = 0;
      reshapedImageDisplayDeltaXToFit = ((width-reshapedImageDisplayWidthToFit)/2.0);
    } else {
      reshapedImageDisplayWidthToFit = width;
      reshapedImageDisplayHeightToFit = (reshapedImageDisplayWidthToFit * ((float)reshapeH / (float)reshapeW));
      reshapedImageDisplayDeltaXToFit = 0;
      reshapedImageDisplayDeltaYToFit = ((height-reshapedImageDisplayHeightToFit)/2.0);
    }
  }


  // Return the index of a pixel based on is x and y position
  int getIndex(int x, int y, int w) {
    return x + y * w;
  }


  // Return a black and white image where the tv screen is white and the rest is black
  PImage getTvScreenMask(PImage camPic, float threshold) {
    PImage tvScreenMask = createImage(camPic.width, camPic.height, RGB); // the result image
    color refColor = camPic.get((int)(camPic.width/2), (int)(camPic.height/2)); // The color use to detect if a pixel is part of the screen or not
    boolean[][] pixelIsAlreadySelected = new boolean[camPic.width][camPic.height]; // Use to avoid computing several time the same pixel
    ArrayList<PVector> pixelsToBeChecked = new ArrayList<PVector>(); // The list of all the pixels that need to be checked

    // Initialization
    pixelsToBeChecked.add(new PVector((int)(camPic.width/2), (int)(camPic.height/2)));
    pixelIsAlreadySelected[(int)(camPic.width/2)][(int)(camPic.height/2)] = true;

    tvScreenMask.loadPixels();
    camPic.loadPixels();
    while (pixelsToBeChecked.size() > 0) {
      // Get the coordinate of the pixel to analyse
      int x = (int)pixelsToBeChecked.get(0).x;
      int y = (int)pixelsToBeChecked.get(0).y;
      int idx = getIndex(x, y, camPic.width);

      // Check if the point is in the selection and if so, spread it (in the image range)
      if (getColorDistance(refColor, camPic.pixels[idx]) < threshold) {
        tvScreenMask.pixels[idx] = color(255);

        // Spread the pixels
        if (x+1 < camPic.width) {
          if (pixelIsAlreadySelected[x+1][y] == false) {
            pixelsToBeChecked.add(new PVector(x+1, y));
            pixelIsAlreadySelected[x+1][y] = true;
          }
        }

        if (x-1 > 0) {
          if (pixelIsAlreadySelected[x-1][y] == false) {
            pixelsToBeChecked.add(new PVector(x-1, y));
            pixelIsAlreadySelected[x-1][y] = true;
          }
        }

        if (y+1 < camPic.height) {
          if (pixelIsAlreadySelected[x][y+1] == false) {
            pixelsToBeChecked.add(new PVector(x, y+1)); 
            pixelIsAlreadySelected[x][y+1] = true;
          }
        }

        if (y-1 > 0) {
          if (pixelIsAlreadySelected[x][y-1] == false) {
            pixelsToBeChecked.add(new PVector(x, y-1)); 
            pixelIsAlreadySelected[x][y-1] = true;
          }
        }
      }

      // Remove the pixel from the list of the pixel to analyse
      pixelsToBeChecked.remove(0);
    }
    tvScreenMask.updatePixels();
    return tvScreenMask;
  }


  // Return a tetragon representing the tv screen
  Tetragon getTvScreen(PImage maskPic, int ctrlAreaSize) {
    PVector tlCorner = getCorner(maskPic, 0, maskPic.width / 2, 0, maskPic.height / 2, ctrlAreaSize);
    PVector trCorner = getCorner(maskPic, maskPic.width / 2, maskPic.width, 0, maskPic.height / 2, ctrlAreaSize);
    PVector brCorner = getCorner(maskPic, 0, maskPic.width / 2, maskPic.height / 2, maskPic.height, ctrlAreaSize);
    PVector blCorner = getCorner(maskPic, maskPic.width / 2, maskPic.width, maskPic.height / 2, maskPic.height, ctrlAreaSize);

    return new Tetragon(tlCorner, trCorner, brCorner, blCorner);
  }


  // Find and return the coordinates of the corner in an area of maskpic
  PVector getCorner(PImage maskPic, int xlBound, int xuBound, int ylBound, int yuBound, int ctrlAreaSize) {
    int minVal = (ctrlAreaSize *2) * (ctrlAreaSize * 2) * 255;
    int tempVal;
    PVector corner = new PVector(0, 0);

    for (int x = xlBound; x < xuBound; x++) {
      for (int y = ylBound; y < yuBound; y++) {

        if ((maskPic.pixels[getIndex(x, y, maskPic.width)] >> 16 & 0xFF) > 0) {

          tempVal = 0;
          for (int dx = -ctrlAreaSize; dx <= ctrlAreaSize; dx++) {
            for (int dy = -ctrlAreaSize; dy <= ctrlAreaSize; dy++) {
              int idx = getIndex(x + dx, y + dy, maskPic.width);
              if (idx > -1 && idx < maskPic.pixels.length) {
                tempVal += (maskPic.pixels[idx] >> 16 & 0xFF);
              }
            }
          }

          if (tempVal < minVal) {
            minVal = tempVal;
            corner.set(x, y);
          }
        }
      }
    }

    return corner;
  }
}
