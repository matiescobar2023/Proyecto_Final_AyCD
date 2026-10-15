# Informe final

Autores: Matías Escobar y Martín Herrera.

La versión actual es **v3**. El PDF y su fuente principal se encuentran en esta carpeta.

## Compilar

Se necesita MiKTeX o TeX Live con pdfLaTeX y los paquetes indicados en `DEPENDENCIAS_LATEX.txt`.

En Windows, ejecutar desde PowerShell:

```powershell
.\compilar.ps1
```

También se puede abrir `Informe_AyCD_EscobarHerrera_v3.tex` en un editor LaTeX y compilar con pdfLaTeX. Ejecutar tres pasadas para actualizar el índice y las referencias.

En Overleaf, cargar el contenido completo de esta carpeta y seleccionar ese archivo como documento principal, con el compilador pdfLaTeX.

## Archivos incluidos

- PDF y fuente LaTeX de la versión v3.
- Clase local `ieeeconf.cls` y las dos secciones externas de pruebas.
- `imagenes_informe`: figuras, diagramas y gráficas del documento.
- `Codigo_MC` y `documentacion_*`: material auxiliar para editar códigos y regenerar figuras de las pruebas y trayectorias.

Conservar las rutas relativas de las imágenes y las secciones externas. No se necesita MATLAB ni CODESYS para compilar el informe; los scripts auxiliares de gráficas pueden requerir MATLAB.
