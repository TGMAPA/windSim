import processing.data.JSONObject;
import processing.data.JSONArray;
import org.gicentre.geomap.*;
import peasy.*;


JSONArray dataU; 
JSONArray dataV; 
int gridCols = 360;
int gridRows = 181; 
float xscale, yscale;    
PVector[][] vectorField;
float maxMag, minMag;

GeoMap geoMap;

PeasyCam cam;
float offX, offY;
float zoom = 1;
float minZoom = 1;
float maxZoom = 5;
float minX, minY, maxX,maxY;

Particle[][] particles;    
PGraphics mapLayer;

void setup() {
  
  size(1600, 800);
  
  xscale = width/ gridCols;
  yscale = height/ gridRows;
  
  
  offX = width / 2;
  offY = height / 2;
  
  geoMap = new GeoMap(this);  // Create the geoMap object.
  geoMap.readFile("world");   // Read shapefile.
  
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);
  
  
  // Leer componentes U y V
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);
  
  dataU = uComponent.getJSONArray("data");
  dataV = vComponent.getJSONArray("data");
  
  vectorField = new PVector[gridRows][gridCols];
  particles = new Particle[gridRows][gridCols];
  
  
  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + y * gridCols;
      if (idx < dataU.size() && idx < dataV.size()) {
        float u = dataU.getFloat(idx);
        float v = dataV.getFloat(idx);
        vectorField[y][x] = new PVector(u, v);
        particles[y][x]   = new Particle(x*xscale, y*yscale, vectorField[y][x].mag()*0.15, vectorField[y][x].mag() );
      }
    }
  }
  
  
  float[] MaxMin = getMinMaxMagnitude( vectorField , gridRows, gridCols);
  minMag = MaxMin[0];
  maxMag = MaxMin[1];
  
  mapLayer = createGraphics(width, height);
  
  frameRate(40);
  
  println("Inicialización finalizada...");
  println("MagMax       : "+maxMag);
  println("MinMax       : "+minMag);
  println("Cols         : "+gridCols);
  println("Rows         : "+gridRows);
  println("Screen_Widht : "+width);
  println("Screen_Height: "+height);
  println("XScale        : "+xscale);
  println("YScale        : "+yscale);
}  


void draw(){
  // Calcular límites dinámicos basados en zoom y tamaño del canvas
  float halfWidth = (width / zoom) / 2;
  float halfHeight = (height / zoom) / 2;
  minX = -halfWidth;
  maxX = width - halfWidth;
  minY = -halfHeight;
  maxY = height - halfHeight;

  // Limitar los valores de offset y zoom
  offX = constrain(offX, minX, maxX);
  offY = constrain(offY, minY, maxY);
  zoom = constrain(zoom, minZoom, maxZoom);

  // Aplicar zoom y traslación
  translate(offX, offY);
  scale(zoom);
  translate(-width / 2, -height / 2); // Centrar el origen de coordenadas
  
  mapLayer.beginDraw();
  mapLayer.noStroke();
  mapLayer.fill(255,30); 
  mapLayer.background(202, 226, 245, 20);
  mapLayer.rect(0, 0, width, height);

  for (int i=0; i< particles.length; i++){
    for (int j=0; j< particles[0].length; j++){
      particles[i][j].follow(vectorField);
      particles[i][j].update();
      particles[i][j].show(mapLayer);
      particles[i][j].edges();
      particles[i][j].checkLifespan(); // Verificar si se debe reiniciar la partícula
    }
  }
  
  //fill(206,173,146, 50);
  //geoMap.draw();

  mapLayer.endDraw();
  
  image(mapLayer, 0, 0);
  
 
}


// Interpolación bilineal para obtener la dirección del viento
PVector interpolateBilinear(float x, float y) {
  int x0 = floor(x / xscale);
  int y0 = floor(y / yscale);
  int x1 = x0 + 1;
  int y1 = y0 + 1;

  // Asegurarse de no salir de los límites
  x0 = constrain(x0, 0, gridCols - 1);
  y0 = constrain(y0, 0, gridRows - 1);
  x1 = constrain(x1, 0, gridCols - 1);
  y1 = constrain(y1, 0, gridRows - 1);

  float tx = (x / xscale) - x0;
  float ty = (y / yscale) - y0;

  PVector v00 = vectorField[y0][x0];
  PVector v10 = vectorField[y0][x1];
  PVector v01 = vectorField[y1][x0];
  PVector v11 = vectorField[y1][x1];

  PVector a = PVector.lerp(v00, v10, tx);
  PVector b = PVector.lerp(v01, v11, tx);
  return PVector.lerp(a, b, ty);
}


// Clase para partículas
class Particle {
  PVector pos0;
  float x0, y0;
  PVector pos;
  PVector vel;
  PVector acc;
  float maxSpeed = 2;
  float birthTime; // Momento en que la partícula nació
  float lifespan;  // Tiempo de vida de la partícula
  float[] particleColor;

