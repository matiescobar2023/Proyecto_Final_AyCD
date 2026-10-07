function result=verificar_regulacion_ff()
% Compara las regulaciones con exactamente las MISMAS estimaciones.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');
old='GruaSeg_R2_FFLimitado_06102026';candidate='Grua_MC_R2_FFLimitado_06102026';
load_system(fullfile(fileparts(root),'R2_Bloques_FFLimitado_06102026',[old '.slx']));
load_system(fullfile(root,[candidate '.slx']));
% Inicializacion desde las carpetas actuales, sin depender de corridas previas.
evalin('base',get_param(old,'InitFcn'));
evalin('base',get_param(candidate,'InitFcn'));
bench='Banco_Regulacion_FF';assert(~bdIsLoaded(bench),'Banco ya abierto.');
new_system(bench);guard=onCleanup(@()close_system(bench,0));
add_block([old '/Subsystem'],[bench '/Anterior']);
add_block([candidate '/Motion Controller'],[bench '/Nuevo']);
add_block([candidate '/Interfaz MC'],[bench '/Interfaz']);
for j=1:4,add_line(bench,['Interfaz/' num2str(j)],['Nuevo/' num2str(j)]);end
h=evalin('base','T_s');p=evalin('base','MC_FF');t=(0:h:12)';
force=150000+90000*sin(.5*t);x=.3*sin(.8*t);
encT=p.i_t/p.r_td*x;encH=p.i_h*4/p.r_hd*sin(.2*t);
theta=.02*sin(2*t);xRef=2*sin(t);vRef=.7+8*sin(.9*t);aRef=.3*sin(1.4*t);
lhRef=.2+.4*sin(1.2*t);lhaRef=.7*cos(1.2*t);
brake=double(t>.5 & ~(t>5 & t<5.3));E=double(t>1 & ~(t>9 & t<9.4));
transfer=.1*sin(5*t);deltaT=20000*double(t>7 & t<8)-15000*double(t>10 & t<11);
u=[force,encT,encH,theta,xRef,vRef,aRef,-lhRef,-lhaRef,brake,E,transfer,deltaT];
input=Simulink.SimulationInput(bench);
for j=1:13
 name=sprintf('U%02d',j);var=sprintf('vfdBenchU%02d',j);
 add_block('simulink/Sources/From Workspace',[bench '/' name],'VariableName',var, ...
  'Interpolate','off','OutputAfterFinalValue','Holding final value','SampleTime','T_s');
 input=input.setVariable(var,timeseries(u(:,j),t));add_line(bench,[name '/1'],['Interfaz/' num2str(j)]);
end
for spec={'Trolley state','x,omegaDrum',4;'Hoist state','length,lengthRate',5}'
 add_block('simulink/Signal Routing/Bus Selector',[bench '/' spec{1}],'OutputSignals',spec{2});
 add_line(bench,['Nuevo/' num2str(spec{3})],[spec{1} '/1']);
end
oldSources={'U01/1','Trolley state/1','Trolley state/2','Hoist state/1','Hoist state/2', ...
 'U04/1','U05/1','U06/1','U07/1','Ref length rate/1','Ref length acceleration/1', ...
 'U10/1','U11/1','U12/1','U13/1'};
for spec={'Ref length rate',lhRef;'Ref length acceleration',lhaRef}'
 add_block('simulink/Sources/From Workspace',[bench '/' spec{1}],'VariableName',matlab.lang.makeValidName(spec{1}), ...
  'Interpolate','off','OutputAfterFinalValue','Holding final value','SampleTime','T_s');
 input=input.setVariable(matlab.lang.makeValidName(spec{1}),timeseries(spec{2},t));
end
for j=1:15,add_line(bench,oldSources{j},['Anterior/' num2str(j)]);end
fields=evalin('base','{MCFF_TrolleyDiagnostics.Elements.Name}');
index=@(name)find(strcmp(fields,name));
spec={'trolleyTorque','Anterior',2,'Nuevo',2; 'hoistTorque','Anterior',1,'Nuevo',1; ...
 'sw','Anterior',3,'Nuevo',3; ...
 'integral','Anterior/Controlador Carro/Integral error velocidad',1,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('diag_integral'); ...
 'aCmd','Anterior/Controlador Carro/Limite aceleracion comando',1,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('diag_acmd_applied'); ...
 'aRaw','Anterior/Controlador Carro/Aceleracion comando',1,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('diag_acmd'); ...
 'awTotal','Anterior/Controlador Carro/Diferencia saturacion total',1,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('aw_delta_a_total'); ...
 'feedbackSW','Anterior/Antisway comun',2,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('sw_feedback_comun'); ...
 'anticipationSW','Anterior/Antisway comun',3,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('sw_anticipacion_comun'); ...
 'alpha','Anterior/Antisway comun',4,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('sw_habilitacion_comun'); ...
 'hoistI1','Anterior/Controlador Izaje/Integrador Tustin',1,'Nuevo/Diagnosticos/Diagnosticos izaje selector',3; ...
 'hoistI2','Anterior/Controlador Izaje/Integrador Tustin1',1,'Nuevo/Diagnosticos/Diagnosticos izaje selector',4; ...
 'integratorInput','Anterior/Controlador Carro/Error con anti-windup',1,'Nuevo/Diagnosticos/Diagnosticos carro selector',index('mc_integrator_input')};
for j=1:size(spec,1)
 for side=1:2
  prefix='r';col=2;if side==2,prefix='m';col=4;end
  path=[bench '/' spec{j,col}];ph=get_param(path,'PortHandles');parent=get_param(path,'Parent');
  name=[prefix '_' spec{j,1}];sink=[parent '/' name];
  add_block('simulink/Sinks/To Workspace',sink,'VariableName',name,'SaveFormat','Timeseries');
  ps=get_param(sink,'PortHandles');add_line(parent,ph.Outport(spec{j,col+1}),ps.Inport(1));
 end
end
set_param(bench,'Solver','FixedStepDiscrete','FixedStep','T_s','StopTime','12', ...
 'SignalLogging','off','SaveOutput','off','SaveTime','off','ReturnWorkspaceOutputs','on');
o=sim(input);rows=cell(size(spec,1),4);
for j=1:size(spec,1)
 a=o.get(['r_' spec{j,1}]);b=o.get(['m_' spec{j,1}]);assert(isequal(a.Time,b.Time));
 err=max(abs(a.Data(:)-b.Data(:)));tol=1e-10;if contains(spec{j,1},'Torque'),tol=1e-7;end
 rows(j,:)={spec{j,1},err,tol,err<=tol};
end
result=struct('metrics',cell2table(rows,'VariableNames',{'signal','maxAbsDifference','tolerance','passed'}), ...
 'sampleTime_s',h,'duration_s',12,'maxIntegral',max(abs(o.m_integral.Data)), ...
 'maxCommand',max(abs(o.m_aCmd.Data)));
result.passed=all(result.metrics.passed);disp(result.metrics);
assert(result.passed,'La regulacion cambio para las mismas estimaciones.');
clear guard
end
