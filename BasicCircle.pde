
//// http
import http.requests.*;

class BasicCircle {

  /// Main Config
  AnimConfig TheConfig;

  float tX;
  float tY;
  float tSize;
  PVector tPos = new PVector();
  
  color tColor = color(255, 255, 255, 165);

  // direction toggles
  boolean dirX = true;
  boolean dirY = true;
  
  float wander_theta;
  float wander_radius;
  
  /// twitter data
  String tweetData;

  // bigger = more edgier, hectic
  float max_wander_offset = 0.1;
  // bigger = faster turns
  float max_wander_radius = 2.5; //// seems to do nothing
  
  /// json data
  processing.data.JSONObject json;

  BasicCircle(float x, float y, float size) {

    TheConfig = AnimConfig.getInstance();
    tPos.x = x;
    tPos.y = y;
    tSize = size;

    wander_theta = random(TWO_PI);
    wander_radius = random(max_wander_radius);
  }
  
  void getSentiment(){
    /// first sanitize URL
    String encodedurl = tweetData;
    try {
        String cleanedTweet = tweetData.toString();
        cleanedTweet = cleanedTweet.replace("\"", "");
        cleanedTweet = cleanedTweet.replaceAll("\\s+", " ");
        cleanedTweet = cleanedTweet.replace(">", "");
        cleanedTweet = cleanedTweet.replace("%", "");
        cleanedTweet = cleanedTweet.replace("|", "");
        cleanedTweet = cleanedTweet.replace(":", "");
        cleanedTweet = cleanedTweet.replace("@", "");
        cleanedTweet = cleanedTweet.replace("#", ""); //// replace all hashtags with unicode %23
        
        cleanedTweet = encodedurl.replace("\n", "");
        
        /// encodedurl = encodedurl.replaceAll("\\s+", "/");
        /// encodedurl = encodedurl.replaceAll("\\s+", "?");
        /// encodedurl = encodedurl.replaceAll("\\s+", ":");
        String simpleUrl = "http://localhost/SentimentReq/sentReq.php?" + "tweet='" + cleanedTweet + "'";
       
        encodedurl = URLEncode(simpleUrl); /// URLEncoder.encode(url,"UTF-8");
        
        println(encodedurl);
        /// String cleanUrl = URLEncode(simpleUrl);
        
        GetRequest get = new GetRequest(encodedurl);
        get.send();
        /// println("Sentiment Content: " + get.getContent());
        /// now let's parse the json
        try{
          json = loadJSONObject(get.getContent());
          /// String sentiment = json.getString("label");
          println("I FEEL THIS WAY: ");
          println(json.toString());
        } catch (Exception e){
          println("can't parse json: " + e);
          
        }

        
        /// println("Get Reponse Content-Length Header: " + get.getHeader("Content-Length"));
    
    } catch (Exception e) {
        println("problem cleaning url" + e);
    }

   

  }
  
 
  void update() {
    
    if(TheConfig.doWrap){
      checkBoundariesWrap();
    } else {
      checkBoundaries();
    }

    float wander_offset = random(-max_wander_offset, max_wander_offset);
    wander_theta += wander_offset;
    
    if(dirX){
      tPos.x += cos(wander_theta);
    } else {
      tPos.x -= cos(wander_theta);
    }
    
    if(dirY){
      tPos.y += sin(wander_theta);
    } else {
      tPos.y -= sin(wander_theta);
    }

    noStroke();
    fill(tColor);
    ellipse(tPos.x, tPos.y, tSize, tSize);
    
    //// display text
    text(tweetData, tPos.x, tPos.y, 200, 200);
  }

//// BOUNCE SIDES
 void checkBoundaries() {
    if (tPos.x > TheConfig.tWidth) {
       if(dirX == false){
        dirX = true;
      } else {
        dirX = false;
      }
    }
    if (tPos.x < 0) {
      if(dirX == false){
        dirX = true;
      } else {
        dirX = false;
      }
      //tColor = color(255, 0, 0, 165);
    }
    if (tPos.y > TheConfig.tHeight) {
       if(dirY == false){
        dirY = true;
      } else {
        dirY = false;
      }
    }
    if (tPos.y < 0) {
      if(dirY == false){
        dirY = true;
      } else {
        dirY = false;
      }
    }
  }

//// WRAP SIDES
  void checkBoundariesWrap() {
    if (tPos.x > TheConfig.tWidth) {
      tPos.x = 0; // cos(wander_theta);
    }
    if (tPos.y > TheConfig.tHeight) {
      tPos.y = 0; // sin(wander_theta);
    }
    if (tPos.x < 0) {
      tPos.x = TheConfig.tWidth; // cos(wander_theta);
    }
    if (tPos.y < 0) {
      tPos.y = TheConfig.tHeight; // sin(wander_theta);
    }
  }

  //// end class
  
  
  //// URL ENCODING
  String URLEncode(String string){
   String output = new String();
   try{
     byte[] input = string.getBytes("UTF-8");
     for(int i=0; i<input.length; i++){
       if(input[i]<0)
         output += '%' + hex(input[i]);
       else if(input[i]==32)
         output += '+';
       else
         output += char(input[i]);
     }
   }
   catch(Exception e){
     println("unsupported encoding exception");
   }
   return output;
  }
}