/*  
  Análisis y Diseño de Algoritmos Avanzados
    Grupo 601
    José María Aguilera Méndez 
  
  Equipo 7 
    Miguel Ángel Pérez Ávila           A01369908
    Máximo Moisés Zamudio Chávez       A01772056
    Andrea Bahena Valdés               A01369019
  
  Graficación de corrientes de viento
    Este programa genera a partir de los datos recabados en un archivo JSON 
    una visualización global de las corrientes de viento. En el programa se 
    modifica el color de las corrientes según la intensidad de las mismas.
    
  Fecha de la última modificación
    24 de noviembre del 2024  (Andrea - Documentación)
  
*/


import processing.data.JSONObject;
import processing.data.JSONArray;
import org.gicentre.geomap.*;


/**********************  Variables globales (viento) ******************************************

  dataU, dataV           Arreglos JSON que almacenan las componentes u y v del vector de viento
  gridCols, gridRows     Columnas y filas de la lectura de datos (viene del JSON)
  xscale, yscale         Escala las partículas a las dimensiones de la pantalla
  xscaleMax, yscaleMax   Escala de zoom máximo (control del tamaño del grid)
  vectorField            Campo vectorial del viento (dirige el movimiento de las particulas)
  maxMag, minMag         Magnitud máxima y minima (normaliza las magnitudes y asigna los colores)

***********************************************************************************************/

JSONArray dataU;                 
JSONArray dataV;        
int gridCols = 360;      
int gridRows = 181; 

float xscale, yscale;          
float xscaleMax, yscaleMax;     

PVector[][] vectorField;   
                            
float maxMag, minMag;     


/**********************  Variables globales (mapa) *******************************************

  geoMap                       Objeto que maneja el mapa
  earth                        Imagen del mapa del globo terráqueo
  offX, offY                   Desplazamiento en coordenadas x,y  (centrar la cámara)
  zoom                   
  minZoom, maxZoom             Rango para el zoom; independiente del grid
  minX, minY, maxX, maxY       Límites de desplazamiento del mapa
  particles                    Matriz de partículas para interpolación (interpolación)
  mapLayer                     Capa de gráficos

***********************************************************************************************/

GeoMap geoMap;
PImage earth;                 
float offX, offY;             
float zoom = 1;              
float minZoom = 1;            
float maxZoom = 5;            
float minX, minY, maxX,maxY;  
Particle[][] particles;      
PGraphics mapLayer;            


/**********************************************************************************************
  setup() - Inicialización de la ventana 
                Configurar el tamaño de la ventana (1)
                Calcular escalas y desplazamientos (2)
                Cargar la imagen del mapa          (3)
                Cargar el archivo JSON             (4)
                Inicializar los campos vectoriales (5)
                Inicializar las partículas         (6)
                Calcular las magnitudes máximas
                y mínimas                          (7)
**********************************************************************************************/


void setup() {
  
  size(1600, 800);                               // (1)
  
  
  xscale = ((float) width / gridCols);           // (2)
  yscale = ((float) height / gridRows);
  xscaleMax = xscale;
  yscaleMax = yscale;
  offX = width / 2;
  offY = height / 2;
  
  geoMap = new GeoMap(this);                     // (3)
  geoMap.readFile("world");  
  earth = loadImage("test1.png");
  earth.resize(width, height);
  
  
                                                  // (4)
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);
  dataU = uComponent.getJSONArray("data");
  dataV = vComponent.getJSONArray("data");
  
  
                                                 // (5), (6)
  vectorField = new PVector[gridRows][gridCols];    
  particles = new Particle[gridRows][gridCols];     
  
/*
  idx convierte las coordenadas (x,y) a un arreglo unidimensional (usado en el JSON)
  
  Para una matriz de 3 filas y 4 columnas (3x4), los índices serían:
      Para (x=0, y=0): idx = 0 + 0 * 4 = 0
      Para (x=1, y=1): idx = 1 + 1 * 4 = 5
      Para (x=3, y=2): idx = 3 + 2 * 4 = 11

*/

  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + (y * gridCols);
      if (idx < dataU.size() && idx < dataV.size()) {
        float u = dataU.getFloat(idx);
        float v = dataV.getFloat(idx);
        vectorField[y][x] = new PVector(u, v);
        particles[y][x]   = new Particle(x*xscale, y*yscale, vectorField[y][x].mag()*0.09, vectorField[y][x].mag(), xscale, yscale);
      }
    }
  }
                                                // (7)
  
  float[] MaxMin = getMinMaxMagnitude( vectorField , gridRows, gridCols);
  minMag = MaxMin[0];
  maxMag = MaxMin[1];
  
  
  
  
  mapLayer = createGraphics(width, height);
  frameRate(40);   // Tasa de actualización
  
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

