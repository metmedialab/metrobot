//RLJ 02/19/16 www.gshed.com
//Connect to UR robot and send squiggles drawn on the screen when click event happens

//Client ur;
String input;
int data[];
String textToSend;

//Array of signatures
ArrayList<Signature> arrSignature = new ArrayList<Signature>();

//App Size
final int APP_WIDTH = 800;
final int APP_HEIGHT = 600;

final boolean MODE_TESTING = true;
final boolean MODE_QUEUE = true;

//Set drawing space values
PVector vRobotDrawingSpace = new PVector(4,3);
PreviewView _previewView = new PreviewView(vRobotDrawingSpace);

//=================================NETWORKING DATA===========================================================================
String ipAddress = "10.100.35.125"; //set the ip address of the robot
int port = 30002; //set the port of the robot
//===========================SET POINTS THAT DEFINE THE BASE PLANE OF OUR COORDINATE SYSTEM===================================
//these values should be read from the teachpendant screen and kept in the same units (Millimeters)
PVector origin = new PVector(174.85,269.00,-183.96); //this is the probed origin point of our local coordinate system.
PVector xPt = new PVector(191.05,-358.39,-181.29); //this is a point probed along the x axis of our local coordinate system
PVector yPt = new PVector(574.95,258.02,-194.25); //this is a point probed along the z axis of our local coordinate system
//===============================SET ROBOT VARIABLES=================================================================
URCom ur; //make an instance of our URCom class for talking to this one robot
float radius = 1000; //set our blend radius in mm for movel and movep commands
float speed = 10; //set our speed in mm/s
String openingLines = "def urscript():\nsleep(3)\n"; //in case we want to send more data than just movements, put that text here
String closingLines = "\nend\n"; //closing lines for the end of what we send
//==============================VARIABLES FOR DRAWING============================================================
ArrayList<PVector> sketchPoints = new ArrayList<PVector>();//store our drawing in this arraylist
float minLength = 5; //only register points on the screen if a given distance past the last saved point(keep from building up a million points at the same spot)
boolean firstTouch = false; //have we started drawing?
float zLift = 10;  //distance to lift between drawings

void setup() 
{
  size(800, 600);

  if (MODE_TESTING)
  {
    //if we aren't connected to the robot, we can start the class in testing mode
    ur = new URCom("testing"); //comment if connected to the robot (uncomment if not)
  }
  else
  {
    //if we are actually connected to the robot, we want to start the class in socket mode...
    ur = new URCom("socket"); //uncomment if connected to the robot (comment if not)
    ur.startSocket(this,ipAddress,port); //uncomment if connected to the robot (comment if not)
  }
  
  //delay(1000);
 // textToSend = getText();
  //println(textToSend);
  //ur.write(textToSend);
  
  //==========================================SETUP BASE PLANE========================================================
 // origin.mult(1000); //we want to use millimeters as our units, as they are a sensible unit, and easier to scale from processing pixel coords
  //xPt.mult(1000);//we want to use millimeters as our units, as they are a sensible unit, and easier to scale from processing pixel coords
  //yPt.mult(1000);//we want to use millimeters as our units, as they are a sensible unit, and easier to scale from processing pixel coords

 Pose basePlane = new Pose(); //make a new "Pose" (Position and orientation) for our base plane
  basePlane.fromPoints(origin,xPt,yPt); //define the base plane based on our probed points
  ur.setWorkObject(basePlane); //set this base plane as our transformation matrix for subsequent movement operations
  //==================================================================================================================
  Pose firstTarget = new Pose(); //make a new pose object to store our desired position and orientation of the tool
  firstTarget.fromTargetAndGuide(new PVector(0,0,0), new PVector(0,0,-1)); //set our pose based on the position we want to be at, and the z axis of our tool
  //if we also care about rotation of the tool, we can add the optional third argument that defines what vector to use as a guide for the x axis:
  //firstMoveL.fromTargetAndGuide(new PVector(0,0,0), new PVector(0,0,-1), new PVector(1,0,0)); 
  //ur.moveL(firstTarget); //uncomment if you want the robot to move to the origin at the start

}

