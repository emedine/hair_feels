public class AnimConfig {

  private static AnimConfig instance = null;


  int tWidth;
  int tHeight;
  
  int numTweets = 0;
  int numRTs = 0;
  int numPos = 0;
  int numNeg = 0;
  
  String searchTerm = "";
  int searchId;
  String imgPath;
  
  /// config
  boolean doWrap = true;
    
  private AnimConfig() {
  
  
  }

  public static AnimConfig getInstance() {
  

  /*
  * Public method which is used for the singleton pattern instantiation
  * 
  * @return Singleton - Returns the singleton object.
  */

    if (instance == null) {
      instance = new AnimConfig();
    }

    return instance;
  }
}