# Banco manual: relojes de simulación y comunicación separados

## Estado

Compilado con 0 errores y 0 advertencias, cargado por el usuario y probado contra el runtime. Conserva los 21 SFC de seguridad y supervisor, sus pasos, transiciones y posiciones. Las expresiones de transición de los SFC de seguridad permanecen iguales. La referencia con antisway completó la entrega a 169,20 s. La variante sin antisway se conservó como prueba válida de traslado sin estabilización, sin entrega.

Proyecto: `Grua_MC_R2_SFC_Relojes_Separados.project`. Es una copia independiente, destinada al banco con planta simulada en Simulink. No es una configuración validada para una grúa física.

## Por qué se preparó

La sincronización anterior resolvió el adelanto del perfil del PLC respecto de la planta. Sin embargo, dejaba la seguridad ejecutándose con tiempo real y empleaba la llegada de tramas físicas como latido real de comunicación. Las pausas de MATLAB disparaban el watchdog aunque la planta simulada también estuviera pausada.

Se conservaron dos intentos sin antisway: uno alcanzó 123,48 s y el entorno del slot 22, pero se detuvo sin descargar después de una pausa OPC de 6,456 s; otro, con captura más liviana, se detuvo durante el despegue a 55,80 s después de una pausa de 5,856 s. Los datos y videos se encuentran en las carpetas de la corrección anterior. Ninguno se declara aprobado.

## Relojes y alcance de la modificación

- `opcModoBancoSimulado` es explícito y comienza en FALSE. La interfaz de estas copias Simulink lo activa. Con FALSE, los programas del PLC se ejecutan en cada ciclo real.
- En el modo de banco, los SFC de seguridad y supervisor, los diagnósticos físicos y los cálculos de referencias avanzan una vez por trama nueva de 20 ms de simulación. Esto conserva los umbrales nativos en segundos de simulación, incluso cuando MATLAB tarda varios segundos reales en renderizar un cuadro.
- Los ocho tiempos de permanencia del supervisor se incrementan 20 ms por trama. El temporizador del watchdog de seguridad y los diagnósticos de sensores también reciben una ejecución por trama. No se aumentan sus umbrales.
- El latido `opcHeartbeatHealth` se envía desde un hilo Python independiente cada 0,2 s. Significa que la sesión OPC del banco está activa; **no significa que haya una medición física nueva**. La novedad de datos continúa identificándose con `opcHeartbeatSimulink`, y el PLC la confirma con `opcHeartbeatPLC` después de procesarla.
- `PRG_ENLACE_OPCUA` mantiene la vigilancia real del enlace, con el mismo timeout de 3 s, usando el latido de salud en modo banco. Sin ese latido, corta permisos por comunicación.
- `PRG_SALIDAS_SEGURIDAD` y el interbloqueo final se recalculan cada ciclo real, aunque no haya una trama física nueva. Se inhiben reguladores y órdenes de apertura de frenos si se pierde el permiso o la comunicación.
- El watchdog de ejecución de la tarea PLC permanece en tiempo real. El latido Python se detiene cuando se cierra la última referencia de la sesión o se invalida por error.

El hilo de salud permite pausar el cálculo de una planta simulada sin confundirlo con un corte de red. No debe utilizarse como prueba de frescura de sensores de una máquina física. Las pausas reales entre tramas siguen registrándose para diagnóstico.

## Pruebas ya realizadas

- Compilación nativa CODESYS: 0 errores, 0 advertencias.
- Reexportación de los SFC y comparación estructural: mismos pasos, transiciones, acciones, divergencias y posiciones. Expresiones de seguridad sin cambios.
- Sintaxis Python y revisión estática MATLAB.
- Prueba aislada del hilo de salud con un nodo simulado: durante una pausa del hilo principal de 6,6 s produjo 32 pulsos, intervalo máximo 0,236 s; al detenerlo dejó de escribir. Esta prueba no accedió al PLC y no sustituye la comprobación contra el runtime cargado.

## Secuencia utilizada para ejecutar

