function guardar_prueba_completa()
% StopFcn: protege el operador y cierra el video aun ante error del modelo.
folder=evalin('base','FullCycleFolder');
if isappdata(groot,'FullCycleSnapshot')
 q=getappdata(groot,'FullCycleSnapshot');save(fullfile(folder,'operador_final.mat'),'q','-v7.3');
end
figs=findall(groot,'Type','figure','Tag','ModeloFinalHMI');
for k=1:numel(figs)
 if isappdata(figs(k),'CycleVideoWriter')
  close(getappdata(figs(k),'CycleVideoWriter'));rmappdata(figs(k),'CycleVideoWriter');
 end
end
end
