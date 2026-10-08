function preparar_banco_seguridad
% Copia el nivel de seguridad vigente, sin editar sus estados ni guardas.
root=fileparts(mfilename('fullpath'));bank=fullfile(root,'Banco');mkdir(bank);
src='Grua_MC_R2_FFLimitado_06102026';
assert(bdIsLoaded(src),'Abra primero el modelo de referencia.');
assert(strcmp(get_param(src,'SimulationStatus'),'stopped'));
source=[src '/Nivel 0 - Seguridad'];mdl='Banco_Seguridad_Stateflow';
assert(~bdIsLoaded(mdl),'El banco ya esta abierto.');
new_system(mdl);add_block(source,[mdl '/Seguridad'],'Position',[370 60 620 500]);
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','0.02', ...
 'StopTime','1','SaveTime','on','TimeSaveName','tout','SaveOutput','off', ...
 'SignalLogging','off','ReturnWorkspaceOutputs','on','InitFcn','T_s0=0.02;');
inputs=find_system([mdl '/Seguridad'],'SearchDepth',1,'BlockType','Inport');
outputs=find_system([mdl '/Seguridad'],'SearchDepth',1,'BlockType','Outport');
inputNames=cell(1,numel(inputs));outputNames=cell(1,numel(outputs));
for k=1:numel(inputs)
 n=str2double(get_param(inputs{k},'Port'));inputNames{n}=get_param(inputs{k},'Name');
 b=sprintf('%s/Entrada_%d',mdl,n);
 add_block('simulink/Sources/From Workspace',b,'VariableName',sprintf('SegU%d',n),'Interpolate','off','OutputAfterFinalValue','Holding final value','Position',[30 30+n*55 180 60+n*55]);
 add_line(mdl,sprintf('Entrada_%d/1',n),sprintf('Seguridad/%d',n),'autorouting','on');
end
for k=1:numel(outputs)
 n=str2double(get_param(outputs{k},'Port'));outputNames{n}=get_param(outputs{k},'Name');
 b=sprintf('%s/Registro_%d',mdl,n);
 add_block('simulink/Sinks/To Workspace',b,'VariableName',sprintf('SegY%d',n),'SaveFormat','Timeseries','MaxDataPoints','inf','Decimation','1','Position',[770 20+n*45 940 45+n*45]);
 add_line(mdl,sprintf('Seguridad/%d',n),sprintf('Registro_%d/1',n),'autorouting','on');
end
% VH_MAX no tiene salida HMI dedicada: observar la linea original sin cambiarla.
add_block('simulink/Sinks/To Workspace',[mdl '/Seguridad/Registro_VH_MAX'],'VariableName','SegVHmax','SaveFormat','Timeseries','MaxDataPoints','inf','Position',[700 500 840 530]);
add_line([mdl '/Seguridad'],'Sensores de seguridad/5','Registro_VH_MAX/1','autorouting','on');
save_system(mdl,fullfile(bank,[mdl '.slx']));
sr=sfroot;original=sr.find('-isa','Stateflow.Chart','Path',[source '/Automata de proteccion']);
copied=sr.find('-isa','Stateflow.Chart','Path',[mdl '/Seguridad/Automata de proteccion']);
a=signature(original);b=signature(copied);assert(isequal(a,b),'El chart copiado difiere.');
origSensor=sr.find('-isa','Stateflow.EMChart','Path',[source '/Sensores de seguridad']);
bankSensor=sr.find('-isa','Stateflow.EMChart','Path',[mdl '/Seguridad/Sensores de seguridad']);
assert(strcmp(origSensor.Script,bankSensor.Script));
info=struct('paso_s',.02,'watchdog_s',5,'entradas',{inputNames},'salidas',{outputNames}, ...
 'estados_y_transiciones',a,'sensor_original',origSensor.Script, ...
 'chart_copia_identico',true,'sensores_copia_identicos',true,'ejecutado_en','MATLAB R2025b');
fid=fopen(fullfile(root,'caracterizacion_banco.json'),'w');fwrite(fid,jsonencode(info,PrettyPrint=true));fclose(fid);
save(fullfile(bank,'configuracion_banco.mat'),'inputNames','outputNames','info');
fprintf('Banco preparado: chart y sensores identicos, %d entradas, %d salidas.\n',numel(inputs),numel(outputs));
end
function q=signature(c)
q=struct('decomposicion',c.Decomposition,'actualizacion',c.ChartUpdate,'periodo',c.SampleTime,'states',[],'transitions',[]);
ss=c.find('-isa','Stateflow.State');
for j=1:numel(ss),q.states=[q.states;struct('name',ss(j).Name,'label',ss(j).LabelString,'order',ss(j).ExecutionOrder,'decomposition',ss(j).Decomposition)];end
ts=c.find('-isa','Stateflow.Transition');
for j=1:numel(ts)
 from='DEFAULT';to='';if ~isempty(ts(j).Source),from=ts(j).Source.Name;end;if ~isempty(ts(j).Destination),to=ts(j).Destination.Name;end
 q.transitions=[q.transitions;struct('from',from,'to',to,'label',ts(j).LabelString,'order',ts(j).ExecutionOrder)];
end
end
