# Simulink con autómatas Stateflow

Última copia probada de la planta MC R2 FF limitado, con ambos autómatas nativos. Incluye los parámetros, controladores, visualización/HMI y operador de las dos transferencias. Los 14 charts conservan la lógica de la fuente, como muestra la verificación incluida.

Para repetir sin video, copiar esta carpeta a un directorio de trabajo de ruta corta, abrir MATLAB en ella y ejecutar `ejecutar_prueba_completa`. El iniciador configura rutas locales de resultados y caché, registra las señales físicas y finaliza a 628 s. No necesita conexión PLC. Luego ejecutar `analizar_prueba_completa` y `graficar_prueba_completa` para procesar la nueva corrida, conservando el resultado en MATLAB.

Requiere MATLAB/Simulink/Stateflow; probado en R2025b. Se preserva el SLX exacto probado; utilizar el iniciador para reemplazar la carpeta histórica de capturas. No se modificaron los autómatas al armar el repositorio.
