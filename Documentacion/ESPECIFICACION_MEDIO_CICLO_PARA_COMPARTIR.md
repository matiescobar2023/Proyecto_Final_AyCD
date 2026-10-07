# Especificación para implementar y registrar la prueba de medio ciclo

## Encargo

Crear una **copia independiente** del modelo de grúa entregado en `GruaPerfilSeg_30092026/ensayo_izaje_auto_sin_descenso_20261001/GruaPerfilSeg_30092026.slx` y preparar una prueba de **medio ciclo cargado**, apta para evaluar control. Conservar la lógica de perfil, envolvente local, cruce alto, izaje y frenos de ese modelo, salvo las adaptaciones imprescindibles para inicializar el ensayo. No modificar el modelo fuente.

La primera variante que se desea evaluar es **sin antisway efectivo**: en la entrada del controlador de velocidad del carro debe cumplirse `v_cmd = v_ref`, es decir, la contribución `v_sw` debe ser cero **en el sumador**. No basta con apagar un indicador de HMI si la corrección sigue llegando al controlador. Guardar también la posibilidad de repetir el mismo ensayo con antisway activo y las ganancias actuales como referencia comparativa; esa segunda corrida debe usar condiciones iniciales y criterios idénticos. Identificar inequívocamente cada variante en metadatos y resultados.

## Tramo de maniobra

1. **Inicio:** carro en reposo y alineado con el slot 2 del muelle (`x ≈ −26,34 m`); spreader vacío cerca del contenedor, a la altura inicial utilizada por la prueba anterior (aproximadamente 25 m). No iniciar a 39 m ni ejecutar un relevamiento dentro de esta corrida.
2. **Perfil inicial:** cargar antes del inicio el vector de **33 alturas** correspondiente al escenario físico inicial. Inicializar coherentemente en el supervisor el perfil, `profileValid`, el máximo del perfil y la envolvente local que calcula el autómata. Verificar que el perfil del supervisor coincide con los obstáculos de la planta. Registrar el vector y su procedencia. No simular un barrido LiDAR ficticio ni modificar la planta para acomodar un perfil erróneo.
3. **Toma manual:** descender en manual sobre el contenedor del slot 2, cerrar twistlocks y confirmar la toma. El contenedor y su masa deben pasar efectivamente a la planta; registrar el instante y el estado de carga.
4. **Despegue manual:** elevar el contenedor hasta superar la altura de seguridad local que **habilita** automático según el modelo usado. El operador virtual solicita automático cuando se cumple esa condición y el movimiento está estabilizado; el autómata decide la transición efectiva. No forzar `modeCode` ni puentear permisos.
5. **Traslado cargado:** seleccionar el slot 22 del barco y ejecutar el movimiento automático existente, con su altura alta de cruce. Mantener los perfiles y límites de seguridad del modelo fuente. Registrar por separado el momento de solicitud y el de entrada efectiva a automático.
6. **Entrega manual:** al cumplirse la condición normal de salida del automático cerca del destino, solicitar manual. Descender, apoyar el contenedor y abrir twistlocks. Confirmar que la masa vuelve a la planta/slot de destino.
7. **Fin:** detener la prueba al confirmar la entrega. No extraer el spreader, no iniciar retorno vacío y no realizar un nuevo relevamiento.

La maniobra manual debe ser suave y reproducible. El operador virtual puede aplicar esperas y consignas graduales, pero no debe escribir directamente las posiciones reales ni alterar el controlador regulatorio para mejorar artificialmente el resultado. Documentar los umbrales, pausas y velocidades que use.

## Variantes y alcance de cambios

| Variante | Contribución al sumador del carro | Finalidad |
| --- | --- | --- |
| `sin_antisway` | `v_cmd = v_ref`; verificar `v_sw_efectiva = 0` en todo el ensayo | Medir el medio ciclo sin compensación de balanceo. |
| `referencia_antisway` | `v_cmd = v_ref + v_sw_efectiva`, con ajuste actual | Comparación directa bajo el mismo perfil y condiciones iniciales. |

El cálculo interno de `v_sw` puede seguir registrándose en la variante sin antisway. Separar en los datos **corrección calculada, limitada y efectivamente sumada**. En ambas variantes dejar constantes las ganancias del carro y del izaje, la carga, el perfil, el operador virtual y las condiciones iniciales. Si el ensayo sin antisway activa una falla de seguimiento o algún interlock, **registrar el fallo y su causa**; cualquier prueba adicional con un umbral modificado debe guardarse como otra variante explícita y nunca sobrescribir la corrida original. No declarar aprobada una entrega que no ocurrió.

## Registro obligatorio de señales

