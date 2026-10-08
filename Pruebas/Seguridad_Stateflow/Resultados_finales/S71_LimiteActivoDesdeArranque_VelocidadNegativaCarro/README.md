# S71: Limite activo desde arranque - Velocidad negativa carro

Duración simulada: 0.4 s; muestras de salida: 21. Paso del chart: 20 ms.

`senales.mat` conserva el resultado Simulink, estímulos, parámetros, tiempos y salidas. `senales.csv` reúne las siete entradas físicas/de mando, las doce salidas del nivel y la indicación interna de sobrevelocidad de izaje. `estimulos_originales.csv` conserva los tiempos originales, incluidos los subciclos del ensayo S66. `cambios_salidas.csv` registra transiciones de salidas.

| Tipo | Comprobación | Tiempo [s] | Esperado | Observado | Resultado |
|---|---|---:|---|---|---|
| ROBUSTEZ | Eje peligroso inhibido al arrancar | 0.1 | 0 | 1 | Hallazgo de robustez |

El vector de ocho salidas se ordena así: permiso global, permiso carro, permiso izaje, apertura freno carro, apertura freno izaje operativo, apertura freno izaje emergencia, emergencia y fallo watchdog. Un permiso/autorización en 1 admite la acción; un valor 0 la prohíbe. No es la confirmación física de un freno.

## Gráficas

- [alarmas](Graficas/alarmas.pdf) · [PNG](Graficas/alarmas.png)
- [entrada 5](Graficas/entrada_5.pdf) · [PNG](Graficas/entrada_5.png)
- [frenos](Graficas/frenos.pdf) · [PNG](Graficas/frenos.png)
- [mandos](Graficas/mandos.pdf) · [PNG](Graficas/mandos.png)
- [permisos](Graficas/permisos.pdf) · [PNG](Graficas/permisos.png)
