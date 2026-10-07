function escribir_informe_desempeno_mc_r2(r,out,~)
fid=fopen(fullfile(out,'INFORME_DESEMPENO.md'),'w');assert(fid>=0);
guard=onCleanup(@()fclose(fid));
fprintf(fid,'# Desempeño de la grúa: %s\n\n',r.analysisLabel);
fprintf(fid,'Modelo: **%s**. Duración: **%.3f s**. Ciclo terminado: **%d**. Criterios aprobados: **%d/%d**. Series originales registradas: **%d**.\n\n', ...
 r.modelo,r.duracion_s,r.termino,sum(r.criterios.cumple),height(r.criterios),r.numero_senales);
if isfield(r,'datosEnMemoria') && r.datosEnMemoria
 fprintf(fid,'Este informe analiza la corrida disponible en memoria de MATLAB; `%s` contiene los resultados del analisis, sin un nuevo paquete de senales. El analisis no ejecuta simulaciones.\n\n',strrep(r.carpeta,'\','/'));
else
 fprintf(fid,'Este informe lee la corrida guardada en `%s`. El script de análisis no ejecuta simulaciones ni modifica sus datos de entrada.\n\n',strrep(r.carpeta,'\','/'));
end
fprintf(fid,'La maniobra usa el mando manual anterior: -0.20 en los descensos finales y -0.16 en la bajada intermedia.\n\n');
fprintf(fid,'## Hallazgos principales\n\n');
cartPeak=r.picos.max_abs(strcmp(r.picos.senal,'Aceleracion fisica carro'));
fprintf(fid,'El ciclo aprueba **%d/%d criterios del protocolo AUTO**. El carro alcanza **%.6f m/s²** de aceleración física; el límite de referencia es ±%.2f. Recorte máximo del mando de aceleración: **%.6g m/s²**; recorte máximo de torque: **%.6g Nm**. Con E=0, el máximo de corrección anti-sway aplicada es **%.6g m/s**.\n\n', ...
 sum(r.criterios.cumple),height(r.criterios),cartPeak,r.parametros.a_tmax,r.maxAWAceleracion,r.maxAWTorque,r.maxSW_E0);
if cartPeak>r.parametros.a_tmax
 fprintf(fid,'**La aceleración física global excede el límite. Aprobar el protocolo AUTO no valida ese transitorio manual.** Consultar las ampliaciones de transitorios de esta revisión y el instante del pico en la tabla.\n\n');
end
fprintf(fid,'La masa total estimada en AUTO cargado es **%.1f kg**, frente a **%.1f kg** físicos; el error relativo de la masa del contenedor es **%.3f %%**. La estimación se declara válida a **%.3f s**. La fuerza de apoyo reconstruida en ese instante es **%.3f kN**.\n\n', ...
 r.pesaje.masa_estimada_auto_kg,r.pesaje.masa_fisica_auto_kg, ...
 100*r.resumenProtocolo.errorEstimacionMasa_relativo,r.pesaje.valido_s,r.pesaje.contacto_al_validar_N/1000);
fprintf(fid,'El error vertical máximo AUTO es **%.6f m**, la aceleración de izaje estimada máxima AUTO es **%.6f m/s²** y el ángulo máximo AUTO es **%.6f grados**. El origen de la corrida comparada se identifica en su sección.\n\n', ...
 r.maxErrorYAuto_m,r.maxAceleracionIzajeEstimadaAuto,r.resumenProtocolo.maxAnguloAuto_deg);
fprintf(fid,'La aprobación del protocolo automático no elimina los transitorios de contacto manual. La carga llega a los apoyos a **%.3f y %.3f m/s**, y los máximos físicos de las ventanas de contacto se detallan en la tabla y en las figuras 09 y 10.\n\n', ...
 abs(r.contactos.vCarga_precontacto_mps(1)),abs(r.contactos.vCarga_precontacto_mps(2)));
fprintf(fid,'## Origen de las señales complementarias\n\n');tabla(fid,r.origenSenales);
fprintf(fid,'\nLa aceleración vertical procede del Divide1 de la planta. mon_vH registra v_ly con decimación y se utiliza como velocidad física de la carga. La fuerza de contacto se reconstruye con F_cy=m*(a_y+g)-2*F_hw*cos(theta), a partir de señales nativas del mismo instante. Es un balance algebraico, no una nueva simulación ni una medición directa de F_cy. La penetración se reconstruye desde la superficie, la altura física de la carga y su posición. No se filtra la aceleración ni se modifican los MAT originales.\n\n');
fprintf(fid,'## Maniobra y alcance\n\n');
fprintf(fid,'Se conserva el anti-windup paramétrico, el izaje, el supervisor y el operador manual anterior. El MC historico permanece intacto; este paquete conserva la regulacion y agrega los dos observadores de encoder discretizados. El automata y su estimacion de masa no se modificaron. La gráfica 13 permite revisar la validación de masa y la desaparición del apoyo durante la toma.\n\n');
if strcmp(r.comparisonKind,'compensacion_horizontal')
 fprintf(fid,'En este R2, E habilita únicamente la rama anti-sway. La compensación horizontal usa theta medida y permanece activa con E=0. Los generadores conservan 0.3 m/s² y a_cmd conserva 0.8 m/s².\n\n');
end
if strcmp(r.comparisonKind,'habilitacion_lineal')
 fprintf(fid,'Esta revisión conserva la compensación horizontal independiente de E y cambia únicamente la incorporación lineal del anti-sway: 0.5 s a %.3f s. E=0 sigue anulando SW inmediatamente. No cambia la selección fija de HMI ni la inhibición durante barrido.\n\n',r.parametros.T_SW_on);
end
fprintf(fid,'## Criterios del protocolo\n\n');tabla(fid,r.criterios);
fprintf(fid,'\nLos criterios de movimiento de la guía evalúan principalmente los tramos automáticos. Los límites físicos globales y los impactos manuales se muestran aparte; terminar el ciclo no equivale a aprobar todos los criterios.\n\n');
fprintf(fid,'## Comparación con bloques FF limitado\n\nOrigen: `%s`.\n\n',strrep(r.comparisonSource,'\','/'));tabla(fid,r.comparacion);
if strcmp(r.comparisonKind,'compensacion_horizontal')
 fprintf(fid,'\nSe compara R2 anterior con R2 actual, manteniendo operador, parámetros y límites. Cambia la habilitación de la compensación horizontal. Los máximos pueden ocurrir en instantes diferentes.\n\n');
elseif strcmp(r.comparisonKind,'habilitacion_lineal')
 fprintf(fid,'\nSe compara la habilitación lineal de 0.5 s con la de 2 s. Ambas corridas tienen compensación horizontal independiente de E, iguales consignas del operador y referencias de 0.3 m/s². Los máximos pueden ocurrir en instantes diferentes.\n\n');
elseif strcmp(r.comparisonKind,'ley_completa')
 fprintf(fid,'\nAmbas versiones habilitan SW linealmente en 2 s. Se retira solamente la memoria ff y el limitador de cambio de la anticipacion: la nueva salida es sat(alpha*(k*theta-k*thetaRef)). Se mantienen operador, referencias de 0.3 m/s², PI, AW, frenos y compensacion horizontal independiente de E.\n\n');
else
 fprintf(fid,'\nSe compara el modelo de bloques FF limitado ensayado con el MC FF limitado y estimadores Tustin a 1 ms. La ley regulatoria coincide exactamente para las mismas estimaciones. Las pequenas diferencias del ciclo cerrado provienen de los estimadores discretos y del muestreo de entradas. Los máximos pueden ocurrir en instantes diferentes.\n\n');
end
fprintf(fid,'## Picos físicos y límites\n\n');tabla(fid,r.picos);
fprintf(fid,'\nEl límite de aceleración de mando del carro es ±%.2f m/s². Un pico físico por encima de ese valor puede aparecer con a_cmd dentro del límite, debido a la planta elástica y a la realimentación. La aceleración estimada desde el motor y la aceleración física de la carga se registran y comparan por separado.\n\n',r.parametros.a_tmax);
fprintf(fid,'La columna cargado indica el estado lógico del supervisor en el instante del pico. La masa física se registra aparte: durante la toma o entrega ambas señales pueden cambiar en instantes diferentes.\n\n');
fprintf(fid,'## Descensos finales y contactos\n\n');tabla(fid,r.contactos);
fprintf(fid,'\nEl contacto se identifica por la primera fuerza vertical superior a 1 kN durante cada descenso. La velocidad previa usa la última muestra física anterior. La media final cubre los cinco segundos previos. Los picos de fuerza, aceleración y torque cubren desde 0.5 s antes hasta 3 s después del contacto: incluyen la actuación de twistlocks, los cambios de masa y el freno, por lo que no se atribuyen todos a una única causa.\n\n');
fprintf(fid,'Estos resultados corresponden al manual anterior. Los picos posteriores al contacto pueden incluir el efecto de la toma/entrega, la conmutación de masa y el freno. La fuerza de contacto de este análisis es reconstruida y su origen se identifica expresamente.\n\n');
fprintf(fid,'## Regulación, anti-windup y transiciones\n\n');
fprintf(fid,'Máximo recorte de torque del carro: **%.6g Nm**, duración **%.6g s**. Máximo recorte de aceleración: **%.6g m/s²**, duración **%.6g s**. Residuo de suma de las ramas AW: **%.3g m/s²**. Máxima corrección anti-sway aplicada con E=0: **%.3g m/s**.\n\n', ...
 r.maxAWTorque,r.torqueSaturado_s,r.maxAWAceleracion,r.mandoSaturado_s,r.errorSumaAW,r.maxSW_E0);
fprintf(fid,'Conversión de torque a aceleración: i_t/(r_td*M_EQt), calculada con los parámetros del ensayo. La comparación entre entrada y salida del limitador se hace antes de la dinámica del motor; su retardo no se interpreta como saturación.\n\n');
fprintf(fid,'El estado integral tiene límite ±%.3f m. Su contribución de aceleración es Ki*I. Las gráficas separan anticipación y amortiguación anti-sway, además de la transferencia explícita de velocidad al deshabilitarlo.\n\n',r.parametros.a_tmax/r.parametros.Ki);
fprintf(fid,'## Seguimiento y balanceo por modo\n\n');tabla(fid,r.porModo);
fprintf(fid,'\nLos errores X/Y comparan las referencias nominales con las posiciones observadas. En manual, las correcciones de posición y anti-sway también intervienen en el objetivo efectivo de velocidad; vRef nominal no es la única entrada del PI.\n\n');
fprintf(fid,'## Izaje y freno\n\n');
fprintf(fid,'Potencia mecánica máxima global muestreada a 20 ms: **%.3f kW**, calculada como T_motor*i_h*omega_tambor. Error vertical máximo AUTO: **%.6f m**. Aceleración de izaje estimada máxima AUTO: **%.6f m/s²**.\n\n', ...
 r.maxPotenciaIzaje_kW,r.maxErrorYAuto_m,r.maxAceleracionIzajeEstimadaAuto);
fprintf(fid,'La figura de frenos muestra permisos de apertura N0 y torque físico. El permiso N0 no es la apertura efectiva: esta también depende de la orden N1. La columna permiso_N0_apertura_contacto conserva esa distinción. Torque resistente y movimiento de la carga deben observarse juntos. El criterio del protocolo para freno en movimiento se limita a izaje automático.\n\n');
fprintf(fid,'## Duraciones y etapas\n\n');tabla(fid,r.etapas);
fprintf(fid,'\n## Método y archivos\n\n%s\n\n',r.metodo);
fprintf(fid,'Los gráficos generales usan 20 ms para presentación. Las posiciones se interpolan linealmente, igual que en el protocolo de validación; modos, banderas y restantes señales usan retención de muestra. Los detalles de contacto usan tiempos nativos sin filtrar. Los excesos se integran por retención de muestra; pequeños cruces entre muestras pueden alterar su duración estimada.\n\n');
if isfield(r,'datosEnMemoria') && r.datosEnMemoria
 fprintf(fid,'Esta corrida conserva las senales y el resultado de simulacion solamente en memoria de MATLAB. No se guardaron senales_nativas.mat, datos_brutos.mat ni video nuevos. Se guardan el informe, tablas de metricas y figuras PNG/FIG; codigo_ensayado conserva los parametros y la funcion anti-sway.\n\n');
else
 fprintf(fid,'Se conservan senales_nativas.mat, datos_brutos.mat, modelo_ensayado.slx, codigo_ensayado, criterios y metadatos. Este análisis agrega CSV, JSON, MAT, PNG y FIG en analisis_desempeno; nunca sobrescribe los datos de simulación.\n\n');
end
fprintf(fid,'## Figuras\n\n');
fprintf(fid,'Las figuras abiertas en MATLAB se identifican como **%s** y también se guardan en PNG y FIG visibles.\n\n',r.analysisLabel);
figs=dir(fullfile(out,'*.png'));
for k=1:numel(figs)
    path=strrep(fullfile(out,figs(k).name),'\','/');
    fprintf(fid,'### %s\n\n![%s](%s)\n\n',strrep(figs(k).name,'_',' '),figs(k).name,path);
end
clear guard
end
function tabla(fid,t)
names=t.Properties.VariableNames;
fprintf(fid,'| %s |\n',strjoin(names,' | '));
fprintf(fid,'| %s |\n',strjoin(repmat({'---'},1,width(t)),' | '));
for i=1:height(t)
    vals=cell(1,width(t));
    for j=1:width(t)
        value=t{i,j};if iscell(value),value=value{1};end
        if isnumeric(value)||islogical(value),vals{j}=sprintf('%.6g',value);
        else,vals{j}=char(string(value));end
    end
    fprintf(fid,'| %s |\n',strjoin(vals,' | '));
end
end


