# Corrida MC_R2_ST_RELOJ_referencia_antisway

Resultado completo: 0. Tiempo final: 279.52 s.

Causa: Detencion diagnostica: PLC vacio y twistlocks abiertos, pero PICK/PLACE conserva carga por tension de cable superior al umbral de descarga.

Datos brutos y buses en datos_brutos.mat, con tiempos nativos; derivados separados. El catalogo de hojas de los buses es catalogo_senales_mc.csv.

Video: D:\AyCD\Chat\Proyecto_grua\version codesys\Prueba_MC_R2_FFLimitado_OPCUA_20261006\Correccion_Automatica_ST_Relojes_Separados\referencia_antisway\Video_prueba_conjunta\Prueba_HMI_Simulink_20261006_230013.mp4.

Ver README del banco para las adaptaciones y la diferencia de transferencia del supervisor.

## Resultado y evidencia de descarga no confirmada

**Prueba valida como evaluacion; entrega NO_APROBADA.** La referencia se detuvo de forma diagnostica a 279,52 s, en manual y apoyada, sin falla ni emergencia del PLC. El permiso para continuar con antisway mas alla de 180 s se respeto. No se alcanzo la confirmacion de descarga ni se hizo retorno.

| Evento del operador/HMI | Tiempo simulado |
| --- | --- |
| Masa fisica cargada confirmada | 49,52 s |
| Solicitud automatico | 75,32 s |
| Deteccion de automatico en HMI | 75,40 s |
| Llegada horizontal | 105,76 s |
| Solicitud manual | 133,20 s |
| Deteccion de manual en HMI | 133,56 s |
| Apoyo y solicitud apertura | 169,24 s |
| Captura diagnostica de discrepancia | 272,52 s |
| Detencion diagnostica | 279,52 s |

Las detecciones del operador corresponden a sus entradas de HMI. eventos_modo.csv usa los monitores discretos originales del PLC en Simulink; puede diferir por el muestreo y las retenciones del circuito de visualizacion. Se conservan ambos tiempos y no se combinan por indices.

Al detener: carro x=22,430430 m; spreader y=8,489828 m; masa fisica suspendida 51.863 kg. El slot 2 disminuyo 2,59 m pero el slot 22 no aumento. La variable loadedState del PLC era cero y los twistlocks estaban fisicamente abiertos; la planta conservaba carga_tomada=1. La transicion PLACE exige tension descargada. La histéresis seguia activada porque F_hw estaba cerca de 99,54 kN, frente al umbral de apagado de 15,009 kN. diagnostico_apoyo.mat conserva esa comprobacion, sin modificar entradas ni estados para obtenerla.

El motivo inmediato del bloqueo esta demostrado. No se afirma una causa unica en PLC Coder sin una comprobacion adicional: debe revisarse la confirmacion de apoyo/tension y su relacion con las referencias manuales ST. No se modificaron la planta, ganancias, umbrales ni el operador para forzar la descarga. Se conserva esta corrida original para comparar una correccion posterior en otra carpeta.

## Cobertura, archivos y reproduccion

Registro completo hasta 279,52 s: **455 hojas variables y 7 constantes de periodo compilado infinito**; cobertura_registro.csv incluye logsout y monitores To Workspace. datos_brutos.mat conserva las series originales; datos_derivados.mat documenta interpolacion temporal y derivadas. dinamica_y_torques_nativos.mat ofrece 19 canales originales de dinamica/torques con sus Time/Data, sin remuestreo, para analisis con menos memoria.

Video 1280 x 720 a 2 cuadros/s, duracion 280 s. La diferencia respecto del tiempo final procede del cierre y muestreo de cuadros. hmi_final_video.png es el ultimo cuadro real; dinamica_referencia_antisway.png y torques_referencia_antisway.png son los resumenes. Los graficos de aceleraciones del resumen usan gradient; las aceleraciones fisicas instrumentadas tambien estan guardadas en los registros nativos.

Durante el posprocesado, cargar una segunda copia completa del MAT produjo falta de memoria. Se termino el analisis reutilizando el resultado original, y posteriormente se verifico la relectura de ambos MAT por separado tras liberar variables. Esto fue un problema de memoria al analizar, no una interrupcion del registro durante la simulacion. Para trabajar con estos archivos grandes, cargar una corrida a la vez, liberarla antes de cargar la siguiente y preferir los MAT de derivados o de dinamica/torques si no se necesitan todos los buses.

Ver ../README.md para proyecto, sincronizacion, vigilancia real, almacenamiento y reproduccion. Antes de repetir, Reset en caliente y RUN; usar carpeta nueva sin resultados. Configurar OPC UA seguro con identidad propia. El modelo fuente y la corrida manual previa permanecen preservados. El mensaje de colision se oculta solo en el alarmero: el detector dedicado devuelve NaN y el criterio se marca NO_DISPONIBLE. Margen geometrico aproximado minimo en automatico: 2,6683 m; no equivale a certificacion de ausencia de colisiones.
