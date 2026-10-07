function cerrar_video_ensayo
figs=findall(0,'Type','figure');
for k=1:numel(figs)
 if isappdata(figs(k),'CODESYSJointVideoWriter')
  writer=getappdata(figs(k),'CODESYSJointVideoWriter');close(writer);
  rmappdata(figs(k),'CODESYSJointVideoWriter');
 end
end
end
