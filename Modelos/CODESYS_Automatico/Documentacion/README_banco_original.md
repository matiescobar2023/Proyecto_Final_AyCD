# Banco automático ST: medio ciclo MC R2 FF limitado

## Estado de preparación

Proyecto `Grua_MC_R2_Automatico_ST_Relojes_Separados.project`, compilado en CODESYS V3.5 SP22 Patch 4: **0 errores, 0 advertencias**, evidencia `compilacion.log`. El usuario lo cargó y reinició en caliente antes de cada variante. Ambas corridas se ejecutaron y quedaron registradas. Los resultados manuales y modelos fuente permanecen preservados.

## Resultados

| Variante ST | Tiempo final simulado | Resultado |
| --- | --- | --- |
| Sin antisway | 180,00 s | Prueba válida; traslado sin estabilización, carga retenida en cruce alto, sin entrega |
| Referencia con antisway | 279,52 s | Llegó, pasó a manual y apoyó; detención diagnóstica por discrepancia de descarga PLC/planta, sin entrega física confirmada |

No se declara aprobado el medio ciclo completo en ninguna de estas dos corridas ST. La falta de entrega sin antisway es el resultado que el usuario aceptó conservar al llegar al límite de tres minutos. La referencia con antisway muestra un problema distinto: después del apoyo, el PLC indica vacío y los twistlocks físicos están abiertos, pero la máquina PICK/PLACE de la planta conserva la carga.

### Hallazgo de la referencia

En la captura diagnóstica a 272,52 s: `loadedState=0` en el PLC, feedback de twistlocks abiertos, contacto presente, modo manual y códigos de falla/comunicación en cero; en la planta, `carga_tomada=1`. La tensión que alimenta la histéresis física era aproximadamente 99,54 kN y su umbral de apagado es 15,009 kN. La transición de entrega de PICK/PLACE exige twistlocks abiertos, contacto, velocidad vertical pequeña **y tensión descargada**. Esta última condición no se cumple.

La posición se mantuvo alrededor de y=8,489828 m y el operador había dejado el joystick en cero al detectar contacto. Se detuvo la corrida para conservar el diagnóstico tras más de 100 s de apoyo sin transferencia física. Es una detención diagnóstica a 279,52 s, no un disparo de falla del PLC ni el límite de 180 s. No se forzaron la masa, las posiciones, los permisos ni los estados, ni se alteraron umbrales o ganancias para declarar entrega.

Evidencia: `referencia_antisway/diagnostico_apoyo.mat`, eventos, criterios, series originales y video. El motivo inmediato está identificado; no se afirma todavía una causa única en el generador de código. Para una corrección posterior se debe revisar cómo se confirma el apoyo completo y la descarga de tensión en la interacción entre referencia manual ST y planta, y repetir esa variante de manera independiente.

La prueba manual SFC previa con antisway sí completó la entrega a 169,20 s. Esta diferencia de resultado queda registrada; no se atribuye al control antisway como única causa.

### Registro y comparación

Los datos brutos, derivados, catálogos, cobertura por canal, eventos, métricas, criterios, metadatos, gráficos y videos están separados por variante. Las comprobaciones nativas sin antisway confirman corrección efectiva y diferencia comando/referencia iguales a cero en 180.001 muestras MC.

`comparar_variantes_st.m` compara únicamente las etapas efectivamente completadas por ambas, anteriores al traslado automático. La etapa automática sin antisway no terminó y la entrega con antisway tampoco: no se presentan como etapas completas comparables. Se verifican perfil inicial y masas idénticos y se conservan los tiempos de entrada efectiva a automático de cada corrida.

La vigilancia real del enlace también se probó contra este PLC ST: el reloj del banco permaneció constante durante 7 s sin trama nueva; al interrumpir el hilo de salud, tras 3,6 s se activó la pérdida de comunicación y se inhibieron reguladores/órdenes de apertura de frenos. Evidencia `sin_antisway/verificacion_watchdog_real.mat`.

## Misma prueba

Se utilizan copias de la planta de la última prueba manual: MC R2 FF limitado, ganancias originales, perfil físico de 33 alturas, masas y controles. Inicio en slot 2 (x=-26,34 m), y=25 m, reposo y vacío. Sin relevamiento. Toma y despegue manual, traslado automático cargado al slot 22, paso efectivo a manual, apoyo, apertura y parada sin retorno.

- `sin_antisway`: contribución efectiva cero al sumador, cálculo interno registrado. Detención a **180 s de simulación** aunque no entregue; se documentará como prueba válida con su resultado real.
- `referencia_antisway`: contribución efectiva activa con ganancias actuales. Autorizado completar la descarga más allá de 180 s si no aparecen fallas. Se conservan los límites de etapa y protecciones normales.

Ambas variantes registran señales nativas de dinámica de carro/izaje/péndulo, referencias, torques de consigna/aplicados/físicos, antisway calculada/limitada/efectiva, perfiles, sensores, estados y eventos. Cada una tiene su propio video de visualización y HMI a 2 cuadros/s de tiempo simulado, ventana 1280 × 720. El mensaje de colisión está oculto solo en el alarmero; su canal se conserva y se documentará su disponibilidad.

