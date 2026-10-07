# Proyecto final de grúa

Repositorio local preparado el 7 de octubre de 2026. Reúne el informe vigente, cinco pruebas finales, sus señales y gráficas, los videos disponibles y las tres implementaciones realmente probadas.

## Contenido

- [Informe final](Informe/Informe_Proyecto_Grua_STS_3009.pdf): PDF, fuente LaTeX y todas las imágenes utilizadas, manteniendo las rutas relativas. Para compilar, trabajar dentro de `Informe/` y compilar el TEX principal dos veces.
- [Videos](Videos/README.md): un nombre descriptivo por prueba y aclaración sobre la ejecución previa de la prueba 1.
- [Prueba 1: barrido y dos transferencias](Pruebas/Prueba_1_Barrido_y_Dos_Transferencias/README.md).
- [CODESYS manual sin antisway](Pruebas/CODESYS_Manual_Sin_Antisway/README.md).
- [CODESYS manual con antisway](Pruebas/CODESYS_Manual_Con_Antisway/README.md).
- [CODESYS automático sin antisway](Pruebas/CODESYS_Automatico_Sin_Antisway/README.md).
- [CODESYS automático con antisway](Pruebas/CODESYS_Automatico_Con_Antisway/README.md).
- `Pruebas/Comparacion_y_Criterios/`: comparación gráfica y criterios de representación usados en el informe.
- [Simulink con Stateflow](Modelos/Simulink_Stateflow/README.md).
- [CODESYS manual SFC + Simulink OPC](Modelos/CODESYS_Manual/README.md).
- [CODESYS automático ST + Simulink OPC](Modelos/CODESYS_Automatico/README.md).
- [Conexión OPC UA](Documentacion/CONEXION_OPC_UA.md) y especificación original del medio ciclo.

## Resultado de cada prueba

| Prueba | Parada simulada | Resultado |
|---|---:|---|
| Stateflow: barrido y dos transferencias | 628 s | Dos entregas físicas; registro completo; sin video en la ejecución final. |
| CODESYS manual sin antisway | 187,20 s | Sin entrega; registro nativo parcial, telemetría completa hasta la parada. |
| CODESYS manual con antisway | 169,20 s | Entrega física confirmada. |
| CODESYS automático sin antisway | 180 s | Sin entrega; detención a tres minutos. |
| CODESYS automático con antisway | 279,52 s | Apoyo e intento de descarga; carga física retenida. |

Las gráficas con antisway terminan en el apoyo o intento de apoyo solicitado (168,92 s manual y 169,24 s automático); los archivos de señales preservan las muestras posteriores hasta su parada. No se extrapolan pérdidas del registro manual. Se incluyen todos los datos guardados disponibles, no datos reconstruidos de períodos ausentes. No se incluyen corridas preparatorias como resultados finales.

## Reproducción

Modelos, resultados y PDF se copiaron sin cambios de contenido. Sólo se añadieron índices y abridores para rutas locales; los PROJECT y SLX mantienen su identidad binaria. Se verificaron las copias; no se repitieron simulaciones al reunirlas.

Abrir los README de modelos antes de ejecutar: CODESYS necesita identidad OPC propia, carga del proyecto correcto y Reset en caliente. Los datos originales están separados de las carpetas ejecutables para evitar sobrescrituras. Este repositorio se inicializa con Git local, sin remoto ni publicación.
