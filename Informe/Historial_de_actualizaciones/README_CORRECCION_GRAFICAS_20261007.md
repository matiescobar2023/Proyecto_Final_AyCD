# Corrección de presentación de las gráficas

Fecha: 7 de octubre de 2026.

## Cambios solicitados

- Estilo similar a la imagen de referencia: fondo blanco, cuadrícula tenue, curvas azules y naranjas, leyendas, bandas grises y lavanda y marcas de eventos físicos.
- Una sola gráfica por figura; se retiraron las agrupaciones de paneles.
- Se mantienen fuera de las gráficas los modos de funcionamiento y sus marcas.
- Cada aceleración de izaje tiene una figura de escala completa y otra con zoom vertical entre -1 y +1 m/s², sobre todo el tiempo registrado. Los picos se conservan en la figura completa. El zoom no filtra ni modifica las señales.
- Se conserva el zoom temporal del torque de carro desde START como figura separada de su registro completo.
- Las comparaciones de cuatro pruebas se separaron en figuras individuales de posición, altura, ángulo y masa. La variación del perfil constituye otra figura independiente.

## Alcance

Se incorporan 89 figuras: 21 por cada una de las cuatro pruebas, cuatro comparaciones de señales y una comparación del perfil. Una figura puede superponer referencia y señal física de la misma magnitud; no contiene subgráficas.

Se conservan los resultados, cronología y explicaciones experimentales. Sólo se adaptan los pies, referencias cruzadas y descripción del método gráfico. No se ejecutaron simulaciones ni se modificó el PLC o los datos originales.

Se mantiene la cobertura parcial de CODESYS manual sin antisway y el bloqueo de descarga física de CODESYS automático con antisway. Las bandas y marcas no implican una entrega ni muestran modos de funcionamiento. Las figuras no contienen nombres de modelos o scripts.

## Verificación

Las 80 gráficas de señales con escala completa incluyen todas las muestras de su intervalo visible. Las cuatro ampliaciones verticales excluyen deliberadamente de su recuadro los picos fuera de +/-1 m/s²; su cantidad y extremos originales quedan auditados y los datos aparecen completos en las cuatro figuras correspondientes.

Las figuras y el PDF compilado se revisaron visualmente. La versión anterior de las agrupaciones se conserva en un respaldo fuera de la carpeta activa del informe.

## Corte temporal solicitado

- CODESYS manual con antisway: todas las curvas temporales terminan en el apoyo, a 168,92 s.
- CODESYS automático con antisway: todas las curvas temporales terminan en el intento de entrega, a 169,24 s, antes de la espera diagnóstica posterior.
- Sin antisway: se mantienen 187,20 s para CODESYS manual y 180,00 s para CODESYS automático, con las limitaciones de cobertura originales.
- Las comparaciones utilizan esos mismos cortes. La comparación del perfil también se evalúa al final del intervalo mostrado.
- No se recortan ni sobrescriben los registros originales. La entrega manual confirmada después del apoyo y el diagnóstico de bloqueo posterior se mantienen explicados y respaldados por los datos completos.

PDF final: 126 páginas, incluida portada. Las pruebas ocupan las páginas 73 a 121 del PDF. Compilación sin referencias pendientes ni cajas desbordadas. Las otras secciones mantienen su contenido.

En la comparación del perfil manual sin antisway se utiliza la última muestra de cobertura conservadora, a 130,72 s, sin extrapolar el tramo restante.
