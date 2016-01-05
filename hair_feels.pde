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
String searchStr = "trump";
int curTweetId = 0;
Twitter twitter;
List<Status> tweets;

//// art objects
ArrayList <BasicPixel> PixelArray = new ArrayList();
/// circle objects
BasicPixel tCirc;
float spotSize = 25;

int refreshDelay = 30000;

/// Main Config
AnimConfig TheConfig;
int tWidth;
int tHeight;
int numRows;
int numCols;

void setup() {
  size(800, 800, P2D);

  /// set the width and height in the singleton
  /// so we can reference it from the objects 
  /// rather than pass it in
  TheConfig = AnimConfig.getInstance();
  TheConfig.tWidth = width;
  TheConfig.tHeight = height;


  //// init twitter
  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey(OAuthConsumerKey);
  cb.setOAuthConsumerSecret(OAuthConsumerSecret);
  cb.setOAuthAccessToken(AccessToken);
  cb.setOAuthAccessTokenSecret(AccessTokenSecret);

  TwitterFactory tf = new TwitterFactory(cb.build());

  twitter = tf.getInstance();

  getNewTweets();


  /// set up tweet recheck
  thread("refreshTweets");
}


void draw() {
  //// check tweets, save to an array
  background(0);
  /// rect(0, 0, width, height);

  curTweetId = curTweetId + 1;

  try {
    if (curTweetId >= tweets.size()) {
      curTweetId = 0;
    }
    /// Status status = tweets.get(curTweetId);
    /// text(status.getText(), random(width), random(height), 300, 200);
    /// println(status.getText());
    /// draw tweets
    drawTweets();
  } 
  catch (Exception e) {
    println("error incrementing tweets: " + e);
  }


  //// delay(250);
  /// show last in array
  /// allow value assign
  /// save in new array
  /// do you want to save?
  /// send to google storage
}

////////////////////////////////
///// drawing ///////////////////

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
  /// create all circles
  /// figure out how big they have
  /// to be to fit from edge to edge
  TheConfig.numTweets = tweets.size();
  float tArea = TheConfig.tWidth * TheConfig.tHeight;


  //// this is maybe gonna work?
  //// Therefore, given circles of radius rr, the number of circles which fit in the square should be the greatest integer less than 112√L2r2

  // float possRad = (3.14/(TheConfig.tWidth*TheConfig.tWidth))/sqrt(12);
  /// float tightRad = 6.2986547; // 3.14 * (possRad*possRad);
  /// println("THIS IS THE POSSIBLE RADIUS: " + possRad + " " + tightRad);
  //// let's calculate how many rows and cols
  //// there's always 15 so let's fudge that
  // numRows = int(sqrt(tweets.size()));
  // numCols = int(sqrt(tweets.size()));
  numRows = int(tweets.size()/3.5);
  numCols = int(tweets.size()/3.5);
  float side = (TheConfig.tWidth * TheConfig.tHeight)/tweets.size();

  /// int numRows = int(TheConfig.tWidth/tightRad);
  ///  int numCols = int(TheConfig.tHeight/tightRad);
  float circWidth = TheConfig.tWidth/numCols;
  float circHeight = TheConfig.tHeight/numRows;
 
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
        tCirc.getSentiment();
        PixelArray.add(tCirc);
        println("cur count: " + tCount + " " + TheConfig.numTweets);
        tCount+=1;
      }
    }
  }

  println("NUMBER TWEETS : " + TheConfig.numTweets);
  println("RETWEETS: " + TheConfig.numRTs);
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


///////////////////////////////////
///// TWITTER HANDLING ///////////
////////////////////////////////////
void getNewTweets() {


  try {
    String searchString = searchStr;
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


void refreshTweets() {


  while (true)
  {
    getNewTweets();

    println("Updated Tweets");

    delay(refreshDelay);
  }
}
void retrieve() {
  //// retrieve value-added tweets?
}