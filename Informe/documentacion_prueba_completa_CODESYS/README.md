# Prueba completa con CODESYS manual

Ensayo realizado el 7 de octubre de 2026: relevamiento LiDAR real, contenedor del centro del muelle al centro del barco y contenedor del extremo derecho del barco al extremo izquierdo del muelle. Antisway habilitado, sin video. El informe no fue modificado.

## Resultado

- Dos tomas y dos entregas fisicas confirmadas; parada normal a los 611.08 s simulados.
- Relevamiento y balance del perfil verificados. Error de relevamiento: 0 m; error del balance final: 0 m.
- 534 series guardadas. Cobertura temporal de todas las series originales verificada.
- 87 registros directos a disco cargados y verificados; todos cubren el final de la maniobra. 23 figuras individuales en PNG y PDF.
- Estado de seguridad despues de START: emergencia maxima 0, codigo de falla maximo 0, falla de seguimiento maxima 0.
- Masa suspendida final: 15000 kg.

## Contenido

- **Documentacion**: indicaciones para el informe, detalles del ensayo y comprobacion inicial del enlace.
- **Resultados/Prueba_Completa**: datos brutos de Simulink, series originales, catalogo y cobertura, perfiles, eventos, resumen, capturas HMI y graficas individuales PNG/PDF.
- **Resultados/Intento_Barrido_Incompleto**: primer intento y evidencia de la omision del primer slot. Se conserva separado; no llego a tomar carga.
- **Resultados/Ejecucion_Previa_Solo_Telemetria**: ejecucion anterior que completo las entregas, con eventos y capturas, pero sin output final por el bloqueo de cierre. No usarla como fuente de torques o aceleraciones de la corrida final.
- **Modelos/Simulink**: copia instrumentada del modelo y dependencias locales del control, la planta, el HMI, el operador y el enlace OPC UA.
- **Modelos/CODESYS**: proyecto manual corregido, XML de los dos objetos afectados y log de compilacion con cero errores y cero advertencias.

## Para incorporarlo al informe

Seguir **Documentacion/INDICACIONES_PARA_INFORME.md**. Usar el nombre de la prueba, no nombres de archivos o rutas, en el texto y los pies de figura. Una grafica por figura y sin graficas de modos. Los graficos temporales terminan en el ultimo apoyo; las senales originales incluyen la liberacion y la parada. La aceleracion de izaje se entrega en escala completa y con zoom vertical separado.

## Para consultar las senales

En el archivo de series originales, cada campo contiene `t` (segundos) y `v` (valores). El catalogo enumera las series; la tabla de cobertura indica paso temporal y ultima muestra. La telemetria HMI y los eventos del operador estan tambien en los archivos del operador. No interpretar la ocultacion del mensaje de colision del HMI como una certificacion de ausencia de colisiones.

## Para repetir

Usar MATLAB/Simulink R2025b y CODESYS V3.5 SP22 Patch 4, runtime Control Win V3 x64, con las bibliotecas del proyecto. Configurar Python 3.12 con los requisitos OPC UA incluidos. Crear una identidad cliente y establecer confianza en el servidor OPC UA local con Basic256Sha256/SignAndEncrypt; se requieren usuario y permisos sobre GVL_GRUA. Configurar las variables de entorno y los dos secretos locales que consulta el puente. Las claves privadas y las contrasenas no se incluyen.

Variables de entorno: CODESYS_OPCUA_ENDPOINT (por ejemplo opc.tcp://127.0.0.1:4840), CODESYS_OPCUA_SERVER_SHA1 (huella propia del servidor de destino), CODESYS_OPCUA_USERNAME y CODESYS_OPCUA_PRIVATE_DIR (carpeta privada de identidad). Secretos locales MATLAB: CODESYS_OPCUA_PASSWORD y CODESYS_OPCUA_KEY_PASSWORD. Configurarlos antes del iniciador: sus valores por defecto corresponden a la PC del ensayo. Usar preparar_identidad_opcua para crear una identidad propia y establecer confianza CA/CRL/cliente en CODESYS; no reutilizar claves privadas de otra PC.

Cargar el proyecto manual corregido, efectuar Reset en caliente y poner el PLC en RUN. Agregar la carpeta Simulink al path de MATLAB y ejecutar el iniciador de prueba completa. El perfil no se precarga. Dejar que la simulacion termine por su limite fijo de 640 segundos simulados. Ejecutar el finalizador solamente cuando Simulink este detenido; no bloquear el hilo MATLAB esperando el cierre. El iniciador reasigna las rutas de registro a una carpeta nueva. Los archivos de funciones con rutas de trabajo anteriores corresponden a la preparacion del banco y no deben ejecutarse para repetir la maniobra.
