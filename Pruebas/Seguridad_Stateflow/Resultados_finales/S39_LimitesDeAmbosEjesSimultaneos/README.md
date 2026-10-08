# S39: Limites de ambos ejes simultaneos

Duración simulada: 0.8 s; muestras de salida: 41. Paso del chart: 20 ms.

`senales.mat` conserva el resultado Simulink, estímulos, parámetros, tiempos y salidas. `senales.csv` reúne las siete entradas físicas/de mando, las doce salidas del nivel y la indicación interna de sobrevelocidad de izaje. `estimulos_originales.csv` conserva los tiempos originales, incluidos los subciclos del ensayo S66. `cambios_salidas.csv` registra transiciones de salidas.

| Tipo | Comprobación | Tiempo [s] | Esperado | Observado | Resultado |
|---|---|---:|---|---|---|
| LOGICA | Prioridad de izaje implementada | 0.24 | [1 1 0 1 0 0 1 0] | [1 1 0 1 0 0 1 0] | Cumple |
| LOGICA | El flanco de carro no se vuelve a evaluar | 0.6 | [1 1 0 1 0 0 1 0] | [1 1 0 1 0 0 1 0] | Cumple |
| ROBUSTEZ | Ambos ejes peligrosos deben quedar inhibidos | 0.24 | [0 0] | [1 0] | Hallazgo de robustez |

El vector de ocho salidas se ordena así: permiso global, permiso carro, permiso izaje, apertura freno carro, apertura freno izaje operativo, apertura freno izaje emergencia, emergencia y fallo watchdog. Un permiso/autorización en 1 admite la acción; un valor 0 la prohíbe. No es la confirmación física de un freno.

## Gráficas

- [alarmas](Graficas/alarmas.pdf) · [PNG](Graficas/alarmas.png)
- [entrada 4](Graficas/entrada_4.pdf) · [PNG](Graficas/entrada_4.png)
- [entrada 6](Graficas/entrada_6.pdf) · [PNG](Graficas/entrada_6.png)
- [frenos](Graficas/frenos.pdf) · [PNG](Graficas/frenos.png)
- [mandos](Graficas/mandos.pdf) · [PNG](Graficas/mandos.png)
- [permisos](Graficas/permisos.pdf) · [PNG](Graficas/permisos.png)
