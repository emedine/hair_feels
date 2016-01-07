/*//////////////////
 TWITTER SENTIMENT TRACKER
 //////////////////*/
import twitter4j.conf.*;
import twitter4j.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import java.util.*; 
import java.io.IOException;

//// OATH CREDENTIALS ///////
String OAuthConsumerKey = "6EV4YHCfQB3xHbLD521ffcvFx";
String OAuthConsumerSecret = "8UjCnXBAW2Mf4gLTyWVZJhy3Cne805oyeDzFGs1Nrqo0CpJ8st"; 
// Access Token info
String AccessToken = "258118580-RqdIvrcIqYXFlS59eS2cNGpSNyPI3Q0ViohqY7W8"; 
String AccessTokenSecret = "PzMgShSUXjEmGeYojvEq0087iJQpuYN5PAXtPhk91Es4w";

String thePath = "http://api.twitter.com/1/users/show.json?user_id=";

//// TWITTER OBJECTS ///////
int curTweetId = 0;
Twitter twitter;
List<Status> tweets;

//// art objects
ArrayList <BasicPixel> PixelArray = new ArrayList();
/// circle objects
BasicPixel tCirc;
float spotSize = 25;

//// images
PImage dtHairball;

//// color anims
color overColor = color(255, 0, 0); //// overview color
color baseColor = color(255, 255, 255); /// color we pulse to
float curR = 0;
float curG = 0;
float curB = 0;
color curColor = color(curR, curG, curB); /// current color

// tweet text params
PFont twtfont;
float twtTxtAlpha = 255;
boolean fadeOut = true;
//// pulse params
boolean pulseIn = true;
float pulseAlpha = 0;/// alpha for the pulse mask
float pulseSpeed = 0; //// smaller number == faster pulse
float plseThreshLw = 700; // thresholds for the pulse timing
float plseThreshHigh = 8000;

/// TIMING FUNCTIONS
int refreshDelay = 25000;
float time; /// wait in between tweets
float wait = 75000;

float pulseTime;
float pulseWait = 1000;
float pulseIncrement = 3.1415; ///11.75
boolean tick = false;
boolean pulsetick = false;
/// Main Config
AnimConfig TheConfig;
int tWidth;
int tHeight;
int numRows;
int numCols;

int candidateID = 2; /// 0: trump, 1: bernie, 2: hillary

/// retweet threshold
int rtThresh = 0; //// number of retweets in current pool of tweets
boolean isPos = false; /// baseline sentiment for current pool of tweets

void setup() {
  size(800, 800, P2D);

  /// frameRate(60);
  smooth();
  /// set config data  in the singleton
  TheConfig = AnimConfig.getInstance();
  TheConfig.tWidth = width;
  TheConfig.tHeight = height;

  updateSearchId(candidateID);


  //// init twitter
  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey(OAuthConsumerKey);
  cb.setOAuthConsumerSecret(OAuthConsumerSecret);
  cb.setOAuthAccessToken(AccessToken);
  cb.setOAuthAccessTokenSecret(AccessTokenSecret);

  TwitterFactory tf = new TwitterFactory(cb.build());

  twitter = tf.getInstance();

  getNewTweets();

  dtHairball = loadImage(TheConfig.imgPath);
  
  // load fonts
  twtfont = createFont("data/Arial-Black-18.vlw", 32);
  textFont(twtfont);
  /// set up tweet recheck
  /// thread("refreshTweets");
}


