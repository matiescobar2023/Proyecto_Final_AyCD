function estado=iniciar_medio_ciclo(variante)
% Requiere proyecto manual actualizado en RUN e identidad OPC UA local.
assert(ismember(variante,{'sin_antisway','referencia_antisway'}));
root=fileparts(mfilename('fullpath'));
if isfolder(fullfile(root,variante)),folder=fullfile(root,variante);else,folder=root;end
models=struct('sin_antisway','MC_R2_ST_RELOJ_sin_antisway','referencia_antisway','MC_R2_ST_RELOJ_referencia_antisway');
mdl=models.(variante);
running=find_system('type','block_diagram');
for k=1:numel(running)
    assert(strcmp(get_param(running{k},'SimulationStatus'),'stopped'),'Ya hay una simulacion en ejecucion.');
end
addpath(folder,'-begin');
% Cambiar solo el modulo local del enlace, con todas las simulaciones paradas.
sys=py.importlib.import_module('sys');
modules=py.getattr(sys,'modules');
old=modules.get('codesys_opcua_st_relojes_sin_antisway');
if ~isequal(old,py.None)
    pool=py.getattr(old,'_shared_pool');
    if ~isequal(pool,py.None)
        assert(double(py.getattr(pool,'references'))==0,'Hay un cliente OPC UA activo.');
    end
    modules.pop('codesys_opcua_st_relojes_sin_antisway');
end
insert(py.sys.path,int32(0),folder);
setenv('CODESYS_JOINT_NO_VIDEO','0');setenv('CODESYS_JOINT_EXTERNAL_VIDEO','0');setenv('CODESYS_JOINT_STOP_AFTER_DELIVERY','1');
load_system(fullfile(folder,[mdl '.slx']));
assert(~isfile(fullfile(folder,'datos_brutos.mat')), ...
    'Esta carpeta ya contiene una corrida: copie los archivos a otra carpeta antes de repetir.');
run(fullfile(folder,'parametros_ganancias_cascada_29072026.m'));
initialProfile=Y_c0(:);
readNames={'modeCode','faultCode','loadedState','profileValid','scannedObstacleProfile','profileMaxY','safetyEnvelopeProfile','autoEntryHeightOK','opcTimeoutSeconds','opcHeartbeatSimulink','opcHeartbeatPLC','opcImplementacionST'};
b=codesys_opcua_bridge({'profileValid','profileScanComplete','opcTimeoutSeconds','opcModoBancoSimulado','opcHeartbeatSimulink'},readNames);
cleanup=onCleanup(@()b.close());
original=cell(b.client.read_values(b.read_nodes));
timeoutOriginal=double(original{9});
assert(logical(original{12}),'El PLC no ejecuta el banco automatico ST esperado.');
assert(~logical(original{3}),'El PLC conserva carga previa: efectuar Reset en caliente antes del ensayo.');
frame=~logical(original{10});
b.exchange(jsonencode({false,false,3.0,true,frame})); % Inicializar supervisor antes de escribir perfil.
frame=~frame;
ua=py.importlib.import_module('asyncua.ua');
nodes=cell(b.read_nodes);
nodes{5}.set_value(ua.Variant(py.list(num2cell(initialProfile.')),ua.VariantType.Double));
b.exchange(jsonencode({true,false,3.0,true,frame}));
pause(.1); % Permitir que la tarea de 20 ms recalcule maximo y envolvente.
before=jsondecode(char(b.exchange(jsonencode({true,false,3.0,true,frame}))));
assert(~before{3},'El PLC indica carga previa; se requiere reinicializar su secuencia de carga.');
assert(max(abs(double(before{5}(:))-initialProfile))<1e-9,'Perfil PLC distinto al fisico inicial.');
assert(abs(double(before{6})-max(initialProfile))<1e-9,'Maximo del perfil aun no coherente.');
preflight=struct('fecha',char(datetime('now')),'variante',variante, ...
    'perfilInicial',initialProfile,'respuestaPLC',{before}, ...
    'masaContenedorSlot2',M_c_profile(2),'masaSpreader',M_s,'ganancias',CASCADE_INFO, ...
    'K_hp',K_hp,'K_hi',K_hi,'K_hd',K_hd,'timeoutEnsayo',3.0,'timeoutOriginal',timeoutOriginal);
save(fullfile(folder,'preflight.mat'),'preflight');
setappdata(0,'MedioCicloCarpeta',folder);
setappdata(0,'MedioCicloPreflight',preflight);
if isappdata(0,'CODESYSCycleResult'),rmappdata(0,'CODESYSCycleResult');end
clear cleanup b
set_param(mdl,'SimulationCommand','start');
estado=get_param(mdl,'SimulationStatus');
fprintf('MEDIO_CICLO %s %s\n',variante,estado);
end






