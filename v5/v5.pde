/*
Fecha: 25/11/2024
--Algoritmos Avanzados 

  Miguel Ángel Pérez Ávila A01369908
  Máximo Moisés Zamudio Chávez A01772056
  Andrea Bahena Valdés A01369019
  
  v5 - Particulas dibujadas con lineas curveadas utilizando puntos de control (bezier) con degradado | Intento de zoom por escala 
  
*/

// Importación de bibliotecas para manejar datos JSON
import processing.data.JSONObject;
import processing.data.JSONArray;

// Declaración de variables globales
JSONArray dataU; // Datos para la componente U del viento
JSONArray dataV; // Datos para la componente V del viento
int gridCols = 360; // Número de columnas en la cuadrícula del campo vectorial
int gridRows = 181; // Número de filas en la cuadrícula del campo vectorial

float xscale, yscale; // Factores de escala para ajustar las coordenadas del campo a la ventana gráfica
float xscaleMax, yscaleMax; // Factores máximos de escala 

PVector[][] vectorField;  // Matriz de campo vectorial
float maxMag, minMag;  // Magnitud maxima y minima de la matriz de vectores

PImage earth; // Imagen del mapa

// Variables de control de zoom a camara
float offX, offY;
float zoom = 1;
float minZoom = 1;
float maxZoom = 5;
float minX, minY, maxX,maxY;

Particle[][] particles;  // Contenedor de particulas como matriz
Particle[] Nparticles;  // Contenedor de particulas como arreglo para n cantidad de particulas
boolean generatewithNparticles;



//==============================================================================
// SETUP
void setup() {
  // Resolución de la ventana
  size(1200, 600);
  
  // Parametros para la manipulación del zoom de cámara y la escala del plano
  xscale = ((float) width / gridCols);
  yscale = ((float) height / gridRows);
  xscaleMax = xscale;
  yscaleMax = yscale;
  offX = width / 2; // Recalcula la posición de desplazamiento en X
  offY = height / 2; // Recalcula la posición de desplazamiento en Y
  
  // Carga de imagen para el mapa de fondo
  earth = loadImage("test5.png");
  earth.resize(width, height);
  
  // Lectura de archivo json e interpretación
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);
  
  // Leer componentes U y V
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);
  
  // Lectura de datos para ambas secciones del json
  dataU = uComponent.getJSONArray("data");
  dataV = vComponent.getJSONArray("data");
  
  // Matriz de vectores 
  vectorField = new PVector[gridRows][gridCols];

  // Bandera para activar la generación de particulas con cantidad N o de acuerdo con el campo vectorial
  generatewithNparticles = false;
  
  if(!generatewithNparticles){
    // Generación de particulas de acuerdo con matriz de vectores
    generateParticle2Matrix();
  }else{
    // Generación de N particulas
    generateNParticle(20000);
  }
  
   // Obtiene los valores mínimos y máximos de la magnitud del viento
  float[] MaxMin = getMinMaxMagnitude( vectorField , gridRows, gridCols);
  minMag = MaxMin[0]; // Magnitud mínima
  maxMag = MaxMin[1]; // Magnitud máxima
  
  frameRate(30); // Configura la velocidad de fotogramas
  
  // Información de depuración inicial
  println("MagMax        : " + maxMag);
  println("MinMax        : " + minMag);
  println("Cols          : " + gridCols);
  println("Rows          : " + gridRows);
  println("Screen_Widht  : " + width);
  println("Screen_Height : " + height);
  println("XScale        : "+ xscale);
  println("YScale        : "+ yscale);
  println("Inicialización finalizada...");
}  
// SETUP
//==============================================================================



