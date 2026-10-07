function [catalogo,cleanup,alias]=instrumentar_variadores_mc(model)
% INSTRUMENTAR_PRUEBA1_SIM Registro temporal de puertos internos.
% No guarda el SLX; restaura las opciones de logging al finalizar.
ports=[]; names={}; sources={}; units={};

addOutput('Automata Supervisor','estimatedContainerMass','masa_contenedor_estimada','kg');
addOutput('Automata Supervisor','massEstimateValid','masa_estimada_valida','bool');
addOutput('Automata Supervisor','manualTrolleyRef','mando_manual_carro','m/s');
addOutput('Automata Supervisor','manualHoistRef','mando_manual_izaje','m/s');
addOutput('Automata Supervisor','clearanceLineY','linea_despeje_supervisor','m');
addOutput('SENSORES','theta_tm_sens','sensor_theta_motor_carro','rad');
addOutput('SENSORES','theta_hm_sens','sensor_theta_motor_izaje','rad');
addOutput('SENSORES','F_hw_sens','sensor_tension_cable','N');
addOutput('SENSORES','omega_l_sens','sensor_velocidad_angular','rad/s');
addOutput('SENSORES','theta_l_sens','sensor_angulo','rad');
addOutput('SENSORES','x_tLSmin','sensor_limite_x_min','bool');
addOutput('SENSORES','x_tLSmax','sensor_limite_x_max','bool');
addOutput('SENSORES','x_tLSEmin','sensor_limite_emergencia_x_min','bool');
addOutput('SENSORES','x_tLSEmax','sensor_limite_emergencia_x_max','bool');
addOutput('SENSORES','Sobrevelocidad Izaje','sensor_sobrevelocidad_izaje','bool');
addOutput('Planta','theta_l','planta_angulo_real','rad');
addOutput('Planta','omega_l','planta_velocidad_angular_real','rad/s');
addOutput('Planta','F_hw','planta_tension_cable','N');
addOutput('Planta','x_l','planta_posicion_carga_x','m');
addOutput('Planta','y_l','planta_posicion_carga_y','m');
addOutput('Motion Controller','T_hm*','torque_izaje_consigna_controlador','N m');
addOutput('Motion Controller','T_tmcontrolador','torque_carro_consigna_controlador','N m');
addOutput('Modulador de Torque Motor Drive Carro','T_tm','torque_carro_fisico_motor','N m');
addOutput('Modulador de Torque Motor Drive Izaje','T_hm','torque_izaje_fisico_motor','N m');
addInput('Planta','T_hm*','torque_izaje_entrada_planta','N m');
addInput('Planta','T_tm*','torque_carro_entrada_planta','N m');

addNamedLine('T_tmlim*','torque_carro_limitado','N m');
addOutput('Subsistema carro','v_t','carro_velocidad_real','m/s');
addDirectSignal('Planta/Subsistema izaje/Dinamica Tambor Izaje/Integrator2', ...
    'tambor_izaje_velocidad_angular','rad/s');
addDirectSignal('Planta/Subsistema izaje/Modelo Freno Operacion de Izaje(Eje Rapido)/T_hb', ...
    'freno_operacion_izaje_torque','N m');
addDirectSignal('Planta/Subsistema carro/Dinamica Carro Traslacional/Gain', ...
    'carro_aceleracion_fisica','m/s^2');
addDirectSignal('MASS_loaded_gate','masa_contenedor_fisica','kg');
addDirectSignal('Planta/Subsistema carga/Calculo Masa Total de Carga/m_l', ...
    'masa_total_fisica','kg');

alias=struct('load_acc1','diag_load_acc1','load_acc2','diag_load_acc2');
addDirectSignal('Planta/BRK_t','diag_brake_effective','bool');
addDirectSignal('Planta/Subsistema carro/Modelo Freno Operacion Carro/Switch','diag_brake_torque','Nm');
addDirectSignal('Planta/Subsistema carro/Dinamica Tambor Carro/Gain8','diag_vdrum','m/s');
addDirectSignal('Planta/Subsistema carro/Dinamica Tambor Carro/Gain7','diag_xdrum','m');
addDirectSignal('Planta/Subsistema carro/Dinamica Carro Traslacional/Integrator1','diag_xtrolley','m');
addDirectSignal('Planta/Subsistema carro/Dinamica cable carro','diag_traction','N');
addDirectSignal('Planta/Subsistema carga/Dinamica Movimiento Carga/Divide','diag_load_acc1','m/s2');
addDirectSignal('Planta/Subsistema carga/Dinamica Movimiento Carga/Divide1','diag_load_acc2','m/s2');
oldLogging=cell(size(ports)); oldMode=cell(size(ports)); oldName=cell(size(ports));
for k=1:numel(ports)
    oldLogging{k}=get_param(ports(k),'DataLogging');
    oldMode{k}=get_param(ports(k),'DataLoggingNameMode');
    oldName{k}=get_param(ports(k),'DataLoggingName');
    set_param(ports(k),'DataLogging','on','DataLoggingNameMode','Custom', ...
        'DataLoggingName',names{k});
