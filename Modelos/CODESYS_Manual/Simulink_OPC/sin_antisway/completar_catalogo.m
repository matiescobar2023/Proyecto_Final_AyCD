function completar_catalogo(folder,out)
% Catalogo de todas las series nativas; el indice distingue nombres repetidos.
if nargin<2,R=load(fullfile(folder,'datos_brutos.mat'),'output');out=R.output;end
interface=fileread(fullfile(folder,'codesys_opcua_conjunto_sfun.m'));
inputs=[parse(interface,'supervisorInputs') parse(interface,'safetyInputs')];
outputs=[parse(interface,'supervisorOutputs')];outputs=outputs(1:38);
outputs=[outputs parse(interface,'safetyOutputs') {'safetyEnvelopeProfile'}];
rows=cell(0,10);
for k=1:out.logsout.numElements
    e=out.logsout.get(k);name=e.Name;desc=name;clase='interna del modelo';
    m=regexp(name,'^grupo1_(Inport|Outport)_(\d+)$','tokens','once');
    explicitUnit='';
    if ~isempty(m)
        index=str2double(m{2});
        if strcmp(m{1},'Inport'),desc=inputs{index};clase='entrada PLC procesada o solicitud HMI';
        else,desc=outputs{index};clase='salida PLC';end
    end
    other=regexp(name,'^grupo([2-6])_(Inport|Outport)_(\d+)$','tokens','once');
    if ~isempty(other),[desc,explicitUnit]=groupMeaning(str2double(other{1}),other{2},str2double(other{3}));end
    source=char(e.BlockPath.getBlock(1));
    if isempty(desc) || startsWith(desc,'grupo')
        desc=meaning(source,e.PortIndex);if isempty(desc),desc=source;end
    end
    ts=e.Values;dt=diff(double(ts.Time));dt=dt(dt>0);
    if isempty(dt),period=NaN;else,period=median(dt);end
    units=unit(desc,source);if ~isempty(explicitUnit),units=explicitUnit;end
    if islogical(ts.Data),units='booleano';end
    rows(end+1,:)={name,desc,units,source,'nativo sin decimacion',clase,k,numel(ts.Time),period,e.PortIndex};
end
vars=out.who;for k=1:numel(vars)
    ts=out.get(vars{k});if ~isa(ts,'timeseries'),continue;end
    dt=diff(double(ts.Time));dt=dt(dt>0);if isempty(dt),period=NaN;else,period=median(dt);end
    rows(end+1,:)={vars{k},vars{k},unit(vars{k},''),'To Workspace del modelo','nativo sin decimacion','monitor original',NaN,numel(ts.Time),period,NaN};
end
C=cell2table(rows,'VariableNames',{'nombre','descripcion','unidad','origen','metodo_muestreo','clase','indice_logsout','muestras','periodo_mediano_s','puerto'});
writetable(C,fullfile(folder,'catalogo_senales.csv'));
U=table(["Subestados activos SFC";"Colision dedicada";"Limites dinamicos de velocidad de izaje";"Aceleracion fisica carro e izaje";"Velocidad angular de referencia"], ...
    ["No publicados como pasos SFC en la interfaz utilizada; se registran modo y etapa del operador"; ...
    "El modelo conecta NaN a este indicador; se informa margen geometrico derivado"; ...
    "vHoistMax no forma parte del intercambio registrado; fuente FB_calcularMandoManual del PLC"; ...
    "No se expone como salida de planta; gradient de velocidades fisicas, datos_derivados.mat"; ...
    "gradient de angulo de referencia, datos_derivados.mat"], ...
    'VariableNames',{'senal','motivo_o_metodo'});
