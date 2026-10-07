function catalogar_mc(folder,out)
% Incluye hojas de buses y conserva las rejillas originales.
if nargin<2,R=load(fullfile(folder,'datos_brutos.mat'),'output');out=R.output;end
rows=cell(0,7);
for k=1:out.logsout.numElements
 e=out.logsout.get(k);source=char(e.BlockPath.getBlock(1));
 walk(e.Values,e.Name,source,sprintf('logsout{%d}.Values',k));
end
vars=out.who;for k=1:numel(vars),v=out.get(vars{k});if isa(v,'timeseries'),walk(v,vars{k},'To Workspace',['output.' vars{k}]);end;end
C=cell2table(rows,'VariableNames',{'nombre','unidad','origen','acceso','muestras','periodo_mediano_s','metodo'});
writetable(C,fullfile(folder,'catalogo_senales_mc.csv'));
 function walk(v,name,source,access)
  if isa(v,'timeseries')
   dt=diff(double(v.Time(:)));dt=dt(dt>0);if isempty(dt),period=NaN;else,period=median(dt);end
   u=unit(name);if ~isempty(v.DataInfo.Units),u=char(v.DataInfo.Units);end
   rows(end+1,:)={name,u,source,access,numel(v.Time),period,'nativo, sin decimacion'};
  elseif isa(v,'Simulink.SimulationData.Dataset')
   for j=1:v.numElements,e=v.get(j);walk(e.Values,[name '.' e.Name],source,sprintf('%s{%d}.Values',access,j));end
  elseif isstruct(v)
   fs=fieldnames(v);for j=1:numel(fs),walk(v.(fs{j}),[name '.' fs{j}],source,[access '.' fs{j}]);end
  else
   rows(end+1,:)={name,'ver definicion del bus',source,access,NaN,NaN,['tipo registrado: ' class(v)]};
  end
 end
end
function u=unit(name)
n=lower(name);
if contains(n,{'torque','tau'}),u='N m';
elseif contains(n,{'aceleracion','acmd','delta_a','aref','axref','ayref','diag_aff'}),u='m/s^2';
elseif contains(n,{'velocidad_angular','omega','swayrate'}),u='rad/s';
elseif contains(n,{'angulo','theta','angle'}),u='rad';
elseif contains(n,{'velocidad','v_ref','v_cmd','vref','vcmd','vobs','antisway','sw_feedback','sw_anticipacion','sw_limitada'}),u='m/s';
elseif contains(n,{'masa','mass'}),u='kg';
elseif contains(n,{'tension','fuerza'}),u='N';
elseif contains(n,{'x_carro','y_carga','profile','envelope','xref','yref','xencoder'}),u='m';
else,u='ver puerto y parametros del modelo';end
end
