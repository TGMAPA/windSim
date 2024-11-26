/*
Fecha: 25/11/2024
--Algoritmos Avanzados 

  Miguel Ángel Pérez Ávila A01369908
  Máximo Moisés Zamudio Chávez A01772056
  Andrea Bahena Valdés A01369019
  
  v1 - primer interpolación con vectores negros sin glujo

*/


import processing.data.JSONObject; // Permite manejar objetos JSON.
import processing.data.JSONArray;  // Permite manejar arreglos JSON.

JSONArray dataU;  // Almacena el componente U del viento.
JSONArray dataV;  // Almacena el componente V del viento.
int gridCols = 360; // Número de columnas en la matriz del JSON.
int gridRows = 181; // Número de filas en la matriz del JSON.
float scale = 4;    // Escala para graficar vectores (espaciado y longitud).
PVector[][] vectorField; // Matriz bidimensional de vectores del campo de viento.


void setup() {
  size(1200, 600); // Define el tamaño de la ventana de visualización.
  
  // Cargar y procesar el archivo JSON
  String jsonString = join(loadStrings("current-wind-surface-level-gfs-1.0.json"), ""); // Carga el archivo JSON como una cadena.
  JSONArray json = JSONArray.parse(jsonString); // Convierte la cadena JSON en un objeto JSONArray.
  
  // Leer componentes U y V del viento desde el JSON
  JSONObject uComponent = json.getJSONObject(0); // Obtiene el primer objeto (componente U).
  JSONObject vComponent = json.getJSONObject(1); // Obtiene el segundo objeto (componente V).
  dataU = uComponent.getJSONArray("data");       // Extrae el arreglo de datos del componente U.
  dataV = vComponent.getJSONArray("data");       // Extrae el arreglo de datos del componente V.
  
  vectorField = new PVector[gridRows][gridCols]; // Inicializa la matriz bidimensional de vectores.
  
  // Llena la matriz de vectores con datos del JSON
  for (int y = 0; y < gridRows; y++) {
    for (int x = 0; x < gridCols; x++) {
      int idx = x + y * gridCols; // Índice lineal en el arreglo JSON.
      if (idx < dataU.size() && idx < dataV.size()) { // Verifica que el índice sea válido.
        float u = dataU.getFloat(idx); // Obtiene el valor del componente U.
        float v = dataV.getFloat(idx); // Obtiene el valor del componente V.
        vectorField[y][x] = new PVector(u, v); // Crea un vector con los componentes U y V.
      }
    }
  }
  
  frameRate(30); // Configura la velocidad de fotogramas por segundo.
  println("Rows : " + vectorField.length); // Muestra el número de filas.
  println("Cols : " + vectorField[0].length); // Muestra el número de columnas.
}


void draw() {
  background(255); // Limpia el fondo con color blanco.
  stroke(0); // Configura el color del borde en negro.
  translate(40, height - 40); // Mueve el origen al margen inferior izquierdo.
  scale(1, -1); // Invierte el eje Y para que el gráfico crezca hacia arriba.

  // Dibuja los vectores del campo
  for (int y = 0; y < gridRows - 1; y++) {
    for (int x = 0; x < gridCols - 1; x++) {
      PVector interpolated = interpolateBilinear(y, x); // Calcula un vector interpolado.
      
      // Coordenadas escaladas para graficar el vector
      float xPos = x * scale; 
      float yPos = y * scale; 
      drawVector(interpolated, xPos, yPos); // Dibuja el vector interpolado.
    }
  }
}


PVector interpolateBilinear(int x, int y) {
  // Vectores de las cuatro esquinas de la celda
  PVector v00 = vectorField[x][y];
  PVector v10 = vectorField[x + 1][y];
  PVector v01 = vectorField[x][y + 1];
  PVector v11 = vectorField[x + 1][y + 1];

  // Factores de interpolación basados en el tiempo
  float tx = (frameCount % gridCols) / float(gridCols); // Factor horizontal.
  float ty = (frameCount % gridRows) / float(gridRows); // Factor vertical.

  // Interpolación horizontal entre vectores
  PVector a = PVector.lerp(v00, v10, tx);
  PVector b = PVector.lerp(v01, v11, tx);

  // Interpolación vertical entre los resultados
  return PVector.lerp(a, b, ty);
}


void drawVector(PVector vec, float x, float y) {
  stroke(0); // Color del borde del vector.
  pushMatrix(); // Guarda el estado actual de la transformación.
  translate(x, y); // Traslada al punto de inicio del vector.
  line(0, 0, vec.x * scale, vec.y * scale); // Dibuja el vector como una línea.
  popMatrix(); // Restaura el estado anterior de la transformación.
}


class Particle {
  PVector pos; // Posición de la partícula.
  PVector vel; // Velocidad de la partícula.
  PVector acc; // Aceleración de la partícula.
  float maxSpeed = 2; // Velocidad máxima permitida.

  Particle(float x, float y) {
    pos = new PVector(x, y); // Inicializa la posición.
    vel = new PVector(0, 0); // Inicializa la velocidad.
    acc = new PVector(0, 0); // Inicializa la aceleración.
  }

  void follow(PVector[][] field) {
    int x = int(pos.x / scale); // Calcula la posición en la matriz.
    int y = int(pos.y / scale);

    x = constrain(x, 0, gridCols - 1); // Constriñe a los límites del campo.
    y = constrain(y, 0, gridRows - 1);

    PVector force = field[x][y]; // Obtiene la fuerza del campo en esa posición.
    acc.add(force); // Suma la fuerza a la aceleración.
  }

  void update() {
    vel.add(acc); // Actualiza la velocidad con la aceleración.
    vel.limit(maxSpeed); // Limita la velocidad máxima.
    pos.add(vel); // Actualiza la posición con la velocidad.
    acc.mult(0); // Resetea la aceleración.
  }

  void show() {
    stroke(255, 150); // Color y transparencia.
    strokeWeight(2); // Grosor del punto.
    point(pos.x, pos.y); // Dibuja la partícula.
  }

  void edges() {
    // Envuelve la partícula al cruzar los bordes de la pantalla.
    if (pos.x > width) pos.x = 0;
    if (pos.x < 0) pos.x = width;
    if (pos.y > height) pos.y = 0;
    if (pos.y < 0) pos.y = height;
  }
}