Guardar las **series originales con sus propios vectores de tiempo**, nombres, unidades, origen del bloque y frecuencia/método de muestreo. Conservar el tiempo de simulación en segundos; al combinar señales de diferentes tasas, interpolar por tiempo, no por índice. Registrar, como mínimo:

| Grupo | Señales requeridas |
| --- | --- |
| Cinemática del carro | Posición, velocidad y aceleración **reales y de referencia**; error de posición y velocidad; `v_ref`, `v_cmd` y, si existe, referencia previa al acondicionamiento. |
| Cinemática del izaje | Altura, velocidad y aceleración **reales y de referencia**; error de altura y velocidad; límites de velocidad/aceleración vigentes. |
| Balanceo | Ángulo real y de referencia; velocidad angular real y de referencia; `v_sw` calculada, limitada y efectiva; selección y habilitación antisway. |
| Actuación | Consignas de torque de carro e izaje; torque a la entrada de cada planta; torque físico de motores; saturaciones, frenos, habilitaciones y permisos relevantes. |
| Carga y cable | Tensión del cable de izaje; masa estimada; masa física total suspendida; estado de carga y twistlocks. |
| Sensores y perfil | Valores de sensores usados por el autómata, idealmente crudos y procesados; perfil inicial y actualizado, `profileValid`, máximo y envolvente local. |
| Estado y órdenes | Modo efectivo, estado/subestado del autómata si está disponible, etapa del operador, solicitudes de manual/automático, selección de slot, órdenes HMI, alarmas/fallas y sus causas. |
| Tiempo | `t` de cada serie y marcas de los eventos de toma, despegue, entrada/salida de automático, llegada, apoyo y apertura de twistlocks. |

Si una señal no está expuesta, instrumentarla sin modificar su dinámica. El catálogo debe indicar las señales no disponibles y por qué. Diferenciar **referencia, consigna, señal aplicada y medición física**; no usar el mismo nombre para magnitudes distintas.

## Archivos a entregar por corrida

Crear una carpeta separada para cada variante, por ejemplo `medio_ciclo/sin_antisway/` y `medio_ciclo/referencia_antisway/`. Incluir:

- Copia del `.slx` realmente simulado y de los scripts/parámetros necesarios para repetir la corrida.
- `datos_brutos.mat` con señales originales de Simulink y sus `.Time`/`.Data`.
- `datos_derivados.mat` solo para magnitudes calculadas después, con método documentado (por ejemplo, velocidad angular de referencia si no existe directamente).
- `catalogo_senales.csv` con nombre, descripción, unidad, origen, tasa y distinción entre real/referencia/consigna/aplicada.
- `eventos_modo.csv` y `eventos_maniobra.csv`, ambos en segundos de simulación y con descripción legible; registrar solicitudes y cambios **efectivos** por separado.
- `criterios.csv` con resultado, valor medido, umbral y motivo de cada criterio; `metadatos.json` con modelo, fecha, variante, perfil, masa inicial, parámetros de control, configuración antisway, versión de MATLAB/Simulink, tiempo final y causa de terminación.
- `README.md` con instrucciones para reproducir y una síntesis de lo observado, incluyendo fallas o maniobras incompletas.
- `ejemplo_analisis.m` que cargue los datos guardados, trace las variables principales, marque los cambios de modo y construya una tabla de duraciones. Las figuras exportadas son opcionales, pero el script debe poder generarlas sin rerun de la simulación.

Preferir MAT para conservar precisión y tasas originales. CSV de eventos y criterios debe poder abrirse sin MATLAB. Guardar nombres estables y un archivo por corrida; no sobrescribir una variante con otra.

## Criterios de comprobación

Verificar y reportar individualmente: posición y reposo iniciales; correspondencia del perfil con la escena; perfil válido sin LiDAR; toma manual confirmada; masa física cargada; despegue manual; permiso y transición real a automático; traslado al slot 22 sin pérdida de despeje ni colisiones; paso efectivo a manual; apoyo y entrega confirmados; ausencia de retorno; y estado final sin emergencia ni falla. Para la variante sin antisway comprobar numéricamente `v_cmd − v_ref ≈ 0` en el punto de entrada al controlador, además de `v_sw_efectiva ≈ 0`. Una corrida puede quedar **no aprobada** y aun así debe conservarse íntegra para diagnóstico.

Calcular para cada etapa al menos duración, máximos de `|x_ref−x|` y `|y_ref−y|`, velocidad/aceleración máximas, ángulo máximo y RMS, oscilación residual al llegar, torques máximos y RMS, tensión máxima/mínima, y saturaciones/interlocks. Comparar las dos variantes solo sobre etapas efectivamente completadas por ambas; indicar claramente si una se abortó antes.

## Borrador de `ejemplo_analisis.m`

