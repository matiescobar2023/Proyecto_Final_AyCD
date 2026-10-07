function result=verificar_regulacion_variadores()
% Alias compatible; el banco FF tiene nombre propio para evitar colisiones.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');
result=verificar_regulacion_ff();
end