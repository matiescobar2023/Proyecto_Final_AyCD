# Medio ciclo manual SFC con antisway — 6 de octubre de 2026

Resultado completo: 1. Tiempo final: 169.20 s.

Causa: Entrega y parada confirmadas.

Datos brutos y buses en datos_brutos.mat, con tiempos nativos; derivados separados. El catalogo de hojas de los buses es catalogo_senales_mc.csv.

Video: D:\AyCD\Chat\Proyecto_grua\version codesys\Prueba_MC_R2_FFLimitado_OPCUA_20261006\Correccion_Manual_Relojes_Separados\referencia_antisway\Video_prueba_conjunta\Prueba_HMI_Simulink_20261006_221114.mp4.

## Resultado comprobado

Se completó toma, despegue, traslado al barco, paso efectivo a manual, apoyo, apertura de twistlocks y parada. Sin fallas ni emergencia después de START, sin relevamiento y sin retorno vacío. La masa suspendida final fue 15.000 kg (spreader vacío). El perfil físico del slot 2 disminuyó 2,59 m y el del slot 22 aumentó 2,59 m. Posición final del carro: 22,4114 m, error al centro del destino: 0,0486 m.

| Evento | Tiempo simulado |
| --- | --- |
| START | 3,24 s |
| Solicitud cierre twistlocks | 46,64 s |
| Masa física cargada confirmada | 49,56 s |
| Despegue físico | 50,04 s |
| Solicitud automático | 75,32 s |
| Entrada efectiva automático | 75,44 s |
| Llegada horizontal al destino | 105,84 s |
| Solicitud manual | 133,24 s |
| Entrada efectiva manual | 133,32 s |
| Apoyo y solicitud apertura | 168,92 s |
| Entrega y orden STOP | 169,12 s |
| Fin de simulación | 169,20 s |

Margen geométrico aproximado mínimo durante automático: 2,6583 m. La aproximación rectangular no considera inclinación y no sustituye un detector de colisiones. El indicador dedicado devuelve NaN; su criterio es NO_DISPONIBLE. El mensaje de colisión se ocultó únicamente en el alarmero visual y se conservó el canal.

## Señales, cobertura y video

- `datos_brutos.mat`: SimulationOutput, tiempos nativos, inicialización, telemetría del operador y diagnósticos de enlace.
- `datos_derivados.mat`: magnitudes remuestreadas por tiempo a 40 ms y método documentado. Aceleraciones y velocidad angular de referencia de los gráficos de resumen se calculan por gradient; no sustituyen los canales instrumentados originales.
- `catalogo_senales_mc.csv`, `catalogo_senales.csv`: dinámica de carro, izaje y péndulo; torques de consigna/aplicados/físicos; referencias, sensores, perfiles y estados.
- `cobertura_registro.csv`: **411 hojas variables hasta la parada y 7 constantes con período compilado infinito**, registradas una sola vez. Registro completo en esta referencia.
- `eventos_modo.csv`, `eventos_maniobra.csv`, `metricas_etapas.csv`, `criterios.csv`, `metadatos.json`, `verificacion_nativa.mat`: eventos, métricas, criterios y parámetros.
- `telemetria_operador_completa.mat`: telemetría original a 40 ms.
- `dinamica_referencia_antisway.png`, `torques_referencia_antisway.png`, `hmi_final_video.png`: figuras y último cuadro del video.
- `ejemplo_analisis.m`: genera gráficos y duraciones leyendo los resultados; no simula ni se conecta al PLC. Las figuras se limitan a la cobertura temporal común.

Video: 1280 × 720, 2 cuadros/s, duración 169,5 s. La diferencia de 0,3 s respecto del fin simulado corresponde al muestreo y cierre. No hubo error de ejecución ni interrupción del almacenamiento. Simulink informó tres advertencias por salidas no conectadas: Constant2 y salidas 33/34 del selector de diagnósticos del carro.

## Condiciones y operador

Se ejecutó `MC_R2_SFC_RELOJ_referencia_antisway.slx`, copia de la planta MC R2 FF limitado entregada, con autómatas sustituidos por interfaces OPC UA. La fuente se preservó. El supervisor PLC anterior no implementa la nueva transferencia bumpless del supervisor fuente: esa salida adicional se mantiene en cero. No se declara equivalencia completa con ese supervisor nuevo.

Inicio: x=-26,34 m, y=25 m, reposo y spreader vacío. Se inicializan las 33 alturas físicas, perfil válido, máximo y envolvente, sin simular un barrido. Ganancias y controladores originales conservados. La corrección antisway efectiva máxima fue 0,462450505 m/s, igual al máximo de la diferencia comando/referencia MC con vectores de tiempo nativos idénticos.

El operador usa botones y joysticks normales del HMI; no fuerza posiciones ni códigos de modo. Descenso/ascenso manual: joystick de magnitud 0,2. Solicita automático después de superar objetivo local +1 m, esperar 2 s y alcanzar velocidad vertical filtrada menor de 0,03 m/s. Solicita manual cerca del destino si distancia menor de 0,5 m, velocidad horizontal filtrada menor de 0,25 m/s y altura menor que objetivo automático +0,25 m. El PLC decide las transiciones efectivas. Tiempo máximo por etapa: 240 s. El usuario autorizó completar con antisway incluso más allá de 180 s; no fue necesario.

## Reproducción y comparación

Leer `../README.md`: proyecto PLC, relojes separados, comprobación del watchdog real, caché corta y almacenamiento SDI en D. Configuración exclusiva del banco simulado, no validada para una grúa física.

1. Copiar modelo y scripts a una carpeta nueva sin resultados; el iniciador impide sobrescribir datos brutos.
2. Configurar OPC UA cifrado y secretos locales propios. Cargar `Grua_MC_R2_SFC_Relojes_Separados.project`, efectuar Reset en caliente y RUN antes de cada variante.
3. Configurar caché corta y repositorio SDI con espacio suficiente. Entrar en la carpeta nueva en MATLAB y ejecutar `iniciar_medio_ciclo('referencia_antisway')`.
4. Al terminar: `guardar_medio_ciclo(pwd)`, `analizar_corrida_mc(pwd)` y `verificar_nativo(pwd)`. `documentar_resultado_completo` comprueba la cobertura usando el período compilado del modelo recién ejecutado.

Comparar solo etapas completadas por ambas variantes y dentro de sus coberturas nativas. Sin antisway no entregó y tuvo registro parcial: no interpretar su cola extrapolada como mediciones. Las corridas anteriores con fallas de sincronización siguen preservadas en carpetas independientes. CODESYS automático queda pendiente.
