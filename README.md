# Pandoc Web CMS

Sitio estático generado desde Markdown con **Pandoc**, estilos **Foundation** (Sass) y automatización con **Gulp**. El contenido vive en `content/*.md` y se compila a `dist/` (branch `gh-pages`).

## Contenido

- `content/*.md` → entradas (cada una con YAML: `title`, `author`, `tags`, `date`).
- `content/img/` → imágenes de las entradas.
- `img/` → logo y recursos de la plantilla.

## Compilado

```bash
npm install          # instalar dependencias (requiere Node >= 18)
bash build.sh        # compila contenido + sass a dist/
gulp                 # igual que build.sh + BrowserSync + watch + deploy
```

`gulp` además vigila cambios (MD/HTML/SCSS), recarga el navegador y publica `dist/` en la rama `gh-pages`.

## PDF

`bash pdf.sh` exporta todo el contenido a `pdf/<fecha>_playaderatas_archivo.pdf` con `xelatex` (estilo halftone B/N, links azules, alineación izquierda).

## Estructura

```
content/        entradas en Markdown
css→dist/css    estilos compilados (solo en dist)
filters/        (deprecado, ya no se usan)
img/            logo y recursos
js/             scripts del sitio
layout.html     template de entradas
layout-archivo.html   template de índice y etiquetas
scss/           fuente del estilo (Foundation)
build.sh        pipeline Bash
gulpfile.js     automatización Node/Gulp
pdf.sh          exportación PDF
```