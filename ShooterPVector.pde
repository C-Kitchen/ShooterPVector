//need to comment code more!
//need to change the names of local variables!

import java.util.Iterator;
import java.util.List;
import java.util.LinkedList;
import java.util.Random;
import java.util.PriorityQueue;

PVector del = new PVector (10, 10);

PFont bigFont;
PFont smallFont;

int gamestate = 0;

String name = "";
String endMessage;
boolean typeName = true;
float nameMaxWidth = 200;

Random rand = new Random();

float ROOT2 = (float) sqrt(2);
int keyW = 0;
int keyA = 0;
int keyS = 0;
int keyD = 0;

float friction = 0.5;
float accelScal = 0.8;
float walkSpeed = 1.5;
int legspace = 7;
float gunLength = 10;

int personHitRad = 7; 
int wallRad = 4;
int wallThickness = 6;

int lowerbound;
int upperbound;
int leftbound;
int rightbound;

public class Weapon {
  int wallDamage, personDamage, personExplosRad, wallExplosRad, cooldown, bulletMaxAge, gunWeight;
  float bulletSpeed, gunLength;
  boolean addMove;

  public Weapon (float wallHits, float personHits, int wallExplosRadi, int personExplosRadi, int cooldowni, int bulletMaxAgei, float bulletSpeedi, boolean addMovei) {
    wallDamage = (int) Math.ceil(120/wallHits);
    personDamage = (int) Math.ceil(120/personHits);
    personExplosRad = personExplosRadi;
    wallExplosRad = wallExplosRadi;
    cooldown = cooldowni;
    bulletMaxAge = bulletMaxAgei;
    bulletSpeed = bulletSpeedi;
    addMove = addMovei;

    gunWeight = wallExplosRad/8;
    gunLength = max(3, min(12, (bulletMaxAge*bulletSpeed)/800*12+3));
  }

  public void draw() {
    pushStyle();
    strokeWeight (max(1, gunWeight));
    line (0, 0, gunLength, 0);
    //line (0, 0, bulletMaxAge*bulletSpeed, 0);
    popStyle();
  }
}

Weapon pistol = new Weapon (1, 3, 13, 13, 30, 60, 4., true);
Weapon auto = new Weapon (1, 5, 16, 16, 15, 30, 6., true);
Weapon sniper = new Weapon (1, 2, 6, 6, 75, 100, 8., true);
Weapon bazooka = new Weapon (1, 2, 25, 25, 75, 60, 3., true);
Weapon rifle = new Weapon (1, 2, 15, 15, 55, 60, 5., true);
Weapon landmine = new Weapon (1, 1, 30, 30, 50, 500, 0, false);

public abstract class GamePiece {
  PVector coords;
  int radius, rColor, gColor, bColor;
  int health = 120;
  boolean death = false;

  public GamePiece (PVector coordsi, int rColori, int gColori, int bColori) {
    coords = coordsi.get();
    defaultRadius();
    rColor = rColori;
    gColor = gColori;
    bColor = bColori;
  }

  public GamePiece (float startX, float startY, int rColori, int gColori, int bColori) {
    this(new PVector(startX, startY), rColori, gColori, bColori);
  }

  protected abstract void defaultRadius();

  public void damage(int dam) {
    health -= dam;
  }

  public int getHealth () {
    return health;
  }

  public void setCoords(float x, float y) {
    coords.set(x, y);
  }

  public void setCoords (PVector coordsi) {
    coords.set(coordsi);
  }

  public abstract void iterate();

  protected abstract void draw2();

  public void draw() {
    pushStyle();
    pushMatrix();
    translate (coords.x, coords.y);
    stroke (rColor, gColor, bColor, health*4/3+95);
    draw2();
    popMatrix();
    popStyle();
  }

  public PVector getCoords () {
    //need to return a copy? or should I return actual thing?
    return coords;
  }
  public int getRadius () {
    return radius;
  }

  public void kill() {
    death = true;
  }

  public boolean isDead() {
    return (death || health <= 0);
  }
}

public abstract class MovablePiece extends GamePiece {
  float theta;
  PVector speed;

  public MovablePiece(PVector coordsi, float thetai, int rColori, int gColori, int bColori, PVector speedi) {
    super (coordsi, rColori, gColori, bColori);
    theta = thetai;

    speed = speedi.get();
  }

  public MovablePiece(float startX, float startY, float thetai, int rColori, int gColori, int bColori, float xSpeedi, float ySpeedi) {
    this (new PVector (startX, startY), thetai, rColori, gColori, bColori, new PVector (xSpeedi, ySpeedi));
  }

  public PVector getSpeed() {
    return speed;
  }

  public void setSpeed(PVector speedi) {
    speed = speedi;
  }

  protected abstract void iterate2();

  public void iterate() {
    iterate2();
    coords.add(speed);
  }

  protected abstract void draw3();

  protected void draw2() {
    pushMatrix();
    rotate(theta);
    draw3();
    popMatrix();
  }
}

public class Bullet extends MovablePiece {
  int age = 0;
  int maxAge, wallDamage, personDamage, wallExplosRad, personExplosRad;

  public Bullet (float startX, float startY, float thetai, int rColori, int gColori, int bColori, float xSpeedi, float ySpeedi, int maxAgei, int wallDamagei, int personDamagei, int wallExplosRadi, int personExplosRadi) {
    this (new PVector (startX, startY), thetai, rColori, gColori, bColori, new PVector (xSpeedi, ySpeedi), maxAgei, wallDamagei, personDamagei, wallExplosRadi, personExplosRadi);
  }

  public Bullet (PVector coordsi, float thetai, int rColori, int gColori, int bColori, PVector speedi, int maxAgei, int wallDamagei, int personDamagei, int wallExplosRadi, int personExplosRadi) {
    super (coordsi, thetai, rColori, gColori, bColori, speedi);
    maxAge = maxAgei;
    wallDamage = wallDamagei;
    personDamage = personDamagei;
    wallExplosRad = wallExplosRadi;
    personExplosRad = personExplosRadi;
  }

  protected void defaultRadius() {
    radius = 0;
  }

  protected void iterate2() {
    age ++;

    if (age >= maxAge) {
      death = true;
    }
  }

  protected void draw3() {
    strokeWeight(2);
    line (-1, 0, 1, 0);
  }
}

public class Wall extends GamePiece {
  PVector delta;
  PVector normPerp;

  public Wall (PVector coordsi, PVector deltai, int healthi) {
    super (coordsi, 0, 0, 0);
    delta = deltai;
    normPerp = new PVector (-delta.y, delta.x);
    normPerp.normalize();
    health = healthi;
  }

  public Wall (float x1, float y1, float xv, float yv) {
    this (new PVector (x1, y1), new PVector(xv, yv), 120);
  }

  public Wall (float x1, float y1, float xv, float yv, int healthi) {
    this (new PVector (x1, y1), new PVector(xv, yv), healthi);
  }

  public Wall (PVector coordsi, PVector deltai) {
    this(coordsi, deltai, 120);
  }

  protected void defaultRadius() {
    radius = wallRad;
  }

  public PVector getDelta() {
    return delta;
  }

  protected void draw2() {
    strokeWeight(1);
    line (0, 0, delta.x, delta.y);
  }

  public void iterate() {
    if (delta.magSq() < 1) {
      death = true;
    }
  }

  public PVector getNormPerp() {
    return normPerp;
  }
}

public class Person extends MovablePiece {
  int up = 0;
  int down = 0;
  int left = 0;
  int right = 0;
  float walk = 0.;
  float legwalk;
  String name;
  PVector targetCoords = new PVector (0, 0);
  float compression = 0;
  float totalSpeed;
  float diag;
  private int score = 0;
  PVector coordsO;
  PVector bulletTraj;
  PVector gunEnd;
  float curBulletSpeed;

  Weapon weap;

  int shootCountdown = 0;
  boolean isPlayer;

  public Person (PVector coordsi, boolean isPlayeri, Weapon weapi, String namei, int rColori, int gColori, int bColori) {
    super(coordsi, 0., rColori, gColori, bColori, new PVector (0, 0));
    coordsO = coordsi.get();
    isPlayer = isPlayeri;
    weap = weapi;
    name = namei;
    setShoot();
  }

  public Person (float startX, float startY, boolean isPlayeri, Weapon weapi, String namei, int rColori, int gColori, int bColori) {
    this (new PVector (startX, startY), isPlayeri, weapi, namei, rColori, gColori, bColori);
  }

  public void reset() {
    coords = coordsO.get();
    PVector targetCoords = new PVector (0, 0);
    theta = 0;
    health = 120;
    death = false;
  }

  protected void defaultRadius() {
    radius = 7;
  }

  public String getName() {
    return name;
  }

  private void setShoot() {
    PVector normalTheta = new PVector(cos(theta), sin(theta));//this is a normal vector in the direction of theta
    float vProjection = speed.dot(normalTheta);//this is the magnitude of the projection of your velocity onto the vector of the bullet
    curBulletSpeed = ((weap.addMove ? vProjection : 0) + weap.bulletSpeed);
    bulletTraj = PVector.mult(normalTheta, curBulletSpeed);
    gunEnd = PVector.add(coords, PVector.mult(normalTheta, gunLength));
  }

