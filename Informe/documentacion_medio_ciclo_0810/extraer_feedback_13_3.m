function extraer_feedback_13_3
base='C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt/tmp/pdfs/revision_13_3/Senales_Medio_Ciclo_CODESYS';
folders={'CODESYS_Manual_Con_Antisway','CODESYS_Automatico_Con_Antisway','CODESYS_Manual_Sin_Antisway'};
ids={'manual_con','autogen_con','manual_sin'};R=cell(1,3);
keys={'mc_encoder_x','mc_encoder_vT','longitud_cable_estimada','mc_encoder_lengthRate','mc_diag_theta_medida','angulo_referencia','antisway_efectiva','v_cmd','mc_diag_vref_input','torque_carro_consigna_controlador','torque_izaje_consigna_controlador','torque_carro_fisico_motor','torque_izaje_fisico_motor','tension_fisica_cable','masa_fisica_suspendida','fuerza_contacto_fisica'};
mons={'mon_xRef','mon_yRef','mon_vxRef','mon_vyRef','mon_axRef','mon_ayRef','mon_thetaRate','mon_twistlocksClosed','mon_twistlockCloseCmd','sup_loadedState','mon_loadedPhysical','mon_obstacleProfile'};
for k=1:3
 D=load(fullfile(base,folders{k},'Senales','datos_brutos.mat'),'output');o=D.output;L=o.logsout;N=L.getElementNames;Q=struct;
 for j=1:numel(keys),ix=find(strcmp(N,keys{j}),1);assert(~isempty(ix),keys{j});q=L{ix}.Values;Q.(keys{j})=struct('t',q.Time(:),'v',double(q.Data(:)));end
 for j=1:numel(mons),q=o.(mons{j});if isa(q,'timeseries'),tt=q.Time;vv=q.Data;else,tt=q.time;vv=q.signals.values;end;Q.(mons{j})=struct('t',tt(:),'v',double(squeeze(vv)));end
 for nm=fieldnames(Q)',q=Q.(nm{1});[q.t,ix]=unique(q.t,'last');q.v=q.v(ix,:);Q.(nm{1})=q;end
 R{k}=Q;clear D o L Q;
end
save('C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt/tmp/pdfs/revision_13_3/feedback_seleccionado.mat','R','ids','-v7.3');
for k=1:3
 Q=R{k};fprintf('%s encoder fin %.3f thetaRate fin %.3f\n',ids{k},Q.mc_encoder_x.t(end),Q.mon_thetaRate.t(end));
 for nm={'torque_carro_consigna_controlador','torque_carro_fisico_motor','torque_izaje_consigna_controlador','torque_izaje_fisico_motor'}
 q=Q.(nm{1});ix=find(q.t<3.24);[v,h]=max(abs(q.v(ix)));fprintf('%s inicial %.6g Nm @ %.6g s, operativo %.6g\n',nm{1},q.v(ix(h)),q.t(ix(h)),max(abs(q.v(q.t>=3.24))));end
end
end
