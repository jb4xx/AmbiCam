import controlP5.*;
import java.util.*;

static abstract class modeList {
  static final int CALIBRATION = 0;
  static final int PLAY  = 1;
  static final int PAUSE  = 1;
}

WebCam cam;
ControlP5 cp5;
ColorDetector cd;
ControlFont font;
int mode;
PImage currentSavedStillFrame;


void setup() {
  //fullScreen();
  size(1000, 800);

  mode = modeList.PLAY;

  font = new ControlFont(createFont("Century gothic", 20, true), 14);

  cd = new ColorDetector(10, 5, 3, 70.0/122.0);

  cam = new WebCam(this);
  cam.moveCamListTo(10, 10);
  cam.resizeCamList(499, 200, 26);
  cam.setCamListFont(font);

  createInterface();
}


void draw() {
  if (mode == modeList.PLAY) {
    background(20);
    cam.displayToFitScreen();
  }
}


void createInterface() {
  cp5 = new ControlP5(this);

  // Add the button to launch the calibration process
  cp5.addButton("calibrate")
    .setPosition(510, 10)
    .setSize(100, 26)
    .setFont(font);

  cp5.getController("calibrate").getCaptionLabel().setPadding(0, 0).align(ControlP5.CENTER, ControlP5.CENTER);


  // Add a slider to control the thresold of the screen detection algorithm
  cp5.addSlider("screenDetectionThreshold")
    .setPosition(10, height + 1)
    .setSize(width - 222, 26)
    .setLabel("Threshold")
    .setValue(20000)
    .setRange(0, 195075)
    .setFont(font)
    .setSliderMode(Slider.FLEXIBLE);

  cp5.getController("screenDetectionThreshold").getValueLabel().setVisible(false);
  cp5.getController("screenDetectionThreshold").getCaptionLabel().align(ControlP5.LEFT, ControlP5.CENTER).setPadding(10, 0);


  // Add a bake button on calibration menu
  cp5.addButton("bake")
    .setPosition(width - 211, height + 1)
    .setSize(100, 26)
    .setFont(font);


  // Add a cancel button on calibration menu
  cp5.addButton("cancelCalibration")
    .setPosition(width - 110, height + 1)
    .setSize(100, 26)
    .setFont(font)
    .setLabel("cancel");
    
  // Add a cancel button on calibration menu
  cp5.addButton("reshapeTvScreen")
    .setPosition(width - 110, 10)
    .setSize(100, 26)
    .setFont(font)
    .setLabel("Reshape");
}


// Action on thershold change
void screenDetectionThreshold(float val) {
  if (cp5.getController("screenDetectionThreshold").getPosition()[1] > height) {
    return;
  }
  cd.displayTvScreenSelectiondMap(currentSavedStillFrame, val, cam.getDisplayToFitParameters());
}


// Action on click on calibrate button
void calibrate(int val) {
  currentSavedStillFrame = cam.getPic();
  displayMenu2();
  mode = modeList.CALIBRATION;
  screenDetectionThreshold(cp5.getController("screenDetectionThreshold").getValue());
}


// Action on click on bake button
void bake(int val) {
  cd.bake(currentSavedStillFrame, cp5.getController("screenDetectionThreshold").getValue());
}


//
void reshapeTvScreen(int val) {
  mode = modeList.CALIBRATION;
 PImage test = cd.getReshapedTvScreen(cam.getPic());
}


// Action on click on bake button
void cancelCalibration(int val) {
  displayMenu1();
  mode = modeList.PLAY;
}


// Hide the second menu and display the first one
// setVisibility is not working properly so the setPosition function is use instead by position elements outside the screen
void displayMenu1() {
  // Hide menu 2
  cp5.getController("screenDetectionThreshold").setPosition(10, height + 1);
  cp5.getController("bake").setPosition(width - 211, height + 1);
  cp5.getController("cancelCalibration").setPosition(width - 110, height + 1);

  // Show menu 1
  cp5.getController("calibrate").setPosition(510, 10);
  cam.showCamList();
}


// Hide the first menu and display the second one
// setVisibility is not working properly so the setPosition function is use instead by position elements outside the screen
void displayMenu2() {
  // Hide menu 1
  cp5.getController("calibrate").setPosition(510, height + 1);
  cam.hideCamList();

  // Show menu 2
  cp5.getController("screenDetectionThreshold").setPosition(10, height - 36);
  cp5.getController("bake").setPosition(width - 211, height - 36);
  cp5.getController("cancelCalibration").setPosition(width - 110, height - 36);
}
