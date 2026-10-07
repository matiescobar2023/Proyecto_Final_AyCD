# Prueba completa: barrido y dos transferencias

Corrida de resultados: `corrida_09`. Duración simulada: **626.36 s**.
Finalización del operador: Sí; motivo de aborto: ninguno.

## Recorrido

1. Barrido LiDAR real, sin precargar el perfil.
2. Toma en el centro del muelle (slot 6, x = −16,58 m) y entrega en el centro del barco (slot 23, x = 24,90 m).
3. Aproximación vacía al extremo derecho operable del barco (slot 32, x = 46,86 m), segunda toma y entrega en el extremo izquierdo del muelle (slot 1, x = −28,78 m).
4. Apertura de twistlocks, liberación física y parada normal.

Se utilizaron la planta, MC con antisway, supervisor y seguridad Stateflow del modelo de origen. Los posicionamientos se pidieron en automático y las aproximaciones finales y extracciones mediante los mandos proporcionales reales del HMI. No se forzaron estados, no se modificaron ganancias ni protecciones y no se utilizó un PLC externo.

## Comprobaciones

- Tomas físicas: 2; entregas físicas: 2.
- Error máximo del perfil relevado en slots operables: 0 m.
- Error del balance final de perfil: 0 m.
- Masa física suspendida final: 15000.000 kg (spreader vacío).
- Emergencia: 0; falla de seguimiento: 0; código de falla: 0.
- Series conservadas: 395; cobertura completa según los tiempos de muestra de cada fuente: Sí. Incluye una referencia de velocidad angular derivada posteriormente, identificada con ese nombre.
- Contactos: 192.12, 308.60, 444.72, 623.88 s; confirmaciones físicas: 194.96, 309.00, 447.56, 624.32 s.
- Fin de maniobras: 626.36 s; registro físico conservado hasta 627.99833 s, seguido del cierre normal por StopTime de 628 s.

El perfil baja 2,59 m en los slots 6 y 32 y sube 2,59 m en los slots 23 y 1. Estas comprobaciones corresponden a una simulación nominal, no a validación de una grúa real.

## Datos y figuras

- `datos_brutos.mat`: salida original de Simulink, operador y tiempo real de ejecución.
- `senales_originales.mat`: series numéricas con sus tiempos originales, sin interpolación ni filtrado. Incluye aceleraciones tomadas de la planta, posición y velocidad del carro/izaje, ángulo y velocidad angular del péndulo, torques físicos y pedidos, tensión, masa, referencias, antisway, permisos y diagnósticos.
- `cobertura_registro.csv` y `catalogo_senales.json`: catálogo y cobertura individual. Decimación 10: el intervalo efectivo depende del tiempo de muestra de la fuente; no todas las señales tienen el mismo paso.
- `perfiles.csv`: perfil físico inicial, medición LiDAR y perfil físico final de los 33 slots.
- `eventos.csv`, `resumen.json` y `operador_final.mat`: cronología y comprobaciones.
- `graficas`: figuras individuales PNG y PDF, escala completa y zoom vertical de aceleración de izaje. No se grafican modos de funcionamiento. La referencia de velocidad angular está identificada como derivada posterior. Los errores de posición se calculan para las figuras, conservando los datos originales.

## Capturas y HMI
No se grabó video en esta repetición, por pedido del usuario después del reinicio de la PC. Se conservaron las capturas del barrido, cuatro contactos, cuatro transferencias y estado final, junto con todas las demás señales solicitadas. Se ocultó únicamente el texto COLISION del alarmero, conservando la lógica de seguridad.

## Instrumentación y correcciones del banco
El original de la carpeta de origen quedó sin cambios. La copia agrega instrumentación y automatiza acciones reales del HMI. La comprobación de los 14 charts no detectó cambios en nombres, etiquetas ni código.
El operador se corrigió para elevar tras cerrar los twistlocks y esperar entonces la confirmación de toma física, que requiere tensión y separación del apoyo.
Las corridas 04 y 06 completaron las dos entregas, pero MATLAB R2025b sufrió una violación de acceso al cerrar el repositorio de señales. Conservaron video, capturas e historial del HMI; sus salidas dinámicas ampliadas no se dan por disponibles. La corrida 06 tiene además una exportación CSV de los datos realmente conservados. La sustitución inicial del registro SDI por sinks To Workspace no evitó el error. La corrida 05 detectó nombres duplicados antes de comenzar y se corrigió la unicidad de los nombres.
Se eliminó la orden de detención dentro del callback de la S-function; el motor finaliza ahora por StopTime, después de la parada física de la grúa. Una comprobación corta de 20 s (corrida 07) cerró y guardó 395 series correctamente. El último ensayo usa esta forma de cierre y conserva el fin de las maniobras separado del tiempo final de registro de Simulink.
La corrida 08 fue interrumpida por el reinicio de la PC comunicado por el usuario. Se repitió desde las condiciones iniciales, ahora sin video; sus archivos no se reutilizaron como resultado completo.
Las corridas 01–03 son preparaciones o intentos incompletos y no deben confundirse con los resultados finales.

## Informe
La actualización sustituye exclusivamente la Prueba 1 antigua por el barrido y las dos transferencias de esta corrida. Incluye explicación de dinámica, balanceo, antisway, torques, contactos y balance del perfil. Se conservan las secciones de seguridad y las pruebas CODESYS manual/automático. El texto visible no incluye nombres de modelos o scripts.

## Reproducción
Abrir la copia del modelo en esta carpeta con MATLAB/Simulink y Stateflow. Ejecutar `ejecutar_prueba_completa` desde esta carpeta; crea una carpeta nueva de corrida. Para analizarla ejecutar `analizar_prueba_completa` y `graficar_prueba_completa`. El banco usa un perfil inicial reproducible y solicitudes reales de HMI. La copia debe permanecer separada del original.