end
catalogo=table(string(names(:)),string(sources(:)),string(units(:)), ...
    'VariableNames',{'senal','origen_en_modelo','unidad'});
cleanup=onCleanup(@()restorePorts(ports,oldLogging,oldMode,oldName));

    function addOutput(blockName,outName,tag,unit)
        block=uniqueBlock(blockName);
        child=[block '/' outName];
        assert(getSimulinkBlockHandle(child)>0,'Falta salida: %s',child);
        number=str2double(get_param(child,'Port'));
        ph=get_param(block,'PortHandles');
        addPort(ph.Outport(number),tag,child,unit);
    end
    function addInput(blockName,inName,tag,unit)
        block=uniqueBlock(blockName);
        child=[block '/' inName];
        assert(getSimulinkBlockHandle(child)>0,'Falta entrada: %s',child);
        number=str2double(get_param(child,'Port'));
        ph=get_param(block,'PortHandles');
        line=get_param(ph.Inport(number),'Line');
        assert(line>0,'Entrada sin linea: %s',child);
        addPort(get_param(line,'SrcPortHandle'),tag,child,unit);
    end
    function addBlockOutput(blockName,number,tag,unit)
        block=uniqueBlock(blockName);
        ph=get_param(block,'PortHandles');
        addPort(ph.Outport(number),tag,block,unit);
    end
    function addNamedLine(lineName,tag,unit)
        lines=find_system(model,'FindAll','on','Type','line');
        found=[];
        for j=1:numel(lines)
            if strcmp(get_param(lines(j),'Name'),lineName)
                found(end+1)=lines(j); %#ok<AGROW>
            end
        end
        assert(~isempty(found),'Falta linea: %s',lineName);
        % Ramas del mismo cable comparten origen y pueden heredar el nombre.
        port=zeros(size(found));
        for n=1:numel(found),port(n)=get_param(found(n),'SrcPortHandle');end
        port=unique(port(port>0));
        assert(isscalar(port),'Se esperaba un origen unico: %s',lineName);
        addPort(port,tag,getfullname(get_param(port,'Parent')),unit);
    end
    function addVelocity()
        lines=find_system(model,'FindAll','on','Type','line');
        found=[];
        for j=1:numel(lines)
            if ~strcmp(get_param(lines(j),'Name'),'v_t'), continue; end
            source=get_param(lines(j),'SrcBlockHandle');
            if source>0 && contains(getfullname(source),'Dinamica Carro Traslacional/Integrator')
                found(end+1)=lines(j); %#ok<AGROW>
            end
        end
        assert(numel(found)==1,'No se encontro la velocidad real del carro.');
        addPort(get_param(found,'SrcPortHandle'),'carro_velocidad_real', ...
            getfullname(get_param(found,'SrcBlockHandle')),'m/s');
    end
    function block=uniqueBlock(blockName)
        direct=[model '/' blockName];
        if getSimulinkBlockHandle(direct)>0
            block=direct; return;
        end
        matches=find_system(model,'LookUnderMasks','all','FollowLinks','on', ...
            'Name',blockName);
        matches=matches(~strcmp(matches,model));
        assert(numel(matches)==1,'Bloque no unico o ausente: %s',blockName);
        block=matches{1};
    end
    function addPort(port,tag,source,unit)
        assert(port>0,'Puerto invalido: %s',tag);
        % Dos puntos de observacion pueden compartir el mismo cable fisico.
        % En ese caso se conserva una sola copia de la serie.
        if ismember(port,ports), return; end
        ports(end+1)=port; names{end+1}=tag; %#ok<AGROW>
        sources{end+1}=source; units{end+1}=unit; %#ok<AGROW>
    end
    function addDirectSignal(relativePath,tag,unit)
        block=[model '/' relativePath];
        assert(getSimulinkBlockHandle(block)>0,'Bloque ausente: %s',block);
        ph=get_param(block,'PortHandles');
        if strcmp(get_param(block,'BlockType'),'Outport')
            line=get_param(ph.Inport(1),'Line');
            port=get_param(line,'SrcPortHandle');
        else
            port=ph.Outport(1);
        end
        addPort(port,tag,block,unit);
    end
end

function restorePorts(ports,oldLogging,oldMode,oldName)
for j=1:numel(ports)
    if ishandle(ports(j))
        set_param(ports(j),'DataLogging',oldLogging{j}, ...
            'DataLoggingNameMode',oldMode{j},'DataLoggingName',oldName{j});
    end
end
end