void draw() {
  //// check for new tweets, save to an array
  if (millis() - time >= wait) {
    getNewTweets();
    tick = !tick;//if it is, do something
    time = millis();//also update the stored time
  }

  //// check to see if it's time for a new pulse
  if (millis() - pulseTime >= pulseWait) {
    resetPulse();
    pulsetick = !pulsetick;//if it is, do something
    pulseTime = millis();//also update the stored time
  }
  //// check background color

  background(curColor);
  checkBGColor();

  try {
    /// draw tweets
    drawTweets();
  } 
  catch (Exception e) {
    println("error incrementing tweets: " + e);
  }
  //// println("Pulse fade: " + pulseAlpha + " pulse speed " + pulseSpeed + " rtAdj: " + rtAdj);
  //// println(frameRate);
  /// curTweetId = curTweetId + 1
  /// draw fake lightbulbs
  drawFakeLightBulbs();
  // filter(BLUR, 6);
  /// draw the "pulse" color
  /// and check its alpha
  fill(baseColor, pulseAlpha);
  rect(0, 0, width, height);
  if (pulseAlpha > 0) { /// make alpha fade out really low so we can see the color longer
    pulseAlpha -= pulseIncrement;
  }

  /// draw image
  imageMode(CORNERS);
  image(dtHairball, 0, 0, width, height);
  /// tint(255,135);
  
  /// draw visible tweet (desktop only)
  drawVisibleTweet();

  //// delay(250);
  /// show last in array
  /// allow value assign
  /// save in new array
  /// do you want to save?
  /// send to google storage
}

/////// draw a tweet on top of everything
////// this gets removed on desktop
void drawVisibleTweet(){
   /// check the tweet color alpha
   /// if we're fading out
   /// check to see if we're all the 
   /// way out
   if(fadeOut){
     
     if(twtTxtAlpha > 0){
       twtTxtAlpha -= pulseIncrement;
     }
     /// if we're all the way out 
     /// fade in and do another tweet
      if(twtTxtAlpha < 0){
       fadeOut = false;
          curTweetId ++;
         /// if it's 0, then reset and get next tweet
         if (curTweetId >= tweets.size()) {
            curTweetId = 0;
         }
     }
   } 


   if(!fadeOut){
     
     if(twtTxtAlpha <= 255){
       twtTxtAlpha += pulseIncrement;
     }
     /// if we're all the way out 
     /// fade in 
      if(twtTxtAlpha >255){
       fadeOut = true;
     }
   } 
   /*
   if(twtTxtAlpha < 0){
     twtTxtAlpha = 255;
     curTweetId ++;
     /// if it's 0, then reset and get next tweet
     if (curTweetId >= tweets.size()) {
        curTweetId = 0;
     }
   }
   */
   BasicPixel tPx = PixelArray.get(curTweetId);
   fill(255, 255,255, twtTxtAlpha);
   textAlign(CENTER);

   textSize(18);
   textLeading(16);
   text(tPx.tweetData, 20, TheConfig.tHeight - 100, TheConfig.tWidth-60, TheConfig.tHeight);

  
}

void resetPulse() {
  /// reset the "pulse" color depending
  /// on how many tweets there are
  println("reset pulse");
  pulseAlpha = 255;
}

/// change background negative/positive colors
/// if the overall sentiment is positive
/// background is green
/// if negative, is red
void checkBGColor() {
  if (TheConfig.numPos >= TheConfig.numNeg) {
    isPos = true;
    /// normalize to green
    overColor = color(0, 255, 0);
    if (curR > red(overColor)) {
      curR -=11;
    }
    if (curG < green(overColor)) {
      curG +=11;
    }

    if (curB > blue(overColor)) {
      curB -=11;
    }
  } else {
    isPos = false;
    overColor = color(255, 0, 0);
    /// normalize to red
    if (curR < red(overColor)) {
      curR +=11;
    }
    if (curG > green(overColor)) {
      curG -=11;
    }

    if (curB > blue(overColor)) {
      curB -=11;
    }
  }
  curColor = color(curR, curG, curB);
}

////////////////////////////////
///// drawing ///////////////////
///////////////////////////////////

void drawTweets() {
  for (int i = 0; i<PixelArray.size(); i++) {
    tCirc = PixelArray.get(i);
    tCirc.update();
  }
}

