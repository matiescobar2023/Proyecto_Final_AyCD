# CODESYS manual

`CODESYS/` contiene el proyecto realmente cargado y probado. `Simulink_OPC/` incluye las dos variantes, sus parámetros, visualización/HMI, operador, módulos Python y enlace seguro OPC UA. Los dos autómatas se ejecutan en el PLC; la planta y el control permanecen en Simulink.

## Repetir una prueba

1. Configurar MATLAB R2025b con Simulink/Stateflow, CODESYS V3.5 SP22 Patch 4 y Control Win V3 x64. Configurar un Python compatible con MATLAB e instalar las dependencias de `requirements-opcua.txt`.
2. Configurar usuario, certificados y confianza OPC UA propios; consultar [conexión segura](../../Documentacion/CONEXION_OPC_UA.md).
3. Copiar una variante de `Simulink_OPC` a una carpeta nueva de ejecución, de ruta corta. No usar las carpetas de resultados para simular.
4. Cargar el proyecto correspondiente al PLC de simulación; hacer Reset en caliente y poner en RUN antes de cada variante.
5. En la carpeta nueva, ejecutar `abrir_modelo_local` y luego `iniciar_medio_ciclo('sin_antisway')` o `iniciar_medio_ciclo('referencia_antisway')`, según la variante copiada.
6. Guardar los datos con las funciones del banco y revisar la entrega física, además de los estados del PLC. El iniciador impide sobrescribir un `datos_brutos.mat` existente.

Las copias SLX y PROJECT se conservan sin alteración. El abridor agregado adapta rutas de callbacks en memoria. Se incluyen los scripts exactos de la ejecución; las referencias históricas de documentación y algunos utilitarios de configuración/generación pueden requerir elegir rutas locales. No se realizaron nuevas simulaciones durante el armado del repositorio.

Banco de planta simulada con tiempos de simulación y comunicación separados: no constituye validación de una grúa física. Consultar [detalle del banco](Documentacion/README_banco_original.md).
