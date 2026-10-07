function run=ensayar_variadores_mc(label)
% Ensayo completo en RAM; no guarda senales, datos brutos ni video.
% La instrumentacion y los ajustes de ejecucion se restauran al terminar.
root=fileparts(mfilename('fullpath'));
model='Grua_MC_R2_FFLimitado_06102026';
if nargin<1
 label='Ciclo_MC_FFLimitado_06102026';
 if isfolder(fullfile(root,label))
  label=[label '_' char(datetime('now','Format','yyyyMMdd_HHmmss'))];
 end
end
assert(ischar(label) && isempty(regexp(label,'[\\/]|^\.\.?$','once')), ...
 'La etiqueta debe ser un nombre de carpeta dentro del paquete MC.');
folder=fullfile(root,label);
assert(~isfolder(folder),'Ya existe el destino del ensayo.');
mkdir(folder);mkdir(fullfile(folder,'codigo_ensayado'));
for name={'parametros_ganancias_cascada_29072026.m','antisway_comun.m', ...
 'controlador_carro_mc_r2.m','controlador_izaje_mc_r2.m', ...
 'definir_buses_variadores.m','configurar_parametros_variadores.m', ...
 'mc_eje_carro.m','mc_eje_izaje.m','mc_estimadores.m','actualizar_observador_encoder.m'}
 copyfile(fullfile(root,name{1}),fullfile(folder,'codigo_ensayado',name{1}));
end
load_system(fullfile(root,[model '.slx']));
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
oldDirty=get_param(model,'Dirty');
ports=find_system(model,'FindAll','on','Type','port','PortType','outport');
opts={'DataLogging','DataLoggingNameMode','DataLoggingName'};
values=cell(numel(ports),numel(opts));
for i=1:numel(ports)
 for j=1:numel(opts),values{i,j}=get_param(ports(i),opts{j});end
end
portGuard=onCleanup(@()restoreLogging(model,ports,opts,values,oldDirty)); %#ok<NASGU>
cfg=Simulink.fileGenControl('getConfig');
fileGuard=onCleanup(@()Simulink.fileGenControl('setConfig','config',cfg)); %#ok<NASGU>
Simulink.fileGenControl('set','CacheFolder',fullfile(root,'cache'), ...
 'CodeGenFolder',fullfile(root,'codegen'),'createDir',true);
[catalog,loggingGuard,alias]=instrumentar_variadores_mc(model); %#ok<ASGLU>
init=get_param(model,'InitFcn');
extra=sprintf(['Pvis.Ts_viz=0.20; Pvis.enable=true; Pvis.keepFigureOnTerminate=true; ' ...
 'Pvis.hmi.captureFolder=''%s''; Pvis.hmi.fastDiagnostic=true; ' ...
 'Pvis.hmi.testDriver=@(block,h)operador_prueba1_maniobra_completa_sim(block,h,false);'], ...
 strrep(folder,'''',''''''));
input=Simulink.SimulationInput(model);
input=input.setModelParameter('InitFcn',[init newline extra], ...
 'StopTime','450','MaxStep','T_s','EnablePacing','off','SimulationMode','accelerator', ...
 'SignalLogging','on','SignalLoggingName','logsout','ReturnWorkspaceOutputs','on');
fprintf('INICIO ENSAYO MC: FF limitado, habilitacion 2 s, datos solo en RAM.\n');
tic;output=sim(input);elapsed=toc;
q=[];figs=findall(groot,'Type','figure','Tag','ModeloFinalHMI');
for k=1:numel(figs)
 if isappdata(figs(k),'CycleOutputFolder') && strcmp(getappdata(figs(k),'CycleOutputFolder'),folder)
  q=getappdata(figs(k),'CycleHMI');
 end
end
assert(~isempty(q),'No se encontro el operador de esta corrida.');
if ~q.done || ~isempty(q.abort),assignin('base','vfdFailedOutput',output);assignin('base','vfdFailedQ',q);end
assert(q.done && isempty(q.abort),'El ciclo no termino: %s',q.abort);
signals=struct;
for k=1:output.logsout.numElements
 item=output.logsout.getElement(k);
 % makeValidName('') genera 'x': excluir anonimas antes de convertir el nombre.
 if isempty(item.Name),continue;end
 key=matlab.lang.makeValidName(item.Name);
 z=item.Values;
 if isa(z,'timeseries') && size(z.Data,2)==1
  signals.(key)=struct('t',double(z.Time(:)),'v',double(z.Data(:)));
 end
end
names=output.who;
for k=1:numel(names)
 z=output.get(names{k});
 if isa(z,'timeseries')
  signals.(names{k})=struct('t',double(z.Time(:)),'v',double(squeeze(z.Data)));
 end
end
protocol=evaluar_ciclo_izaje_auto(output,q);
result=struct('model',model,'label',label,'folder',folder,'elapsed_s',elapsed, ...
 'done',q.done,'abort',q.abort,'duration_s',double(output.mon_xT.Time(end)), ...
 'alias',alias,'passed',protocol.passed,'rawDataSaved',false,'videoSaved',false);
result.parameters=evalin('base',['struct(''g'',g,''r_td'',r_td,''i_t'',i_t,' ...
 '''M_EQt'',M_EQt,''b_EQt'',b_EQt,''T_s'',T_s,''T_SW_on'',T_SW_on)']);
run=struct('output',output,'signals',signals,'q',q,'result',result,'protocol',protocol);
clear loggingGuard
clear portGuard fileGuard
fprintf('FIN ENSAYO: %.6f s, AUTO %d/%d, tiempo real %.1f s.\n', ...
 result.duration_s,sum(protocol.checks.cumple),height(protocol.checks),elapsed);
end

function restoreLogging(model,ports,opts,values,dirty)
for i=1:numel(ports)
 if ishandle(ports(i))
  for j=1:numel(opts),set_param(ports(i),opts{j},values{i,j});end
 end
end
set_param(model,'Dirty',dirty);
end