///////////////////////////////////////////
/// CREATE TWEET CIRCLES ////////////
/////////////////////////////////////////////////
void buildTweetCircs() {
  /// reset the display values for each 
  /// twitter pool
  TheConfig.numTweets = tweets.size();
  TheConfig.numPos = 0;
  TheConfig.numNeg = 0;
  TheConfig.numRTs = 0;

  //// let's calculate how many rows and cols
  //// there's always 15 so let's fudge that
  // numRows = int(sqrt(tweets.size()));
  // numCols = int(sqrt(tweets.size()));
  numRows = 4; //  int(tweets.size()/3.5);
  numCols = 4;// int(tweets.size()/3.5);
  float side = TheConfig.tWidth/numRows; /// (TheConfig.tWidth * TheConfig.tHeight)/tweets.size();

  /// int numRows = int(TheConfig.tWidth/tightRad);
  ///  int numCols = int(TheConfig.tHeight/tightRad);
  float circWidth = side; //TheConfig.tWidth/numCols;
  float circHeight = side; //TheConfig.tHeight/numRows;

  /// println("width: " + circWidth + " " + circHeight);
  int tCount = 0;
  /// fall right on a border
  for (int i=0; i<numRows; i++) {
    for (int j=0; j<numCols; j++) {
      float newx = i * circWidth + circWidth/2;
      float newy = j * circHeight + circHeight/2;
      BasicPixel tCirc = new BasicPixel(newx, newy, circWidth, circHeight);
      if (tCount < TheConfig.numTweets) {
        Status status = tweets.get(tCount);

        /// look for retweeted_status

        // println(" ");
        // println(" ");
        // println(tweets.get(i).toString());
        tCirc.tweetData = status.getText();
        //// println("RT STATUS " + status.isRetweet());
        if (status.isRetweet()) {
          TheConfig.numRTs +=1;
        }
        /// println(status.getText());
        /// we change this once we get the sentiment anyway
        tCirc.tColor = color(random(255), random(255), random(255), 135);
        /// GET THE SENTIMENT FOR EACH CIRCLE/TWEET
        tCirc.getSentiment();
        PixelArray.add(tCirc);
        tCount+=1;
      }
    }
  }
  println("NUMBER TWEETS : " + TheConfig.numTweets);
  println("RETWEETS: " + TheConfig.numRTs);
  println("POSITIVE: " +  isPos + " pos: " + TheConfig.numPos + " neg: " + TheConfig.numNeg);
  println("PULSE SPEED: " +  pulseSpeed + " twts: " +  TheConfig.numTweets + " rts: " + TheConfig.numRTs);

  /// get our pulse rate from
  /// our retweet ratio pulseWait
  /// reset the pulse timer
  /// since no one is getting less than 6 RTs
  /// adjust pattern upward
  // TheConfig.numRTs = 15;
  int btNum = 0;// TheConfig.numRTs;
  if(TheConfig.numRTs <= 7){
    btNum = 7;
  }
  pulseWait = map(TheConfig.numRTs, btNum, 15, plseThreshHigh, plseThreshLw); //// smaller RT == faster pulse
  pulseTime = millis();//also update the stored time
}

/////////////////////////////////////////
///// HANDLE CIRCLE UPDATES /////////////
//////////////////////////////////////////

/// do multiple circle instances
void addCircles(int tNum) {

  for (int i=0; i<tNum; i++) {
    float zx = random(0, TheConfig.tWidth);
    float zy = random(0, TheConfig.tHeight);
    addCircle(zx, zy, spotSize);
  }
}
void removeCircles(int tNum) {

  for (int i=PixelArray.size(); i>tNum; i--) {
    deleteCircle();
  }
}


/// add/remove single circles
void addCircle(float zx, float zy, float tSiz) {


  /*    BasicPixel tCirc = new BasicPixel(zx, zy, tSiz);
   Status status = tweets.get(i);
   
   tCirc.tweetData = status;
   PixelArray.add(tCirc);
   */
}