//==============================================================================
//==============================================================================
// Método draw() - Ciclo principal del programa
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
  translate(offX, offY); // Aplica la traslación
  scale(zoom); // Aplica el zoom
  translate(-width / 2, -height / 2); // Centra el origen de coordenadas

  // Limitar los valores de offset y zoom
  offX = constrain(offX, minX, maxX);
  offY = constrain(offY, minY, maxY);
  
  noStroke();
  background(50, 50, 50, 10 );
  image(earth, 0, 0, width, height );
  
  // Actualización de particulas de acuerdo con matriz de vectores
  if(!generatewithNparticles){
    for (int i=0; i< particles.length; i++){
      for (int j=0; j< particles[0].length; j++){
        particles[i][j].follow();
        particles[i][j].update();
        particles[i][j].show();
        particles[i][j].edges();
        particles[i][j].checkLifespan(); // Verificar si se debe reiniciar la partícula
      }
    }
  }else{
    // Actualización de N particulas
    for( int i=0; i< Nparticles.length; i++ ){
      Nparticles[i].follow();
      Nparticles[i].update();
      Nparticles[i].show();
      Nparticles[i].edges();
      Nparticles[i].checkLifespan(); // Verificar si se debe reiniciar la partícula
    }
  }
}
// END DRAW
//==============================================================================
//==============================================================================



//==============================================================================
// Clase para partículas
class Particle {
  PVector pos0;
  float x0, y0, xscale0, yscale0;
  PVector pos, prevPos;
  PVector vel;
  PVector acc;
  float maxSpeed = 2;
  float birthTime; 
  float lifespan; 
  float[] particleColor;
  PVector bezierControl;

  Particle(float x, float y, float lifespan, float xscale_, float yscale_) {
    this.x0 = x;
    this.y0 = y;
    this.xscale0 = xscale_;
    this.yscale0 = yscale_;
    
    this.pos = new PVector(x, y);
    this.prevPos = this.pos.copy();
    bezierControl = new PVector(); // Punto de control para la curva Bezier
    
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
    int k = 15;
    // Punto de control determinado de acuerdo con la velocidad de la particula y una constate determinada
    bezierControl.set(pos.x + vel.x * k, pos.y + vel.y * k);
    this.prevPos = this.pos.copy();
   }

  // Dibuja la partícula en la capa de estelas
  void show() {
    stroke(this.particleColor[0], this.particleColor[1], this.particleColor[2], this.particleColor[3]); // Color semitransparente
    strokeWeight(1.8);
    point(this.pos.x, this.pos.y); // Dibuja un punto en la posición
    bezier(prevPos.x, prevPos.y, bezierControl.x, bezierControl.y, bezierControl.x, bezierControl.y, pos.x, pos.y); // Dibuja una curva apoyada en puntos de control definidos
  }

  // Reaparece en los bordes
  void edges() {
    if (this.pos.x > width) this.pos.x = 0;
    if (this.pos.x < 0) this.pos.x = width;
    if (this.pos.y > height) this.pos.y = 0;
    if (this.pos.y < 0) this.pos.y = height;
  }
  
  void follow() { // PVector[][] field
      PVector force = interpolateBilinear(this.pos.x, this.pos.y);
      this.acc.add(force);
      this.updateColor(force.mag()); 
  }
  
