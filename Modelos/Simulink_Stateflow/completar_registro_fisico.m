function completar_registro_fisico(m)
important={'Planta/Subsistema carro/Dinamica Carro Traslacional',1,'x_carro_fisica';
 'Planta/Subsistema carro/Dinamica Carro Traslacional',2,'v_carro_fisica';
 'Planta/Subsistema carga/Dinamica Movimiento Carga',2,'y_carga_fisica';
 'Planta/Subsistema carga/Dinamica Movimiento Carga',4,'v_izaje_fisica';
 'Planta',4,'angulo_fisico';'Planta',5,'velocidad_angular_fisica';
 'Planta',3,'tension_fisica_cable';'Planta',9,'fuerza_contacto_fisica';
 'Planta/Subsistema carga/Calculo Masa Total de Carga',1,'masa_fisica_suspendida'};
for k=1:size(important,1),ph=get_param([m '/' important{k,1}],'PortHandles');logport(ph.Outport(important{k,2}),important{k,3});end
accel={'Planta/Subsistema carro/Dinamica Carro Traslacional/Integrator','aceleracion_carro_fisica';
 'Planta/Subsistema carga/Dinamica Movimiento Carga/Integrator2','aceleracion_carga_x_fisica';
 'Planta/Subsistema carga/Dinamica Movimiento Carga/Integrator3','aceleracion_izaje_fisica'};
for k=1:size(accel,1),ph=get_param([m '/' accel{k,1}],'PortHandles');ln=get_param(ph.Inport,'Line');logport(get_param(ln,'SrcPortHandle'),accel{k,2});end
ints=find_system([m '/Planta'],'BlockType','Integrator');
for k=1:numel(ints),ph=get_param(ints{k},'PortHandles');for side={'Inport','Outport'}
 pp=ph.(side{1});if strcmp(side{1},'Inport'),ln=get_param(pp,'Line');if ln==-1,continue;end;pp=get_param(ln,'SrcPortHandle');end
 if ~strcmp(get_param(pp,'DataLogging'),'on'),logport(pp,sprintf('planta_integrador_%02d_%s',k,side{1}));end
end;end
groups={'Automata Supervisor','SENSORES','PICK // PLACE','VISUALIZACION 2D SISTEMA GRUA','Planta','Motion Controller'};
for g=1:numel(groups)
 ph=get_param([m '/' groups{g}],'PortHandles');
 for side={'Inport','Outport'},pp=ph.(side{1});for k=1:numel(pp)
  p=pp(k);if strcmp(side{1},'Inport'),ln=get_param(p,'Line');if ln==-1,continue;end;p=get_param(ln,'SrcPortHandle');end
  if ~strcmp(get_param(p,'DataLogging'),'on'),logport(p,sprintf('grupo%d_%s_%02d',g,side{1},k));end
 end;end
end
end
function logport(p,n)
set_param(p,'DataLogging','on','DataLoggingNameMode','Custom','DataLoggingName',n, ...
 'DataLoggingDecimateData','on','DataLoggingDecimation','10','DataLoggingLimitDataPoints','off');
end
