/*
Fecha: 25/11/2024
--Algoritmos Avanzados 

  Miguel Ángel Pérez Ávila A01369908
  Máximo Moisés Zamudio Chávez A01772056
  Andrea Bahena Valdés A01369019
  
  v4 - Particulas dibujadas con puntos con degradado  | sin mapa
  
*/

// Importación de bibliotecas para manejar datos JSON, mapas geográficos y la cámara de visualización
import processing.data.JSONObject;
import processing.data.JSONArray;

// Declaración de variables globales
JSONArray dataU; // Datos para la componente U del viento
JSONArray dataV; // Datos para la componente V del viento
int gridCols = 360; // Número de columnas en la cuadrícula del campo vectorial
int gridRows = 181; // Número de filas en la cuadrícula del campo vectorial

float xscale, yscale; // Factores de escala para ajustar las coordenadas del campo a la ventana gráfica
float xscaleMax, yscaleMax; // Factores máximos de escala 

PVector[][] vectorField; // Matriz que contiene los vectores del campo de viento
float maxMag, minMag; // Magnitudes máximas y mínimas del campo vectorial

PImage earth; // Imagen que representa el mapa base

float offX, offY; // Variables para desplazamiento en los ejes X e Y
float zoom = 1; // Nivel inicial de zoom
float minZoom = 1, maxZoom = 5; // Límites de zoom
float minX, minY, maxX, maxY; // Límites de desplazamiento de la cámara

Particle[][] particles;  // Contenedor de particulas como matriz
Particle[] Nparticles;  // Contenedor de particulas como arreglo para n cantidad de particulas
boolean generatewithNparticles;
PGraphics mapLayer; // Capa gráfica para dibujar partículas y sus trayectorias

// Configuración inicial
void setup() {
  
  size(1600, 800); // Configuración del tamaño de la ventana
  
  xscale = ((float) width / gridCols); // Escala en X basada en la cuadrícula y el ancho
  yscale = ((float) height / gridRows); // Escala en Y basada en la cuadrícula y el alto
  xscaleMax = xscale;
  yscaleMax = yscale;
  
  offX = width / 2; // Posición inicial de desplazamiento en X
  offY = height / 2; // Posición inicial de desplazamiento en Y
  
  earth = loadImage("test1.jpg"); // Carga una imagen que representa la Tierra
  earth.resize(width, height); // Ajusta la imagen al tamaño de la ventana
  
  // Carga datos JSON desde un archivo y los convierte a una cadena
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);
  
  // Lee las componentes U y V del viento desde el JSON
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);
  
  dataU = uComponent.getJSONArray("data"); // Obtiene datos de la componente U
  dataV = vComponent.getJSONArray("data"); // Obtiene datos de la componente V
  
  // Matriz de vectores 
  vectorField = new PVector[gridRows][gridCols];

  // Bandera para activar la generación de particulas con cantidad N o de acuerdo con el campo vectorial
  generatewithNparticles = false;
  
  if(!generatewithNparticles){
    // Generación de particulas de acuerdo con matriz de vectores
    generateParticle2Matrix();
  }else{
    // Generación de N particulas
    generateNParticle(65000);
  }
  
  
  mapLayer = createGraphics(width, height); // Crea una capa gráfica para dibujar
  
  frameRate(30); // Establece la tasa de cuadros por segundo
  
  // Mensajes de depuración
  println("Inicialización finalizada...");
  println("MagMax       : " + maxMag);
  println("MinMax       : " + minMag);
  println("Cols         : " + gridCols);
  println("Rows         : " + gridRows);
  println("Screen_Width : " + width);
  println("Screen_Height: " + height);
  println("XScale       : " + xscale);
  println("YScale       : " + yscale);
}  



