# Conexión OPC UA del banco

El enlace usa `opc.tcp://127.0.0.1:4840`, Basic256Sha256 y SignAndEncrypt. Cada equipo debe configurar su usuario del dispositivo con permisos sobre `GVL_GRUA`, generar su identidad de cliente y establecer confianza con el servidor. No se incluyen contraseñas, almacenes privados ni claves privadas.

La interfaz lee estas variables de entorno desde MATLAB: `CODESYS_OPCUA_ENDPOINT`, `CODESYS_OPCUA_SERVER_SHA1` (huella completa del certificado servidor del equipo), `CODESYS_OPCUA_USERNAME` y `CODESYS_OPCUA_PRIVATE_DIR` (carpeta local de identidad). Lee los secretos locales `CODESYS_OPCUA_PASSWORD` y `CODESYS_OPCUA_KEY_PASSWORD` mediante `getSecret`. Guardarlos localmente con el administrador de secretos de MATLAB, sin escribir sus valores en scripts ni en el repositorio.

`opcua_ca_identity.py` contiene las funciones `provision` y `verify`: generan/verifican la CA, certificado cliente, claves cifradas y CRL dentro de la carpeta privada elegida. Importar el certificado público CA en los certificados de confianza del dispositivo CODESYS y comparar su huella. Importar la CRL mediante `cert/import` y `cert-importcrl` en Shell PLC. Si el cliente queda en cuarentena, comparar su huella antes de confiar en él. No copiar claves privadas al runtime.

El proyecto manual y el automático publican el modo de banco simulado; los scripts manejan tramas simuladas de 20 ms y un latido real independiente. Mantener el timeout real de comunicación de 3 s. Antes de cada variante, Reset en caliente y RUN. Los README originales describen las verificaciones de watchdog y los requisitos del banco.
