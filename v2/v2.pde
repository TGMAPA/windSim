/*
Fecha: 25/11/2024
--Algoritmos Avanzados 

  Miguel Ángel Pérez Ávila A01369908
  Máximo Moisés Zamudio Chávez A01772056
  Andrea Bahena Valdés A01369019
  
  v2 - Implementación de interpolación con animación de particulas en forma de puntos y mapa erroneo
*/


// Importa las clases necesarias para manejar JSON y mapas geográficos.
import processing.data.JSONObject;
import processing.data.JSONArray;
import org.gicentre.geomap.*;

// Declaración de variables globales para almacenar componentes vectoriales del viento.
JSONArray dataU; // Componente U del viento (dirección horizontal).
JSONArray dataV; // Componente V del viento (dirección vertical).
int gridCols = 360; // Número de columnas en el grid del campo vectorial.
int gridRows = 181; // Número de filas en el grid del campo vectorial.
float scale = 4;    // Escala para graficar vectores en la visualización.
PVector[][] vectorField; // Arreglo bidimensional que contiene los vectores del viento.

GeoMap geoMap; // Objeto para manejar mapas geográficos (shapefiles).

Particle[][] particles; // Arreglo bidimensional para las partículas que siguen el flujo del viento.
PGraphics trailLayer;    // Capa gráfica para almacenar las estelas de las partículas.
PGraphics mapLayer;      // Capa gráfica para renderizar el mapa base.

void setup() {
  size(1200, 600); // Define el tamaño de la ventana gráfica.

  // Inicializa el objeto GeoMap y carga un shapefile con los contornos del mapa mundial.
  geoMap = new GeoMap(this);
  geoMap.readFile("world");

  // Carga y parsea el archivo JSON que contiene los datos del viento.
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), "");
  JSONArray json = JSONArray.parse(jsonString);

  // Extrae los componentes U y V del archivo JSON.
  JSONObject uComponent = json.getJSONObject(0);
  JSONObject vComponent = json.getJSONObject(1);

  dataU = uComponent.getJSONArray("data"); // Datos del componente U.
  dataV = vComponent.getJSONArray("data"); // Datos del componente V.

  // Inicializa el campo vectorial y las partículas.
  vectorField = new PVector[gridRows][gridCols];
  particles = new Particle[gridRows][gridCols];

  // Llena el campo vectorial y crea partículas para cada celda del grid.
  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + y * gridCols; // Calcula el índice lineal para acceder a los datos JSON.
      if (idx < dataU.size() && idx < dataV.size()) {
        float u = dataU.getFloat(idx); // Componente U en la celda (x, y).
        float v = dataV.getFloat(idx); // Componente V en la celda (x, y).
        vectorField[y][x] = new PVector(u, v); // Crea un vector con U y V.
        particles[y][x] = new Particle(random(width), random(height), vectorField[y][x].mag() * 0.1, vectorField[y][x].mag()); // Genera una partícula inicial.
      }
    }
  }

  // Crea una capa gráfica para almacenar el mapa.
  mapLayer = createGraphics(width, height);

  frameRate(30); // Define la tasa de refresco en 30 cuadros por segundo.
}

void draw() {
  // Configura y limpia la capa gráfica para el mapa.
  mapLayer.beginDraw();
  mapLayer.noStroke();
  mapLayer.fill(255, 30);
  mapLayer.background(202, 226, 245, 20); // Fondo semitransparente para las estelas.
  mapLayer.rect(0, 0, width, height);

  // Actualiza y dibuja cada partícula.
  for (int i = 0; i < particles.length; i++) {
    for (int j = 0; j < particles[0].length; j++) {
      particles[i][j].follow();   // Las partículas siguen el flujo del viento.
      particles[i][j].update();             // Actualiza su posición.
      particles[i][j].show(mapLayer);       // Dibuja la partícula en la capa.
      particles[i][j].edges();              // Reaparece en los bordes si sale del canvas.
      particles[i][j].checkLifespan();      // Verifica y reinicia partículas al final de su vida útil.
    }
  }

  // Dibuja el mapa geográfico en la capa gráfica.
  fill(206, 173, 146, 50);
  geoMap.draw();

  mapLayer.endDraw();

  // Renderiza la capa gráfica del mapa sobre el canvas principal.
  image(mapLayer, 0, 0);
}

