# Incorporación de la prueba completa con CODESYS manual

Este documento indica cómo incorporar la prueba al informe. El informe no se ha modificado.

## Ubicación y nombre

Crear una subsección en la sección de pruebas denominada **Prueba completa con CODESYS manual**. Presentarla separada de las pruebas de medio ciclo y de la prueba del autómata de seguridad. En el texto, los títulos y los pies de figura usar nombres de pruebas y de señales; no mencionar nombres de modelos, proyectos, scripts ni rutas.

## Qué explicar

1. Arquitectura del ensayo: supervisor y seguridad SFC en el PLC; planta, accionamientos, control de movimiento, sensores, contenedores, visualización y HMI en Simulink. Comunicación OPC UA cifrada y avance coordinado por tramas de 20 ms simulados.
2. Condiciones iniciales: PLC con Reset en caliente y RUN; carro en -26,34 m; altura nominal inicial 25 m; reposo, spreader vacío, perfil aún no válido y antisway habilitado.
3. Secuencia: relevamiento LiDAR, toma del centro del muelle, entrega en el centro del barco, desplazamiento vacío hacia el extremo derecho del barco, segunda toma, retorno al extremo izquierdo del muelle, apoyo, liberación y parada.
4. Validación física: dos tomas y dos entregas, cambio de una altura de contenedor en cada origen/destino y masa suspendida final correspondiente al spreader vacío.
5. Resultado del relevamiento y comparación entre perfil inicial, relevado y final.
6. Comportamiento dinámico: aceleración, velocidad y posición de ambos ejes; ángulo y velocidad angular del péndulo; torques de consigna y del motor, tensión del cable, masa suspendida y contribuciones del antisway.

## Tiempos de los eventos

| Evento | Tiempo simulado [s] |
|---|---:|
| Relevamiento validado | 130,08 |
| Contacto para la primera toma | 200,80 |
| Primera toma física confirmada | 203,68 |
| Primer apoyo en el barco | 315,80 |
| Primera liberación confirmada | 316,24 |
| Contacto para la segunda toma | 445,24 |
| Segunda toma física confirmada | 448,12 |
| Segundo apoyo en el muelle | 608,60 |
| Segunda liberación confirmada | 609,04 |
| Parada normal confirmada | 611,08 |

Estos tiempos corresponden a la telemetría del operador, con muestreo de 40 ms. Los archivos de señales conservan sus propias rejillas temporales; consultar la cobertura del registro antes de usar un valor puntual.

## Figuras

- Una gráfica por figura, con ejes y unidades legibles. No agrupar gráficas como subfiguras pequeñas.
- No añadir gráficas de códigos de modos de funcionamiento.
- Mostrar consignas y señales físicas en colores diferenciados, con límites de motor en las figuras de torque.
- Usar las figuras de aceleración de izaje en escala completa y con zoom vertical como dos figuras independientes. El zoom tiene recorte vertical deliberado; los picos se conservan en la figura de escala completa y en las señales originales.
- Las gráficas temporales de la corrida completa se presentan hasta el último apoyo, a los 608,60 s. Las señales guardadas incluyen la liberación y la parada posteriores.
- Incorporar las figuras del perfil inicial/relevado/final y del balance de alturas. Explicar las cuatro variaciones: origen de la primera toma y origen de la segunda toma bajan 2,59 m; sus destinos suben 2,59 m.
- Las capturas HMI del relevamiento, de los contactos, de las transferencias y del estado final pueden ir en un anexo. No se grabó video.

## Corrección necesaria para el barrido

Documentar como incidencia de preparación que el primer intento dejó el primer slot sin muestras. El barrido izquierdo se daba por terminado con un criterio basado en el carro que no garantizaba cubrir el extremo con el LiDAR desplazado 3,1 m. La corrección usa la posición del LiDAR para el cierre y extiende el objetivo de frenado del carro hacia la izquierda. La copia corrigió solamente esta condición del SFC y su función de velocidad de barrido, y compiló con cero errores y cero advertencias.

Después de repetir, el perfil quedó válido y el primer slot obtuvo 177 muestras. Separar el intento incompleto del ensayo completo; no contar ese primer intento como un transporte fallido de contenedor.

## Evidencia y límites

Usar los resultados finales de la corrida completa para cuantificar picos, errores y códigos de falla. Distinguir la recuperación inicial del enlace de la operación después de START. No deducir ausencia de colisiones del alarmero: su mensaje de colisión está oculto y no constituye una verificación geométrica. El éxito de una corrida no demuestra cobertura de todas las fallas del autómata de seguridad; esa evaluación corresponde a su prueba específica.

Los registros se guardan con decimación 10 en las series del modelo; el operador guarda telemetría cada 40 ms. Las aceleraciones físicas provienen de las entradas de los integradores. La velocidad angular de referencia derivada se identifica por separado de la velocidad angular física medida en la planta.

## Interpretación de las gráficas

Explicar las figuras de posición y velocidad siguiendo la secuencia: elevación y barrido, aproximación vacía a la primera toma, extracción y traslado cargado, descenso y entrega, desplazamiento vacío hacia la segunda toma, extracción, retorno cargado y descenso final. Relacionar las discontinuidades de masa con las tomas y liberaciones físicas, y las variaciones de tensión y torque con el peso suspendido, la aceleración y el contacto.

En los transportes cargados, el ángulo físico máximo absoluto fue 0,02877 rad en la ida y 0,01425 rad en el regreso; las velocidades máximas del carro fueron 2,419 y 1,673 m/s. Mostrar el ángulo junto con su referencia y describir la corrección antisway como parte del control de esta corrida. No atribuir causalmente una mejora al antisway sin una comparación bajo las mismas condiciones.

Las figuras de velocidad angular incluyen una referencia derivada que puede presentar picos por cambios de consigna. Distinguir esos picos de la velocidad angular física. Las figuras de error incluyen el arranque; describir por separado la diferencia inicial respecto de las referencias y el seguimiento durante los transportes.

El torque físico máximo absoluto fue 1,699 kNm para el carro y 15,212 kNm para el izaje. La figura completa de torque del carro conserva el transitorio de consigna de arranque; la figura operativa permite observar los transportes con la escala de los límites del motor. No confundir consigna pedida con torque físico aplicado.

El máximo absoluto de aceleración física de izaje en todos los datos fue 144,628 m/s² a los 608,66052 s, inmediatamente después de detectar el último apoyo. Es un transitorio del contacto en el modelo. Como las figuras se cortan a los 608,60 s por la indicación de terminar en el apoyo, ese máximo posterior no aparece en ellas; sí permanece en las señales completas. Aclarar el intervalo al citar máximos del registro y máximos visibles.

## Verificación final y selección de evidencia

Se guardaron 534 series y se verificó su cobertura; además se cargaron los 87 registros directos a disco y todos cubren el final de la maniobra. La simulación terminó a 640 s y la última muestra física es de 639,997 s. El operador confirmó la parada a 611,08 s. Distinguir tiempo de la maniobra de tiempo total registrado.

El error de relevamiento y del balance final es 0 m. La masa final es 15.000 kg, spreader vacío. Después de START no hubo emergencia, código de falla ni falla de seguimiento. Los valores globales incluyen la recuperación de una emergencia y código 12 durante el arranque; no presentarlos como falla durante el transporte ni afirmar que nunca hubo un estado de falla.

Usar solamente la carpeta de resultados de la prueba completa final para las cifras y figuras definitivas. Los intentos previos pueden describirse brevemente como incidencias de preparación. La ejecución previa con solo telemetría no contiene las señales completas de torque o aceleración y no debe mezclarse con esta corrida.

