function encapsular_diagnosticos_mc(model)
% Agrupa selectores y terminadores de diagnostico, sin alterar calculos.
sub=[model '/Motion Controller'];
if getSimulinkBlockHandle([sub '/Diagnosticos'])>0,return;end
bb=find_system(sub,'SearchDepth',1,'Type','Block');handles=[];
for j=2:numel(bb)
 name=get_param(bb{j},'Name');
 if startsWith(name,'Monitor ') || endsWith(name,' selector')
  handles(end+1)=get_param(bb{j},'Handle');
 end
end
Simulink.BlockDiagram.createSubsystem(handles,'Name','Diagnosticos','MakeNameUnique','off');
Simulink.BlockDiagram.arrangeSystem([sub '/Diagnosticos']);
set_param([sub '/MC Carro'],'BackgroundColor','lightBlue');
set_param([sub '/MC Izaje'],'BackgroundColor','lightBlue');
set_param([sub '/Estimadores'],'BackgroundColor','green');
Simulink.BlockDiagram.arrangeSystem(sub);
end