writetable(U,fullfile(folder,'senales_no_nativas.csv'));
end
function names=parse(code,variable)
tok=regexp(code,['(?s)' variable ' = \{(.*?)\};'],'tokens','once');
parts=regexp(tok{1},'''([^'']+)''','tokens');names=cellfun(@(p)p{1},parts,'UniformOutput',false);
end
function u=unit(name,source)
n=lower(name);s=lower(source);
if contains(n,{'torque','tau','t_tm','t_hm','thm'}),u='N m';
elseif contains(n,{'mass','masa'}),u='kg';
elseif contains(n,{'tension','f_hw','fuerza_contacto'}),u='N';
elseif contains(n,{'v_cmd','v_ref','antisway_calculada','antisway_limitada','antisway_efectiva'}),u='m/s';
elseif contains(n,'mon_vh'),u='m/s';
elseif contains(n,{'mon_xt','mon_yh'}),u='m';
elseif contains(n,'sumfc'),u='N';
elseif contains(n,{'code','codigo','slot','k_c'}),u='codigo adimensional';
elseif contains(n,{'joy','keyboard'}),u='normalizado [-1,1]';
elseif contains(n,{'bool','permit','enable','brake','brk','fault','cmd','req','contact','loaded','lock','valid','scanactive','scancomplete','watchdog','reset','emerg','reinicio','lst_','lsh_','vh_max'}),u='booleano';
elseif contains(n,{'swayrate','thetarate','omega','angular'}),u='rad/s';
elseif contains(n,{'angle','angulo','theta'}),u='rad';
elseif contains(n,{'axref','ayref','atrolley','ahoist','aceleracion'}),u='m/s^2';
elseif contains(n,{'vx','vy','vhoist','vtrolley','velocidad','v_ref','v_cmd','antisway','manualtrolleyref','manualhoistref','scanspeed'}),u='m/s';
elseif contains(n,{'time','tiempo'}),u='s';
elseif contains(n,{'profile','envelope','height','distanc','perfil','xtrolley','yhoist','xref','yref','lidarx','lidary','x_t','x_l','y_l','y_c','l_h','limity','limitx','yc','x_actual','y_actual','targetx','targety','liney'}),u='m';
else,u=['adimensional u otra unidad; consultar bloque ' s];end
end
function [d,u]=groupMeaning(group,direction,k)
in=strcmp(direction,'Inport');
switch group
    case 2
        if in
            names={'theta_tm cruda','theta_hm cruda','F_hw cruda','theta_l cruda','omega_l cruda','x_t cruda','v_ly cruda','TLK fisico'};
            units={'rad','rad','N','rad','rad/s','m','m/s','booleano'};
        else
            names={'theta_tm_sens','theta_hm_sens','F_hw_sens','omega_l_sens','theta_l_sens','x_tLSmin','x_tLSmax','x_tLSEmin','x_tLSEmax','Sobrevelocidad izaje'};
            units={'rad','rad','N','rad/s','rad','booleano','booleano','booleano','booleano','booleano'};
        end
    case 3
        if in,names={'TLK','k_slot','slot_ok','v_yl','contacto','tension'};units={'booleano','indice slot','booleano','m/s','booleano','N'};
        else,names={'evento_cambio','tipo_evento','slot_evento','carga_tomada'};units={'booleano','codigo','indice slot','booleano'};end
    case 4
        if in
            names={'x_t','x_l','y_l','theta_l','TLK','Y_c fisico','slot_actual','altura_perfil_actual','carga_tomada','modeCode','contact4','masa_estimada','masa_valida','antisway_habilitado','brakeTrolleyOpen','brakeHoistOpen','emergencyBrakeHoistOpen','joyTrolley','joyHoist','velocidad_manual_carro','velocidad_manual_izaje','emergency','overload','limitXmin','limitXmax','limitYmin','limitYmax','colision_NaN','watchdog','modeAutoReq','limitXminUltimo','limitXmaxUltimo','limitYminUltimo','limitYmaxUltimo','clearanceLineY','automaticTargetY','profileValid','scanActive','trackingFault','faultCode','scanComplete','safetyEnvelopeProfile'};
            units={'m','m','m','rad','booleano','m','indice slot','m','booleano','codigo','booleano','kg','booleano','booleano','booleano','booleano','booleano','normalizado [-1,1]','normalizado [-1,1]','m/s','m/s','booleano','booleano','booleano','booleano','booleano','booleano','no disponible (NaN)','booleano','booleano','booleano','booleano','booleano','booleano','m','m','booleano','booleano','booleano','codigo','booleano','m'};
        else
            names={'startPending','stopPending','eStop','surveyPending','targetSlot','targetX','targetY','targetPending','modeAutoReq','autoStartPending','resetPending','twistPulsePending','twistlockOpenReq','keyboardTrolley','keyboardHoist'};
            units={'booleano','booleano','booleano','booleano','indice slot','m','m','booleano','booleano','booleano','booleano','booleano','booleano','normalizado [-1,1]','normalizado [-1,1]'};
        end
    case 5
        if in,names={'Torque izaje aplicado a planta','Torque carro aplicado a planta','BRK_t','BRK_hE','BRK_h','TLK','M_c','y_c0(x_l,t)'};units={'N m','N m','booleano','booleano','booleano','booleano','kg','m'};
        else,names={'theta_tm','theta_hm','F_hw','theta_l','omega_l','omega_hd','v_ly','x_l','F_cy','x_t','y_l'};units={'rad','rad','N','rad','rad/s','rad/s','m/s','m','N','m','m'};end
    case 6
        if in,names={'profileMass','loaded fisico'};units={'kg','booleano'};else,names={'masa contenedor retenida'};units={'kg'};end
end
d=names{k};u=units{k};
end
function description=meaning(source,port)
description='';
try
    if strcmp(get_param(source,'BlockType'),'SubSystem')
        outs=find_system(source,'SearchDepth',1,'BlockType','Outport');
        for j=1:numel(outs)
            if str2double(get_param(outs{j},'Port'))==port,description=get_param(outs{j},'Name');return;end
        end
    end
    description=get_param(source,'Name');
catch
    description=source;
end
end