  Particle(float x, float y, float lifespan, float mag) {
    
    this.x0 = x;
    this.y0 = y;
    this.pos = new PVector(x, y);
    this.vel = new PVector();
    this.acc = new PVector();
    this.lifespan = lifespan;
    this.birthTime = millis() / 1000.0; // Guardar tiempo inicial en segundos
    
    this.particleColor = new float[4];

    // Normaliza la magnitud en un rango entre 0 y 1
    float normalizedMag;
    if (maxMag != minMag) {
      normalizedMag = map(mag, minMag, maxMag, 0.0, 1.0);
    } else {
        normalizedMag = 0; // O algún valor por defecto
    }
    
    // Determina el color basado en la magnitud
    if (normalizedMag > 0.95) {  // Mag alta
        this.particleColor[0] = 255;  
        this.particleColor[1] = 0;    
        this.particleColor[2] = 0;    
    } else if (normalizedMag > 0.33) {  // Mag Verde
        this.particleColor[0] = 0;   
        this.particleColor[1] = 255; 
        this.particleColor[2] = 0;   
    } else {  // Mag Azul
        this.particleColor[0] = 0;   
        this.particleColor[1] = 0;   
        this.particleColor[2] = 255;  
    }
    
    // Asigna transparencia basada en la magnitud
    if (maxMag != minMag) {
      this.particleColor[3] = map(mag, minMag, maxMag, 0.0, 255.0);
    } else {
      this.particleColor[3] = 0;
    }
    
  }

  // Actualiza la posición de la partícula
  void update() {
    this.vel.add(acc);
    this.vel.limit(maxSpeed);
    this.pos.add(vel);
    this.acc.mult(0);
  }

  // Dibuja la partícula en la capa de estelas
  void show(PGraphics pg) {
    pg.stroke(this.particleColor[0], this.particleColor[1], this.particleColor[2], this.particleColor[3]); // Color semitransparente
    pg.strokeWeight(1.8);
    pg.point(this.pos.x, this.pos.y);
  }

  // Reaparece en los bordes
  void edges() {
    if (this.pos.x > width) this.pos.x = 0;
    if (this.pos.x < 0) this.pos.x = width;
    if (this.pos.y > height) this.pos.y = 0;
    if (this.pos.y < 0) this.pos.y = height;
  }

  // Sigue el campo vectorial con interpolación bilineal
  void follow(PVector[][] field) {
    PVector force = interpolateBilinear(this.pos.x, this.pos.y);
    this.acc.add(force);
    
    // Normaliza la magnitud en un rango entre 0 y 1
    float normalizedMag = map(force.mag(), minMag, maxMag, 0.0, 1.0);
    
    // Determina el color basado en la magnitud
    if (normalizedMag > 0.55) {  // Magnitud alta - Rojo
        this.particleColor[0] = 255;  // R
        this.particleColor[1] = 0;    // G
        this.particleColor[2] = 0;    // B
    } else if (normalizedMag > 0.10) {  // Magnitud moderada - Verde
        this.particleColor[0] = 0;    // R
        this.particleColor[1] = 255;  // G
        this.particleColor[2] = 0;    // B
    } else {  // Magnitud baja - Azul
        this.particleColor[0] = 0;    // R
        this.particleColor[1] = 0;    // G
        this.particleColor[2] = 255;  // B
    }
    
    // Asigna transparencia basada en la magnitud
    this.particleColor[3] = map(force.mag(), minMag, maxMag, 100, 255.0);  // Alpha
  }

  // Verifica el tiempo de vida de la partícula y la reinicia si es necesario
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos
    if (currentTime - this.birthTime > this.lifespan) {
      // Reiniciar partícula
      //this.pos = new PVector(random(width), random(height));
      this.pos = new PVector(this.x0, this.y0);
      this.vel.set(0, 0);
      this.acc.set(0, 0);
      this.birthTime = currentTime; // Reiniciar tiempo de vida
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom -= e * 0.05;
  zoom = constrain(zoom, minZoom, maxZoom); // Limitar el zoom
}

void mouseDragged() {
  offX += (mouseX - pmouseX) / zoom;
  offY += (mouseY - pmouseY) / zoom;
  // Aplicar límites basados en la posición de la cámara y el tamaño del canvas
  offX = constrain(offX, -minX, maxX); // Limitar el desplazamiento horizontal
  offY = constrain(offY, -minY, maxY); // Limitar el desplazamiento vertical
}

float[] getMinMaxMagnitude(PVector[][] vectorField, int cols, int rows) {
  float maxMagnitude = 0;  // Inicia con el valor más pequeño posible
  float minMagnitude = 0;  // Inicia con el valor más grande posible

  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      float magnitude = vectorField[x][y].mag();  // Calcula la magnitud del vector
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;  // Actualiza el máximo si es mayor
      }
      if (magnitude < minMagnitude) {
        minMagnitude = magnitude;  // Actualiza el mínimo si es menor
      }
    }
  }
  float[] out = new float[2];
  out[0] = minMagnitude;
  out[1] = maxMagnitude;
  
  return out;  // Devuelve ambos valores
}