1. Cargar este proyecto en el simulador PLC, hacer Reset en caliente y ponerlo en RUN.
2. Antes del movimiento, comprobar contra el PLC que el latido de salud continúa durante una pausa de cálculo y que su interrupción produce fallo de comunicación y salidas inhibidas.
3. Ejecutar la copia de `sin_antisway`, con inicialización coherente del perfil físico. Video en vivo a 2 cuadros/s y ventana 1280 × 720.
4. Conservar resultados aunque haya fallos. La entrega exige toma, traslado, transición efectiva a manual, apoyo, apertura y masa descargada en el slot 22.
5. Tras Reset en caliente, repetir con `referencia_antisway`, bajo los mismos requisitos.

Se mantienen la planta MC R2 FF limitado, los controladores y sus ganancias, la dinámica física, las tolerancias de seguimiento y los comandos del operador virtual. El mensaje de colisión del alarmero visual sigue oculto como se pidió, pero se conserva el canal diagnóstico. Todavía no se han ejecutado las nuevas pruebas con CODESYS automático.

## Resultados del 6 de octubre de 2026

| Variante manual SFC | Fin simulado | Entrega | Registro |
| --- | --- | --- | --- |
| Sin antisway | 187,20 s | No; permaneció cargado en el cruce alto | Registro nativo parcial por interrupción del almacenamiento; video y telemetría del operador hasta el final |
| Referencia con antisway | 169,20 s | Sí; toma, traslado, apoyo, apertura y parada | 411 hojas variables hasta el final y 7 entradas constantes con tiempo de muestreo infinito |

El usuario indicó detener sin antisway a 180 s cuando la corrida ya había superado ese instante; se detuvo a 187,20 s. Se conserva el tiempo real obtenido. Autorizó completar con antisway incluso más allá de 180 s, aunque esta referencia terminó antes.

La referencia dejó masa suspendida de 15.000 kg (spreader vacío), retiro de 2,59 m en el perfil del slot 2 e incremento de 2,59 m en el slot 22. No hubo retorno, emergencia ni fallas durante la maniobra. El margen geométrico aproximado mínimo en automático fue 2,658 m. El detector dedicado de colisión devuelve NaN: no se certifica ausencia de colisiones por ese canal.

La vigilancia real se verificó contra el PLC: el hilo de salud siguió durante una pausa de MATLAB de 7 s; al detenerlo, tras 3,6 s apareció fallo de comunicación y quedaron inhibidos reguladores y órdenes de apertura de frenos. Evidencia en `sin_antisway/verificacion_watchdog_real.mat`.

### Almacenamiento y reproducción

Para la referencia se trasladó el repositorio SDI al disco D y se desactivó el borrado automático de corridas por bajo espacio. La configuración previa y una prueba aislada de registro se guardaron en `Verificacion_Registro/verificacion_registro.mat`. El registro completo de la referencia se comprobó en `referencia_antisway/cobertura_registro.csv`; las siete muestras únicas son constantes compiladas con período infinito, no pérdidas del registro.

La caché de generación se configuró en una ruta corta para evitar el límite de longitud de rutas de Windows:

```matlab
Simulink.fileGenControl('set', ...
 'CacheFolder','D:\AyCD\Chat\Proyecto_grua\Cache_MC_R2\cache', ...
 'CodeGenFolder','D:\AyCD\Chat\Proyecto_grua\Cache_MC_R2\codegen', ...
 'createDir',true);
```

En otra PC, elegir rutas cortas equivalentes. Configurar OPC UA seguro y secretos locales propios, cargar este proyecto, efectuar Reset en caliente y RUN antes de cada variante. Copiar los archivos de la variante a una carpeta nueva sin resultados; `iniciar_medio_ciclo` impide sobrescribir `datos_brutos.mat`. Inicializa el perfil físico real de 33 alturas sin hacer relevamiento.

La captura usa una ventana 1280 × 720 a 2 cuadros/s de tiempo simulado. En sin antisway, el redondeo del período a 0,52 s comprime ligeramente la duración reproducida. En la referencia se corrigió el planificador de captura para conservar el período medio de 0,5 s. Esta corrección solo afecta al video.

### Comparación válida

Ambas variantes comparten planta, masas, perfil inicial, ganancias, controles y operador virtual; cambia únicamente la contribución antisway efectiva al sumador. La referencia completó etapas que sin antisway no alcanzó. Comparar solo etapas y ventanas comunes, usando los tiempos originales: la comprobación nativa del controlador sin antisway llega a 130,72 s y varias señales físicas a 177,305 s. No utilizar como mediciones las extrapolaciones de derivados fuera de esas coberturas. Consultar los README y CSV de cada variante.
