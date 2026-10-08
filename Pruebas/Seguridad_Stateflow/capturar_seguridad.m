function capturar_seguridad
root=fileparts(mfilename('fullpath'));m='Banco_Seguridad_Stateflow';load_system(fullfile(root,'Banco',[m '.slx']));
rt=sfroot;chart=rt.find('-isa','Stateflow.Chart','Path',[m '/Seguridad/Automata de proteccion']);
folder=fullfile(root,'Capturas');mkdir(folder);
rpt=slreportgen.report.Report(fullfile(root,'temporal_captura'),'html');rpt.Debug=true;rpt.CompileModelBeforeReporting=false;
exportar(chart,[],'seguridad_completa');
for name={'SALTOS_EMERGENCIAS','WATCHDOG'}
 s=chart.find('-isa','Stateflow.State','Name',name{1});p=s.Position;
 exportar(s.Subviewer,[p(1:2)-[10 25] p(3:4)+[20 50]],lower(name{1}));
end
 function exportar(obj,area,name)
  for ext={'png','svg'}
   diagram=slreportgen.report.Diagram(obj);diagram.SnapshotFormat=ext{1};
   if ~isempty(area),diagram.SnapshotArea=area;end
   f=diagram.getSnapshotImage(rpt);copyfile(f,fullfile(folder,[name '.' ext{1}]));
  end
 end
end
