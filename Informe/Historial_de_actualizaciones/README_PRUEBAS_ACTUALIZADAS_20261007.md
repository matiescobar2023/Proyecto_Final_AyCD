> Presentación gráfica corregida posteriormente: la versión activa contiene 89 figuras individuales y 126 páginas, con corte de las curvas con antisway en 168,92 s y 169,24 s. El detalle actualizado de estilo, separación y zoom se documenta en el README de corrección de gráficas. Los resultados experimentales descritos abajo se mantienen.

# Actualización de pruebas de medio ciclo

Fecha: 7 de octubre de 2026.

## Cambios

- Reemplazo completo de las tres secciones de pruebas anteriores: CODESYS manual, CODESYS automático y comparación experimental.
- Actualización del resumen de resultados dentro del apartado del supervisor, que todavía describía entregas de corridas anteriores.
- Incorporación de 18 figuras nuevas: cuatro grupos de gráficas por prueba, comparación de las cuatro trayectorias y confirmación por variación del perfil físico.
- Dinámica: posiciones, velocidades y aceleraciones de carro e izaje, referencias, aceleración horizontal de la carga, ángulo y velocidad angular del péndulo.
- Control y actuación: referencia base y comando de velocidad, corrección antisway efectiva, errores de posición y velocidad, consignas y torques físicos de ambos motores, tensión y masa suspendida.
- Los modos de funcionamiento no aparecen en gráficas ni como marcas sobre sus ejes. La secuencia se explica en el texto.
- La redacción incorporada no muestra nombres de modelos, proyectos, scripts ni rutas: utiliza los nombres de las pruebas.
- No se modificaron las demás secciones, diagramas de autómatas ni el contenido de la prueba nominal anterior de Simulink.

## Resultados documentados

| Prueba | Fin simulado | Resultado |
|---|---:|---|
| CODESYS manual sin antisway | 187,20 s | Sin entrega, carga retenida; registro nativo parcial. |
| CODESYS manual con antisway | 169,20 s | Entrega física confirmada; masa final 15.000 kg. |
| CODESYS automático sin antisway | 180,00 s | Límite programado, sin entrega; masa final 51.863 kg. |
| CODESYS automático con antisway | 279,52 s | Apoyo alcanzado, descarga física bloqueada; masa final 51.863 kg. |

En la última prueba el PLC indica vacío y twistlocks abiertos, pero la planta mantiene carga. La tensión de aproximadamente 99,54 kN supera el umbral de desactivación de 15,009 kN de la histéresis física de descarga. Se describe esta condición inmediata y la divergencia entre consigna y torque físico de izaje, sin atribuir una causa raíz no demostrada al generador de código. No se declara entrega completada.

## Cobertura y representación

La prueba manual sin antisway conserva control y monitores hasta 130,72 s, numerosas señales físicas hasta 177,305 s y telemetría de posiciones hasta 187,20 s. Las curvas se detienen en su última muestra; no se extrapolan referencias, errores ni torques. La comprobación de antisway nula se limita a su cobertura nativa. Las otras tres pruebas conservan registro hasta la parada.

Las figuras de torques incluyen el arranque completo y una ampliación de la maniobra. La velocidad angular de referencia es derivada; la señal física es nativa. Los transitorios de contacto se conservan sin filtrado. Los valores nativos de máxima corrección son 0,46245 m/s en CODESYS manual con antisway y 0,46702 m/s en CODESYS automático con antisway.

Las comparaciones completas de trayectorias son descriptivas. No se comparan esperas truncadas con ciclos completos para calcular mejoras globales de RMS. Sólo una prueba confirmó entrega, con retiro de 2,59 m en origen e incremento de 2,59 m en destino. El detector dedicado de colisión no estuvo disponible; los márgenes geométricos no se presentan como certificación de ausencia de colisiones.

## Comprobaciones

- Generación offline con MATLAB; no se ejecutaron nuevas simulaciones ni se modificó el PLC.
- 80 paneles de señales verificados numéricamente: cero muestras fuera de escala. Las líneas de umbral también se incluyen en los límites.
- Revisión visual de las gráficas y las páginas nuevas, con figuras de cada prueba agrupadas antes de la siguiente.
- Compilación con referencias resueltas y sin cajas desbordadas; permanecen advertencias previas de clase, captions y justificación de párrafos ajenos a esta edición.
- PDF final: 96 páginas, incluida portada. Las pruebas nuevas ocupan las páginas 73 a 91 del PDF.
- Valores y afirmaciones de las corridas desactualizadas retirados del informe; figuras y evidencia antigua de estas pruebas archivadas fuera de la carpeta activa del informe.
- Los datos brutos y videos originales de las cuatro pruebas permanecen intactos. Se incluyen tablas de eventos, criterios y cobertura; no se duplican los MAT brutos en el repositorio.

Se conserva un respaldo previo y el procesamiento en la carpeta de trabajo de esta actualización. Las copias finales del PDF en la raíz del informe y en su carpeta de salida son idénticas.
