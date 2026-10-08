# Ejecución anterior: solo telemetría y capturas

Se completaron el relevamiento, las dos tomas, las dos entregas y la parada normal, confirmada a los 612,36 s. Quedaron guardados los eventos y la telemetría HMI en los archivos del operador, el diagnóstico del barrido y las capturas.

El cierre de la simulación quedó bloqueado porque una función esperaba que el motor se detuviera antes de devolver el control a MATLAB. No se llegó a guardar el output completo de señales antes del reinicio de la PC. Esta carpeta no contiene resultados completos de torques, aceleraciones o demás canales internos.

Para la repetición se eliminó esa espera y se fijó un tiempo final de simulación. Se agregó registro directo a disco de 87 canales físicos y monitores, manteniendo el registro completo de las demás señales.