// Interpolación bilineal para obtener un vector del viento en coordenadas específicas.
PVector interpolateBilinear(float x, float y) {
  int x0 = floor(x / scale);
  int y0 = floor(y / scale);
  int x1 = x0 + 1;
  int y1 = y0 + 1;

  // Restringe las coordenadas a los límites del grid.
  x0 = constrain(x0, 0, gridCols - 1);
  y0 = constrain(y0, 0, gridRows - 1);
  x1 = constrain(x1, 0, gridCols - 1);
  y1 = constrain(y1, 0, gridRows - 1);

  float tx = (x / scale) - x0;
  float ty = (y / scale) - y0;

  // Interpola entre los vectores de las esquinas.
  PVector v00 = vectorField[y0][x0];
  PVector v10 = vectorField[y0][x1];
  PVector v01 = vectorField[y1][x0];
  PVector v11 = vectorField[y1][x1];

  PVector a = PVector.lerp(v00, v10, tx);
  PVector b = PVector.lerp(v01, v11, tx);
  return PVector.lerp(a, b, ty);
}


// Clase que representa una partícula que sigue el flujo del viento.
class Particle {
  PVector pos;       // Posición actual de la partícula.
  PVector vel;       // Velocidad de la partícula.
  PVector acc;       // Aceleración de la partícula.
  float maxSpeed = 2; // Velocidad máxima permitida para la partícula.
  float birthTime;    // Tiempo en el que la partícula fue creada (en segundos).
  float lifespan;     // Tiempo de vida útil de la partícula (en segundos).
  boolean alive;      // Indicador para saber si la partícula sigue activa.
  float[] particleColor; // Arreglo para almacenar los valores RGBA del color de la partícula.

  // Constructor de la clase Particle.
  // Inicializa la posición, velocidad, aceleración, tiempo de vida y color de la partícula.
  Particle(float x, float y, float lifespan, float mag) {
    pos = new PVector(x, y); // Posición inicial de la partícula.
    vel = new PVector();     // Velocidad inicial (en reposo).
    acc = new PVector();     // Aceleración inicial (sin fuerza aplicada).
    this.lifespan = lifespan; // Tiempo de vida especificado.
    birthTime = millis() / 1000.0; // Registra el tiempo actual en segundos.

    // Asigna un color inicial a la partícula basado en la magnitud del vector del viento.
    this.particleColor = new float[4];
    particleColor[0] = 30; // Rojo.
    particleColor[1] = 174; // Verde.
    particleColor[2] = 39;  // Azul.
    particleColor[3] = map(mag, 1.0, 10.0, 150.0, 200.0); // Transparencia basada en magnitud.
  }

  // Actualiza la posición de la partícula basada en su velocidad y aceleración.
  void update() {
    vel.add(acc);         // Suma la aceleración a la velocidad.
    vel.limit(maxSpeed);  // Limita la velocidad al valor máximo permitido.
    pos.add(vel);         // Actualiza la posición sumando la velocidad.
    acc.mult(0);          // Resetea la aceleración después de aplicarla.
  }

  // Dibuja la partícula en una capa gráfica específica.
  void show(PGraphics pg) {
    pg.stroke(this.particleColor[0], this.particleColor[1], this.particleColor[2], this.particleColor[3]); // Define el color de la partícula.
    pg.strokeWeight(1.7); // Grosor del trazo para la partícula.
    pg.point(pos.x, pos.y); // Dibuja la partícula como un punto en su posición actual.
  }

  // Si la partícula sale del canvas, reaparece en el lado opuesto.
  void edges() {
    if (pos.x > width) pos.x = 0;     // Si sale por la derecha, reaparece en la izquierda.
    if (pos.x < 0) pos.x = width;    // Si sale por la izquierda, reaparece en la derecha.
    if (pos.y > height) pos.y = 0;   // Si sale por abajo, reaparece arriba.
    if (pos.y < 0) pos.y = height;   // Si sale por arriba, reaparece abajo.
  }

  // La partícula sigue el flujo del viento en función del campo vectorial.
  void follow() {
    PVector force = interpolateBilinear(pos.x, pos.y); // Calcula la dirección del viento mediante interpolación bilineal.
    acc.add(force); // Aplica la fuerza del viento como aceleración.
  }

  // Verifica si la partícula ha excedido su tiempo de vida y la reinicia si es necesario.
  void checkLifespan() {
    float currentTime = millis() / 1000.0; // Tiempo actual en segundos.
    if (currentTime - birthTime > lifespan) { // Si la partícula ha vivido más que su vida útil:
      pos.set(random(width), random(height)); // Reinicia su posición a un punto aleatorio.
      vel.set(0, 0);                          // Reinicia la velocidad a cero.
      acc.set(0, 0);                          // Reinicia la aceleración a cero.
      birthTime = currentTime;                // Reinicia su tiempo de vida.
    }
  }
}