void draw() 
{
  background(255);
  smooth();
  
  //Draw Preview View
  _previewView.drawPreview();

  if(firstTouch){//if we've started drawing
  
    PVector currentPos = new PVector(mouseX,height-mouseY,0);
    if(PVector.dist(currentPos,sketchPoints.get(sketchPoints.size()-1)) > minLength){
      sketchPoints.add(currentPos);
    }
  }

  //DRAW THE SIGNATURE
  strokeWeight(1);
  noFill();
  beginShape();
  for(int i = 0; i< sketchPoints.size()-1; i++){
    vertex(sketchPoints.get(i).x,(sketchPoints.get(i).y-height)*-1);
  }
  endShape();
}

void keyPressed() {
   
  // 'a' draw next value in queue
  //
  // 'q' draw next value and remove
  //
  if (key == 'q' || key == 'a') {
    
    //Pop out of Queue and Draw Preview
    if (arrSignature.size() > 0) {
        
        //Find random point and scale in preview area
        PVector _v = _previewView.getRandomPoint();
        float _s = .5 + random(1);
        
        //Pass this set of points to UR Robot.
        //Currently I'm not conforming these numbers to above scale and random point.
        //This will be done next
        sendPointsToUR(arrSignature.get(0).sketchPoints);
        
        //Add points to preview view
        _previewView.addSignature(arrSignature.get(0).getPreviewPoints(_v, _s, random(360)));
        
        if (key == 'q') { 
          arrSignature.remove(0);
        }
 
        println(arrSignature.size());
    }
  }
}

boolean validDrawingLocation()
{
   if (mouseX >= _previewView.topX && mouseX < _previewView.bottomX && mouseY > _previewView.topY && mouseY < _previewView.bottomY)
   {
     return true;
   }
   return false;
}

void mouseClicked(){
  
  //Add a signature
  if (firstTouch) {
    
   if (MODE_QUEUE)
   {
     arrSignature.add(new Signature(sketchPoints));
   }
   else 
   {
     //If no queue, just send signature right to robot
     sendPointsToUR(sketchPoints);
   }

   sketchPoints.clear();
   //reset to a new drawing
   firstTouch = false;
  } else {
    
   firstTouch = true;
   
   PVector pos = new PVector(mouseX,height-mouseY,0);
    if(validDrawingLocation()){ //ignore the annoying corner case
      sketchPoints.add(pos);
    }
  }

}

//SEND POINTS TO UR
void sendPointsToUR(ArrayList<PVector> _sketchPoints)
{
  //send the list of target points when the mouse is clicked
  Pose [] poseArray = new Pose[_sketchPoints.size() + 2]; //CREATE A POSE ARRAY TO HOLD ALL OF OUR DRAWING SEQUENCE
  
  ///ADD THE LIFT POINTS TO THE BEGINNING AND END OF THE POSE ARRAY
  PVector aboveFirstPt = new PVector(_sketchPoints.get(0).x,_sketchPoints.get(0).y,_sketchPoints.get(0).z+zLift);
  PVector aboveLastPt = new PVector(_sketchPoints.get(_sketchPoints.size()-1).x,_sketchPoints.get(_sketchPoints.size()-1).y,_sketchPoints.get(_sketchPoints.size()-1).z+zLift);
  Pose aboveFirstPose = new Pose();
  Pose aboveLastPose = new Pose();
  aboveFirstPose.fromTargetAndGuide(aboveFirstPt,new PVector(0,0,-1));
  aboveLastPose.fromTargetAndGuide(aboveLastPt,new PVector(0,0,-1));
  poseArray[0] = aboveFirstPose;
  poseArray[_sketchPoints.size() + 1] = aboveLastPose; //something is off here...the above point isn't getting added...no time to debug...
  
  ///ADD ALL THE ACTUAL SKETCH POINTS TO OUR POSE ARRAY
  for(int i = 0; i< _sketchPoints.size(); i++){ //for each point in our arraylist
    Pose target = new Pose();//creat a new target pose
    target.fromTargetAndGuide(_sketchPoints.get(i), new PVector(0,0,-1)); //set our pose based on the position we want to be at, and the z axis of our tool
    //ur.moveL(target);
    poseArray[i+1] = target;
  }
  ur.bufferedMoveL(poseArray,openingLines,closingLines); //make our drawing happen!
}