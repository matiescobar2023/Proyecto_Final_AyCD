function ejecutar_prueba_completa(stopTime)
% Ejecuta sim de forma sincronica; el progreso se guarda desde el HMI.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');m='Grua_MC_R2_FFLimitado_06102026';
if nargin<1,stopTime=628;end
load_system(fullfile(root,[m '.slx']));assert(strcmp(get_param(m,'SimulationStatus'),'stopped'));
Simulink.fileGenControl('set','CacheFolder',fullfile(root,'cache'),'CodeGenFolder',fullfile(root,'codegen'),'createDir',true);
idx=3;while isfolder(fullfile(root,sprintf('corrida_%02d',idx))),idx=idx+1;end
folder=fullfile(root,sprintf('corrida_%02d',idx));mkdir(folder);
init=get_param(m,'InitFcn');cut=strfind(init,'Pvis.Ts_viz');init=init(1:cut(1)-1);
extra=sprintf(['Pvis.Ts_viz=.04;Pvis.enable=true;Pvis.keepFigureOnTerminate=true;' ...
 'Pvis.hmi.captureFolder=''%s'';Pvis.hmi.fastDiagnostic=false;' ...
 'Pvis.hmi.testDriver=@operador_dos_traslados_v4;Pvis.hmi.renderPeriod=.20;'],strrep(folder,'''',''''''));
set_param(m,'InitFcn',[init newline extra],'StopTime',num2str(stopTime));completar_registro_fisico(m);registro_sin_sdi(m);
assignin('base','FullCycleFolder',folder);if isappdata(groot,'FullCycleSnapshot'),rmappdata(groot,'FullCycleSnapshot');end
save_system(m);diary(fullfile(folder,'ejecucion_matlab.txt'));
tic;out=sim(m);elapsed=toc;assignin('base','FullCycleOutput',out);
q=getappdata(groot,'FullCycleSnapshot');save(fullfile(folder,'datos_brutos.mat'),'out','q','elapsed','-v7.3');
diary off;fprintf('FIN t=%.2f completo=%d motivo=%s, real=%.1f s\n',q.lastT,q.done,q.abort,elapsed);
end
