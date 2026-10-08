# S51: Watchdog durante emergencia parcial

Duración simulada: 5.5 s; muestras de salida: 276. Paso del chart: 20 ms.

`senales.mat` conserva el resultado Simulink, estímulos, parámetros, tiempos y salidas. `senales.csv` reúne las siete entradas físicas/de mando, las doce salidas del nivel y la indicación interna de sobrevelocidad de izaje. `estimulos_originales.csv` conserva los tiempos originales, incluidos los subciclos del ensayo S66. `cambios_salidas.csv` registra transiciones de salidas.

| Tipo | Comprobación | Tiempo [s] | Esperado | Observado | Resultado |
|---|---|---:|---|---|---|
| LOGICA | Parcial antes del watchdog | 0.24 | [1 0 1 0 1 1 1 0] | [1 0 1 0 1 1 1 0] | Cumple |
| LOGICA | Watchdog escala parcial a total | 5.2 | [0 0 0 0 0 0 1 1] | [0 0 0 0 0 0 1 1] | Cumple |

El vector de ocho salidas se ordena así: permiso global, permiso carro, permiso izaje, apertura freno carro, apertura freno izaje operativo, apertura freno izaje emergencia, emergencia y fallo watchdog. Un permiso/autorización en 1 admite la acción; un valor 0 la prohíbe. No es la confirmación física de un freno.

## Gráficas

- [alarmas](Graficas/alarmas.pdf) · [PNG](Graficas/alarmas.png)
- [entrada 4](Graficas/entrada_4.pdf) · [PNG](Graficas/entrada_4.png)
- [frenos](Graficas/frenos.pdf) · [PNG](Graficas/frenos.png)
- [mandos](Graficas/mandos.pdf) · [PNG](Graficas/mandos.png)
- [permisos](Graficas/permisos.pdf) · [PNG](Graficas/permisos.png)
