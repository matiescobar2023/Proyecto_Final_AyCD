function registrar_progreso_mc(q,t,x,y,mode,loaded,fault,finished)
if nargin<8,finished=false;end
folder=getappdata(0,'MedioCicloCarpeta');
state=struct('tiempoSimulacion_s',t,'etapa',q.stage,'x_m',x,'y_m',y, ...
 'modo',mode,'cargado',loaded,'falla',fault,'terminado',finished, ...
 'entregaConfirmada',q.done,'causa',q.abort,'horaReal',char(datetime('now')));
fid=fopen(fullfile(folder,'progreso.json'),'w','n','UTF-8');
if fid>0,fprintf(fid,'%s',jsonencode(state,PrettyPrint=true));fclose(fid);end
end
