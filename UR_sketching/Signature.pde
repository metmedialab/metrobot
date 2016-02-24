/******************************
*  Signature
*
******************************/
class Signature {

  ArrayList<PVector> sketchPoints = new ArrayList<PVector>();  //store our drawing in this arraylist
  float DEFAULT_PREVIEW_SCALE = .3;

  Signature(ArrayList<PVector> _sketchPoints) {

    sketchPoints = (ArrayList<PVector>)_sketchPoints.clone();
  }
  
  void Get() {
    
    println("get");
  }
  
  //Draw the preview points
  ArrayList<PVector> getPreviewPoints(PVector _v, float _scale, float _rot) {

    ArrayList<PVector> previewSketchPoints = new ArrayList<PVector>();
    
    for (int i=0;i<sketchPoints.size();i++)
    {
       previewSketchPoints.add(
         new PVector(
           _v.x+int(sketchPoints.get(i).x*DEFAULT_PREVIEW_SCALE*_scale),
           _v.y+int(sketchPoints.get(i).y*DEFAULT_PREVIEW_SCALE*_scale)
         )
       );     
    }
    return previewSketchPoints;
  }

}