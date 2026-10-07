# Prueba valida: CODESYS manual sin antisway efectivo

## Resultado

La prueba es valida como evaluacion del comportamiento sin antisway. No completo el medio ciclo ni se declara aprobada la entrega. El contenedor se tomo del slot 2, se elevo y se traslado al entorno del slot 22. Permanecio suspendido a la altura de cruce, sin estabilizarse para completar el descenso. No hubo apertura ni descarga.

El usuario indico detener al alcanzar 180 s. La instruccion llego despues de ese instante y la parada efectiva fue a 187.20 s. Se conservaron todas las muestras y el video originales. No se presentan 180 s como tiempo efectivo de parada.

## Balanceo y fallas

En la parte registrada del intervalo [120,180] s (hasta 177.305 s): angulo RMS 0.031690 rad y maximo absoluto 0.045209 rad; velocidad angular RMS 0.021325 rad/s y maximo absoluto 0.030301 rad/s. Las lineas del resumen representan las condiciones angulares de comienzo del descenso automatico, no una certificacion de seguridad.

Fallas durante la maniobra: 0. Emergencia: 0. Watchdog: 0. La detencion final fue solicitada por el usuario, sin aumentar limites ni modificar ganancias.

## Verificacion y archivos

La verificacion numerica nativa confirma antisway efectiva cero y v_cmd igual a la referencia hasta 130.72 s; no cubre numericamente la cola que no se registro. El perfil fisico del slot 2 disminuyo un contenedor; el slot 22 no cambio. Se registro carga fisica suspendida.

- datos_brutos.mat: salida Simulink completa, q del operador, perfil inicial, tiempos OPC y eventos de seguridad. Series con sus tiempos originales.
- datos_derivados.mat: magnitudes remuestreadas por tiempo y calculadas; no sustituyen los originales.
- catalogo_senales.csv y catalogo_senales_mc.csv: senales escalares, dinamica, torques y hojas de buses.
- eventos_modo.csv y eventos_maniobra.csv: solicitudes y transiciones efectivas, en segundos de simulacion.
- criterios.csv: comprobaciones individuales; entrega y fin de medio ciclo no aprobados. Esto no invalida el ensayo de control.
- metadatos.json y verificacion_nativa.mat: parametros, variante y mediciones de comprobacion.
- verificacion_watchdog_real.mat: vigilancia real del enlace comprobada antes del movimiento.
- resumen_sin_antisway.png, hmi_final_video.png y Video_prueba_conjunta: resumen y video en vivo de HMI y visualizacion.
- Copia del modelo realmente ejecutado y scripts para reproducir. La parada de esta corrida fue una orden del usuario; para repetir con corte automatico fijar previamente StopTime=180.

Video: D:\AyCD\Chat\Proyecto_grua\version codesys\Prueba_MC_R2_FFLimitado_OPCUA_20261006\Correccion_Manual_Relojes_Separados\sin_antisway\Video_prueba_conjunta\Prueba_HMI_Simulink_20261006_214111.mp4.

No se ejecutaron corridas ST automaticas. La referencia con antisway requiere condiciones iniciales reinicializadas.

## Limitacion de cobertura

La simulacion informo falta de espacio o exceso de uso del almacenamiento y desactivo el registro de datos. Algunas senales del supervisor y MC llegan hasta 130,72 s y varias senales fisicas hasta 177,305 s, aunque la maniobra termino a 187,20 s. Consultar cobertura_registro.csv para cada canal. No se declara completo el registro nativo.

El video y telemetria_operador_completa.mat llegan hasta el final. La telemetria permite seguir posiciones, angulo y estados, pero no recupera los torques faltantes. Las magnitudes remuestreadas fuera de la cobertura nativa no deben interpretarse como nuevas mediciones. Los criterios que dependen de esa cola requieren considerar esta limitacion. La prueba sigue siendo valida como observacion del traslado y balanceo sin antisway; no se certifica entrega ni integridad de todos los canales.

## Tiempo del video e indicador antisway

El video dura 180.00 s de reproduccion y contiene la secuencia hasta el estado final del HMI. La captura cada 0,5 s se cuantiza al operador de 40 ms (0,52 s entre cuadros), por lo que el tiempo de reproduccion no equivale exactamente al de simulacion: usar el reloj visible del HMI. El indicador ANTISWAY ACTIVO muestra el permiso del supervisor; en esta variante la contribucion se anulo en el sumador. No debe interpretarse ese indicador como correccion efectiva distinta de cero.
