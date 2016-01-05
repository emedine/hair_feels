
//// http
import http.requests.*;

class BasicPixel {

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
  float posVal = 0;
  float negVal = 0;
  
  String theSent = ""; //// sentiment data

  // bigger = more edgier, hectic
  float max_wander_offset = 0.1;
  // bigger = faster turns
  float max_wander_radius = 2.5; //// seems to do nothing
  
  /// json data
  processing.data.JSONObject json;

  BasicPixel(float x, float y, float size) {

    TheConfig = AnimConfig.getInstance();
    tPos.x = x;
    tPos.y = y;
    tSize = size;

   
  }
  
  void getSentiment(){
    /// first sanitize URL
    
    /// String simpleUrl = "http://localhost/SentimentReq/sentReq.php?" + "tweet='" + encodedurl + "'";
    
    try {
        String cleanedTweet = tweetData.toString();
        cleanedTweet = cleanedTweet.replace("\"", "");
        cleanedTweet = cleanedTweet.replaceAll("\\s+", " ");
        cleanedTweet = cleanedTweet.replace("-", "");
        cleanedTweet = cleanedTweet.replace("|", "");
        cleanedTweet = cleanedTweet.replace(":", "");
        cleanedTweet = cleanedTweet.replace("@", "");
        cleanedTweet = cleanedTweet.replace("#", "");
        cleanedTweet = cleanedTweet.replace("!", "");
        cleanedTweet = cleanedTweet.replace(",", "");
        cleanedTweet = cleanedTweet.replace("%", "");
        cleanedTweet = cleanedTweet.replace("/", "");
        /// println("Cleaned: " + cleanedTweet);
        
        String encodedurl = "http://localhost/SentimentReq/sentReq.php?" + "tweet='" + cleanedTweet + "'";
       
        encodedurl = URLEncode(encodedurl); /// URLEncoder.encode(url,"UTF-8");
        
        /// println("Encoded: " + encodedurl);

        GetRequest get = new GetRequest(encodedurl);
        get.send();
        /// println("Sentiment Content: " + get.getContent());
        /// now let's parse the json
        try{
          String jsondata = get.getContent();
          processing.data.JSONObject json = processing.data.JSONObject.parse(jsondata);
          processing.data.JSONObject jsonSubNode = json.getJSONObject("probability");
          String name = json.getString("label");
          negVal = jsonSubNode.getFloat("neg");
          posVal = jsonSubNode.getFloat("pos");
          theSent = name.toString();
          if(theSent.equals("neg")){
            tColor = color(255,0,0,217);
          }
          if(theSent.equals("pos")){
            tColor = color(0,255,0,217);
          }
          if(theSent.equals("neutral")){
            /// calculate a third color based on the mix of pos and neg
            tColor = color(map(negVal,0,1,0,255), map(posVal,0,1,0,255), random(0,255), 217);
          }
          println(name);
          
        } catch (Exception e){
          println("can't parse json: " + e);
          
        }

        
        /// println("Get Reponse Content-Length Header: " + get.getHeader("Content-Length"));
    
    } catch (Exception e) {
        println("problem cleaning url" + e);
    }

   

  }
  
 
  void update() {

    noStroke();
    fill(tColor);
    ellipse(tPos.x, tPos.y, tSize, tSize);
    
    //// display text
    text(theSent, tPos.x, tPos.y, 200, 200);
  }


  
  
  //// URL ENCODING ///////// 
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
  
  
  //// end classe
}