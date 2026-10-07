function bridge = codesys_opcua_bridge(writeNames,readNames)
% Enlace OPC UA cifrado del modelo con el PLC CODESYS.
% Las claves privadas permanecen fuera del paquete compartible.
endpoint = strtrim(getenv('CODESYS_OPCUA_ENDPOINT'));
if isempty(endpoint), endpoint = 'opc.tcp://127.0.0.1:4840'; end
serverSha1 = strtrim(getenv('CODESYS_OPCUA_SERVER_SHA1'));
username = strtrim(getenv('CODESYS_OPCUA_USERNAME'));
storageDir = strtrim(getenv('CODESYS_OPCUA_PRIVATE_DIR'));
if isempty(serverSha1) || isempty(username) || isempty(storageDir)
    error('CODESYS:OPCUA:Config', ...
        ['Defina CODESYS_OPCUA_SERVER_SHA1, CODESYS_OPCUA_USERNAME y ', ...
         'CODESYS_OPCUA_PRIVATE_DIR antes de simular.']);
end
password = getSecret('CODESYS_OPCUA_PASSWORD');
keyPassword = getSecret('CODESYS_OPCUA_KEY_PASSWORD');
try
    rootDir = fileparts(mfilename('fullpath'));
    pythonPaths = cellfun(@char,cell(py.sys.path),'UniformOutput',false);
    if ~any(strcmpi(pythonPaths,rootDir))
        insert(py.sys.path,int32(0),rootDir);
    end
    module = py.importlib.import_module('codesys_opcua_st_relojes_sin_antisway');
    if ~strcmpi(char(py.getattr(module,'__file__')),fullfile(rootDir,'codesys_opcua_st_relojes_sin_antisway.py'))
        error('CODESYS:OPCUA:PythonPath', ...
            'Python cargo codesys_opcua_st_relojes_sin_antisway desde otra carpeta; reinicie MATLAB.');
    end
    constructor = py.getattr(module,'Bridge');
    bridge = constructor(endpoint,serverSha1,username,char(password), ...
        char(keyPassword),storageDir,jsonencode(writeNames),jsonencode(readNames));
catch exception
    clear password keyPassword
    rethrow(exception);
end
clear password keyPassword
end



