# MC con anticipación anti-sway limitada — 6/10/2026

Modelo: `Grua_MC_R2_FFLimitado_06102026.slx`.

Referencia regulatoria: `../R2_Bloques_FFLimitado_06102026/GruaSeg_R2_FFLimitado_06102026.slx`, copia de `modelo_ensayado.slx` del ensayo `Ciclo_R2_HabilitacionLineal_2s_06102026`. Se verificó que su MATLAB Function contiene la ley FF guardada en aquel ensayo. La única adaptación de esa copia es la ruta de inicialización al nuevo nombre y carpeta.

## Ley implementada

Con E=1 y orden de freno abierto:

```
h = max(Ts, 1e-6)
alpha[n] = min(1, alpha[n-1] + h/T_on)
k_fb = 2*sqrt(g*l)
k_ff = 2*sqrt(9.80665*max(1,l))
theta_ref = atan2(-aRef,g)
ff_obj = -k_ff*theta_ref
ff[n] = ff[n-1] + clip(ff_obj - ff[n-1], -R_ff*h, R_ff*h)
feedbackUsed = alpha[n]*k_fb*theta
anticipationUsed = alpha[n]*ff[n]
v_sw = clip(feedbackUsed + anticipationUsed, -3.2, 3.2)
```

`T_on=2 s`, `R_ff=0.25 m/s²`, `Ts=0.001 s`. En el MC `R_ff` es el parámetro `MC_FF.swayFFRate`, definido en `configurar_parametros_variadores.m` y transportado por el bus de parámetros. El valor proviene de la versión de bloques ensayada.

La limitación corresponde a la derivada de una contribución de **velocidad** anti-sway. No limita aRef ni modifica los generadores de referencias. La rampa alpha multiplica ambas ramas. El feedback no atraviesa el limitador de variación de FF. La derivada de la contribución aplicada `alpha*ff` puede superar R_ff durante la habilitación, por el término `ff*dalpha/dt`; el límite se aplica al estado ff antes de alpha.

Si E=0 o la orden de freno está cerrada: v_sw, ambas contribuciones, ff y alpha se hacen cero inmediatamente. Se conserva el comportamiento probado, incluida esa deshabilitación inmediata. El freno aquí es la orden del supervisor; no se redefine su secuencia ni se sustituye por el estado mecánico efectivo.

## Arquitectura y regulación preservadas

Se parte del último MC aprobado: `../MC_R2_Variadores_Discreto_06102026/`. Tres MATLAB Functions dentro del MC: `Estimadores`, `MC Carro` y `MC Izaje`. Los cálculos del carro, incluido anti-sway, están en su función. Los cálculos de izaje están en la suya. Entre funciones solo viajan buses; los selectores de diagnóstico son pasivos. El contenedor no es atómico para permitir que las estimaciones alimenten el supervisor sin introducir una dependencia artificial de las referencias.

Los observadores de encoder usan la misma discretización Tustin a 1 ms del MC aprobado. Los archivos `mc_estimadores.m` y `mc_eje_izaje.m` conservan su código. El autómata, pesaje y estimación de masa, perfiles, referencias, transferencias, interbloqueos y gestión del freno no se implementaron ni trasladaron al MC.

Los límites de ambos generadores de referencias permanecen en 0.3 m/s². El regulador limita a_cmd a ±0.8 m/s² y conserva PI, anti-windup de aceleración y torque, y sus estados. El modo MANUAL/AUTO/barrido no entra en la regulación. La compensación horizontal usa theta medida independientemente de E.

El anti-windup conserva:

```
Delta_a = Delta_a_limite[n-1] + i_t/(r_td*M_EQt)*Delta_T[n-1]
entrada_integrador = error_v + Delta_a/Ki
Imax = amax/Ki
```

La integral conserva la actualización Tustin y limitación separada de salida y estado del bloque original. La ganancia de torque no usa un número fijo.

## Verificación y uso

`verificar_regulacion_variadores` compara los subsistemas reales del modelo de bloques y del MC con exactamente las mismas estimaciones. Fuerza saturación de PI/aceleración y recorte de torque, abre/cierra el freno y alterna E. Los trece resultados coinciden exactamente.

`ensayar_variadores_mc` ejecuta la maniobra completa en RAM. No guarda un paquete nuevo de señales ni video. `comparar_variadores_mc` y `analizar_desempeno_variadores` generan métricas, informes y figuras de las corridas ya disponibles en RAM. `ejemplo_analisis.m` abre las figuras guardadas sin simular.

Las señales de la nueva corrida quedan en `ffRun.signals`, su salida Simulink en `ffRun.output`; no son persistentes tras cerrar MATLAB. La referencia de bloques permanece disponible en su carpeta histórica de ensayo. Las cifras finales y diferencias se encuentran en `Ciclo_MC_FFLimitado_06102026/comparacion_mc/INFORME_COMPARACION.md` y `analisis_desempeno/INFORME_DESEMPENO.md`.

`verificacion_charts_originales.csv` compara los XML de los charts con el último MC simple: once son idénticos; los tres del MC cambian por los nombres independientes de buses, y únicamente el carro cambia su ley.