  // Verifica el tiempo de vida de la partícula y la reinicia si es necesario
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos
    if (currentTime - this.birthTime > this.lifespan) {
      float newposx = random(width);
      float newposy = random(height);
      
      // intento de zoom por escala
      /*
      float newposx = 0;
      float newposy = 0;
      if(this.x0*xscale/this.xscale0 > xscale || this.x0*xscale/this.xscale0 < 0){
        newposx =  this.x0*xscale/this.xscale0;
      }else{
        newposx = random(width/xscale);
      }
      
      if(this.y0*yscale/this.yscale0 > yscale || this.y0*yscale/this.yscale0 < 0){
        newposy =   this.y0*yscale/this.yscale0;
      }else{
        newposy = random(height/yscale);
      }
      */
      
      this.pos = new PVector(newposx, newposy);
      this.vel.set(0, 0);
      this.acc.set(0, 0);
      this.birthTime = currentTime; // Reiniciar tiempo de vida
    }
  }
  
  void updateColor(float mag){
    // Normaliza la magnitud de la fuerza en un rango de 0 a 1
      float normalizedMag = map(mag, minMag, maxMag, 0.0, 1.0);
  
      // Define los colores de los extremos para el degradado
      color lowColor = color(0, 0, 10);      // Azul para magnitud baja
      color midColor = color(30, 200, 39);    // Verde para magnitud moderada
      color highColor = color(255, 0, 0);     // Rojo para magnitud alta
  
      // Interpola el color basado en la magnitud normalizada
      if (normalizedMag < 0.5) {
          // Degradado de azul a verde
          float t = map(normalizedMag, 0.0, 0.5, 0.0, 1.0);
          this.particleColor[0] = lerp(red(lowColor), red(midColor), t);
          this.particleColor[1] = lerp(green(lowColor), green(midColor), t);
          this.particleColor[2] = lerp(blue(lowColor), blue(midColor), t);
      } else {
          // Degradado de verde a rojo
          float t = map(normalizedMag, 0.5, 1.0, 0.0, 1.0);
          this.particleColor[0] = lerp(red(midColor), red(highColor), t);
          this.particleColor[1] = lerp(green(midColor), green(highColor), t);
          this.particleColor[2] = lerp(blue(midColor), blue(highColor), t);
      }
      // Asigna la transparencia basada en la magnitud
      this.particleColor[3] = map(mag, minMag, maxMag, 0, 240);  // Alpha
  }
}

// Clase para partículas
//==============================================================================




//============================================================================== INCOMPLETO
// Zoom - Scale
/*
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  float scaleK = 0.2;
  if((xscale - e * scaleK) > 0 && (xscale - e * scaleK) > xscaleMax){
    xscale -= e * scaleK;
  }
  
  if((yscale - e * scaleK) > 0 && (yscale - e * scaleK) > yscaleMax){
    yscale -= e * scaleK;
  }
}

void mouseDragged() {
  offX += (mouseX - pmouseX) / xscale;
  offY += (mouseY - pmouseY) / yscale;
  
  // Aplicar límites basados en la posición de la cámara y el tamaño del canvas
  offX = constrain(offX, -minX, maxX); // Limitar el desplazamiento horizontal
  offY = constrain(offY, -minY, maxY); // Limitar el desplazamiento vertical
  translate(offX, offY);
}
*/
// Zoom - Scale - End
//============================================================================== INCOMPLETO


//==============================================================================
// Zoom - Camara
// Método mouseWheel() - Controla el zoom utilizando la rueda del mouse
void mouseWheel(MouseEvent event) {
  float e = event.getCount(); // Obtiene la cantidad de desplazamiento de la rueda del mouse
  zoom -= e * 0.2; // Ajusta el nivel de zoom en función del desplazamiento
  zoom = constrain(zoom, minZoom, maxZoom); // Limita el zoom entre el nivel mínimo y máximo permitido
}

// Método mouseDragged() - Controla el desplazamiento de la vista al arrastrar el mouse
void mouseDragged() {
  offX += (mouseX - pmouseX) / zoom; // Actualiza el desplazamiento en X en función del movimiento del mouse y el nivel de zoom
  offY += (mouseY - pmouseY) / zoom; // Actualiza el desplazamiento en Y en función del movimiento del mouse y el nivel de zoom
  offX = constrain(offX, -minX, maxX); // Limita el desplazamiento en X entre los valores permitidos
  offY = constrain(offY, -minY, maxY); // Limita el desplazamiento en Y entre los valores permitidos
}
// Zoom - Camara
//==============================================================================



//==============================================================================
// Funciones Auxiliares

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

// Función para obtener la magnitud maxima y minima para la interpolación del degradado de colores
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
  // Generar cantidad n de particulas en lugar random del plano
  for(int i=0; i<n; i++){
    Nparticles[i]   = new Particle(random(width), random(height), 0, xscale, yscale );
  }
}