  public PVector leadTarget(PVector tCurCoords) {
    PVector tSpeed = PVector.sub(tCurCoords, targetCoords);
    if (tSpeed.mag() > walkSpeed + 1) {
      tSpeed = new PVector (0, 0);
    }
    float distance = (curBulletSpeed*gunLength-tSpeed.x*(tCurCoords.x-coords.x)-tSpeed.y*(tCurCoords.y-coords.y)-curBulletSpeed*gunLength-(float)Math.sqrt(2*tSpeed.x*(tCurCoords.x-coords.x)*(tSpeed.y*(tCurCoords.y-coords.y)-curBulletSpeed*gunLength)-2*tSpeed.y*curBulletSpeed*gunLength*(tCurCoords.y-coords.y)+(sq(curBulletSpeed)-sq(tSpeed.x))*sq(tCurCoords.y-coords.y)+(sq(curBulletSpeed)-sq(tSpeed.y))*sq(tCurCoords.x-coords.x)+sq(curBulletSpeed)*(sq(tSpeed.x)+sq(tSpeed.y))))/(sq(tSpeed.x)+sq(tSpeed.y)-sq(curBulletSpeed));
    return PVector.add(tCurCoords, PVector.mult(tSpeed, distance));
  }

  public void shoot() {
    if (shootCountdown == 0) {
      shootCountdown = weap.cooldown;
      bl.add(new Bullet  (gunEnd, theta, rColor, gColor, bColor, bulletTraj, weap.bulletMaxAge, weap.wallDamage, weap.personDamage, weap.wallExplosRad, weap.personExplosRad));
      compression = 4;
    }
  }

  private float friction(float speedi) {//need to change friction method
    float oSpeed = speedi;
    int direction = (int)(speedi / Math.abs(speedi));
    speedi = speedi - friction * direction;
    if (speedi * oSpeed < 0) {
      speedi = 0;
    }
    return speedi;
  }

  private void pControl() {
    up = keyW;
    down = keyS;
    left = keyA;
    right = keyD;
    theta = (new PVector(mouseX - coords.x, mouseY - coords.y)).heading();
    setShoot();
    if (mousePressed) {
      shoot();
    }
  }

  private boolean checkVis(PVector targ, boolean actSpeed) {
    Iterator wIt = wl.iterator();
    boolean vis = coords.dist(targ)/(actSpeed ? bulletTraj.mag(): (weap.bulletSpeed + walkSpeed)) < weap.bulletMaxAge;
    while (wIt.hasNext () && vis) {
      Wall curWall = (Wall) wIt.next();
      vis = (intersect (curWall.getCoords(), curWall.getDelta(), coords, PVector.sub(targ, coords))) == null;
    }
    return vis;
  }

  private void cControl() {

    //choose a target
    Iterator pIt2 = living.iterator();
    PVector bestTarget = new PVector (2000, 2000);
    //find lead target for each potential target? // find check vis for each potential lead target
    boolean canSee = false;
    while (pIt2.hasNext ()) {
      Person checkP = (Person) pIt2.next();
      if (checkP != this) {

        boolean checkV = checkVis(checkP.getCoords(), false);
        if (checkV == canSee) {
          if (coords.dist(checkP.getCoords()) < coords.dist(bestTarget)) {
            bestTarget = checkP.getCoords();
          }
        } else if (checkV) {
          bestTarget = checkP.getCoords();
          canSee = true;
        }
      }
    }
    
    PVector leadTargetCoords = leadTarget(bestTarget);
    targetCoords = bestTarget.get();
    PVector shortGoal;
    if (shootCountdown <= 3) {
      shortGoal = PVector.sub(nm.getShortGoal(coords, leadTargetCoords), coords);
    } else {
      //might need to make the goal better
      shortGoal = PVector.sub(nm.getShortGoal(coords, PVector.sub(PVector.add(coords, coords), targetCoords)), coords);
    }
    up = ((shortGoal.y < 0) && (Math.abs (shortGoal.x)*.415 <= -shortGoal.y)) ? 1 : 0;
    down = ((shortGoal.y > 0) && (Math.abs (shortGoal.x)*.415 <= shortGoal.y)) ? 1 : 0;
    left = ((shortGoal.x < 0) && (Math.abs (shortGoal.y)*.415 <= -shortGoal.x)) ? 1 : 0;
    right = ((shortGoal.x > 0) && (Math.abs (shortGoal.y)*.415 <= shortGoal.x)) ? 1 : 0;


    theta = (PVector.sub(leadTargetCoords, coords)).heading();
    //shoot only if you can hit your target
    setShoot();
    if (checkVis(leadTargetCoords, true)) {
      shoot();
    }
  }

  public void score() {
    score++;
  }

  public int getScore() {
    return score;
  }

  protected void iterate2() {//beginning of control stuff
    if (isPlayer) {
      pControl();
    } else {
      cControl();
    }


    if (Math.abs(right-left) == 1 || Math.abs(up-down) == 1) {
      walk += 1;
    } else {
      walk = 0;
    }
    PVector accel = new PVector(right * accelScal - left * accelScal, down * accelScal - up * accelScal);

    speed.add(accel);

    speed.x = friction (speed.x);//need to change friction method
    speed.y = friction (speed.y);

    speed.limit(walkSpeed);

    if (shootCountdown > 0) {
      shootCountdown -=1;
    } else {
      shootCountdown = 0;
    }

    if (compression > 0) {
      compression -= 0.25;
    } else {
      compression = 0;
    }

    legwalk = (legspace-4)*sin(walk/15*walkSpeed);
  }

  protected void draw3() {
    strokeWeight(1);
    weap.draw();
    fill (0, 0, 0, 0);
    ellipse(-compression/2, 0, 16-compression, 16);

    popMatrix();

    if (abs(right-left) == abs(up-down)) {
      diag = ROOT2;
    } else {
      diag = 1;
    }

    pushMatrix();
    translate ((right-left)*legwalk/diag, (down-up)*legwalk/diag);
    rotate(theta);
    ellipse(2, -legspace, 10, 7);
    popMatrix();

    pushMatrix();
    translate (-(right-left)*legwalk/diag, -(down-up)*legwalk/diag);
    rotate(theta);
    ellipse(2, legspace, 10, 7);
    popMatrix();

    pushMatrix();
  }
}

public class Explosion extends GamePiece {
  float visibleRad = 0;
  int wallDamage, personDamage;


  public Explosion (float startX, float startY, int radiusi, int wallDamagei, int personDamagei) {
    this (new PVector (startX, startY), radiusi, wallDamagei, personDamagei);
  }

  public Explosion (PVector coordsi, int radiusi, int wallDamagei, int personDamagei) {
    super (coordsi, 128, 0, 0);
    radius = radiusi;
    wallDamage = wallDamagei;
    personDamage = personDamagei;
    checkHits();
  }

  protected void defaultRadius() {
  }

  private void checkHits() {
    Iterator pIt = living.iterator();
    while (pIt.hasNext ()) {
      Person curPerson = (Person)pIt.next();
      PVector pCoords = curPerson.getCoords();
      if (coords.dist(pCoords) <= curPerson.getRadius() + radius) {
        curPerson.damage(personDamage);
      }
    }
    //begin wall damage part

    Iterator wIt = wl.iterator();
    while (wIt.hasNext ()) {
      Wall curWall = (Wall) wIt.next();
      PVector wCoords = curWall.getCoords();
      PVector wDelta = curWall.getDelta();

      PVector f = PVector.sub(wCoords, coords);

      float a = wDelta.dot(wDelta);
      float b = 2*f.dot(wDelta);
      float c = f.dot(f) - radius * radius;

      float discriminant = b*b - 4*a*c;
      if (discriminant > 0) {
        discriminant = (float)Math.sqrt(discriminant);
        float t1 = (-b - discriminant)/(2*a);
        float t2 = (-b + discriminant)/(2*a);

        List<PVector> points = new LinkedList<PVector>();
        int damagedSegment = 0;
        if (t1 > 0 && t1 < 1) {
          points.add(PVector.add(wCoords, PVector.mult(wDelta, t1)));//add the first intersection point
          damagedSegment += 1;
        }
        if (t2 < 1 && t2 > 0) {
          points.add(PVector.add(wCoords, PVector.mult(wDelta, t2)));
        }

        if (points.isEmpty()) {
          if (t1 <= 0 && t2 >= 1) {
            curWall.damage(wallDamage);
          }
        } else {
          PVector p1;
          PVector p2 = wCoords.get();
          int curSegment = 0;
          points.add(PVector.add(wCoords, wDelta));
          Iterator poIt = points.iterator();
          while (poIt.hasNext ()) {
            p1 = p2;
            p2 = (PVector) poIt.next();
            int health = curWall.getHealth() - ((curSegment == damagedSegment) ? wallDamage : 0);
            curSegment ++;
            newWalls.add(new Wall(p1, PVector.sub(p2, p1), health));
          }
          try {
            curWall.kill();
          }
          catch (IllegalStateException e) {
          }
        }

        //else remove wall, add walls (make the one that starts with t1 or ends with t2 damaged)
      }
    }
    //wl.addAll(newWalls);
    //end wall damage part
  }

  public void iterate() {
    visibleRad ++;
    if (visibleRad >= radius) {
      death = true;
    }
  }

  protected void draw2() {
    strokeWeight(2);
    ellipse (0, 0, visibleRad*2, visibleRad*2);
  }
}

public class Ghost extends MovablePiece {
  public Ghost (PVector coordsi, int rColori, int gColori, int bColori) {
    super (coordsi, 0, rColori, gColori, bColori, new PVector(0, -1));
  }

  public Ghost (float startX, float startY, int rColori, int gColori, int bColori) {
    this (new PVector (startX, startY), rColori, gColori, bColori);
  }

  public void defaultRadius() {
  }

  public void draw3() {
    noFill();

    line (-6, 2, 0, 12);
    line (6, 2, 0, 12);

    ellipse (0, 0, 12, 12);

    line (2, -2, 5, 1);
    line (5, -2, 2, 1);
    line (-2, -2, -5, 1);
    line (-5, -2, -2, 1);
  }
  public void iterate2() {
    damage (5);
  }
}


void println (PVector pv) {
  println("("+pv.x+", "+pv.y+")");
}

