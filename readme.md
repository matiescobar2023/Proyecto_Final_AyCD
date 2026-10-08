# Proyecto final de grúa

Repositorio local preparado el 7 de octubre de 2026. Reúne el informe vigente, siete grupos de pruebas, sus señales y gráficas, los videos disponibles y las tres implementaciones realmente probadas.

Actualizado el 8 de octubre de 2026 con las pruebas de seguridad Stateflow y ciclo completo CODESYS manual, y el video de su repetición sin señales.

## Contenido

- [Informe final](Informe/Informe_Proyecto_Grua_STS_3009.pdf): PDF, fuente LaTeX y todas las imágenes utilizadas, manteniendo las rutas relativas. Para compilar, trabajar dentro de `Informe/` y compilar el TEX principal dos veces.
- [Videos](Videos/README.md): un nombre descriptivo por prueba y aclaración sobre la ejecución previa de la Prueba ciclo completo en simulink.
- [Prueba ciclo completo en simulink](Pruebas/Prueba_ciclo_completo_en_simulink/README.md).
- [CODESYS manual sin antisway](Pruebas/CODESYS_Manual_Sin_Antisway/README.md).
- [CODESYS manual con antisway](Pruebas/CODESYS_Manual_Con_Antisway/README.md).
- [CODESYS automático sin antisway](Pruebas/CODESYS_Automatico_Sin_Antisway/README.md).
- [CODESYS automático con antisway](Pruebas/CODESYS_Automatico_Con_Antisway/README.md).
- [Seguridad Stateflow: 75 escenarios](Pruebas/Seguridad_Stateflow/README.md).
- [Prueba completa con CODESYS manual](Pruebas/CODESYS_Manual_Ciclo_Completo/README.md).
- `Pruebas/Comparacion_y_Criterios/`: comparación gráfica y criterios de representación usados en el informe.
- [Simulink con Stateflow](Modelos/Simulink_Stateflow/README.md).
- [CODESYS manual SFC + Simulink OPC](Modelos/CODESYS_Manual/README.md).
- [CODESYS automático ST + Simulink OPC](Modelos/CODESYS_Automatico/README.md).
- [Conexión OPC UA](Documentacion/CONEXION_OPC_UA.md) y especificación original del medio ciclo.

## Resultado de cada prueba

| Prueba | Parada simulada | Resultado |
|---|---:|---|
| Prueba ciclo completo en simulink | 628 s | Dos entregas físicas; registro completo; sin video en la ejecución final. |
| CODESYS manual sin antisway | 187,20 s | Sin entrega; registro nativo parcial, telemetría completa hasta la parada. |
| CODESYS manual con antisway | 169,20 s | Entrega física confirmada. |
| CODESYS automático sin antisway | 180 s | Sin entrega; detención a tres minutos. |
| CODESYS automático con antisway | 279,52 s | Apoyo e intento de descarga; carga física retenida. |
| Seguridad Stateflow | Según cada escenario | 75 escenarios; 143 comprobaciones de lógica conformes y 14 desafíos de robustez no satisfechos, documentados. |
| CODESYS manual: barrido y dos transferencias | 611,08 s; registro hasta 640 s | Dos entregas físicas, 534 series y 87 registros directos. Video de una repetición posterior sin señales. |

Las gráficas con antisway terminan en el apoyo o intento de apoyo solicitado (168,92 s manual y 169,24 s automático); los archivos de señales preservan las muestras posteriores hasta su parada. No se extrapolan pérdidas del registro manual. Se incluyen todos los datos guardados disponibles, no datos reconstruidos de períodos ausentes. Las incidencias preparatorias de la prueba manual completa se conservan separadas de sus resultados definitivos.

## Reproducción

Los resultados históricos y los proyectos PLC se conservan. Las carpetas de modelos contienen las constantes, la visualización/HMI y sus dependencias internas de ejecución. Se retiraron los scripts de ensayo, operadores externos, registros y análisis; los callbacks SLX cargan los parámetros locales y no ejecutan ensayos. Se comprobó la compilación de los seis modelos y que sus archivos internos Stateflow no cambiaron.

Abrir los README de modelos antes de ejecutar: CODESYS necesita identidad OPC propia, carga del proyecto correcto y Reset en caliente. Los datos originales están separados de las carpetas ejecutables para evitar sobrescrituras. Este repositorio se inicializa con Git local, sin remoto ni publicación.
