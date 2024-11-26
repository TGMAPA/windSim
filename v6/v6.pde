/*
Fecha: 25/11/2024
--Algoritmos Avanzados 

  Miguel Ángel Pérez Ávila A01369908
  Máximo Moisés Zamudio Chávez A01772056
  Andrea Bahena Valdés A01369019
  
  v6 - Particulas dibujadas como puintos con degradado | Mapa reiniciado cada dt
  
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

PGraphics mapLayer; // Capa de dibujo para particulas
int lastClearTime = 0; 
int clearInterval = 60;

// Método setup() - Configuración inicial del programa
void setup() {
  
  size(1600, 800); // Configura el tamaño de la ventana
  
  offX = width / 2; // Inicializa la posición de desplazamiento en X
  offY = height / 2; // Inicializa la posición de desplazamiento en Y

  xscale = ((float) width / gridCols); // Calcula la escala en X para mapear la cuadrícula
  yscale = ((float) height / gridRows); // Calcula la escala en Y para mapear la cuadrícula
  xscaleMax = xscale; // Escala máxima en X
  yscaleMax = yscale; // Escala máxima en Y
  
  offX = width / 2; // Recalcula la posición de desplazamiento en X
  offY = height / 2; // Recalcula la posición de desplazamiento en Y
     
  earth = loadImage("test1.jpg"); // Carga la imagen de fondo
  earth.resize(width, height); // Ajusta la imagen al tamaño de la ventana
  
  // Carga y parsea los datos del archivo JSON
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);
  
  // Leer componentes U y V del campo de viento
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);
  dataU = uComponent.getJSONArray("data");
  dataV = vComponent.getJSONArray("data");
  
  vectorField = new PVector[gridRows][gridCols]; // Inicializa el campo vectorial
  // Bandera para activar la generación de particulas con cantidad N o de acuerdo con el campo vectorial
  generatewithNparticles = false;
  
  if(!generatewithNparticles){
    // Generación de particulas de acuerdo con matriz de vectores
    generateParticle2Matrix();
  }else{
    // Generación de N particulas
    generateNParticle(9000);
  }
  
  
  mapLayer = createGraphics(width, height); // Crea una capa gráfica para dibujar
  
  frameRate(30); // Configura la velocidad de fotogramas
  
  // Mensajes informativos en la consola
  println("Inicialización finalizada...");
  println("MagMax       : " + maxMag);
  println("MinMax       : " + minMag);
  println("Cols         : " + gridCols);
  println("Rows         : " + gridRows);
  println("Screen_Widht : " + width);
  println("Screen_Height: " + height);
  println("XScale        : "+ xscale);
  println("YScale        : "+ yscale);
}  
// SETUP
//==============================================================================


// Método draw() - Ciclo principal del programa
void draw() {
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
  
  image(earth, 0, 0); // Dibuja la imagen de fondo
  
  int currentTime = frameCount; // Tiempo actual en fotogramas
  if (currentTime - lastClearTime >= clearInterval) { // Limpieza periódica de la capa gráfica
    mapLayer.clear(); // Limpia el contenido anterior
    mapLayer.fill(0,0); // Aplica un color transparente
    image(earth,0,0); // Redibuja la imagen de fondo
    lastClearTime = currentTime; // Actualiza el último tiempo de limpieza
  }
  
  mapLayer.beginDraw(); // Comienza a dibujar en la capa gráfica
  mapLayer.noStroke(); // Sin bordes
  mapLayer.fill(0,3); // Fondo semitransparente para la capa gráfica
  mapLayer.rect(0, 0, width, height); // Dibuja un rectángulo para la persistencia visual
  
  // Actualización de particulas de acuerdo con matriz de vectores
  if(!generatewithNparticles){
    for (int i=0; i< particles.length; i++){
      for (int j=0; j< particles[0].length; j++){
        particles[i][j].follow(); // Actualiza la dirección según el campo vectorial
        particles[i][j].update(); // Actualiza la posición
        particles[i][j].show(mapLayer); // Dibuja la partícula
        particles[i][j].edges(); // Maneja los bordes del lienzo
        particles[i][j].checkLifespan(); // Verifica el tiempo de vida
      }
    }
  }else{
    // Actualización de N particulas
    for( int i=0; i< Nparticles.length; i++ ){
      Nparticles[i].follow(); // Actualiza la dirección según el campo vectorial
      Nparticles[i].update(); // Actualiza la posición
      Nparticles[i].show(mapLayer); // Dibuja la partícula
      Nparticles[i].edges(); // Maneja los bordes del lienzo
      Nparticles[i].checkLifespan(); // Verifica el tiempo de vida
    }
  }
  
  mapLayer.endDraw(); // Finaliza el dibujo en la capa gráfica
  image(mapLayer, 0, 0); // Dibuja la capa gráfica sobre la imagen de fondo
}


// Clase Particle
// Representa una partícula que sigue el flujo de viento en el campo vectorial.

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
// - Constructor: Inicializa la posición, velocidad, color y tiempo de vida de la partícula.
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

// - Método update(): Actualiza la posición y velocidad de la partícula.
  void update() {
    this.vel.add(acc);
    this.vel.limit(maxSpeed);
    this.pos.add(vel);
    this.acc.mult(0);
  }
  
// - Método show(): Dibuja la partícula en el mapa con un color y transparencia que depende de su magnitud.
void show(PGraphics pg) {
    pg.stroke(this.particleColor[0], this.particleColor[1], this.particleColor[2], this.particleColor[3]); 
    pg.strokeWeight(1.8);
    pg.point(this.pos.x, this.pos.y);
}

// - Método edges(): Hace que la partícula reaparezca al alcanzar los bordes del lienzo.
  void edges() {
    if (this.pos.x > width) this.pos.x = 0;
    if (this.pos.x < 0) this.pos.x = width;
    if (this.pos.y > height) this.pos.y = 0;
    if (this.pos.y < 0) this.pos.y = height;
  }
  
// - Método follow(): Actualiza la aceleración de la partícula siguiendo la dirección del vector de viento.
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
    this.particleColor[3] = map(force.mag(), minMag, maxMag, 0, 255.0);  // Alpha
  }

// - Método checkLifespan(): Verifica el tiempo de vida de la partícula y la reinicia si ha expirado.
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos
    if (currentTime - this.birthTime > this.lifespan) {
      //float newposx = random(width);
      //float newposy = random(height);
      float newposx =  this.x0*xscale/this.xscale0;
      float newposy =   this.y0*yscale/this.yscale0;
      /*
      float newposx = 0;
      float newposy = 0;
      if(this.x0*xscale/this.xscale0 > xscale || this.x0*xscale/this.xscale0 < 0){
        newposx =  this.x0*xscale/this.xscale0;
      }else{
        newposx = random(width);
      }
      
      if(this.y0*yscale/this.yscale0 > yscale || this.y0*yscale/this.yscale0 < 0){
        newposy =   this.y0*yscale/this.yscale0;
      }else{
        newposy = random(height);
      }
      */
      this.pos = new PVector(newposx, newposy);
      this.vel.set(0, 0);
      this.acc.set(0, 0);
      this.birthTime = currentTime; // Reiniciar tiempo de vida
    }
  }
  
}

