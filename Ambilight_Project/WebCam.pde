import processing.video.*;
import controlP5.*;
import java.util.*;

class WebCam {
  protected Capture cam;
  protected ControlP5 cp5;
  protected float camPicWidth, camPicHeight;
  protected float imageDisplayWidthToFit, imageDisplayHeightToFit, imageDisplayDeltaXToFit, imageDisplayDeltaYToFit;
  protected PApplet parent;
  protected ScrollableList cameraList;
  protected String currentCam;

  // Constructor 1
  WebCam(PApplet p_parent) {
    parent = p_parent;
    currentCam = "cameraList";
    addCameraList();
    initializeCamera(cameraList.getLabel());
  }


  // Add the camera list and the event listener
  void addCameraList() {
    String[] cameras = getCameraList();
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    }

    cp5 = new ControlP5(parent);
    cameraList = cp5.addScrollableList("cameraList")
      .setPosition(20, 20)
      .setSize(400, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(cameras)
      .setValue(0);

    cameraList.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        switch(theEvent.getAction()) {
          case(ControlP5.ACTION_RELEASE): 
          initializeCamera(theEvent.getController().getLabel());
        }
      }
    }
    );
  }


  // Move the list
  void moveCamListTo(float x, float y) {
    cameraList.setPosition(x, y);
  }


  // Resize the list
  void resizeCamList(int p_width, int p_height, int closed_height) {
    cameraList.setSize(p_width, p_height);
    cameraList.setBarHeight(closed_height);
    cameraList.setItemHeight(closed_height);
  }


  // Change the font of the list
  void setCamListFont(ControlFont font) {
    cameraList.getCaptionLabel().setFont(font);
    cameraList.getValueLabel().setFont(font);

    cameraList.getCaptionLabel().alignX(ControlP5.CENTER);
  }


  // Return the list of cameras
  String[] getCameraList() {
    return Capture.list();
  }


  // Set up the selected camera
  void initializeCamera(String camName) {
    if (currentCam == camName) {
      return;
    }

    currentCam = camName;

    if (cam != null) {
      cam.stop();
    }


    //Initialize the cam
    cam = new Capture(parent, camName);
    cam.start();

    while (cam.available() == false) {
      delay(10);
    }

    cam.read();
    camPicWidth = cam.width;
    camPicHeight = cam.height;
    if ( (camPicWidth / camPicHeight) < (width / height) ) {
      imageDisplayHeightToFit = height;
      imageDisplayWidthToFit = (imageDisplayHeightToFit * (camPicWidth / camPicHeight));
      imageDisplayDeltaYToFit = 0;
      imageDisplayDeltaXToFit = ((width-imageDisplayWidthToFit)/2);
    } else {
      imageDisplayWidthToFit = width;
      imageDisplayHeightToFit = (imageDisplayWidthToFit * (camPicHeight / camPicWidth));
      imageDisplayDeltaXToFit = 0;
      imageDisplayDeltaYToFit = ((height-imageDisplayHeightToFit)/2);
    }
  }


  // Display and fit webcam image to the canvas
  void displayToFitScreen() {
    if (cam != null) {
      if (cam.available() == true) {
        cam.read();
      }
      image(cam, imageDisplayDeltaXToFit, imageDisplayDeltaYToFit, imageDisplayWidthToFit, imageDisplayHeightToFit);
    }
  }


  // Return the cam image
  //PImage getPic() {
  //  if (cam == null) { 
  //    println("No camera activated");
  //    return createImage(1, 1, RGB);
  //  }

  //  if (cam.available() == true) {
  //    cam.read();
  //    return cam;
  //  } 

  //  return createImage(1, 1, RGB);
  //}
  PImage getPic() {
    while (cam.available() == false) {
      delay(10);
    } 
    cam.read();
    return cam;
  }


  // Hide the camera list
  void hideCamList() {
    cameraList.setVisible(false);
  }


  // Show the camera list
  void showCamList() {
    cameraList.setVisible(true);
  }


  // Return the width of the selected camera
  float getWidth() {
    return camPicWidth;
  }


  // Return the height of the selected camera
  float getHeight() {
    return camPicHeight;
  }


  // Return the parameters needed to display an image from the webcam in order to fit the screen
  float[] getDisplayToFitParameters() {
    float[] param = new float[4];
    param[0] = imageDisplayDeltaXToFit;
    param[1] = imageDisplayDeltaYToFit;
    param[2] = imageDisplayWidthToFit;
    param[3] = imageDisplayHeightToFit;
    return param;
  }


  //C
}