PVector intersect (PVector x1, PVector v1, PVector x2, PVector v2) {
  //takes 4 PVectors
  //x1 = position of start of first line
  //v1 = the difference between end and start of first line
  //x2 = position of start of second line
  //v2 = the difference between end and start of second line
  boolean debug = false; 

  float denominator = (v1.dot(v1))*(v2.dot(v2)) - (v1.dot(v2))*(v1.dot(v2));
  if (debug) {
    println(denominator);
  }
  if (denominator != 0) {
    float a = ((v2.dot(v2))*(v1.dot(PVector.sub(x2, x1)))-((v1.dot(v2)))*(v2.dot(PVector.sub(x2, x1)))) / denominator;
    float b = ((v1.dot(v2))*(v1.dot(PVector.sub(x2, x1)))-((v1.dot(v1)))*(v2.dot(PVector.sub(x2, x1)))) / denominator;

    if (0 < a && a <= 1 && 0 < b && b <= 1) {
      return PVector.add(x1, PVector.mult(v1, a));
    } else {
      return null;
    }
  } else {
    return null;
  }
}

public float distanceToSegment(PVector p1, PVector p2, PVector p3) {
  //finds the distance from a line: p1-p2 to a point p3.
  PVector delta = PVector.sub(p2, p1);

  if ((delta.x == 0) && (delta.y == 0)) {
    return p1.dist(p3);
  }

  float u = ((p3.x - p1.x) * delta.x + (p3.y - p1.y) * delta.y) / delta.magSq();
  PVector closestPoint;

  if (u < 0) {
    closestPoint = p1.get();
  } else if (u > 1) {
    closestPoint = p2.get();
  } else {
    closestPoint = PVector.add(p1, PVector.mult(delta, u));
  }

  return p3.dist(closestPoint);
}

public float distanceBetweenSegments (PVector x1, PVector v1, PVector x2, PVector v2) {
  //change local variable names?
  //find the closest distance between to segments (if they don't intersect!)
  boolean debug = false;

  float d1 = distanceToSegment(x1, PVector.add(x1, v1), x2);
  float d2 = distanceToSegment(x1, PVector.add(x1, v1), PVector.add(x2, v2));
  float d3 = distanceToSegment(x2, PVector.add(x2, v2), x1);
  float d4 = distanceToSegment(x2, PVector.add(x2, v2), PVector.add(x1, v1));
  if (debug) {
    println ("d1: "+ d1);
    println ("d2: "+ d2);
    println ("d3: "+ d3);
    println ("d4: "+ d4);
    println ("SMALLEST: " + Math.min(Math.min(d1, d2), Math.min(d3, d4)));
  }
  return Math.min(Math.min(d1, d2), Math.min(d3, d4));
}

List<Bullet> bl = new LinkedList<Bullet>();
List<Wall> wl = new LinkedList<Wall>();
List<Wall> newWalls = new LinkedList<Wall>();
List<Explosion> el = new LinkedList<Explosion>();
List<Person> allPeople = new LinkedList<Person>();
List<Person> living = new LinkedList<Person>();
List<Ghost> gl = new LinkedList<Ghost>();



void startscreen() {
  background (255);
  pushStyle();
  fill(0);
  textFont (bigFont);
  textAlign(CENTER, BOTTOM);
  text("ShooterPVector", width/2, 60);

  textFont (smallFont);
  textAlign(LEFT, BOTTOM);
  text("Name: " + name, 30, 100);

  line(30+textWidth("Name: "), 100, 30 + textWidth("Name: ") + nameMaxWidth, 100);
  if (typeName) {
    line(31+textWidth("Name: "+name), 97, 31+textWidth("Name: "+name), 75);
  }

  fill(0);
  textFont (bigFont);
  textAlign(CENTER, BOTTOM);
  text("Esc to Quit", width/2, height - 20);
  text("Enter to Start", width/2, height - 90);

  popStyle();
  /*
  pushStyle();
   noStroke();
   int buttonWidth = (int) (textWidth("Name: ") + nameMaxWidth) /6;
   for (int i = 0; i < 6; i++) {
   fill((i>3 || i == 0) ? 128: 0, (i<3) ? 128: 0, (i<5 && i >1) ? 128: 0);
   rect(30 + i * buttonWidth, 110, buttonWidth, buttonWidth);
   }
   popStyle();*/

  if (mousePressed) {
    if (mouseX >= 30+textWidth("Name: ") && mouseX <= 30 + textWidth("Name: ") + nameMaxWidth && mouseY >= 75 && mouseY <= 100) {
      typeName = true;
    } else {
      typeName = false;
    }
  }
}

void gameloop() {
  boolean debug = false;
  background (255);

  Iterator pIt = living.iterator();
  boolean firstP = true;
  while (pIt.hasNext () || firstP) {
    Person curPerson = null;
    PVector pCoords = null;
    PVector pDelta = null;

    if (pIt.hasNext()) {
      curPerson = (Person)pIt.next();
      pCoords = curPerson.getCoords();
      pDelta = curPerson.getSpeed();

      curPerson.iterate();
      if (pCoords.y > lowerbound) {//check against bounds of screen
        pCoords.y = lowerbound; //this is a clunky way to do this!, should use method inside the object need to fix it!
      }
      if (pCoords.y < upperbound) {
        pCoords.y = upperbound;
      }
      if (pCoords.x > rightbound) {
        pCoords.x = rightbound;
      }
      if (pCoords.x < leftbound) {
        pCoords.x = leftbound;
      }
    }

    Iterator wIt = wl.iterator();
    boolean firstW = true;
    while (wIt.hasNext () || firstW) {
      Wall curWall = null;
      PVector wCoords = null;
      PVector wDelta = null;

      if (wIt.hasNext()) {
        curWall = (Wall)wIt.next();
        wCoords = curWall.getCoords();
        wDelta = curWall.getDelta();

        //checks for intersection between curPerson and curWall
        if (curPerson != null) {
          float dist = distanceBetweenSegments(wCoords, wDelta, pCoords, pDelta);
          float minDist = curWall.getRadius() + curPerson.getRadius();
          if (dist < minDist) {

            PVector wallNormal = curWall.getNormPerp();
            float side;
            {

              PVector temp = PVector.sub(pCoords, wCoords);
              float sign = wDelta.dot(new PVector(-temp.y, temp.x));

              side = (sign > 0) ? 1 : -1;
            }

            curPerson.setCoords(PVector.add(pCoords, PVector.mult(wallNormal, side*(dist-minDist))));
          }
        }

        if (firstP) {
          curWall.iterate();
        }
      }

      if (firstP || firstW) {
        Iterator bIt = bl.iterator();
        while (bIt.hasNext ()) {
          Bullet curBullet = (Bullet)bIt.next();
          if (!curBullet.isDead()) {
            PVector bCoords = curBullet.getCoords();
            PVector bDelta = curBullet.getSpeed();

            if (firstP && firstW) {
              curBullet.iterate();
            }

            if (firstP && curWall != null) {
              //checks intersection between curBullet and curWall
              //needs to be generalized - the whole point of the inheritance garbage was to make it so you could generalize!

              PVector wbIntersection = intersect (bCoords, bDelta, wCoords, wDelta);
              if (/*distanceBetweenSegments(bCoords, bDelta, wCoords, wDelta) <= (curBullet.getRadius() + curWall.getRadius()) ||*/ wbIntersection != null) {
                PVector bulletEnd;

                if (wbIntersection != null) {//if the bullet path and wall actually intersect, use point of intersection as the end point
                  bulletEnd = wbIntersection.get();
                  if (debug) {
                    print ("intersect ");
                  }
                } else { //if the bullet path and wall do not intersect, but come close enough, use the bullet's newest position as the end point
                  bulletEnd = bCoords.get();
                  if (debug) {
                    print ("nearby ");
                  }
                }
                curBullet.kill();

                if (debug) {
                  print ("hit wall: ");
                  println (wCoords);
                }

                el.add(new Explosion(bulletEnd, curBullet.wallExplosRad, curBullet.wallDamage, curBullet.personDamage));//bulletEnd may not be sufficient!
              }
            }

            if (firstW && curPerson != null) {
              //checks intersection between curBullet and curPerson

              if (distanceBetweenSegments(bCoords, bDelta, pCoords, pDelta) <= (curBullet.getRadius() + curPerson.getRadius())) {
                curBullet.kill();
                if (debug) {
                  println ("hit "+curPerson.getName());
                }
                el.add(new Explosion(PVector.add(bCoords, bDelta), curBullet.personExplosRad, curBullet.wallDamage, curBullet.personDamage));
              }
            }
          }
          if (firstP && firstW) {
            if (curBullet.isDead()) {
              try {
                bIt.remove();
              }
              catch (IllegalStateException e) {
              }
            } else {
              curBullet.draw();
            }
          }
        }
      }
      if (firstP && curWall != null) {
        if (curWall.isDead()) {
          try {
            wIt.remove();
          }
          catch (Throwable e) {
          }
        } else {
          curWall.draw();
        }
      }
      firstW = false;
    }
    if (curPerson != null) {
      if (curPerson.isDead()) {
        try {
          gl.add(new Ghost(curPerson.getCoords(), curPerson.rColor, curPerson.gColor, curPerson.bColor));
          pIt.remove();
        }
        catch (IllegalStateException e) {
        }
      } else {
        curPerson.draw();
      }
    }
    firstP = false;
  }
  Iterator nwIt = newWalls.iterator();
  while (nwIt.hasNext ()) {
    Wall curWall = (Wall) nwIt.next();
    curWall.draw();
    wl.add(curWall);
    nwIt.remove();
  }

  Iterator eIt = el.iterator();
  while (eIt.hasNext ()) {
    Explosion curExplosion = (Explosion) eIt.next();
    curExplosion.iterate();

    if (curExplosion.isDead()) {
      try {
        eIt.remove();
      }
      catch (IllegalStateException e) {
      }
    } else {
      curExplosion.draw();
    }
  }

  Iterator gIt = gl.iterator();
  while (gIt.hasNext ()) {
    Ghost curGhost = (Ghost) gIt.next();
    curGhost.iterate();
    if (curGhost.isDead()) {
      try {
        gIt.remove();
      }
      catch (IllegalStateException e) {
      }
    } else {
      curGhost.draw();
    }
  }

  if (gl.size() == 0 && living.size() <= 1) {
    try {
      Person winner = living.get(0);
      winner.score();
      endMessage = winner.getName() + " wins!";
    } 
    catch (Throwable e) {
      endMessage = "It's a draw!";
    }

    bl.clear();
    wl.clear();
    newWalls.clear();
    el.clear();
    living.clear();
    gl.clear();

    endGame();
  }
}

