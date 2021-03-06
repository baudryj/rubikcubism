class QImage {
  int width, height;
  int[] pixels;
  color[] palette;

  int[] freq;

  QImage(PImage img, int colorCount, int colorSpace) {
    width = img.width;
    height = img.height;
    pixels = new int[width * height];
    palette = new color[colorCount];
    freq = new int[colorCount];

    float[][] vPixels = new float[pixels.length][3];
    img.loadPixels();
    for (int i = 0; i < pixels.length; i++) {
      if (colorSpace == RGB) {
        colorToRgb(img.pixels[i], vPixels[i]);
      } else {
        colorToLab(img.pixels[i], vPixels[i]);
      }
    }

    KMeans km = new KMeans(vPixels, colorCount);
    km.compute();

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = km.getCluster(i);
    }

    for (int c = 0; c < palette.length; c++) {
      float[] v = km.getCentroid(c);
      palette[c] = colorSpace == RGB ? rgbToColor(v) : labToColor(v);
    }
  }

  void display(int x0, int y0, int pSize) {
    display(x0, y0, 0, 0, width, height, pSize);
  }

  void display(int x0, int y0, int xs, int ys, int w, int h, int pSize) {
    stroke(0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int i = (ys + y) * width + xs +x;
        fill(palette[pixels[i]]);
        rect(x0 + x * pSize, y0 + y * pSize, pSize, pSize, pSize / 6);
      }
    }
  }


    void shrink(int blockSize) {
      int newWidth = width / blockSize;
      int newHeight = height / blockSize;
      int[] newPixels = new int[newWidth * newHeight];

      int i = 0;
      for (int newY = 0; newY < newHeight; newY++) {
        for (int newX = 0; newX < newWidth; newX++) {
          newPixels[i++] = mostFrequentColor(blockSize * newX, blockSize * newY, blockSize, blockSize);
        }
      }

      width = newWidth;
      height = newHeight;
      pixels = newPixels;
    }

    int mostFrequentColor(int x0, int y0, int w, int h) {
      for (int c = 0; c < freq.length; c++) freq[c] = 0;

      int cMax = 0;
      for (int y = y0; y < y0 + h; y++) {
        for (int x = x0; x < x0 + w; x++) {
          int c = pixels[y * width + x];
          freq[c]++;
          if (freq[c] > freq[cMax]) cMax = c;
        }
      }

      return cMax;
    }

    void changePalette(color[] newPalette) {
      // compute cost matrix
      int k = palette.length;
      float[][] costs = new float[k][k];
      float[][] rgb = new float[k][3];
      float[][] newRgb = new float[k][3];

      for (int c = 0; c < k; c++) {
        colorToRgb(palette[c], rgb[c]);
        colorToRgb(newPalette[c], newRgb[c]);
      }

      for (int i = 0; i < k; i++) {
        for (int j = 0; j < k; j++) {
          costs[i][j] = sqrt(sqDist(rgb[i], newRgb[j]));
        }
      }

      // assign new colors to current colors  
      Assignment ass = new Assignment(costs);
      ass.compute();
      palette = newPalette;
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = ass.getPair(pixels[i]);
      }
    }

    float commonPixelsWith(QImage other) {
      int common = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (pixels[i] == other.pixels[i]) common++;
      }
      return float(common) / pixels.length;
    }
  }
