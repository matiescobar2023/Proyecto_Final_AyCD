function agregar_inyeccion_nan
% Genera datos no validos fuera del subsistema probado.
root=fileparts(mfilename('fullpath'));m='Banco_Seguridad_Stateflow';load_system(fullfile(root,'Banco',[m '.slx']));
for j=4:7
 if getSimulinkBlockHandle(sprintf('%s/InyectarNaN_%d',m,j))~=-1,continue;end
 delete_line(m,sprintf('Entrada_%d/1',j),sprintf('Seguridad/%d',j));
 add_block('simulink/Sources/From Workspace',sprintf('%s/EntradaInvalida_%d',m,j), ...
 'VariableName',sprintf('SegInvalid%d',j),'Interpolate','off','OutputAfterFinalValue','Holding final value');
 add_block('simulink/Sources/Constant',sprintf('%s/NaN_%d',m,j),'Value','NaN');
 add_block('simulink/Signal Routing/Switch',sprintf('%s/InyectarNaN_%d',m,j),'Criteria','u2 ~= 0');
 add_line(m,sprintf('NaN_%d/1',j),sprintf('InyectarNaN_%d/1',j));
 add_line(m,sprintf('EntradaInvalida_%d/1',j),sprintf('InyectarNaN_%d/2',j));
 add_line(m,sprintf('Entrada_%d/1',j),sprintf('InyectarNaN_%d/3',j));
 add_line(m,sprintf('InyectarNaN_%d/1',j),sprintf('Seguridad/%d',j));
end
Simulink.BlockDiagram.arrangeSystem(m);save_system(m);
end
