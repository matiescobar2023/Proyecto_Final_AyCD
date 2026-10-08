# S49: Watchdog congelado en 0

Duración simulada: 5.9 s; muestras de salida: 296. Paso del chart: 20 ms.

`senales.mat` conserva el resultado Simulink, estímulos, parámetros, tiempos y salidas. `senales.csv` reúne las siete entradas físicas/de mando, las doce salidas del nivel y la indicación interna de sobrevelocidad de izaje. `estimulos_originales.csv` conserva los tiempos originales, incluidos los subciclos del ensayo S66. `cambios_salidas.csv` registra transiciones de salidas.

| Tipo | Comprobación | Tiempo [s] | Esperado | Observado | Resultado |
|---|---|---:|---|---|---|
| LOGICA | Sin cambios aparece fallo y total | 5.26 | [0 0 0 0 0 0 1 1] | [0 0 0 0 0 0 1 1] | Cumple |
| LOGICA | Primer reset limpia WD, total permanece | 5.42 | [0 0 0 0 0 0 1 0] | [0 0 0 0 0 0 1 0] | Cumple |
| LOGICA | Segundo flanco rearma emergencia total | 5.72 | [1 1 1 1 1 1 0 0] | [1 1 1 1 1 1 0 0] | Cumple |

El vector de ocho salidas se ordena así: permiso global, permiso carro, permiso izaje, apertura freno carro, apertura freno izaje operativo, apertura freno izaje emergencia, emergencia y fallo watchdog. Un permiso/autorización en 1 admite la acción; un valor 0 la prohíbe. No es la confirmación física de un freno.

## Gráficas

- [alarmas](Graficas/alarmas.pdf) · [PNG](Graficas/alarmas.png)
- [detalle watchdog](Graficas/detalle_watchdog.pdf) · [PNG](Graficas/detalle_watchdog.png)
- [frenos](Graficas/frenos.pdf) · [PNG](Graficas/frenos.png)
- [mandos](Graficas/mandos.pdf) · [PNG](Graficas/mandos.png)
- [permisos](Graficas/permisos.pdf) · [PNG](Graficas/permisos.png)