## Adaptación ST para el banco simulado

Base: proyecto automático ST de la prueba de medio ciclo anterior, con inicialización externa del perfil físico. Los FB de los autómatas y los adaptadores `PRG_AUTO_SEGURIDAD`/`PRG_AUTO_SUPERVISOR` conservan su lógica. No se regenera ni se modifica su máquina de estados para mejorar el ensayo.

- Nueva tarea: enlace OPC real y `PRG_AUTOMATAS_ST_OPC_SINCRONOS`.
- Modo explícito `opcModoBancoSimulado`, inicialmente FALSE. Cuando es TRUE, se llama a los dos programas automáticos una vez por nueva trama de 20 ms simulados. El acuse se escribe después de procesar ambos.
- `opcHeartbeatHealth` es la salud de la sesión, pulsada por un hilo Python cada 0,2 s reales. No representa una medición física nueva. La trama física usa un latido separado.
- Timeout de enlace conservado en **3 s reales**; permisos y órdenes de apertura de frenos se inhiben en el ciclo real aunque no llegue una trama nueva. El watchdog de la tarea sigue en tiempo real.
- `SEG_PLC_CODER_TIMER`, generado originalmente sobre TON, usa `opcTiempoBancoMs` en modo banco. RESET borra la memoria; AFTER/BEFORE conservan el umbral en milisegundos y comienzan al primer llamado de evaluación, como TON. Fuera del modo banco conserva el cuerpo TON original. El supervisor generado ya utiliza su paso de 0,02 s para sus cálculos y contadores.
- `opcImplementacionST=TRUE` identifica esta copia a la interfaz. El iniciador exige esa variable para evitar probar por error el PLC manual.

Esta adaptación sirve para una **planta simulada**, no constituye una configuración validada para una grúa física. El supervisor anterior del PLC tampoco implementa la nueva salida de transferencia bumpless del supervisor del modelo fuente: se conserva su adaptación de salida cero, igual que en las corridas manuales. No se afirma equivalencia total con ese supervisor nuevo.

## Ejecución

1. Cargar el proyecto preparado, **Reset en caliente** y RUN. La descarga la realiza el usuario.
2. En MATLAB, entrar en esta carpeta y ejecutar `configurar_ensayo_st('sin_antisway')`. Después entrar en la carpeta devuelta y ejecutar `iniciar_medio_ciclo('sin_antisway')`.
3. Guardar y analizar resultados sin sobrescribir variantes. Antes de la referencia, Reset en caliente y RUN para eliminar carga/perfil anteriores; avisar al operador de la prueba.
4. Repetir preparación e inicio con `referencia_antisway`.

Se usa caché corta en `D:\AyCD\Chat\Proyecto_grua\Cache_MC_R2` y repositorio SDI local al banco en D para evitar el límite de rutas y pérdidas por espacio en C. En otra PC elegir rutas cortas con espacio suficiente y configurar su propia identidad OPC UA segura. Nunca compartir contraseñas ni claves privadas.

Las carpetas por variante contienen los SLX realmente preparados y los scripts. `iniciar_medio_ciclo` rechaza una carpeta con `datos_brutos.mat` existente. `ejemplo_analisis.m` lee los resultados sin rerun. Los XML antes/importados/verificados y el log conservan la trazabilidad de la adaptación. El primer intento de importación falló por el reporter y el orden de los elementos XML; se corrigió antes de guardar/compilar la copia final y se conserva su log separado.

## Entregables y acceso

Cada variante tiene **455 hojas variables registradas hasta su parada y 7 constantes de periodo infinito**. Ambas relecturas de datos_brutos.mat se comprobaron por separado. Ademas se guardaron 19 canales originales en dinamica_y_torques_nativos.mat para trabajar con menos memoria. Los derivados y el ejemplo de analisis tambien permiten revisar resultados sin cargar todo el MAT.

La reconstruccion de una segunda copia del registro completo durante el primer posprocesado de la referencia agoto la memoria. Se corrigio el posprocesado para reutilizar el resultado disponible; se verifico despues que los MAT guardados se pueden reabrir por separado. El registro durante ambas simulaciones fue completo. Cargar una sola corrida grande a la vez.

Los eventos del operador/HMI y los cambios de modo de los monitores To Workspace pueden diferir por las tasas y retenciones de visualizacion. Los CSV conservan sus tiempos originales. La comparacion usa los monitores discretos y excluye las etapas no completadas por ambas.

El paquete Paquete_Prueba_MC_R2_CODESYS_ST_20261006.zip contiene proyecto, dos modelos probados, scripts/parametros, resultados, videos, diagnostico, documentacion. Excluye repositorio SDI/cache, proyectos auxiliares no probados, preferencias de usuario y certificados/claves privadas. Para replicar hacen falta MATLAB/Simulink y soporte para los bloques Stateflow del modelo, CODESYS Control Win V3 x64 y Python compatible con MATLAB con las dependencias de requirements-opcua.txt. PLC Coder se usa para generar, no para correr el codigo ST ya incluido. Cada PC debe configurar su identidad y confianza OPC UA segura.
