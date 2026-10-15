# Prueba completa con CODESYS manual

Ensayo finalizado el 7 de octubre de 2026. Supervisor y seguridad SFC en el PLC; planta, accionamientos, control, sensores, visualización y HMI en Simulink. Antisway habilitado. Sin video. El informe no fue modificado.

## Resultado final

La corrida final completó el relevamiento real, dos tomas, dos entregas físicas y la parada normal. El perfil no se precargó. El error máximo del perfil relevado y del balance final es 0 m. Al terminar, la masa suspendida es 15.000 kg, correspondiente al spreader vacío.

| Evento | Tiempo simulado [s] |
|---|---:|
| START | 3,24 |
| Perfil relevado válido | 130,08 |
| Contacto para primera toma | 200,80 |
| Primera toma física confirmada | 203,68 |
| Apoyo en centro del barco | 315,80 |
| Primera liberación confirmada | 316,24 |
| Contacto para segunda toma | 445,24 |
| Segunda toma física confirmada | 448,12 |
| Apoyo en extremo izquierdo del muelle | 608,60 |
| Segunda liberación confirmada | 609,04 |
| Parada normal confirmada | 611,08 |

La simulación terminó normalmente por el límite fijo de 640 s; las señales físicas llegan hasta 639,997 s. La telemetría del operador tiene paso de 40 ms. No hubo emergencia, código de falla ni falla de seguimiento después de START. Los máximos globales incluyen una emergencia y código 12 recuperados durante el arranque; no corresponden a una falla durante los transportes.

## Condiciones y maniobra

PLC con Reset en caliente y RUN, carro en -26,34 m, altura nominal inicial 25 m, reposo, spreader vacío y perfil inicialmente inválido. Comunicación OPC UA Basic256Sha256/SignAndEncrypt y avance del banco mediante tramas de 20 ms simulados.

1. Barrido LiDAR real del perfil. El primer slot obtuvo 177 muestras.
2. Contenedor del centro del muelle: slot 6, x=-16,58 m → centro del barco: slot 23, x=24,90 m.
3. Desplazamiento vacío hacia el extremo derecho operable del barco.
4. Contenedor del slot 32, x=46,86 m → extremo izquierdo del muelle: slot 1, x=-28,78 m.
5. Apoyo, apertura de twistlocks, liberación física y parada normal.

El operador utiliza botones y joystick del HMI; no fuerza estados ni modifica la planta. Los dos orígenes disminuyen 2,59 m y los dos destinos aumentan 2,59 m.

## Señales y figuras

Se guardaron 534 series: canales originales del modelo, referencias, posiciones, velocidades y aceleraciones físicas del carro e izaje, ángulo y velocidad angular del péndulo, torques de consigna y motor, tensión, masa, contacto, perfiles, permisos, frenos, fallas, enlace y contribuciones del antisway. Las aceleraciones físicas son las entradas de los integradores; la velocidad angular de referencia derivada está identificada por separado.

Cada serie conserva sus propios tiempos. La decimación es 10. Los datos brutos y las series extraídas están guardados, con catálogo, tablas de cobertura, eventos, resumen y perfiles inicial/relevado/final. Además, 87 canales se escribieron directamente a disco mediante bloques To File; los 87 se cargaron y verificaron después del cierre y cubren el fin de la maniobra.

Hay 23 figuras independientes, cada una en PNG y PDF, sin gráficas de modos. Las figuras temporales terminan en el último apoyo, a los 608,60 s; los registros completos incluyen el contacto posterior, la liberación y la parada. La aceleración de izaje incluye escala completa y zoom vertical de ±1 m/s². La comprobación de escalas no encontró muestras fuera de los ejes salvo el recorte deliberado del zoom. Se incluyen capturas HMI de barrido, contactos, transferencias y estado final.

### Comportamiento observado

En los tramos cargados, el ángulo físico máximo absoluto fue 0,02877 rad para la ida y 0,01425 rad para el regreso. Las velocidades máximas del carro en esos tramos fueron 2,419 y 1,673 m/s, respectivamente. Estos valores describen esta corrida; no demuestran por sí solos una comparación causal con una corrida sin antisway.

En el registro completo, el torque físico máximo absoluto del carro fue 1,699 kNm y el de izaje 15,212 kNm. La aceleración física máxima absoluta de izaje fue 144,628 m/s² a los 608,66052 s, inmediatamente después de detectar el último apoyo. Ese pico pertenece al transitorio de contacto del modelo y está conservado en los datos completos; ocurre después del corte de las figuras a 608,60 s. No interpretarlo como aceleración sostenida de la maniobra.

El mensaje de colisión está oculto en el HMI por indicación del usuario. Esto no certifica ausencia geométrica de colisiones. La prueba completa tampoco sustituye la prueba específica de cobertura del autómata de seguridad.

## Incidencias y correcciones

- Primer intento: terminó sin tomar carga a los 175,44 s porque el primer slot no recibió muestras y el perfil permaneció inválido. Se conservaron datos y gráficas de ese intento separado.
- Corrección del barrido: la transición izquierda usa la posición LiDAR (lidarX<=-28.78) con velocidad baja, además de la salida por límite normal. El objetivo de frenado del carro pasó de -24,6 a -26,0 m. La copia del proyecto compiló con cero errores y cero advertencias.
- Comprobación de enlace: un intento no llegó a simular por timeout de arranque. Se habilitó el reloj del banco antes de esperar el primer acuse.
- Ejecución previa: completó físicamente los transportes, pero el cierre quedó bloqueado y el reinicio de la PC perdió las señales finales que seguían en memoria. Se conservan únicamente telemetría, eventos, perfiles y capturas de esa ejecución; no usarlos para torques ni aceleraciones de la corrida final.
- Corrida final: cierre autónomo a 640 s, sin espera bloqueante en MATLAB, más 87 registros directos a disco. La actualización gráfica se limita a 5 Hz; HMI y operador conservan su paso de 40 ms. Todos los datos finales se guardaron y verificaron.

## Repetición

Usar el proyecto manual corregido incluido, Reset en caliente y RUN. MATLAB/Simulink R2025b, CODESYS V3.5 SP22 Patch 4 con Control Win V3 x64 y bibliotecas del proyecto. Python 3.12 con los requisitos incluidos. Configurar usuario OPC UA, certificados y confianza en la PC de destino; las claves privadas y contraseñas no se distribuyen. La huella del servidor de otra PC debe verificarse y configurarse antes de conectar.

Con esta carpeta en el path, ejecutar iniciar_prueba_completa_manual. El iniciador crea una carpeta numerada y reasigna las rutas de registro. Dejar terminar automáticamente a 640 s. Cuando el modelo esté detenido, ejecutar finalizar_prueba_completa_manual y validar_registro_disco. No bloquear el hilo MATLAB en un bucle esperando el cierre.

## Uso en el informe

Seguir INDICACIONES_PARA_INFORME.md. En el informe usar el nombre Prueba completa con CODESYS manual, sin nombres de modelos, proyectos o scripts. Los resultados definitivos corresponden a corrida_04; los intentos previos están separados y documentados.
