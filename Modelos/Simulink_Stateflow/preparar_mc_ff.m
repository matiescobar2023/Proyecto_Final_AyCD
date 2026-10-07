function preparar_mc_ff()
% Copias independientes; solo cambia la ley anti-sway del carro en el MC.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');
model='Grua_MC_R2_FFLimitado_06102026';old='Grua_MC_R2_Variadores_Discreto_06102026';
blocks='GruaSeg_R2_FFLimitado_06102026';br=fullfile(fileparts(root),'R2_Bloques_FFLimitado_06102026');
load_system(fullfile(br,[blocks '.slx']));
init=get_param(blocks,'InitFcn');
init=strrep(init,'GruaSeg_ControlComun_AWTorque_06102026',blocks);
% El snapshot ensayado puede incluir configuracion del operador de prueba.
cut=strfind(init,'Pvis.Ts_viz');if ~isempty(cut),init=init(1:cut(1)-1);end
set_param(blocks,'InitFcn',init);
sr=sfroot;ch=sr.find('-isa','Stateflow.EMChart','Path',[blocks '/Subsystem/Antisway comun']);
expected=fileread(fullfile(br,'antisway_comun.m'));
assert(strcmp(regexprep(ch.Script,'\s',''),regexprep(expected,'\s','')), ...
 'Snapshot y ley FF guardada no coinciden.');
save_system(blocks);
load_system(fullfile(root,[model '.slx']));
init=strrep(get_param(model,'InitFcn'),old,model);set_param(model,'InitFcn',init);
for name={'definir_buses_variadores.m','parametros_ganancias_cascada_29072026.m','configurar_parametros_variadores.m'}
 evalin('base',sprintf('run(''%s'');',strrep(fullfile(root,name{1}),'''','''''')));
end
bb=find_system(model,'Type','Block');
for j=1:numel(bb)
 pars=get_param(bb{j},'ObjectParameters');
 for opt={'OutDataTypeStr','Value'}
  if isfield(pars,opt{1})
   val=get_param(bb{j},opt{1});
   if ischar(val) && (contains(val,'MCVFD_') || strcmp(val,'MC_VFD'))
    set_param(bb{j},opt{1},strrep(strrep(val,'MCVFD_','MCFF_'),'MC_VFD','MC_FF'));
   end
  end
 end
end
charts=sr.find('-isa','Stateflow.EMChart');
for j=1:numel(charts)
 if startsWith(charts(j).Path,[model '/Motion Controller/'])
  data=charts(j).find('-isa','Stateflow.Data');
  for k=1:numel(data)
   if contains(data(k).DataType,'MCVFD_'),data(k).DataType=strrep(data(k).DataType,'MCVFD_','MCFF_');end
  end
 end
end
ch=sr.find('-isa','Stateflow.EMChart','Path',[model '/Motion Controller/MC Carro']);
ch.Script=strrep(fileread(fullfile(root,'mc_eje_carro.m')),'mc_eje_carro(','fcn(');
set_param(model,'SimulationCommand','update');save_system(model);
set_param(blocks,'SimulationCommand','update');
fprintf('Modelos FF preparados y compilados, automata sin cambios.\n');
end