/*******************************************************************************************

  draw()  -  Renderizado continuo
               Restricciones de cámara         (1)
               Aplicar traslaciones            (2)
               Dibujar las partículas          (3)
               Actualizarlas                   (4)
               Renderizar la capa y el mapa    (5)
    
********************************************************************************************/

void draw(){
                                                // (1)  
  offX = constrain(offX, minX, maxX);
  offY = constrain(offY, minY, maxY);

                                                // (2)
  translate(offX, offY);
  mapLayer.beginDraw();                         // (5)
  mapLayer.noStroke();
  mapLayer.fill(80,25); 
  mapLayer.rect(0, 0, width, height);
                                                
                                                // (3)
  for (int i=0; i< particles.length; i++){
    for (int j=0; j< particles[0].length; j++){
      particles[i][j].follow();
      particles[i][j].update();
      particles[i][j].show(mapLayer);
      particles[i][j].edges();
      particles[i][j].checkLifespan();         // (4)
    }
  }

  mapLayer.endDraw();                          // (5)
  image(earth, 0, 0);
  image(mapLayer, 0, 0);
  
}

/****************************************************************************************

  interpolateBilinear(float x, float y) - Interpolación bilineal (dirección del viento)
  
        Parámetros:
          x: Coordenada x del punto a interpolar
          y: Coordenada y del punto a interpolar
          
          
        Retorno:
          PVector: Vector interpolado con la dirección del viento
          
          
         Fuente de infromación:  bilinear interpolation using java. (n.d.).Stack Overflow.
                                 https://stackoverflow.com/questions/
                                 32032872/bilinear-interpolation-using-java
                  
******************************************************************************************/


