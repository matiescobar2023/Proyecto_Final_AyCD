function estado_ensayo_mc
disp(get_param('MC_R2_SFC_sin_antisway','SimulationStatus'));
figs=findall(0,'Type','figure');
for k=1:numel(figs)
 if isappdata(figs(k),'CODESYSCycle')
  q=getappdata(figs(k),'CODESYSCycle');
  disp(struct('stage',q.stage,'time',q.lastT,'x',q.lastX,'y',q.lastY,'abort',q.abort));
 end
end
end
