function registro_sin_sdi(m)
% Replica los canales marcados en sinks normales; evita el repositorio SDI.
ports=find_system(m,'FindAll','on','Type','port','PortType','outport');
count=0;
for k=1:numel(ports)
 p=ports(k);if ~strcmp(get_param(p,'DataLogging'),'on'),continue;end
 name=get_param(p,'DataLoggingName');
 if isempty(name),name=get_param(p,'Name');end
 if isempty(name),name=sprintf('registro_%d',k);end
 name=matlab.lang.makeValidName(name);
 source=get_param(p,'Parent');parent=get_param(source,'Parent');
 sink=[parent '/RegistroPersistente_' num2str(k)];
 if getSimulinkBlockHandle(sink)<0
  add_block('simulink/Sinks/To Workspace',sink,'VariableName',name, ...
   'SaveFormat','Timeseries','Decimation','10','MaxDataPoints','inf', ...
   'Position',[10 10 80 35]);
  ph=get_param(sink,'PortHandles');add_line(parent,p,ph.Inport,'autorouting','off');
 end
 set_param(p,'DataLogging','off');count=count+1;
end
set_param(m,'SignalLogging','off');
blocks=find_system(m,'BlockType','ToWorkspace');
[~,order]=sort(cellfun(@length,blocks));blocks=blocks(order);
used=containers.Map('KeyType','char','ValueType','logical');
for k=1:numel(blocks)
 base=get_param(blocks{k},'VariableName');name=base;n=2;
 while isKey(used,name),name=[base '_' num2str(n)];n=n+1;end
 set_param(blocks{k},'VariableName',name);used(name)=true;
end
fprintf('REGISTRO SIN SDI: %d canales convertidos\n',count);
end
