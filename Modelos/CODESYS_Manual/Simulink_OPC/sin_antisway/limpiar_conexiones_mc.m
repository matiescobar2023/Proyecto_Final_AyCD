function limpiar_conexiones_mc(model)
% Quita unicamente cables y wrappers sin productor/consumidor en la raiz.
% No entra al automata, a seguridad ni a la planta.
for pass=1:4
 gotos=find_system(model,'SearchDepth',1,'BlockType','Goto');
 for j=1:numel(gotos)
  pp=get_param(gotos{j},'PortHandles');lh=get_param(pp.Inport(1),'Line');
  if lh<0 || get_param(lh,'SrcPortHandle')<0
   ff=find_system(model,'SearchDepth',1,'BlockType','From','GotoTag',get_param(gotos{j},'GotoTag'));
   for k=1:numel(ff),delete_block(ff{k});end
   delete_block(gotos{j});
  end
 end
 ll=find_system(model,'SearchDepth',1,'FindAll','on','Type','line');
 for j=1:numel(ll)
  if ~ishandle(ll(j)),continue;end
  children=get_param(ll(j),'LineChildren');
  if isempty(children) && (get_param(ll(j),'SrcPortHandle')<0 || all(get_param(ll(j),'DstPortHandle')<0))
   delete_line(ll(j));
  end
 end
 ff=find_system(model,'SearchDepth',1,'BlockType','From');
 for j=1:numel(ff)
  pp=get_param(ff{j},'PortHandles');lh=get_param(pp.Outport(1),'Line');
  if lh<0,delete_block(ff{j});end
 end
end
for name={'Terminator','Terminator1'}
 b=[model '/' name{1}];if getSimulinkBlockHandle(b)<0,continue;end
 pp=get_param(b,'PortHandles');if get_param(pp.Inport(1),'Line')<0,delete_block(b);end
end
pp=get_param([model '/Motion Controller'],'PortHandles');
for j=6:7
 if get_param(pp.Outport(j),'Line')<0
  b=[model '/Monitor bus diagnosticos ' num2str(j)];
  add_block('simulink/Sinks/Terminator',b);pt=get_param(b,'PortHandles');add_line(model,pp.Outport(j),pt.Inport(1));
 end
end
end