void endscreen() {
  background (255);
  pushStyle();
  fill(0);
  textFont (bigFont);
  textAlign(CENTER, BOTTOM);
  text(endMessage, width/2, 60);

  textFont (smallFont);
  textAlign(LEFT, BOTTOM);
  Iterator pIt = allPeople.iterator();
  int textY = 100;
  while (pIt.hasNext ()) {
    Person curPerson = (Person) pIt.next();
    fill(curPerson.rColor, curPerson.gColor, curPerson.bColor);
    text(curPerson.getName() + ": " + curPerson.getScore(), width/10, textY);
    textY += 40;
  }

  fill(0);
  textFont (bigFont);
  textAlign(CENTER, TOP);
  text("Rematch? (y/n)", width/2, textY);

  popStyle();
}

void makeThickWall(float x, float y, float xv, float yv) {
  if (Math.abs(yv) > Math.abs(xv)) {
    for (int i=0; i < 6; i++) {
      wl.add(new Wall (x+i-3, y, xv, yv));
    }
  } else {
    for (int i=0; i < 6; i++) {
      wl.add(new Wall (x, y+i-3, xv, yv));
    }
  }
}

boolean randBool(float tPart, float fPart) {
  return (rand.nextFloat() < (float)tPart/(fPart+tPart));
}

private void bigInnerDiag() {
  makeThickWall(width/4, height/4, width/2, height/2);
  makeThickWall(width/4, 3*height/4, width/2, -height /2);
}
private void bigOuterDiag() {
  makeThickWall(0, 0, width/4, height/4);
  makeThickWall(width*3/4, height*3/4, width/4, height/4);
  makeThickWall(0, height, width/4, -height/4);
  makeThickWall(width, 0, -width/4, height/4);
}
private void bigInnerH() {
  makeThickWall(width/4, height/2, width/2, 0);
}
private void bigOuterH() {
  makeThickWall(0, height/2, width/4, 0);
  makeThickWall(width, height/2, -width/4, 0);
}
private void bigInnerV() {
  makeThickWall(width/2, height/4, 0, height/2);
}
private void bigOuterV() {
  makeThickWall(width/2, 0, 0, height/4);
  makeThickWall(width/2, height, 0, -height/4);
}
private void smallInnerDiag() {
  makeThickWall(width/8, height/8, width/4, height/4);
  makeThickWall(width/8, height*3/8, width/4, -height/4);

  makeThickWall(width*5/8, height/8, width/4, height/4);
  makeThickWall(width*5/8, height*3/8, width/4, -height/4);

  makeThickWall(width/8, height*5/8, width/4, height/4);
  makeThickWall(width/8, height*7/8, width/4, -height/4);

  makeThickWall(width*5/8, height*5/8, width/4, height/4);
  makeThickWall(width*5/8, height*7/8, width/4, -height/4);
}
private void smallOuterDiag() {
  makeThickWall(0, 0, width/8, height/8);
  makeThickWall(width*3/8, height*3/8, width/4, height/4);
  makeThickWall(width, height, -width/8, -height/8);

  makeThickWall(0, height, width/8, -height/8);
  makeThickWall(width*3/8, height*5/8, width/4, -height/4);
  makeThickWall(width, 0, -width/8, height/8);

  makeThickWall(0, height/2, width/8, -height/8);
  makeThickWall(0, height/2, width/8, height/8);

  makeThickWall(width, height/2, -width/8, -height/8);
  makeThickWall(width, height/2, -width/8, height/8);

  makeThickWall(width/2, 0, -width/8, height/8);
  makeThickWall(width/2, 0, width/8, height/8);

  makeThickWall(width/2, height, -width/8, -height/8);
  makeThickWall(width/2, height, width/8, -height/8);
}
private void smallInnerH() {
  makeThickWall(width/8, height/4, width/4, 0);
  makeThickWall(width*5/8, height/4, width/4, 0);
  makeThickWall(width/8, height*3/4, width/4, 0);
  makeThickWall(width*5/8, height*3/4, width/4, 0);
}
private void smallOuterH() {
  makeThickWall(0, height/4, width/8, 0);
  makeThickWall(0, height*3/4, width/8, 0);
  makeThickWall(width, height/4, -width/8, 0);
  makeThickWall(width, height*3/4, -width/8, 0);

  makeThickWall(width*3/8, height/4, width/4, 0);
  makeThickWall(width*3/8, height*3/4, width/4, 0);
}
private void smallInnerV() {
  makeThickWall(width/4, height/8, 0, height/4);
  makeThickWall(width*3/4, height/8, 0, height/4);
  makeThickWall(width/4, height*5/8, 0, height/4);
  makeThickWall(width*3/4, height*5/8, 0, height/4);
}
private void smallOuterV() {
  makeThickWall(width/4, 0, 0, height/8);
  makeThickWall(width*3/4, 0, 0, height/8);
  makeThickWall(width/4, height, 0, -height/8);
  makeThickWall(width*3/4, height, 0, -height/8);

  makeThickWall(width/4, height*3/8, 0, height/4);
  makeThickWall(width*3/4, height*3/8, 0, height/4);
}

void generateLevel() {
  boolean[] bools = new boolean[5];
  for (int i = 0; i < bools.length; i++) {
    if (i == 0) {
      bools[i] = randBool(0, 1);
    } else {
      bools[i] = randBool(1, 1);
    }
  }

  if (bools[0]) {
    //diagonal
    if (bools[1]) {
      //diagonal is big
      if (bools[2]) {
        bigInnerDiag();
      } else {
        bigOuterDiag();
      }

      if (bools[3]) {
        smallInnerH();
      } else {
        smallOuterH();
      }

      if (bools[4]) {
        smallInnerV();
      } else {
        smallOuterV();
      }
    } else {
      //diagonal is small
      if (bools[2]) {
        smallInnerDiag();
      } else {
        smallOuterDiag();
      }

      if (bools[3]) {
        bigInnerH();
      } else {
        bigOuterH();
      }

      if (bools[4]) {
        bigInnerV();
      } else {
        bigOuterV();
      }
    }
  } else {
    if (bools[1]) {
      bigInnerH();
    } else {
      bigOuterH();
    }

    if (bools[2]) {
      bigInnerV();
    } else {
      bigOuterV();
    }

    if (bools[3]) {
      smallInnerH();
    } else {
      smallOuterH();
    }

    if (bools[4]) {
      smallInnerV();
    } else {
      smallOuterV();
    }
  }

  nm = new NavMesh(bools[0], bools[1], bools[2], bools[3], bools[4]);
}

void setup() 
{
  size(900, 600);

  bigFont = createFont("Georgia", 50);
  smallFont = createFont("Georgia", 25);
  textAlign(LEFT, BOTTOM);

  int margin = 10;
  lowerbound = height - margin;
  upperbound = margin;
  leftbound = margin;
  rightbound = width - margin;
}

public class NavMesh {
  //Vertices stored as PVectors

  private class Edge {
    private PVector[] vertices = new PVector[2];
    private Face[] adjacentFaces = new Face[2];
    private int nextP = 0;
    private int nextF = 0;

    private Edge () {
    }

    private Edge (PVector p0, PVector p1) {
      vertices[0] = p0;
      vertices[1] = p1;
    }

    private PVector getP0 () {
      return vertices[0].get();
    }
    private void setP0 (PVector p0) {
      vertices[0] = p0;
    }

    private PVector getP1 () {
      return vertices[1].get();
    }
    private void setP1(PVector p1) {
      vertices[1] = p1;
    }

    private float getDistance () {
      PVector center = PVector.mult(PVector.add(vertices[0], vertices[1]), 0.5);
      return (center.dist(adjacentFaces[0].center) + center.dist(adjacentFaces[1].center));
    }


    private Face getOther (Face original) {
      if (original.equals(adjacentFaces[0])) {
        return adjacentFaces[1];
      } else if (original.equals(adjacentFaces[1])) {
        return adjacentFaces[0];
      } else {
        return null;
      }
    }

    private PVector getDelta() {
      return PVector.sub(vertices[1], vertices[0]);
    }

    private void setNextP(PVector p) {
      vertices[nextP] = p;
      nextP = (nextP + 1) % 2;
    }

    private void setNextF(Face f) {
      adjacentFaces[nextF] = f;
      nextF = (nextF + 1) % 2;
    }
  }

  private class Face {
    Edge[] edgeArray;
    PVector center = new PVector (0, 0);
    PVector test;

    //Map from face to edge: 
    //give it a face, it tells you what edge to go to
    HashMap<Face, Edge> navTo;

    private Face (ArrayList<Edge> edgesi) {
      edgeArray = new Edge[edgesi.size()];
      edgesi.toArray(edgeArray);
      for (int i = 0; i < edgeArray.length; i++) {
        edgeArray[i].setNextF(this);
        center.add(PVector.div(edgeArray[i].getP0(), edgeArray.length*2));
        center.add(PVector.div(edgeArray[i].getP1(), edgeArray.length*2));
      }

      setTest();
    }

