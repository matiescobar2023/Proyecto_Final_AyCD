# S05: Posicion minima carro - retencion y rearme

Duración simulada: 0.8 s; muestras de salida: 41. Paso del chart: 20 ms.

`senales.mat` conserva el resultado Simulink, estímulos, parámetros, tiempos y salidas. `senales.csv` reúne las siete entradas físicas/de mando, las doce salidas del nivel y la indicación interna de sobrevelocidad de izaje. `estimulos_originales.csv` conserva los tiempos originales, incluidos los subciclos del ensayo S66. `cambios_salidas.csv` registra transiciones de salidas.

| Tipo | Comprobación | Tiempo [s] | Esperado | Observado | Resultado |
|---|---|---:|---|---|---|
| LOGICA | Intervencion de eje | 0.24 | [1 0 1 0 1 1 1 0] | [1 0 1 0 1 1 1 0] | Cumple |
| LOGICA | Reinicio rechazado con causa activa | 0.32 | [1 0 1 0 1 1 1 0] | [1 0 1 0 1 1 1 0] | Cumple |
| LOGICA | Retencion tras desaparecer la causa | 0.5 | [1 0 1 0 1 1 1 0] | [1 0 1 0 1 1 1 0] | Cumple |
| LOGICA | Nuevo flanco con causa inactiva | 0.62 | [1 1 1 1 1 1 0 0] | [1 1 1 1 1 1 0 0] | Cumple |

El vector de ocho salidas se ordena así: permiso global, permiso carro, permiso izaje, apertura freno carro, apertura freno izaje operativo, apertura freno izaje emergencia, emergencia y fallo watchdog. Un permiso/autorización en 1 admite la acción; un valor 0 la prohíbe. No es la confirmación física de un freno.

## Gráficas

- [alarmas](Graficas/alarmas.pdf) · [PNG](Graficas/alarmas.png)
- [entrada 4](Graficas/entrada_4.pdf) · [PNG](Graficas/entrada_4.png)
- [frenos](Graficas/frenos.pdf) · [PNG](Graficas/frenos.png)
- [mandos](Graficas/mandos.pdf) · [PNG](Graficas/mandos.png)
- [permisos](Graficas/permisos.pdf) · [PNG](Graficas/permisos.png)