void draw(){
  float halfWidth = (width / zoom) / 2; // Mitad del ancho ajustado al zoom
  float halfHeight = (height / zoom) / 2; // Mitad de la altura ajustada al zoom
  minX = -halfWidth; // Mínimo desplazamiento en X
  maxX = width - halfWidth; // Máximo desplazamiento en X
  minY = -halfHeight; // Mínimo desplazamiento en Y
  maxY = height - halfHeight; // Máximo desplazamiento en Y

  // Limitar los valores de offset y zoom
  offX = constrain(offX, minX, maxX); // Restringe el desplazamiento en X
  offY = constrain(offY, minY, maxY); // Restringe el desplazamiento en Y
  zoom = constrain(zoom, minZoom, maxZoom); // Restringe el zoom entre sus límites

  // Aplicar zoom y traslación
  translate(offX, offY);
  scale(zoom);
  translate(-width / 2, -height / 2); // Centrar el origen de coordenadas
  
  
  mapLayer.beginDraw();
  mapLayer.noStroke();
  
  mapLayer.fill(80,25); 
  mapLayer.rect(0, 0, width, height);
  
  // Actualización de particulas de acuerdo con matriz de vectores
  if(!generatewithNparticles){
    for (int i=0; i< particles.length; i++){
      for (int j=0; j< particles[0].length; j++){
        particles[i][j].follow();
        particles[i][j].update();
        particles[i][j].show(mapLayer);
        particles[i][j].edges();
        particles[i][j].checkLifespan(); // Verificar si se debe reiniciar la partícula
      }
    }
  }else{
    // Actualización de N particulas
    for( int i=0; i< Nparticles.length; i++ ){
      Nparticles[i].follow();
      Nparticles[i].update();
      Nparticles[i].show(mapLayer);
      Nparticles[i].edges();
      Nparticles[i].checkLifespan(); // Verificar si se debe reiniciar la partícula
    }
  }
  

  mapLayer.endDraw();
  image(earth, 0, 0);
  image(mapLayer, 0, 0);
  
}

// Clase para partículas
class Particle {
  PVector pos0;
  float x0, y0, xscale0, yscale0;
  PVector pos;
  PVector vel;
  PVector acc;
  float maxSpeed = 2;
  float birthTime; // Momento en que la partícula nació
  float lifespan;  // Tiempo de vida de la partícula
  float[] particleColor;

  Particle(float x, float y, float lifespan, float xscale_, float yscale_) {
    this.x0 = x;
    this.y0 = y;
    this.xscale0 = xscale_;
    this.yscale0 = yscale_;
    
    this.pos = new PVector(x, y);
    this.vel = new PVector();
    this.acc = new PVector();
    this.lifespan = lifespan;
    this.birthTime = millis() / 1000.0; // Guardar tiempo inicial en segundos
    this.particleColor = new float[4];
    
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
  void follow() {
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
        this.particleColor[0] = 30;    // R
        this.particleColor[1] = 200;  // G
        this.particleColor[2] = 39;    // B
    } else if (normalizedMag > 0.2) {  // Magnitud moderada - Verde
        this.particleColor[0] = 139;    // R
        this.particleColor[1] = 205;  // G
        this.particleColor[2] = 143;    // B
    } else {  // Magnitud baja - Azul
        this.particleColor[0] = 0;    // R
        this.particleColor[1] = 0;    // G
        this.particleColor[2] = 255;  // B
    }
    
    // Asigna transparencia basada en la magnitud
    this.particleColor[3] = map(force.mag(), minMag, maxMag, 50, 255.0);  // Alpha
  }

  // Verifica el tiempo de vida de la partícula y la reinicia si es necesario
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos
    if (currentTime - this.birthTime > this.lifespan) {
      // Reiniciar partícula
      //this.pos = new PVector(this.x0, this.y0);
      float newposx = random(width);
      float newposy = random(height);
      this.pos = new PVector(newposx, newposy);
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

// Función para generar una cantidad de particulas con respecto a la matriz de vectores
void generateParticle2Matrix(){
  particles = new Particle[gridRows][gridCols];
  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + y * gridCols;
      if (idx < dataU.size() && idx < dataV.size()) {
        float u = dataU.getFloat(idx);
        float v = dataV.getFloat(idx);
        vectorField[y][x] = new PVector(u, v);
        particles[y][x]   = new Particle(x*xscale, y*yscale, vectorField[y][x].mag()*0.09, xscale, yscale );
      }
    }
  }
  // Obtiene las magnitudes mínima y máxima del campo vectorial
  float[] MaxMin = getMinMaxMagnitude(vectorField, gridRows, gridCols);
  minMag = MaxMin[0];
  maxMag = MaxMin[1];
}

// Función para generar una cantidad N de particulas
void generateNParticle(int n){
  Nparticles = new Particle[n];
  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + y * gridCols;
      if (idx < dataU.size() && idx < dataV.size()) {
        float u = dataU.getFloat(idx);
        float v = dataV.getFloat(idx);
        vectorField[y][x] = new PVector(u, v);
      }
    }
  }
  // Obtiene las magnitudes mínima y máxima del campo vectorial
  float[] MaxMin = getMinMaxMagnitude(vectorField, gridRows, gridCols);
  minMag = MaxMin[0];
  maxMag = MaxMin[1];
  
  // Generar cantidad n de particulas en lugar random del plano
  for(int i=0; i<n; i++){
    Nparticles[i]   = new Particle(random(width), random(height), random(minMag, maxMag), xscale, yscale );
  }
}
