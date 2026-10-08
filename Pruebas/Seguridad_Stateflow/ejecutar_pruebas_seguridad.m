function ejecutar_pruebas_seguridad(indices)
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');
mdl='Banco_Seguridad_Stateflow';load_system(fullfile(root,'Banco',[mdl '.slx']));
agregar_inyeccion_nan;
cfg=load(fullfile(root,'Banco/configuracion_banco.mat'));cases=construir_casos_seguridad;
if nargin<1,indices=1:numel(cases);end
results=fullfile(root,'Resultados_finales');mkdir(results);assignin('base','T_s0',.02);
cvTotal=[];summary={};checks={};
if isfile(fullfile(results,'resumen.csv'))
 summary=table2cell(readtable(fullfile(results,'resumen.csv'),'TextType','char'));
 checks=table2cell(readtable(fullfile(results,'comprobaciones_globales.csv'),'TextType','char'));
 [~,prev]=cvload(fullfile(results,'cobertura_acumulada.cvt'));cvTotal=prev{end};
end
for k=indices
 c=cases{k};folder=fullfile(results,[c.id '_' matlab.lang.makeValidName(c.nombre)]);mkdir(folder);
 assert(~isfile(fullfile(folder,'senales.mat')),'Ya existen datos de este caso; no sobrescribir.');
 for j=1:7
  v=c.U(:,j);if j>=4,assignin('base',sprintf('SegInvalid%d',j),timeseries(isnan(v),c.t));v(isnan(v))=0;end
  if j<=3,v=logical(v);end
  assignin('base',sprintf('SegU%d',j),timeseries(v,c.t));
 end
 set_param(mdl,'StopTime',num2str(c.stop));test=cvtest([mdl '/Seguridad'],c.nombre);test.settings.condition=1;test.settings.mcdc=1;
 tic;[cov,out]=cvsim(test);wall=toc;t=out.get('tout');Y=zeros(numel(t),13);
 for j=1:12,v=out.get(sprintf('SegY%d',j));Y(:,j)=double(v.Data(:));end
 v=out.get('SegVHmax');Y(:,13)=double(v.Data(:));
 sampleU=interp1(c.t,c.U,t,'previous');
 save(fullfile(folder,'senales.mat'),'out','t','Y','sampleU','c','cfg','wall','-v7.3');
 tableNames=[{'tiempo_s'},cfg.inputNames,cfg.outputNames,{'hmiHoistOverspeed'}];
 writetable(array2table([t sampleU Y],'VariableNames',tableNames),fullfile(folder,'senales.csv'));
 writetable(array2table([c.t c.U],'VariableNames',[{'tiempo_s'},cfg.inputNames]),fullfile(folder,'estimulos_originales.csv'));
 okLogic=0;badLogic=0;findings=0;localChecks={};
 for j=1:numel(c.checks)
  q=c.checks(j);[~,pos]=min(abs(t-q.t));actual=Y(pos,q.cols);pass=isequal(actual,double(q.expected));
  if strcmp(q.tipo,'LOGICA'),if pass,okLogic=okLogic+1;else,badLogic=badLogic+1;end;elseif ~pass,findings=findings+1;end
  row={c.id,c.nombre,q.tipo,q.texto,t(pos),mat2str(q.expected),mat2str(actual),pass};checks(end+1,:)=row;localChecks(end+1,:)=row;
 end
 writetable(cell2table(localChecks,'VariableNames',{'caso','nombre','tipo','criterio','tiempo_s','esperado','observado','cumple'}),fullfile(folder,'comprobaciones.csv'));
 events=diff([Y(1,:);Y])~=0;ev=find(any(events,2));
 writetable(array2table([t(ev) Y(ev,:)],'VariableNames',[{'tiempo_s'},cfg.outputNames,{'hmiHoistOverspeed'}]),fullfile(folder,'cambios_salidas.csv'));
 wd=find(Y(:,8)==1,1);total=find(Y(:,1)==0,1);tw=NaN;tg=NaN;if ~isempty(wd),tw=t(wd);end;if ~isempty(total),tg=t(total);end
 summary(end+1,:)={c.id,c.nombre,c.stop,numel(t),wall,okLogic,badLogic,findings,tw,tg,folder};
 if isempty(cvTotal),cvTotal=cov;else,cvTotal=cvTotal+cov;end
 cvsave(fullfile(results,'cobertura_acumulada.cvt'),cvTotal);
 save(fullfile(root,'casos_ejecutados.mat'),'cases','indices');
 writetable(cell2table(summary,'VariableNames',{'caso','nombre','duracion_s','muestras','tiempo_real_s','criterios_logica_cumplen','criterios_logica_no_cumplen','hallazgos_robustez','primer_fallo_WD_s','primera_total_s','carpeta'}),fullfile(results,'resumen.csv'));
 writetable(cell2table(checks,'VariableNames',{'caso','nombre','tipo','criterio','tiempo_s','esperado','observado','cumple'}),fullfile(results,'comprobaciones_globales.csv'));
 fprintf('%s %d/%d: %s | logica %d OK/%d NO | hallazgos %d\n',c.id,k,numel(cases),c.nombre,okLogic,badLogic,findings);
end
cvhtml(fullfile(results,'cobertura_estructural.html'),cvTotal,'-sRT=0');
coverage=struct('decision',decisioninfo(cvTotal,[mdl '/Seguridad']),'condition',conditioninfo(cvTotal,[mdl '/Seguridad']),'mcdc',mcdcinfo(cvTotal,[mdl '/Seguridad']));
fid=fopen(fullfile(results,'cobertura_resumen.json'),'w');fwrite(fid,jsonencode(coverage,PrettyPrint=true));fclose(fid);
save_system(mdl);fprintf('FIN: %d casos ejecutados.\n',numel(indices));
end
