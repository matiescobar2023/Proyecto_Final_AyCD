function abrir_modelo_local
% Abre la copia probada y adapta rutas del banco únicamente en memoria.
folder=fileparts(mfilename('fullpath'));cd(folder);addpath(folder,'-begin');
Simulink.fileGenControl('set','CacheFolder',fullfile(tempdir,'GruaMC_cache'),'CodeGenFolder',fullfile(tempdir,'GruaMC_codegen'),'createDir',true);
load_system(fullfile(folder,'MC_R2_ST_RELOJ_referencia_antisway.slx'));open_system('MC_R2_ST_RELOJ_referencia_antisway');
callbacks={'PreLoadFcn','PostLoadFcn','InitFcn','StartFcn','StopFcn','CloseFcn'};
old='D:/AyCD/Chat/Proyecto_grua/version codesys/Prueba_MC_R2_FFLimitado_OPCUA_20261006/Correccion_Automatica_ST_Relojes_Separados/referencia_antisway';
for k=1:numel(callbacks)
 value=get_param('MC_R2_ST_RELOJ_referencia_antisway',callbacks{k});
 value=strrep(value,strrep(old,'/',''),folder);
 value=strrep(value,old,folder);
 set_param('MC_R2_ST_RELOJ_referencia_antisway',callbacks{k},value);
end
setappdata(0,'MedioCicloCarpeta',folder);
end
