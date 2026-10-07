function file=construir_variadores_discretos()
% Reorganiza una copia del MC; no cambia ninguna funcion del automata.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');
model='Grua_MC_R2_FFLimitado_06102026';file=fullfile(root,[model '.slx']);
load_system(file);sub=[model '/Motion Controller'];
assert(getSimulinkBlockHandle([sub '/MC Carro'])<0,'Modelo ya convertido.');
for name={'definir_buses_variadores.m','parametros_ganancias_cascada_29072026.m','configurar_parametros_variadores.m'}
 evalin('base',sprintf('run(''%s'');',strrep(fullfile(root,name{1}),'''','''''')));
end
init=sprintf(['addpath(fileparts(get_param(''%s'',''FileName'')),''-begin'');\n' ...
 'run(fullfile(fileparts(get_param(''%s'',''FileName'')),''definir_buses_variadores.m''));\n' ...
 'run(fullfile(fileparts(get_param(''%s'',''FileName'')),''parametros_ganancias_cascada_29072026.m''));\n' ...
 'run(fullfile(fileparts(get_param(''%s'',''FileName'')),''configurar_modelo_final_hmi.m''));\n' ...
 'run(fullfile(fileparts(get_param(''%s'',''FileName'')),''configurar_parametros_variadores.m''));'], ...
 model,model,model,model,model);
set_param(model,'InitFcn',init);
% Recordar los cables actuales antes de sustituir la frontera de entrada.
ph=get_param(sub,'PortHandles');oldSources=zeros(1,15);
for j=1:15
 lh=get_param(ph.Inport(j),'Line');oldSources(j)=get_param(lh,'SrcPortHandle');delete_line(lh);
end
inside=find_system(sub,'FindAll','on','SearchDepth',1,'Type','line');
for j=1:numel(inside),if ishandle(inside(j)),delete_line(inside(j));end;end
bb=find_system(sub,'SearchDepth',1,'Type','Block');
for j=2:numel(bb)
 if ~strcmp(get_param(bb{j},'BlockType'),'Outport'),delete_block(bb{j});end
end
adapter=[model '/Interfaz MC'];add_block('simulink/Ports & Subsystems/Subsystem',adapter);
delete_line(adapter,'In1/1','Out1/1');delete_block([adapter '/In1']);delete_block([adapter '/Out1']);
inputNames={'Tension cable','Encoder carro','Encoder izaje','Angulo balanceo', ...
 'xRef','vRef','aRef','Velocidad izaje ref','Aceleracion izaje ref', ...
 'Freno carro abierto','E antisway','Transferencia SW','Recorte torque demorado'};
sensorPorts=get_param([model '/SENSORES'],'PortHandles');
superPorts=get_param([model '/Automata Supervisor'],'PortHandles');
anglePorts=get_param([model '/' sprintf('Zero-Order\nHold5')],'PortHandles');
sources=[oldSources(1),sensorPorts.Outport(1),sensorPorts.Outport(2), ...
 anglePorts.Outport(1),oldSources(7:9),superPorts.Outport(16),superPorts.Outport(17),oldSources(12:15)];
for j=1:numel(inputNames)
 add_block('simulink/Sources/In1',[adapter '/' inputNames{j}],'Port',num2str(j));
 add_block('simulink/Discrete/Zero-Order Hold',[adapter '/Muestreo ' num2str(j)],'SampleTime','T_s');
 add_line(adapter,[inputNames{j} '/1'],['Muestreo ' num2str(j) '/1']);
 pa=get_param(adapter,'PortHandles');add_line(model,sources(j),pa.Inport(j),'autorouting','on');
end
group={1:4,5:9,10:11,13};group{2}=[group{2},12];
busNames={'Sensors','References','Commands','Drive Feedback'};
busTypes={'MCFF_Sensors','MCFF_References','MCFF_Commands','MCFF_DriveFeedback'};
for j=1:4
 busObject=evalin('base',busTypes{j});fields={busObject.Elements.Name};
 add_block('simulink/Signal Routing/Bus Creator',[adapter '/' busNames{j} ' Bus'], ...
  'Inputs',num2str(numel(group{j})),'OutDataTypeStr',['Bus: ' busTypes{j}],'NonVirtualBus','on');
 for k=1:numel(group{j})
  src=['Muestreo ' num2str(group{j}(k)) '/1'];
  if j==3
   converter=['Boolean ' fields{k}];
   add_block('simulink/Signal Attributes/Data Type Conversion',[adapter '/' converter],'OutDataTypeStr','boolean');
   add_line(adapter,src,[converter '/1']);src=[converter '/1'];
  end
  ln=add_line(adapter,src,[busNames{j} ' Bus/' num2str(k)]);set_param(ln,'Name',fields{k});
 end
 add_block('simulink/Sinks/Out1',[adapter '/' busNames{j}],'Port',num2str(j));
 add_line(adapter,[busNames{j} ' Bus/1'],[busNames{j} '/1']);
 add_block('simulink/Sources/In1',[sub '/' busNames{j}],'Port',num2str(j), ...
  'OutDataTypeStr',['Bus: ' busTypes{j}]);
 pa=get_param(adapter,'PortHandles');ps=get_param(sub,'PortHandles');
 add_line(model,pa.Outport(j),ps.Inport(j),'autorouting','on');
end
add_block('simulink/Sources/Constant',[sub '/Parameters'],'Value','MC_FF', ...
 'OutDataTypeStr','Bus: MCFF_Parameters','SampleTime','T_s');
addFunction(sub,'MC Izaje','mc_eje_izaje.m', ...
 {'s','r','est','p'},{'MCFF_Sensors','MCFF_References','MCFF_HoistState','MCFF_Parameters'}, ...
 {'d'},{'MCFF_HoistDiagnostics'});
addFunction(sub,'MC Carro','mc_eje_carro.m', ...
 {'s','r','c','drive','est','hoist','p'}, ...
 {'MCFF_Sensors','MCFF_References','MCFF_Commands','MCFF_DriveFeedback','MCFF_TrolleyState','MCFF_HoistState','MCFF_Parameters'}, ...
 {'d'},{'MCFF_TrolleyDiagnostics'});
addFunction(sub,'Estimadores','mc_estimadores.m', ...
 {'s','p'},{'MCFF_Sensors','MCFF_Parameters'}, ...
 {'cart','hoist'},{'MCFF_TrolleyState','MCFF_HoistState'});
add_line(sub,'Sensors/1','Estimadores/1');add_line(sub,'Parameters/1','Estimadores/2');
for j=1:4
 src={'Sensors/1','References/1','Estimadores/2','Parameters/1'};add_line(sub,src{j},['MC Izaje/' num2str(j)]);
end
src={'Sensors/1','References/1','Commands/1','Drive Feedback/1','Estimadores/1','Estimadores/2','Parameters/1'};
for j=1:numel(src),add_line(sub,src{j},['MC Carro/' num2str(j)]);end
add_line(sub,'MC Izaje/1','T_hm*/1');add_line(sub,'MC Carro/1','T_tmcontrolador/1');
add_line(sub,'MC Carro/2','SW aplicada comun/1');
for spec={'Estados carro',4,'Estimadores/1';'Estados izaje',5,'Estimadores/2'; ...
 'Diagnosticos carro',6,'MC Carro/3';'Diagnosticos izaje',7,'MC Izaje/2'}'
 add_block('simulink/Sinks/Out1',[sub '/' spec{1}],'Port',num2str(spec{2}));
 add_line(sub,spec{3},[spec{1} '/1']);
end
% Diagnosticos y estados: selectores y cables, sin operaciones externas.
diagSelector(sub,'Diagnosticos carro','MCFF_TrolleyDiagnostics','MC Carro/3');
diagSelector(sub,'Diagnosticos izaje','MCFF_HoistDiagnostics','MC Izaje/2');
add_block('simulink/Signal Routing/Bus Selector',[model '/Estados MC carro'], ...
 'OutputSignals','x,omegaDrum,velocity,observerAngle');
add_block('simulink/Signal Routing/Bus Selector',[model '/Estados MC izaje'], ...
 'OutputSignals','length,lengthRate,omegaDrum,observerAngle');
ps=get_param(sub,'PortHandles');pc=get_param([model '/Estados MC carro'],'PortHandles');
ph=get_param([model '/Estados MC izaje'],'PortHandles');
add_line(model,ps.Outport(4),pc.Inport(1));add_line(model,ps.Outport(5),ph.Inport(1));
for j=1:4
 add_block('simulink/Sinks/Terminator',[model '/Monitor estado carro ' num2str(j)]);
 pt=get_param([model '/Monitor estado carro ' num2str(j)],'PortHandles');ln=add_line(model,pc.Outport(j),pt.Inport(1));
 names={'mc_encoder_x','mc_encoder_omegaT','mc_encoder_vT','mc_observer_qT'};logPort(pc.Outport(j),names{j});
 add_block('simulink/Sinks/Terminator',[model '/Monitor estado izaje ' num2str(j)]);
 pt=get_param([model '/Monitor estado izaje ' num2str(j)],'PortHandles');ln=add_line(model,ph.Outport(j),pt.Inport(1));
 names={'longitud_cable_estimada','mc_encoder_lengthRate','mc_encoder_omegaH','mc_observer_qH'};logPort(ph.Outport(j),names{j});
end
% Sustituir productores de los canales externos; conservar consumidores.
core={'Gain','Gain1','Gain3','Gain4','Gain5','Gain6','Gain7','Gain9','Gain10','Gain12', ...
 'Integrator','Integrator1','Integrator2','Integrator3','Sum','Sum1','Sum2','Sum3','Sum4', ...
 'Gain2','Gain8','N0_OMEGA_A_VT','Angulo medido para compensacion', ...
 sprintf('Zero-Order\nHold1'),sprintf('Zero-Order\nHold2'),sprintf('Zero-Order\nHold3'), ...
 sprintf('Zero-Order\nHold4'),sprintf('Zero-Order\nHold13'),sprintf('Zero-Order\nHold14')};
replaceChannel('Gain6',pc.Outport(1));replaceChannel('Integrator1',pc.Outport(2));
replaceChannel('N0_OMEGA_A_VT',pc.Outport(3));
for j=1:numel(core)
 b=[model '/' core{j}];if getSimulinkBlockHandle(b)>0,delete_block(b);end
end
% Quitar wrappers Goto/From que quedaron sin productor o consumidor.
for pass=1:4
 froms=find_system(model,'SearchDepth',1,'BlockType','From');
 for j=1:numel(froms)
  p=get_param(froms{j},'PortHandles');ln=get_param(p.Outport(1),'Line');
  if ln<0 || all(get_param(ln,'DstBlockHandle')<0),delete_block(froms{j});end
 end
 gotos=find_system(model,'SearchDepth',1,'BlockType','Goto');
 for j=1:numel(gotos)
  tag=get_param(gotos{j},'GotoTag');ff=find_system(model,'SearchDepth',1,'BlockType','From','GotoTag',tag);
  p=get_param(gotos{j},'PortHandles');ln=get_param(p.Inport(1),'Line');
  if isempty(ff) || ln<0
   for k=1:numel(ff),delete_block(ff{k});end
   delete_block(gotos{j});
  end
 end
end
% El contenedor no es atomico: estimadores antes del supervisor; ejes despues.
% Mantenerlo atomico crea una dependencia artificial referencias-estados.
set_param(sub,'TreatAsAtomicUnit','off');
limpiar_conexiones_mc(model);
encapsular_diagnosticos_mc(model);
Simulink.BlockDiagram.arrangeSystem(adapter);formatear_diagrama_mc(model);
set_param(model,'SimulationCommand','update');save_system(model,file);
fprintf('Variadores compilados: %s\n',file);

 function replaceChannel(oldName,newPort)
  p=get_param([model '/' oldName],'PortHandles');ln=get_param(p.Outport(1),'Line');
  dd=get_param(ln,'DstBlockHandle');
  for channelIndex=1:numel(dd)
   if strcmp(get_param(dd(channelIndex),'BlockType'),'Goto')
    tag=get_param(dd(channelIndex),'GotoTag');ff=find_system(model,'SearchDepth',1,'BlockType','From','GotoTag',tag);
    needed=false;
    for z=1:numel(ff)
     pf=get_param(ff{z},'PortHandles');lf=get_param(pf.Outport(1),'Line');if lf<0,continue;end
     ds=get_param(lf,'DstBlockHandle');
     for n=1:numel(ds)
      if ds(n)>0 && ~ismember(get_param(ds(n),'Name'),core),needed=true;end
     end
    end
    if needed
     pg=get_param(dd(channelIndex),'PortHandles');delete_line(get_param(pg.Inport(1),'Line'));
     add_line(model,newPort,pg.Inport(1),'autorouting','on');
    end
   end
  end
 end
 function addFunction(parent,name,source,inNames,inTypes,outNames,outTypes)
  b=[parent '/' name];add_block('simulink/User-Defined Functions/MATLAB Function',b);
  r=sfroot;c=r.find('-isa','Stateflow.EMChart','Path',b);
  code=fileread(fullfile(root,source));functionName=erase(source,'.m');
  c.Script=strrep(code,[functionName '('],'fcn(');c.ChartUpdate='DISCRETE';c.SampleTime='T_s';
  for z=1:numel(inNames)
   data=c.find('-isa','Stateflow.Data','Name',inNames{z});data.DataType=['Bus: ' inTypes{z}];
  end
  for z=1:numel(outNames)
   data=c.find('-isa','Stateflow.Data','Name',outNames{z});data.DataType=['Bus: ' outTypes{z}];
  end
 end
 function diagSelector(parent,name,type,src)
  obj=evalin('base',type);fields={obj.Elements.Name};b=[parent '/' name ' selector'];
  add_block('simulink/Signal Routing/Bus Selector',b,'OutputSignals',strjoin(fields,','));
  add_line(parent,src,[name ' selector/1']);p=get_param(b,'PortHandles');
  for z=1:numel(fields)
   term=['Monitor ' fields{z}];add_block('simulink/Sinks/Terminator',[parent '/' term]);
   ln=add_line(parent,[name ' selector/' num2str(z)],[term '/1']);logPort(p.Outport(z),fields{z});
  end
 end
end
function logPort(port,name)
set_param(port,'DataLogging','on','DataLoggingNameMode','Custom','DataLoggingName',name);
end
