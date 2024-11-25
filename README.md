# Graficación de Corrientes de Viento 

## Descripción General
Se trata de un sistema de graficación de corrientes de viento globales desarrollado en Processing. El software genera una representación visual interactiva de corrientes de viento utilizando datos meteorológicos almacenados en un formato JSON, empleando un sistema de partículas y vectores para su visualización.

Este proyecto supone una alternativa a las herramientas de visualización de datos meteorológicos como Google Earth, permitiendo una visualización dinámica e interactiva de los patrones de viento.

Los datos de viento se obtuvieron del sistema de pronóstico de viento de US National Weather Service - NCEP(WMC), mismos que se encontraban almmacenados en un archivo JSON.

Es escalable para visualizar distintas corrientes, por ejemplo corrientes marítimas. La base e inspiración de este proyecto fue el proyecto https://earth.nullschool.net/#current/wind/surface/level/equirectangular=-90.00,0.00,120/loc=-133.014,-52.877.

|
## Desarrollado por
**Equipo 7 - Análisis y Diseño de Algoritmos Avanzados (Grupo 601)**
- Miguel Ángel Pérez Ávila           A01369908
- Máximo Moisés Zamudio Chávez       A01772056
- Andrea Bahena Valdés               A01369019

## Características Técnicas

### Sistema de Visualización
- **Grid de Datos**: 
  - Columnas: 360
  - Filas: 181
  Las dimensiones del grid de datos fueron dadas en el archivo JSON.

- **Campo Vectorial**: Matriz de vectores PVector para dirección del viento
    Es necesario para generar la interpolación bilineal, que simula el movimiento de las partículas.

- **Sistema de Partículas**: Matriz dinámica de partículas con ciclo de vida
- **Mapa Base**: Imagen del globo terráqueo con superposición de corrientes

### Sistema de Colores
Codificación dinámica basada en la magnitud normalizada del viento:
- **Rojo (255, 0, 0)**: Vientos de alta intensidad (> 0.55)
- **Verde (30, 200, 39)**: Vientos moderados (> 0.10)
- **Verde Claro (139, 205, 143)**: Vientos moderados-bajos (> 0.2)
- **Azul (0, 0, 255)**: Vientos suaves (< 0.10)
 El proyecto original utilizaba un esquema de colores ligeramente distinto, puesto que también inetgraba otros sistemas de lectura de corrientes. 

### Componentes Principales

#### Variables Globales
- **Datos de Viento**: 
  - `dataU`: Componente U del vector de viento
  - `dataV`: Componente V del vector de viento
- **Escalado**: 
  - `xscale`, `yscale`: Escalas para ajuste a pantalla
  - `xscaleMax`, `yscaleMax`: Límites de zoom

#### Sistema de Partículas
Cada partícula contiene:
- Posición inicial y actual
- Velocidad y aceleración
- Tiempo de vida
- Color dinámico basado en magnitud

## Requisitos del Sistema

### Software Requerido
- Processing 3.0 o superior
- Java Runtime Environment (JRE)
- Bibliotecas Processing:
  - GeoMap (https://www.gicentre.net/geomap)
  - processing.data.*
  Las bibliotecas GeoMap y processing.data.* se encuentran en el repositorio.

## Instalación y Configuración

1. Clonar el repositorio
2. Estructura de archivos necesaria:
```bash
proyecto/
├── test3interpolacionpvectorparticlezoom.pde
├── data/
│   ├── current-wind-surface-level-gfs-1.0.json
│   ├── test1.png
│   └── world
```

3. Configuración de bibliotecas:
   - Abrir Processing
   - Sketch -> Import Library -> Add Library
   - Instalar GeoMap
   En caso de no encontrar la biblioteca, se puede agregar la ruta al archivo en el directorio de bibliotecas de Processing.

## Uso del Sistema

### Controles de Usuario
- **Zoom**: Rueda del ratón, o trackpad 
  - Ajusta `xscale` y `yscale` manteniendo proporciones
- **Navegación**: Clic y arrastre
  - Actualiza `offX` y `offY` para el desplazamiento

### Visualización
- Tasa de actualización: 40 FPS
- Renderizado en capas separadas para optimización
- Sistema de partículas con ciclo de vida automático

## Detalles Técnicos

### Interpolación
El sistema utiliza interpolación bilineal para:
- Suavizar el movimiento de partículas
- Calcular vectores de viento entre puntos de datos
- Mejorar la precisión visual de la simulación

### Optimizaciones
- Uso de PGraphics para capa de renderizado independiente
- Sistema de ciclo de vida para gestión de partículas
- Restricciones de movimiento para mantener visualización coherente

## Posibles Mejoras
- Implementar un sistema de lectura de datos de corrientes marítimas y fusionarlos con los datos de viento
- Lectura de datos en tiempo real para usuarios del mundo entero
- Diferentes visualizaciones (tipo esférica)

## Estado del Proyecto
- Última actualización: 24 de noviembre del 2024
- Versión: 1.0
- Estado: Funcional para uso educativo

## Agradecimientos
- Al equipo de trabajo por toda su dedicación y esfuerzo, por toda su paciencia y comprensión
- Al profesor José María Aguilera Méndez por haber despertado una vez más el amor por la programación
- A Daniel Shiffman por haber desarrollado Processing, un software lleno de posibilidades, intuitivo y con una comunidad de apoyo excepcional


## Referencias
- Documentación de Processing
- Stack Overflow: "bilinear interpolation using java"
- earth/public at master · cambecc/earth. (n.d.). GitHub. https://github.com/cambecc/earth/tree/master/public
- Processing Hour of Code | Home. (n.d.). https://hello.processing.org/
- The coding train. (2018, July 31). https://thecodingtrain.com/


## Notas de Desarrollo
Este proyecto fue desarrollado como parte del curso de Análisis y Diseño de Algoritmos Avanzados, como parte del proyecto de la evaluación final