    private Face (Edge[] edgeArrayi) {
      edgeArray = edgeArrayi;
      for (int i = 0; i < edgeArray.length; i++) {
        edgeArray[i].setNextF(this);
        center.add(PVector.div(edgeArray[i].getP0(), edgeArray.length*2));
        center.add(PVector.div(edgeArray[i].getP1(), edgeArray.length*2));
      }

      setTest();
    }

    private void setNavTo(HashMap<Face, Edge> navToi) {
      navTo = navToi;
    }

    private void setTest() { //this makes sure the test vector is not parallel to any edges
      boolean[] whichone = new boolean[edgeArray.length + 1];
      float minX = Float.NaN;
      float minY = Float.NaN;
      float maxX = Float.NaN;
      float maxY = Float.NaN;
      for (int i = 0; i < whichone.length; i++) {
        whichone[i] = true;
      }

      for (int i = 0; i < edgeArray.length; i++) {
        PVector p0 = edgeArray[i].getP0();
        PVector p1 = edgeArray[i].getP1();
        minX = min(minX, min(p0.x, p1.x));
        minY = min(minY, min(p0.y, p1.y));
        maxX = max(maxX, max(p0.x, p1.x));
        maxY = max(maxY, max(p0.y, p1.y));

        whichone[(int) ((((edgeArray[i].getDelta().heading()) / Math.PI * whichone.length) + whichone.length) % whichone.length)] = false;
      }

      {
        int i = 0;
        while (!whichone[i]) {
          i++;
        }
        test = PVector.fromAngle((float) Math.PI * (i + 0.5) / whichone.length);
      }
    }

    public Edge[] getEdgeArray() {
      return edgeArray;
    };

    private boolean contains(PVector newp) {
      //may not work right if intersects right at a corner!
      //problems on the edge
      int hits = 0;
      for (int i = 0; i < edgeArray.length; i++) {
        float dist = max(PVector.dist(newp, edgeArray[i].getP0()), PVector.dist(newp, edgeArray[i].getP1())) + 10;
        if (intersect(edgeArray[i].getP0(), edgeArray[i].getDelta(), newp, PVector.mult(test, dist)) != null) {
          hits ++;
        }
      }
      return (hits % 2) == 1;
    }

    private float getDist(PVector target) {
      return target.dist(center);
    }

    private Edge getPath(Face f) {
      return navTo.get(f);
    }
  }

  List<Face> allFaces = new ArrayList<Face>();

  private void addV(int x, int y, HashMap<String, PVector> target) {
    float xCalc, yCalc;
    int wallBerth = wallThickness/2 + wallRad;

    //if x < 16 (need to add more cases and such when dealing with diagonals
    float diff;
    switch (x%8) {
    case 0:
      diff = personHitRad;
      break;
    case 1:
      diff = width/8 - personHitRad;
      break;
    case 2:
      diff = width/8 + personHitRad;
      break;
    case 3:
      diff = width/4 - wallBerth - personHitRad;
      break;
    case 4:
      diff = width/4 + wallBerth + personHitRad; 
      break;
    case 5:
      diff = width*3/8 - personHitRad;
      break;
    case 6:
      diff = width*3/8 + personHitRad;
      break;
    default:
      diff = width/2 - wallBerth - personHitRad;
      break;
    }
    if (x/8 == 0) {
      xCalc = diff;
    } else {
      xCalc = width - diff;
    }

    //if y < 16 (need to add more cases and such when dealing with diagonals
    switch (y%8) {
    case 0:
      diff = personHitRad;
      break;
    case 1:
      diff = height/8 - personHitRad;
      break;
    case 2:
      diff = height/8 + personHitRad;
      break;
    case 3:
      diff = height/4 - wallBerth - personHitRad;
      break;
    case 4:
      diff = height/4 + wallBerth + personHitRad; 
      break;
    case 5:
      diff = height*3/8 - personHitRad;
      break;
    case 6:
      diff = height*3/8 + personHitRad;
      break;
    default:
      diff = height/2 - wallBerth - personHitRad;
      break;
    }
    if (y/8 == 0) {
      yCalc = diff;
    } else {
      yCalc = height - diff;
    }

    PVector pt = new PVector(xCalc, yCalc);
    target.put(""+x+","+y, pt);
  }

  private void addE(String p1, String p2, HashMap<String, PVector> from, HashMap<String, Edge> target) {
    target.put(""+p1+"-"+p2, new Edge(from.get(p1), from.get(p2)));
  }

