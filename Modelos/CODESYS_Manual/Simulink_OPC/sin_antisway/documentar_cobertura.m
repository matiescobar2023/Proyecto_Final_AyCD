function documentar_cobertura(folder,out,q)
rows=cell(0,6);
for k=1:out.logsout.numElements
 e=out.logsout.get(k);walk(e.Values,e.Name);
end
T=cell2table(rows,'VariableNames',{'senal','tiempoInicial_s','tiempoFinal_s','muestras','cubreParada','origen'});
writetable(T,fullfile(folder,'cobertura_registro.csv'));
telemetria=q.telemetry;
columnas={'tiempo_s','x_carro_m','y_spreader_m','vx_derivada_m_s','vy_derivada_m_s', ...
 'ax_derivada_m_s2','ay_derivada_m_s2','angulo_rad','modo','cargado','contacto', ...
 'emergencia','watchdog','falla','perfilValido','relevando','relevamientoCompleto', ...
 'lineaSeguridad_m','colision','antiswayIndicador','frenoCarroAbierto','frenoIzajeAbierto'};
metodo='Telemetria original del operador a 40 ms: posiciones/angulo/estados leidos del modelo; velocidades y aceleraciones calculadas en linea por diferencias temporales. No sustituye torques ni otros canales nativos faltantes.';
save(fullfile(folder,'telemetria_operador_completa.mat'),'telemetria','columnas','metodo');
meta=jsondecode(fileread(fullfile(folder,'metadatos.json')));
meta.registroNativoCompleto=false;
meta.limitacionRegistro='Simulink detuvo el registro por falta de espacio o exceso de uso de almacenamiento. Las senales tienen tiempos finales distintos; no se reconstruyen ni se inventan muestras faltantes.';
meta.coberturaRegistroCSV='cobertura_registro.csv';
meta.telemetriaCompleta='telemetria_operador_completa.mat';
meta.verificacionAntiswayNativaHasta_s=out.logsout.get('v_cmd').Values.Time(end);
meta.pruebaValida=true;meta.entregaCompleta=false;
theta=out.logsout.get('angulo_fisico').Values;
meta.balanceoUltimoMinuto.coberturaAngulo_s=[120 min(180,theta.Time(end))];
omega=out.logsout.get('velocidad_angular_fisica').Values;
meta.balanceoUltimoMinuto.coberturaOmega_s=[120 min(180,omega.Time(end))];
fid=fopen(fullfile(folder,'metadatos.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
f=fullfile(folder,'README.md');s=fileread(f);
s=strrep(s,'En el intervalo [120,180] s:',sprintf('En la parte registrada del intervalo [120,180] s (hasta %.3f s):',min(180,theta.Time(end))));
s=strrep(s,'La verificacion nativa conserva los resultados de antisway efectiva cero y v_cmd igual a la referencia en el sumador.',sprintf('La verificacion numerica nativa confirma antisway efectiva cero y v_cmd igual a la referencia hasta %.2f s; no cubre numericamente la cola que no se registro.',meta.verificacionAntiswayNativaHasta_s));
s=[s sprintf('\n## Limitacion de cobertura\n\nLa simulacion informo falta de espacio o exceso de uso del almacenamiento y desactivo el registro de datos. Algunas senales del supervisor y MC llegan hasta 130,72 s y varias senales fisicas hasta 177,305 s, aunque la maniobra termino a 187,20 s. Consultar cobertura_registro.csv para cada canal. No se declara completo el registro nativo.\n\nEl video y telemetria_operador_completa.mat llegan hasta el final. La telemetria permite seguir posiciones, angulo y estados, pero no recupera los torques faltantes. Las magnitudes remuestreadas fuera de la cobertura nativa no deben interpretarse como nuevas mediciones. Los criterios que dependen de esa cola requieren considerar esta limitacion. La prueba sigue siendo valida como observacion del traslado y balanceo sin antisway; no se certifica entrega ni integridad de todos los canales.\n')];
fid=fopen(f,'w','n','UTF-8');fprintf(fid,'%s',s);fclose(fid);
fprintf('COBERTURA: hojas=%d completas=%d/%d; telemetria completa hasta %.2f s\n',height(T),sum(T.cubreParada),height(T),q.lastT);
 function walk(value,name)
  if isa(value,'timeseries')
   rows(end+1,:)={name,value.Time(1),value.Time(end),numel(value.Time),value.Time(end)>=q.lastT-.04,'logsout original'};
  elseif isstruct(value)
   fields=fieldnames(value);for j=1:numel(fields),walk(value.(fields{j}),[name '.' fields{j}]);end
  elseif isa(value,'Simulink.SimulationData.Dataset')
   for j=1:value.numElements,leaf=value.get(j);walk(leaf.Values,[name '.' leaf.Name]);end
  end
 end
end