void deleteCircle() {
  println("Cur num Circs: " + PixelArray.size());
  PixelArray.remove(PixelArray.size() - 1);
}


//////////////////////////////////
/////// update candidate name ////
////////////////////////////////////
void updateSearchId(int tId) {

  if (tId == 0) {
    TheConfig.searchTerm = "trump";
    TheConfig.searchId = tId;
    TheConfig.imgPath = "data/hairballs_trump_pure.png";
  } 
  if (tId == 1) {
    TheConfig.searchTerm = "berniesanders";
    TheConfig.searchId = tId;
    TheConfig.imgPath = "data/haiballs_bernie_pure.png";
  }

  if (tId == 2) {
    TheConfig.searchTerm = "hillary";
    TheConfig.searchId = tId;
    TheConfig.imgPath = "data/hairballs_hillary_pure.png";
  }
}


////////////////////////////////////
//////// draw fake light bulbs ////
///////////////////////////////////

void drawFakeLightBulbs() {
  float circWidth = 18;
  float numRows = TheConfig.tWidth/circWidth;
  float numCols = TheConfig.tHeight/circWidth;
  int clrId = 0;
  for (int i=0; i<numCols; i++) {

    for (int j=0; j<numRows; j++) {
      /// get the color of any of the "pixels" in order

      try {

        BasicPixel tpx = PixelArray.get((int)random(0, 14)); // PixelArray.get(clrId); // 
        color tclr = tpx.tColor;
        noStroke();
        fill(tclr);
        ellipse(i*circWidth, j*circWidth, circWidth, circWidth);
        clrId ++;
        if (clrId >= PixelArray.size()) {
          clrId = 0;
        }
      } 
      catch (Exception e) {
        println("error drawing the fake light bulbs");
      }
    }
  }
}

///////////////////////////////////
///// TWITTER HANDLING ///////////
////////////////////////////////////
void getNewTweets() {


  try {
    String searchString = TheConfig.searchTerm;
    // try to get tweets here
    Query query = new Query(searchString);
    QueryResult result = twitter.search(query);
    tweets = result.getTweets();
    //// now that we have the tweets 
    //// let's build the circles
    buildTweetCircs();
  }
  catch (TwitterException te) {
    // deal with the case where we can't get them here
    println("search error: " + te.getMessage());
  }
}

////////////////////////////////////////
///// HSL to RGB ///////////
// Given H,S,L in range of 0-360, 0-1, 0-1  Returns a Color
color HSL2RGB(float hue, float sat, float lum) {
  float v;
  float red, green, blue;
  float m;
  float sv;
  int sextant;
  float fract, vsf, mid1, mid2;

  red = lum;   // default to gray
  green = lum;
  blue = lum;
  v = (lum <= 0.5) ? (lum * (1.0 + sat)) : (lum + sat - lum * sat);
  m = lum + lum - v;
  sv = (v - m) / v;
  hue /= 60.0;  //get into range 0..6
  sextant = floor(hue);  // int32 rounds up or down.
  fract = hue - sextant;
  vsf = v * sv * fract;
  mid1 = m + vsf;
  mid2 = v - vsf;

  if (v > 0)
  {
    switch (sextant)
    {
    case 0: 
      red = v; 
      green = mid1; 
      blue = m; 
      break;
    case 1: 
      red = mid2; 
      green = v; 
      blue = m; 
      break;
    case 2: 
      red = m; 
      green = v; 
      blue = mid1; 
      break;
    case 3: 
      red = m; 
      green = mid2; 
      blue = v; 
      break;
    case 4: 
      red = mid1; 
      green = m; 
      blue = v; 
      break;
    case 5: 
      red = v; 
      green = m; 
      blue = mid2; 
      break;
    }
  }
  return color(red * 255, green * 255, blue * 255);
}