//==============================================================================
// Zoom - Scale
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

// Zoom - Scale - End
//==============================================================================




// Método interpolateBilinear() - Interpolación bilineal
// Calcula la dirección del viento en una posición específica basada en los valores de los puntos más cercanos
// en la cuadrícula, utilizando interpolación bilineal para suavizar las transiciones.

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
        particles[y][x]   = new Particle(x * xscale, y * yscale, vectorField[y][x].mag() * 0.09, xscale, yscale);
      }
    }
  }
  // Obtiene los valores mínimos y máximos de la magnitud del viento
  float[] MaxMin = getMinMaxMagnitude(vectorField, gridRows, gridCols);
  minMag = MaxMin[0]; // Magnitud mínima
  maxMag = MaxMin[1]; // Magnitud máxima
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
  // Obtiene los valores mínimos y máximos de la magnitud del viento
  float[] MaxMin = getMinMaxMagnitude(vectorField, gridRows, gridCols);
  minMag = MaxMin[0]; // Magnitud mínima
  maxMag = MaxMin[1]; // Magnitud máxima
  
  // Generar cantidad n de particulas en lugar random del plano
  for(int i=0; i<n; i++){
    Nparticles[i]   = new Particle(random(width), random(height), random(minMag, maxMag), xscale, yscale );
  }
}
