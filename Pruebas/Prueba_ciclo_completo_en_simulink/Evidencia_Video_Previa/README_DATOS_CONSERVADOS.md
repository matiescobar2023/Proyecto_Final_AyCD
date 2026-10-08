# Datos conservados de la corrida

La maniobra terminó a los 626.36 s simulados, con dos tomas y dos entregas.

Se conservaron el video completo, las capturas y `operador_progreso.mat`, que contiene 15660 muestras de las 42 entradas del HMI a intervalos de 40 ms (107 columnas con tiempo y vectores de perfil). El CSV adjunto exporta esas muestras directamente, sin reconstruirlas ni interpolarlas.

Incluye posiciones, ángulo, perfiles, contacto, twistlocks, carga suspendida, masa estimada, mandos y diagnósticos recibidos por el HMI. No contiene todas las aceleraciones ni torques físicos solicitados. El cierre de MATLAB falló y no se recuperó la salida dinámica ampliada. Esta limitación no debe confundirse con ausencia total de datos.
