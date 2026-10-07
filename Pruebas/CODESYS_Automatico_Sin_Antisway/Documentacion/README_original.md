# Corrida MC_R2_ST_RELOJ_sin_antisway

Resultado completo: 0. Tiempo final: 180.00 s.

Causa: Limite de 180 s: sin antisway, prueba valida sin entrega.

Datos brutos y buses en datos_brutos.mat, con tiempos nativos; derivados separados. El catalogo de hojas de los buses es catalogo_senales_mc.csv.

Video: D:\AyCD\Chat\Proyecto_grua\version codesys\Prueba_MC_R2_FFLimitado_OPCUA_20261006\Correccion_Automatica_ST_Relojes_Separados\sin_antisway\Video_prueba_conjunta\Prueba_HMI_Simulink_20261006_224533.mp4.

Ver README del banco para las adaptaciones y la diferencia de transferencia del supervisor.

## Resultado interpretado

**Prueba valida, maniobra incompleta**. Se detuvo exactamente a 180,00 s por el limite solicitado, sin fallas ni emergencia durante la maniobra. La carga permanecio suspendida en la altura de cruce y no se apoyo ni se abrieron twistlocks en destino. No se declara entrega aprobada.

- Toma fisica: 49,52 s; despegue fisico: 50,00 s.
- Solicitud automatico: 75,28 s; entrada efectiva: 75,36 s.
- Llegada horizontal al entorno del slot 22: 105,60 s; no implica descarga.
- Posicion final: carro x=22,3999 m, spreader y=24,0741 m. Masa fisica suspendida: 51.863 kg (spreader 15.000 kg mas contenedor 36.863 kg).
- Perfil slot 2: -2,59 m respecto del inicial. Perfil slot 22: sin incremento. No hubo retorno.
- Margen geometrico aproximado minimo durante automatico: 2,6261 m. El detector dedicado de colision devuelve NaN: no se certifica ausencia por ese canal.
- Verificacion nativa: **180.001 muestras MC**, antisway efectiva cero y comando igual a referencia en todos los tiempos registrados, sin remuestreo para esta comprobacion.

## Integridad de datos y video

Registro completo: **455 hojas variables hasta la parada y 7 entradas constantes con periodo compilado infinito**, incluidas en cobertura_registro.csv. Se verificaron logsout y las series de monitores To Workspace. Se conservaron torques y dinamica originales con sus tiempos. Los graficos resumidos de aceleraciones y omega de referencia usan derivadas documentadas; los canales fisicos instrumentados permanecen en los datos brutos.

El video se capturo a 2 cuadros/s de tiempo simulado, 1280 x 720; el planificador conserva periodo medio 0,5 s. El indicador ANTISWAY ACTIVO del HMI expresa el permiso del PLC: en esta variante el multiplicador experimental anula la contribucion en el sumador. La comprobacion numerica del sumador es la evidencia de antisway no efectivo.

Simulink no reporto error de ejecucion ni perdida de registro por almacenamiento. Solo tres advertencias por salidas no conectadas, iguales a las del banco manual. hmi_final_video.png es el ultimo cuadro del video; hmi_final.png puede omitir controles por la limitacion de exportgraphics. Usar la captura del video para el HMI.

## Reproduccion

Leer ../README.md y ESPECIFICACION_MEDIO_CICLO_PARA_COMPARTIR.md. Copiar modelo/scripts a carpeta nueva sin datos_brutos.mat. Cargar el proyecto ST de este banco, efectuar Reset en caliente y RUN. Configurar las credenciales OPC UA propias; preparar cache corta y almacenamiento con configurar_ensayo_st. Ejecutar iniciar_medio_ciclo('sin_antisway') desde la copia de la variante. No forzar posiciones, permisos ni codigos de modo. El operador detiene a 180 s automaticamente. Antes de la referencia: nuevo Reset en caliente y RUN.

ejemplo_analisis.m genera figuras y una tabla de duraciones leyendo archivos guardados. datos_derivados.mat usa interpolacion por tiempo y gradient; datos_brutos.mat conserva las mediciones originales. criterios.csv distingue criterios aprobados, no aprobados por falta de entrega y no disponibles. Las ganancias, masas, perfil inicial, controladores y operador son los mismos de la referencia; cambia la contribucion antisway efectiva. El banco simulado y las diferencias del supervisor respecto del modelo fuente se explican en el README principal.

El archivo dinamica_y_torques_nativos.mat contiene 19 canales originales Time/Data para analizar dinamica y torques con menor memoria. El MAT completo se verifico mediante relectura por separado. Video: 180,5 s de reproduccion a 2 cuadros/s. No cargar simultaneamente ambos MAT completos si la memoria disponible es insuficiente.