PVector interpolateBilinear(float x, float y) {
  int x0 = floor(x / xscale);
  int y0 = floor(y / yscale);
  int x1 = x0 + 1;
  int y1 = y0 + 1;

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


/********************************* Clase Particle ********************************************

  Clase para las partículas que generan la visualización de las corrientes de viento
  
  Atributos
    pos0                     Posición inicial de la partícula
    x0, y0                   Coordenadas iniciales (reposicionar la partícula al reiniciar)
    xscale0, yscale0         Escalas iniciales (calcular la posición después de hacer el zoom)
    pos                      Posición actual
    vel                      Velocidad
    acc                      Aceleración 
    maxSpeed                 Velocidad máxima permitida
    birthTime                Momento en el que la partícula nació
    lifespan                 Tiempo de vida
    particleColor            Valores RGBA para el color
  
  Métodos
    update()                 Actualizar la posición de la partícula
    show()                   Dibujar la partícula en la capa gráfica
    edges()                  Manejar el comportamiento en los bordes
    follow()                 Aplicar el campo vectorial a la partícula
    checkLifespan()          Controlar el ciclo de vida de la partícula
    
**********************************************************************************************/

class Particle {
  PVector pos0;
  float x0, y0, xscale0, yscale0;
  PVector pos;
  PVector vel;
  PVector acc;
  float maxSpeed = 2;
  float birthTime; 
  float lifespan; 
  float[] particleColor;

  Particle(float x, float y, float lifespan, float mag, float xscale_,float yscale_) {
    
    this.x0 = x;
    this.y0 = y;
    this.xscale0 = xscale_;
    this.yscale0 = yscale_;
    this.pos = new PVector(x, y);
    this.vel = new PVector();
    this.acc = new PVector();
    this.lifespan = lifespan;
    this.birthTime = millis() / 1000.0; // Guardar el tiempo inicial en segundos
    
    this.particleColor = new float[4];

 // Normalizar la magnitud en un rango entre 0 y 1
    float normalizedMag;
    if (maxMag != minMag) {
      normalizedMag = map(mag, minMag, maxMag, 0.0, 1.0);
    } else {
        normalizedMag = 0; // O algún valor por defecto
    }
    
    // Determina el color basado en la magnitud
    if (normalizedMag > 0.95) {        // Magnitud Alta -. Rojo
        this.particleColor[0] = 255;  
        this.particleColor[1] = 0;    
        this.particleColor[2] = 0;    
    } else if (normalizedMag > 0.33) {  // Magnitud Media - Verde
        this.particleColor[0] = 0;   
        this.particleColor[1] = 255; 
        this.particleColor[2] = 0;   
    } else {                            // Magnitud Baja - Azul
        this.particleColor[0] = 0;   
        this.particleColor[1] = 0;   
        this.particleColor[2] = 255;  
    }
    
 
 
 // Asignar transparencia basada en la magnitud
    if (maxMag != minMag) {
      this.particleColor[3] = map(mag, minMag, maxMag, 100.0, 255.0);
    } else {
      this.particleColor[3] = 0;
    }
    
  }

  // Actualizar la posición de la partícula
  void update() {
    this.vel.add(acc);
    this.vel.limit(maxSpeed);
    this.pos.add(vel);
    this.acc.mult(0);
  }

  
  // Dibujar la partícula en la capa de gráficos  
  void show(PGraphics pg) {
    pg.stroke(this.particleColor[0], this.particleColor[1], this.particleColor[2], this.particleColor[3]); // Color semitransparente
    pg.strokeWeight(1.8);
    pg.point(this.pos.x, this.pos.y);
  }
  
  // Reaparecer en los bordes
  void edges() {
    if (this.pos.x > width) this.pos.x = 0;
    if (this.pos.x < 0) this.pos.x = width;
    if (this.pos.y > height) this.pos.y = 0;
    if (this.pos.y < 0) this.pos.y = height;
  }

  
  // Seguir el campo vectorial con la interpolación bilineal
  void follow() {
    PVector force = interpolateBilinear(this.pos.x, this.pos.y);
    this.acc.add(force);
    
  
  // Normalizar la magnitud en un rango entre 0 y 1
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
    
    // Asignar transparencia basada en la magnitud
    this.particleColor[3] = map(force.mag(), minMag, maxMag, 50, 255.0);  // Alpha
  }

  // Verificar el tiempo de vida de la partícula y reiniciarla si es necesario
  
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos
    if (currentTime - this.birthTime > this.lifespan) {
      // Reiniciar partícula
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
      
      this.pos = new PVector(newposx, newposy);
      this.vel.set(0, 0);
      this.acc.set(0, 0);
      this.birthTime = currentTime; // Reiniciar el tiempo de vida
    }
  }
} 

/******************************************************************************************
  
  mouseWheel(MouseEvent event) - Manejar el zoom leyendo los eventos del mouse o trackpad
  
            Parámetros:
            
              event: Evento que contiene la información para el desplazamiento
            
******************************************************************************************/

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
 
 
/*******************************************************************************************
  mouseDragged()  -  Manejar el desplazamiento en el mapa al arrastrar
    
                       Actualiza offX y offY respetando las restricciones
                       de los límites
*******************************************************************************************/


void mouseDragged() {
  offX += (mouseX - pmouseX) / zoom;
  offY += (mouseY - pmouseY) / zoom;
  // Aplicar límites basados en la posición de la cámara y el tamaño del canvas
  offX = constrain(offX, -minX, maxX); // Limitar el desplazamiento horizontal
  offY = constrain(offY, -minY, maxY); // Limitar el desplazamiento vertical
}

/*******************************************************************************************

  getMinMaxMagnitude(PVector[][] vectorField, int cols, int rows) - Calcula las magnitudes
                                                                    máxima y mínima del campo
                                                                    vectorial  
                                                                        
          Parámetros:
            vectorField: Campo vectorial a analizar
            cols, rows:  Dimensiones del campo
            
            
          Retorno:
            float[]: [magnitud mínima, magnitud máxima]
    
            
*******************************************************************************************/

float[] getMinMaxMagnitude(PVector[][] vectorField, int cols, int rows) {
  
  float maxMagnitude = 0;                      // Inicia con el valor más pequeño posible
  float minMagnitude = 0;                      // Inicia con el valor más grande posible

  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      float magnitude = vectorField[x][y].mag();        // Calcula la magnitud del vector
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;                      // Actualiza el máximo si es mayor
      }
      if (magnitude < minMagnitude) {
        minMagnitude = magnitude;                      // Actualiza el mínimo si es menor
      }
    }
  }
  float[] out = new float[2];
  out[0] = minMagnitude;
  out[1] = maxMagnitude;
  
  return out;                                          
}
  