Adaptar los nombres del bloque `S` al catálogo definitivo. Este ejemplo supone que `datos_brutos.mat` contiene `output`, que las señales supervisadas se guardan como campos `output.mon_*`, y que las internas están en `output.logsout`. Si la instrumentación usa otro esquema, crear una función de mapeo en vez de cambiar los datos originales.

```matlab
% EJEMPLO_ANALISIS Medio ciclo; no ejecuta la simulacion.
carpeta = fileparts(mfilename('fullpath'));
R = load(fullfile(carpeta,'datos_brutos.mat'),'output');
out = R.output;
E = readtable(fullfile(carpeta,'eventos_modo.csv'));
M = readtable(fullfile(carpeta,'eventos_maniobra.csv'));

% Ajustar estos nombres al catalogo_senales.csv de la corrida.
S.x = out.mon_xT;       S.xr = out.mon_xRef;
S.y = out.mon_yH;       S.yr = out.mon_yRef;
S.theta = out.mon_theta;
S.tension = out.mon_ropeTension;
S.thetaRef = out.logsout.get('angulo_referencia').Values;
S.vsw = out.logsout.get('antisway_correccion_efectiva').Values;
S.tauXcmd = out.logsout.get('torque_carro_consigna_controlador').Values;
S.tauXfis = out.logsout.get('torque_carro_fisico_motor').Values;
S.tauYcmd = out.logsout.get('torque_izaje_consigna_controlador').Values;
S.tauYfis = out.logsout.get('torque_izaje_fisico_motor').Values;

figure('Name','Seguimiento de posicion'); tiledlayout(2,1);
nexttile; plot(S.x.Time,S.x.Data,S.xr.Time,S.xr.Data); grid on;
ylabel('Carro x [m]'); legend('real','referencia','Location','best');
nexttile; plot(S.y.Time,S.y.Data,S.yr.Time,S.yr.Data); grid on;
ylabel('Izaje y [m]'); xlabel('Tiempo [s]');
legend('real','referencia','Location','best');

figure('Name','Balanceo y antisway'); tiledlayout(2,1);
nexttile; plot(S.theta.Time,rad2deg(S.theta.Data), ...
              S.thetaRef.Time,rad2deg(S.thetaRef.Data)); grid on;
ylabel('Angulo [grados]'); legend('real','referencia','Location','best');
nexttile; plot(S.vsw.Time,S.vsw.Data); grid on;
ylabel('v_{sw} efectiva [m/s]'); xlabel('Tiempo [s]');

figure('Name','Torques y tension'); tiledlayout(3,1);
nexttile; plot(S.tauXcmd.Time,S.tauXcmd.Data, ...
              S.tauXfis.Time,S.tauXfis.Data); grid on;
ylabel('Carro [N m]'); legend('consigna','fisico');
nexttile; plot(S.tauYcmd.Time,S.tauYcmd.Data, ...
              S.tauYfis.Time,S.tauYfis.Data); grid on;
ylabel('Izaje [N m]'); legend('consigna','fisico');
nexttile; plot(S.tension.Time,S.tension.Data); grid on;
ylabel('Tension [N]'); xlabel('Tiempo [s]');

figure('Name','Modos efectivos');
stairs(E.tiempo_s,E.modo_codigo,'LineWidth',1.3); grid on;
xlabel('Tiempo [s]'); ylabel('Codigo de modo');

% Cada fila de M debe ser una marca de inicio de etapa ordenada por tiempo.
duraciones = table(string(M.etapa(1:end-1)), M.tiempo_s(1:end-1), ...
    M.tiempo_s(2:end), diff(M.tiempo_s), ...
    'VariableNames',{'etapa','inicio_s','fin_s','duracion_s'});
disp(duraciones);

% Error de seguimiento: interpolar referencias sobre el tiempo real.
ex = S.x.Data - interp1(S.xr.Time,S.xr.Data,S.x.Time,'linear','extrap');
ey = S.y.Data - interp1(S.yr.Time,S.yr.Data,S.y.Time,'linear','extrap');
fprintf('Error maximo: carro %.3f m; izaje %.3f m\n', ...
    max(abs(ex)), max(abs(ey)));
fprintf('Angulo maximo: %.3f grados\n', ...
    max(abs(rad2deg(S.theta.Data))));
% writetable(duraciones,fullfile(carpeta,'duraciones.csv'));
% exportgraphics(gcf,fullfile(carpeta,'figura.png'),'Resolution',300);
```

Ampliar ese script con las velocidades/aceleraciones, velocidades angulares, masa, sensores, energía/potencia si se registran, y sombreado de etapas. Para comparar variantes, cargar ambas carpetas y alinear las curvas por el evento de entrada efectiva al automático, además de mostrar los tiempos absolutos de cada corrida.