  private NavMesh(boolean bool0, boolean bool1, boolean bool2, boolean bool3, boolean bool4) {
    HashMap<String, PVector> allVertices = new HashMap<String, PVector>();
    HashMap<String, Edge> allEdges = new HashMap<String, Edge>();
    List<Edge[]> newFaces = new LinkedList<Edge[]>();

    //adds all the vertices necessary for a map with no diagonals
    for (int i = 0; i < 16; i++) {
      switch (i) {
      case 0: 
      case 7: 
      case 8: 
      case 15:
        addV(i, 0, allVertices);
        addV(i, 3, allVertices);
        addE(""+i+","+0, ""+i+","+3, allVertices, allEdges);
        addV(i, 4, allVertices);
        addE(""+i+","+3, ""+i+","+4, allVertices, allEdges);
        addV(i, 7, allVertices);
        addE(""+i+","+4, ""+i+","+7, allVertices, allEdges);
        addV(i, 8, allVertices);
        addV(i, 11, allVertices);
        addE(""+i+","+8, ""+i+","+11, allVertices, allEdges);
        addV(i, 12, allVertices);
        addE(""+i+","+11, ""+i+","+12, allVertices, allEdges);
        addV(i, 15, allVertices);
        addE(""+i+","+12, ""+i+","+15, allVertices, allEdges);
        addE(""+i+","+7, ""+i+","+15, allVertices, allEdges);
        break;
      case 1: 
      case 2: 
      case 5: 
      case 6: 
      case 9: 
      case 10: 
      case 13: 
      case 14:
        addV(i, 3, allVertices);
        addV(i, 4, allVertices);
        addE(""+i+","+3, ""+i+","+4, allVertices, allEdges);
        addV(i, 11, allVertices);
        addV(i, 12, allVertices);
        addE(""+i+","+11, ""+i+","+12, allVertices, allEdges);
        addE(""+i+","+4, ""+i+","+12, allVertices, allEdges);
        break;
      case 3: 
      case 4: 
      case 11: 
      case 12:
        for (int j = 0; j < 16; j++) {
          addV(i, j, allVertices);
          if (j > 0 && j != 8) {
            if (j == 15) {
              addE(""+i+","+7, ""+i+","+j, allVertices, allEdges);
            }
            addE(""+i+","+(j-1), ""+i+","+j, allVertices, allEdges);
          }
        }
        break;
      default:
        break;
      }
    }

    for (int i = 0; i < 16; i++) {
      switch (i) {
      case 0: 
      case 7: 
      case 8: 
      case 15:
        addE(""+0+","+i, ""+3+","+i, allVertices, allEdges);
        addE(""+3+","+i, ""+4+","+i, allVertices, allEdges);
        addE(""+4+","+i, ""+7+","+i, allVertices, allEdges);
        addE(""+7+","+i, ""+15+","+i, allVertices, allEdges);
        addE(""+8+","+i, ""+11+","+i, allVertices, allEdges);
        addE(""+11+","+i, ""+12+","+i, allVertices, allEdges);
        addE(""+12+","+i, ""+15+","+i, allVertices, allEdges);
        break;
      case 1: 
      case 2: 
      case 5: 
      case 6: 
      case 9: 
      case 10: 
      case 13: 
      case 14:
        addE(""+3+","+i, ""+4+","+i, allVertices, allEdges);
        addE(""+4+","+i, ""+12+","+i, allVertices, allEdges);
        addE(""+11+","+i, ""+12+","+i, allVertices, allEdges);
        break;
      case 3: 
      case 4: 
      case 11: 
      case 12:
        for (int j = 0; j < 16; j++) {
          if (j > 0 && j != 8) {
            if (j == 15) {
              addE(""+7+","+i, ""+j+","+i, allVertices, allEdges);
            }
            addE(""+(j-1)+","+i, ""+j+","+i, allVertices, allEdges);
          }
        }
        break;
      default:
        break;
      }
    }

    if (bool0) {
      //diagonal
      if (bool1) {
        //diagonal is big
        if (bool2) {
          //bigInnerDiag();
        } else {
          //bigOuterDiag();
        }
        if (bool3) {
          //smallInnerH();
        } else {
          //smallOuterH();
        }

        if (bool4) {
          //smallInnerV();
        } else {
          //smallOuterV();
        }
      } else {
        //diagonal is small
        if (bool2) {
          //smallInnerDiag();
        } else {
          //smallOuterDiag();
        }

        if (bool3) {
          //bigInnerH();
        } else {
          //bigOuterH();
        }

        if (bool4) {
          //bigInnerV();
        } else {
          //bigOuterV();
        }
      }
    } else {
      {
        Edge[] temp = {
          allEdges.get("0,0-3,0"), allEdges.get("3,0-3,1"), allEdges.get("3,1-3,2"), allEdges.get("3,2-3,3"), 
          allEdges.get("0,0-0,3"), allEdges.get("0,3-1,3"), allEdges.get("1,3-2,3"), allEdges.get("2,3-3,3")
          };
          allFaces.add(new Face(temp));
      }
      {
        Edge[] temp = {
          allEdges.get("0,8-3,8"), allEdges.get("3,8-3,9"), allEdges.get("3,9-3,10"), allEdges.get("3,10-3,11"), 
          allEdges.get("0,8-0,11"), allEdges.get("0,11-1,11"), allEdges.get("1,11-2,11"), allEdges.get("2,11-3,11")
          };
          allFaces.add(new Face(temp));
      }
      {
        Edge[] temp = {
          allEdges.get("8,0-11,0"), allEdges.get("11,0-11,1"), allEdges.get("11,1-11,2"), allEdges.get("11,2-11,3"), 
          allEdges.get("8,0-8,3"), allEdges.get("8,3-9,3"), allEdges.get("9,3-10,3"), allEdges.get("10,3-11,3")
          };
          allFaces.add(new Face(temp));
      }
      {
        Edge[] temp = {
          allEdges.get("8,8-11,8"), allEdges.get("11,8-11,9"), allEdges.get("11,9-11,10"), allEdges.get("11,10-11,11"), 
          allEdges.get("8,8-8,11"), allEdges.get("8,11-9,11"), allEdges.get("9,11-10,11"), allEdges.get("10,11-11,11")
          };
          allFaces.add(new Face(temp));
      }

      if (!bool1 && !bool2) {
        //add the big central area
        {
          Edge[] temp = {
            allEdges.get("4,4-4,5"), allEdges.get("4,5-4,6"), allEdges.get("4,6-4,7"), allEdges.get("4,7-4,15"), 
            allEdges.get("4,12-4,13"), allEdges.get("4,13-4,14"), allEdges.get("4,14-4,15"), 
            allEdges.get("12,4-12,5"), allEdges.get("12,5-12,6"), allEdges.get("12,6-12,7"), allEdges.get("12,7-12,15"), 
            allEdges.get("12,12-12,13"), allEdges.get("12,13-12,14"), allEdges.get("12,14-12,15"), 
            allEdges.get("4,4-5,4"), allEdges.get("5,4-6,4"), allEdges.get("6,4-7,4"), allEdges.get("7,4-15,4"), 
            allEdges.get("12,4-13,4"), allEdges.get("13,4-14,4"), allEdges.get("14,4-15,4"), 
            allEdges.get("4,12-5,12"), allEdges.get("5,12-6,12"), allEdges.get("6,12-7,12"), allEdges.get("7,12-15,12"), 
            allEdges.get("12,12-13,12"), allEdges.get("13,12-14,12"), allEdges.get("14,12-15,12")
            };
            allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("0,4-1,4"), allEdges.get("1,4-2,4"), allEdges.get("2,4-3,4"), 
            allEdges.get("0,7-3,7"), allEdges.get("0,4-0,7"), allEdges.get("3,4-3,5"), 
            allEdges.get("3,5-3,6"), allEdges.get("3,6-3,7"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("0,12-1,12"), allEdges.get("1,12-2,12"), allEdges.get("2,12-3,12"), 
            allEdges.get("0,15-3,15"), allEdges.get("0,12-0,15"), allEdges.get("3,12-3,13"), 
            allEdges.get("3,13-3,14"), allEdges.get("3,14-3,15"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("8,4-9,4"), allEdges.get("9,4-10,4"), allEdges.get("10,4-11,4"), 
            allEdges.get("8,7-11,7"), allEdges.get("8,4-8,7"), allEdges.get("11,4-11,5"), 
            allEdges.get("11,5-11,6"), allEdges.get("11,6-11,7"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("8,12-9,12"), allEdges.get("9,12-10,12"), allEdges.get("10,12-11,12"), 
            allEdges.get("8,15-11,15"), allEdges.get("8,12-8,15"), allEdges.get("11,12-11,13"), 
            allEdges.get("11,13-11,14"), allEdges.get("11,14-11,15"),
          };
          allFaces.add(new Face(temp));
        }

        {
          Edge[] temp = {
            allEdges.get("4,0-4,1"), allEdges.get("4,1-4,2"), allEdges.get("4,2-4,3"), 
            allEdges.get("7,0-7,3"), allEdges.get("4,0-7,0"), allEdges.get("4,3-5,3"), 
            allEdges.get("5,3-6,3"), allEdges.get("6,3-7,3"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("12,0-12,1"), allEdges.get("12,1-12,2"), allEdges.get("12,2-12,3"), 
            allEdges.get("15,0-15,3"), allEdges.get("12,0-15,0"), allEdges.get("12,3-13,3"), 
            allEdges.get("13,3-14,3"), allEdges.get("14,3-15,3"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("4,8-4,9"), allEdges.get("4,9-4,10"), allEdges.get("4,10-4,11"), 
            allEdges.get("7,8-7,11"), allEdges.get("4,8-7,8"), allEdges.get("4,11-5,11"), 
            allEdges.get("5,11-6,11"), allEdges.get("6,11-7,11"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("12,8-12,9"), allEdges.get("12,9-12,10"), allEdges.get("12,10-12,11"), 
            allEdges.get("15,8-15,11"), allEdges.get("12,8-15,8"), allEdges.get("12,11-13,11"), 
            allEdges.get("13,11-14,11"), allEdges.get("14,11-15,11"),
          };
          allFaces.add(new Face(temp));
        }
      } else {
        if (!bool1) {
          //bigOuterH();
          //bigInnerV();
          {
            Edge[] temp = {
              allEdges.get("4,3-5,3"), allEdges.get("5,3-6,3"), allEdges.get("6,3-7,3"), allEdges.get("7,3-15,3"), 
              allEdges.get("12,3-13,3"), allEdges.get("13,3-14,3"), allEdges.get("14,3-15,3"), 
              allEdges.get("4,2-4,3"), allEdges.get("4,1-4,2"), allEdges.get("4,0-4,1"), 
              allEdges.get("4,0-7,0"), allEdges.get("7,0-15,0"), allEdges.get("12,0-15,0"), 
              allEdges.get("12,2-12,3"), allEdges.get("12,1-12,2"), allEdges.get("12,0-12,1")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,11-5,11"), allEdges.get("5,11-6,11"), allEdges.get("6,11-7,11"), allEdges.get("7,11-15,11"), 
              allEdges.get("12,11-13,11"), allEdges.get("13,11-14,11"), allEdges.get("14,11-15,11"), 
              allEdges.get("4,10-4,11"), allEdges.get("4,9-4,10"), allEdges.get("4,8-4,9"), 
              allEdges.get("4,8-7,8"), allEdges.get("7,8-15,8"), allEdges.get("12,8-15,8"), 
              allEdges.get("12,10-12,11"), allEdges.get("12,9-12,10"), allEdges.get("12,8-12,9")
              };
              allFaces.add(new Face(temp));
          }
          { 
            Edge[] temp = {
              allEdges.get("4,4-4,5"), allEdges.get("4,5-4,6"), allEdges.get("4,6-4,7"), allEdges.get("4,7-4,15"), 
              allEdges.get("4,12-4,13"), allEdges.get("4,13-4,14"), allEdges.get("4,14-4,15"), 
              allEdges.get("4,4-5,4"), allEdges.get("5,4-6,4"), allEdges.get("6,4-7,4"), 
              allEdges.get("4,12-5,12"), allEdges.get("5,12-6,12"), allEdges.get("6,12-7,12"), 
              allEdges.get("7,12-7,15"), allEdges.get("7,7-7,15"), allEdges.get("7,4-7,7")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("12,4-12,5"), allEdges.get("12,5-12,6"), allEdges.get("12,6-12,7"), allEdges.get("12,7-12,15"), 
              allEdges.get("12,12-12,13"), allEdges.get("12,13-12,14"), allEdges.get("12,14-12,15"), 
              allEdges.get("12,4-13,4"), allEdges.get("13,4-14,4"), allEdges.get("14,4-15,4"), 
              allEdges.get("12,12-13,12"), allEdges.get("13,12-14,12"), allEdges.get("14,12-15,12"), 
              allEdges.get("15,12-15,15"), allEdges.get("15,7-15,15"), allEdges.get("15,4-15,7")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("0,4-1,4"), allEdges.get("1,4-2,4"), allEdges.get("2,4-3,4"), 
              allEdges.get("0,7-3,7"), allEdges.get("0,4-0,7"), allEdges.get("3,4-3,5"), 
              allEdges.get("3,5-3,6"), allEdges.get("3,6-3,7"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("0,12-1,12"), allEdges.get("1,12-2,12"), allEdges.get("2,12-3,12"), 
              allEdges.get("0,15-3,15"), allEdges.get("0,12-0,15"), allEdges.get("3,12-3,13"), 
              allEdges.get("3,13-3,14"), allEdges.get("3,14-3,15"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("8,4-9,4"), allEdges.get("9,4-10,4"), allEdges.get("10,4-11,4"), 
              allEdges.get("8,7-11,7"), allEdges.get("8,4-8,7"), allEdges.get("11,4-11,5"), 
              allEdges.get("11,5-11,6"), allEdges.get("11,6-11,7"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("8,12-9,12"), allEdges.get("9,12-10,12"), allEdges.get("10,12-11,12"), 
              allEdges.get("8,15-11,15"), allEdges.get("8,12-8,15"), allEdges.get("11,12-11,13"), 
              allEdges.get("11,13-11,14"), allEdges.get("11,14-11,15"),
            };
            allFaces.add(new Face(temp));
          }
        } else if (!bool2) {
          //bigOuterV();
          //bigInnerH();

          {
            Edge[] temp = {
              allEdges.get("3,4-3,5"), allEdges.get("3,5-3,6"), allEdges.get("3,6-3,7"), allEdges.get("3,7-3,15"), 
              allEdges.get("3,12-3,13"), allEdges.get("3,13-3,14"), allEdges.get("3,14-3,15"), 
              allEdges.get("2,4-3,4"), allEdges.get("1,4-2,4"), allEdges.get("0,4-1,4"), 
              allEdges.get("0,4-0,7"), allEdges.get("0,7-0,15"), allEdges.get("0,12-0,15"), 
              allEdges.get("2,12-3,12"), allEdges.get("1,12-2,12"), allEdges.get("0,12-1,12")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("11,4-11,5"), allEdges.get("11,5-11,6"), allEdges.get("11,6-11,7"), allEdges.get("11,7-11,15"), 
              allEdges.get("11,12-11,13"), allEdges.get("11,13-11,14"), allEdges.get("11,14-11,15"), 
              allEdges.get("10,4-11,4"), allEdges.get("9,4-10,4"), allEdges.get("8,4-9,4"), 
              allEdges.get("8,4-8,7"), allEdges.get("8,7-8,15"), allEdges.get("8,12-8,15"), 
              allEdges.get("10,12-11,12"), allEdges.get("9,12-10,12"), allEdges.get("8,12-9,12")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,4-5,4"), allEdges.get("5,4-6,4"), allEdges.get("6,4-7,4"), allEdges.get("7,4-15,4"), 
              allEdges.get("12,4-13,4"), allEdges.get("13,4-14,4"), allEdges.get("14,4-15,4"), 
              allEdges.get("4,4-4,5"), allEdges.get("4,5-4,6"), allEdges.get("4,6-4,7"), 
              allEdges.get("12,4-12,5"), allEdges.get("12,5-12,6"), allEdges.get("12,6-12,7"), 
              allEdges.get("12,7-15,7"), allEdges.get("7,7-15,7"), allEdges.get("4,7-7,7")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,12-5,12"), allEdges.get("5,12-6,12"), allEdges.get("6,12-7,12"), allEdges.get("7,12-15,12"), 
              allEdges.get("12,12-13,12"), allEdges.get("13,12-14,12"), allEdges.get("14,12-15,12"), 
              allEdges.get("4,12-4,13"), allEdges.get("4,13-4,14"), allEdges.get("4,14-4,15"), 
              allEdges.get("12,12-12,13"), allEdges.get("12,13-12,14"), allEdges.get("12,14-12,15"), 
              allEdges.get("12,15-15,15"), allEdges.get("7,15-15,15"), allEdges.get("4,15-7,15")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,0-4,1"), allEdges.get("4,1-4,2"), allEdges.get("4,2-4,3"), 
              allEdges.get("7,0-7,3"), allEdges.get("4,0-7,0"), allEdges.get("4,3-5,3"), 
              allEdges.get("5,3-6,3"), allEdges.get("6,3-7,3"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("12,0-12,1"), allEdges.get("12,1-12,2"), allEdges.get("12,2-12,3"), 
              allEdges.get("15,0-15,3"), allEdges.get("12,0-15,0"), allEdges.get("12,3-13,3"), 
              allEdges.get("13,3-14,3"), allEdges.get("14,3-15,3"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,8-4,9"), allEdges.get("4,9-4,10"), allEdges.get("4,10-4,11"), 
              allEdges.get("7,8-7,11"), allEdges.get("4,8-7,8"), allEdges.get("4,11-5,11"), 
              allEdges.get("5,11-6,11"), allEdges.get("6,11-7,11"),
            };
            allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("12,8-12,9"), allEdges.get("12,9-12,10"), allEdges.get("12,10-12,11"), 
              allEdges.get("15,8-15,11"), allEdges.get("12,8-15,8"), allEdges.get("12,11-13,11"), 
              allEdges.get("13,11-14,11"), allEdges.get("14,11-15,11"),
            };
            allFaces.add(new Face(temp));
          }
        } else {
          //bigInnerV();
          //bigInnerH();
          {
            Edge[] temp = {
              allEdges.get("3,4-3,5"), allEdges.get("3,5-3,6"), allEdges.get("3,6-3,7"), allEdges.get("3,7-3,15"), 
              allEdges.get("3,12-3,13"), allEdges.get("3,13-3,14"), allEdges.get("3,14-3,15"), 
              allEdges.get("2,4-3,4"), allEdges.get("1,4-2,4"), allEdges.get("0,4-1,4"), 
              allEdges.get("0,4-0,7"), allEdges.get("0,7-0,15"), allEdges.get("0,12-0,15"), 
              allEdges.get("2,12-3,12"), allEdges.get("1,12-2,12"), allEdges.get("0,12-1,12")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("11,4-11,5"), allEdges.get("11,5-11,6"), allEdges.get("11,6-11,7"), allEdges.get("11,7-11,15"), 
              allEdges.get("11,12-11,13"), allEdges.get("11,13-11,14"), allEdges.get("11,14-11,15"), 
              allEdges.get("10,4-11,4"), allEdges.get("9,4-10,4"), allEdges.get("8,4-9,4"), 
              allEdges.get("8,4-8,7"), allEdges.get("8,7-8,15"), allEdges.get("8,12-8,15"), 
              allEdges.get("10,12-11,12"), allEdges.get("9,12-10,12"), allEdges.get("8,12-9,12")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,3-5,3"), allEdges.get("5,3-6,3"), allEdges.get("6,3-7,3"), allEdges.get("7,3-15,3"), 
              allEdges.get("12,3-13,3"), allEdges.get("13,3-14,3"), allEdges.get("14,3-15,3"), 
              allEdges.get("4,2-4,3"), allEdges.get("4,1-4,2"), allEdges.get("4,0-4,1"), 
              allEdges.get("4,0-7,0"), allEdges.get("7,0-15,0"), allEdges.get("12,0-15,0"), 
              allEdges.get("12,2-12,3"), allEdges.get("12,1-12,2"), allEdges.get("12,0-12,1")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("4,11-5,11"), allEdges.get("5,11-6,11"), allEdges.get("6,11-7,11"), allEdges.get("7,11-15,11"), 
              allEdges.get("12,11-13,11"), allEdges.get("13,11-14,11"), allEdges.get("14,11-15,11"), 
              allEdges.get("4,10-4,11"), allEdges.get("4,9-4,10"), allEdges.get("4,8-4,9"), 
              allEdges.get("4,8-7,8"), allEdges.get("7,8-15,8"), allEdges.get("12,8-15,8"), 
              allEdges.get("12,10-12,11"), allEdges.get("12,9-12,10"), allEdges.get("12,8-12,9")
              };
              allFaces.add(new Face(temp));
          }

          {
            Edge[] temp = {
              allEdges.get("4,4-5,4"), allEdges.get("5,4-6,4"), allEdges.get("6,4-7,4"), 
              allEdges.get("4,4-4,5"), allEdges.get("4,5-4,6"), allEdges.get("4,6-4,7"), 
              allEdges.get("4,7-7,7"), allEdges.get("7,4-7,7")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("12,4-13,4"), allEdges.get("13,4-14,4"), allEdges.get("14,4-15,4"), 
              allEdges.get("12,4-12,5"), allEdges.get("12,5-12,6"), allEdges.get("12,6-12,7"), 
              allEdges.get("12,7-15,7"), allEdges.get("15,4-15,7")
              };
              allFaces.add(new Face(temp));
          }

          {
            Edge[] temp = {
              allEdges.get("4,12-5,12"), allEdges.get("5,12-6,12"), allEdges.get("6,12-7,12"), 
              allEdges.get("4,12-4,13"), allEdges.get("4,13-4,14"), allEdges.get("4,14-4,15"), 
              allEdges.get("4,15-7,15"), allEdges.get("7,12-7,15")
              };
              allFaces.add(new Face(temp));
          }
          {
            Edge[] temp = {
              allEdges.get("12,12-13,12"), allEdges.get("13,12-14,12"), allEdges.get("14,12-15,12"), 
              allEdges.get("12,12-12,13"), allEdges.get("12,13-12,14"), allEdges.get("12,14-12,15"), 
              allEdges.get("12,15-15,15"), allEdges.get("15,12-15,15")
              };
              allFaces.add(new Face(temp));
          }
        }
      }

      if (bool3) {
        //smallInnerH();
        {
          Edge[] temp = {
            allEdges.get("0,3-1,3"), allEdges.get("1,3-1,4"), allEdges.get("0,4-1,4"), allEdges.get("0,3-0,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("8,3-9,3"), allEdges.get("9,3-9,4"), allEdges.get("8,4-9,4"), allEdges.get("8,3-8,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("0,11-1,11"), allEdges.get("1,11-1,12"), allEdges.get("0,12-1,12"), allEdges.get("0,11-0,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("8,11-9,11"), allEdges.get("9,11-9,12"), allEdges.get("8,12-9,12"), allEdges.get("8,11-8,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("6,11-7,11"), allEdges.get("7,11-7,12"), allEdges.get("6,12-7,12"), allEdges.get("6,11-6,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("6,3-7,3"), allEdges.get("7,3-7,4"), allEdges.get("6,4-7,4"), allEdges.get("6,3-6,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("14,11-15,11"), allEdges.get("15,11-15,12"), allEdges.get("14,12-15,12"), allEdges.get("14,11-14,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("14,3-15,3"), allEdges.get("15,3-15,4"), allEdges.get("14,4-15,4"), allEdges.get("14,3-14,4"),
          };
          allFaces.add(new Face(temp));
        }
      } else {
        //smallOuterH();
        {
          Edge[] temp = {
            allEdges.get("2,3-2,4"), allEdges.get("2,3-3,3"), allEdges.get("3,3-3,4"), allEdges.get("2,4-3,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("10,3-10,4"), allEdges.get("10,3-11,3"), allEdges.get("11,3-11,4"), allEdges.get("10,4-11,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("2,11-2,12"), allEdges.get("2,11-3,11"), allEdges.get("3,11-3,12"), allEdges.get("2,12-3,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("10,11-10,12"), allEdges.get("10,11-11,11"), allEdges.get("11,11-11,12"), allEdges.get("10,12-11,12"),
          };
          allFaces.add(new Face(temp));
        }

        {
          Edge[] temp = {
            allEdges.get("4,3-4,4"), allEdges.get("4,3-5,3"), allEdges.get("5,3-5,4"), allEdges.get("4,4-5,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("4,11-4,12"), allEdges.get("4,11-5,11"), allEdges.get("5,11-5,12"), allEdges.get("4,12-5,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("12,3-12,4"), allEdges.get("12,3-13,3"), allEdges.get("13,3-13,4"), allEdges.get("12,4-13,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("12,11-12,12"), allEdges.get("12,11-13,11"), allEdges.get("13,11-13,12"), allEdges.get("12,12-13,12"),
          };
          allFaces.add(new Face(temp));
        }
      }

      if (bool4) {
        //smallInnerV();
        {
          Edge[] temp = {
            allEdges.get("3,0-3,1"), allEdges.get("3,1-4,1"), allEdges.get("4,0-4,1"), allEdges.get("3,0-4,0"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,8-3,9"), allEdges.get("3,9-4,9"), allEdges.get("4,8-4,9"), allEdges.get("3,8-4,8"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,0-11,1"), allEdges.get("11,1-12,1"), allEdges.get("12,0-12,1"), allEdges.get("11,0-12,0"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,8-11,9"), allEdges.get("11,9-12,9"), allEdges.get("12,8-12,9"), allEdges.get("11,8-12,8"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,6-11,7"), allEdges.get("11,7-12,7"), allEdges.get("12,6-12,7"), allEdges.get("11,6-12,6"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,6-3,7"), allEdges.get("3,7-4,7"), allEdges.get("4,6-4,7"), allEdges.get("3,6-4,6"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,14-11,15"), allEdges.get("11,15-12,15"), allEdges.get("12,14-12,15"), allEdges.get("11,14-12,14"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,14-3,15"), allEdges.get("3,15-4,15"), allEdges.get("4,14-4,15"), allEdges.get("3,14-4,14"),
          };
          allFaces.add(new Face(temp));
        }
      } else {
        //smallOuterV();
        {
          Edge[] temp = {
            allEdges.get("3,2-4,2"), allEdges.get("3,2-3,3"), allEdges.get("3,3-4,3"), allEdges.get("4,2-4,3"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,10-4,10"), allEdges.get("3,10-3,11"), allEdges.get("3,11-4,11"), allEdges.get("4,10-4,11"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,2-12,2"), allEdges.get("11,2-11,3"), allEdges.get("11,3-12,3"), allEdges.get("12,2-12,3"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,10-12,10"), allEdges.get("11,10-11,11"), allEdges.get("11,11-12,11"), allEdges.get("12,10-12,11"),
          };
          allFaces.add(new Face(temp));
        }

        {
          Edge[] temp = {
            allEdges.get("3,4-4,4"), allEdges.get("3,4-3,5"), allEdges.get("3,5-4,5"), allEdges.get("4,4-4,5"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,4-12,4"), allEdges.get("11,4-11,5"), allEdges.get("11,5-12,5"), allEdges.get("12,4-12,5"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,12-4,12"), allEdges.get("3,12-3,13"), allEdges.get("3,13-4,13"), allEdges.get("4,12-4,13"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,12-12,12"), allEdges.get("11,12-11,13"), allEdges.get("11,13-12,13"), allEdges.get("12,12-12,13"),
          };
          allFaces.add(new Face(temp));
        }
      }
      if (!bool3 && !bool4) {
        {
          Edge[] temp = {
            allEdges.get("3,3-3,4"), allEdges.get("3,4-4,4"), allEdges.get("3,3-4,3"), allEdges.get("4,3-4,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,3-11,4"), allEdges.get("11,4-12,4"), allEdges.get("11,3-12,3"), allEdges.get("12,3-12,4"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("3,11-3,12"), allEdges.get("3,12-4,12"), allEdges.get("3,11-4,11"), allEdges.get("4,11-4,12"),
          };
          allFaces.add(new Face(temp));
        }
        {
          Edge[] temp = {
            allEdges.get("11,11-11,12"), allEdges.get("11,12-12,12"), allEdges.get("11,11-12,11"), allEdges.get("12,11-12,12"),
          };
          allFaces.add(new Face(temp));
        }
      }
    }
    connectAllFaces();
  }

  private void connectAllFaces () {

    Iterator fIt = allFaces.iterator();
    while (fIt.hasNext ()) {
      Face sFace = (Face) fIt.next();
      PriorityQueue<NavNode> openFaces = new PriorityQueue<NavNode>();
      HashMap<Face, Edge> closedFaces = new HashMap<Face, Edge>();
      openFaces.add(new NavNode(sFace));
      while (!openFaces.isEmpty ()) {
        NavNode curFace = openFaces.poll();

        if (!closedFaces.containsKey(curFace.getFace())) {
          //if the current face has not been resolved, look at it, otherwise move on
          Edge[] curEdges = curFace.getFace().getEdgeArray();

          //go through all the edges of the current face, and add the faces if they haven't been resolved already
          for (int i = 0; i < curEdges.length; i++) {
            Face nextFace = curEdges[i].getOther(curFace.getFace());
            if (nextFace != null && !(closedFaces.containsKey(nextFace))) {
              openFaces.add(new NavNode(nextFace, (curFace.getStep() == null) ? curEdges[i] : curFace.getStep(), curFace.getCost() + curEdges[i].getDistance()));
              //if the current node has a step, then use it, otherwise use the edge you just passed through
            }
          }

          //now that you've checked all the adjacent faces, this face is done and is added to closed
          closedFaces.put(curFace.getFace(), curFace.getStep());
        }
      }
      sFace.setNavTo(closedFaces);
    }
  }

  private Face findFace (PVector p) {
    Face outside = null;
    float dist = 0;
    for (int i = 0; i < allFaces.size (); i++) {
      Face curFace = allFaces.get(i);
      if (curFace.contains(p)) {
        return curFace;
      }
      if (outside == null) {
        outside = curFace;
        dist = curFace.getDist(p);
      } else if (curFace.getDist(p) < dist) {
        outside = curFace;
        dist = curFace.getDist(p);
      }
    }
    return outside;
  }

  private PVector closePtOn (PVector a1, PVector a2, PVector b1, PVector b2) {
    //find the best point on a1-a2 if trying to move along b1-b2
    //needs work?
    return (new PVector((a1.x + a2.x)/2, (a1.y + a2.y)/2));
  }

  PVector getShortGoal (PVector start, PVector finish) {//gets the point that is the short term goal to get from start to finish
    //get the first step from start to finish
    Face sFace = findFace(start);
    Face fFace = findFace(finish);
    if (sFace.equals(fFace)) {
      return finish;
    } else {
      Edge targetEdge = sFace.getPath(fFace);
      return closePtOn (targetEdge.getP0(), targetEdge.getP1(), start, finish);
    }
  }

  private class NavNode implements Comparable {
    private Face f;
    private Edge step = null;
    private float cost;

    private NavNode (Face fi) { //only for initial face
      f = fi;
      cost = 0;
    }

    private NavNode (Face fi, Edge stepi, float costi) {
      f = fi;
      step = stepi;
      cost = costi;
    }

    private Face getFace() {
      return f;
    }

    private Edge getStep() {
      return step;
    }

    public float getCost() {
      return cost;
    }

    public int compareTo(Object other) {
      float oCost = ((NavNode) other).getCost();
      if (this.equals(other)) {
        return 0;
      } else if (cost > oCost) {
        return 1;
      } else {
        return -1;
      }
    }
  }
}

NavMesh nm;


void startGame() {
  gamestate = 1;
  Iterator pIt = allPeople.iterator();
  while (pIt.hasNext ()) {
    ((Person)pIt.next()).reset();
  }

  living = (List) ((LinkedList) allPeople).clone();

  generateLevel();
}

void endGame() {
  gamestate = 2;
}

void startOver() {
  allPeople.clear();
  gamestate = 0;
}

void draw() {
  switch (gamestate) {
  case 0:
    startscreen();
    break;
  case 1:
    gameloop();
    break;
  case 2:
    endscreen();
    break;
  }
}


void keyTyped() {
  switch (gamestate) {
  case 0:
    if (typeName) {
      textFont (smallFont);
      if (key >= 32 && key <= 126) {
        if (textWidth(name + (String.valueOf(key))) <= nameMaxWidth) {
          name = name + (String.valueOf(key));
        }
      } else if ((int) key == 8 && name.length() > 0) {
        name = name.substring(0, name.length()-1);
      }
    }
    if (key == 10) {
      allPeople.add(new Person(width/16, height*3/16, true, pistol, name, 128, 0, 0));
      allPeople.add(new Person(width*15/16, height*13/16, false, pistol, "LR", 0, 0, 128));
      allPeople.add(new Person(width/16, height*13/16, false, pistol, "LL", 0, 128, 0)); 
      allPeople.add(new Person(width*15/16, height*3/16, false, pistol, "UR", 128, 0, 128));
      startGame();
    }
    break;
  case 1:
    if (key == 'W' || key == 'w') {
      keyW = 1;
    }
    if (key == 'A' || key == 'a') {
      keyA = 1;
    }
    if (key == 'S' || key == 's') {
      keyS = 1;
    }
    if (key == 'D' || key == 'd') {
      keyD = 1;
    }
    if (key == 'k') {
      try {
        Iterator lIt = living.iterator();
        while (lIt.hasNext ()) {
          ((Person)lIt.next()).kill();
        }
      } 
      catch (Throwable e) {
      }
    }
    break;
  case 2:
    if (key == 'Y' || key == 'y') {
      startGame();
    }
    if (key == 'N' || key == 'n') {
      startOver();
    }
    break;
  }
}

void keyReleased() {
  if (key == 'W' || key == 'w') {
    keyW = 0;
  }
  if (key == 'A' || key == 'a') {
    keyA = 0;
  }
  if (key == 'S' || key == 's') {
    keyS = 0;
  }
  if (key == 'D' || key == 'd') {
    keyD = 0;
  }
}

