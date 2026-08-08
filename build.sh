#!/bin/bash
SOURCE_DIR="content"
OUTPUT_DIR="dist"

# Limpieza absoluta de dist para evitar conflictos de archivos viejos
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.html

# 1. DEFINIR NAVEGACIÓN (Última entrada por fecha/nombre)
LAST_FILE_PATH=$(ls "$SOURCE_DIR"/*.md | grep -vE "archivo.md|[Rr][Ee][Aa][Dd][Mm].md" | sort -V | tail -n 1)
LAST_FILENAME=$(basename "$LAST_FILE_PATH")
LAST_FILENAME="${LAST_FILENAME%.*}"
# Extraemos título real del YAML
LAST_TITLE=$(grep -m 1 '^title:' "$LAST_FILE_PATH" | sed -E 's/^title:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//' | xargs)
[ -z "$LAST_TITLE" ] && LAST_TITLE="$LAST_FILENAME"

NAV_LINKS="<li id='nav-index'><a href='index.html'>index</a></li>"
NAV_LINKS="$NAV_LINKS<li id='nav-last'><a href='${LAST_FILENAME}.html'>$LAST_TITLE</a></li>"

# 2. MAPEAR ETIQUETAS (Extraídas del YAML, normalizadas a slug ASCII)
slugify() {
    echo "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E "s/['\"]//g; s/[^a-z0-9]+/-/g; s/^-+//; s/-+$//"
}

declare -A TAG_MAP TAG_DISPLAY
ALL_FILES=$(ls "$SOURCE_DIR"/*.md | sort -V)

for file in $ALL_FILES; do
    filename=$(basename "$file")
    filename="${filename%.*}"
    [[ "$filename" == "README" || "$filename" == "readme" || "$filename" == "archivo" ]] && continue
    
    # Limpiamos comas y comillas de los tags para que Bash los procese bien
    TAGS_RAW=$(grep -m 1 '^tags:' "$file" | sed -E 's/^tags:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//' | tr ',' ' ')
    for tag in $TAGS_RAW; do
        tag=$(echo "$tag" | xargs)
        [ -z "$tag" ] && continue
        slug=$(slugify "$tag")
        [ -n "$slug" ] || continue
        TAG_MAP["$slug"]+="${file} "
        [ -z "${TAG_DISPLAY[$slug]}" ] && TAG_DISPLAY["$slug"]="$tag"
    done
done

# 3. GENERAR PÁGINAS DE ETIQUETAS
for slug in "${!TAG_MAP[@]}"; do
    display="${TAG_DISPLAY[$slug]}"
    TAG_FILENAME="tag-${slug}.html"
    TAG_PAGE_CONTENT="---\ntitle: \"Etiqueta: $display\"\n---\n<h3>Registro de <b>$display</b></h3>\n<ul>"
    for file_path in ${TAG_MAP[$slug]}; do
        fname=$(basename "$file_path")
        fname="${fname%.*}"
        title=$(grep -m 1 '^title:' "$file_path" | sed -E 's/^title:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//' | xargs)
        [ -z "$title" ] && title="$fname"
        TAG_PAGE_CONTENT="$TAG_PAGE_CONTENT\n  <li><a href='${fname}.html'>${title}</a></li>"
    done
    TAG_PAGE_CONTENT="$TAG_PAGE_CONTENT\n</ul>"
    echo -e "$TAG_PAGE_CONTENT" | pandoc -s -f markdown+raw_html --template="./layout-archivo.html" -V lang="es" -V nav-menu="$NAV_LINKS" -o "$OUTPUT_DIR/$TAG_FILENAME"
done

# 4. GENERAR ÍNDICE (Con etiquetas al lado del título)
INDEX_CONTENT="---
title: Rosetta
---
<ol id=\"lista-entradas\">"
for file in $ALL_FILES; do
    filename=$(basename "$file")
    filename="${filename%.*}"
    [[ "$filename" == "README" || "$filename" == "readme" || "$filename" == "archivo" ]] && continue

    TITLE=$(grep -m 1 '^title:' "$file" | sed -E 's/^title:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//' | xargs)
    [ -z "$TITLE" ] && TITLE=$(echo "$filename" | sed 's/-/ /g')
    
    # Generamos los links de las etiquetas para el listado
    TAGS_RAW=$(grep -m 1 '^tags:' "$file" | sed -E 's/^tags:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//' | tr ',' ' ')
    TAG_LINKS=""
    for tag in $TAGS_RAW; do
        tag=$(echo "$tag" | xargs)
        [ -z "$tag" ] && continue
        slug=$(slugify "$tag")
        [ -n "$slug" ] && TAG_LINKS="$TAG_LINKS <a href='tag-${slug}.html' class='tag-label'>$tag</a>"
    done
    INDEX_CONTENT="$INDEX_CONTENT\n  <li><a href='${filename}.html'>${TITLE}</a> $TAG_LINKS</li>"
done
INDEX_CONTENT="$INDEX_CONTENT\n</ol>"

# 5. COMPILACIÓN DE ENTRADAS 
for file in $ALL_FILES; do
    filename=$(basename "$file")
    filename="${filename%.*}"
    if [[ "$filename" == "README" || "$filename" == "readme" || "$filename" == "archivo" ]]; then continue; fi
    
    echo "📄 Generando: $filename.html"
    pandoc -s "$file" -f markdown+raw_html -t html --template="./layout.html" -V lang="es" -V nav-menu="$NAV_LINKS" -o "$OUTPUT_DIR/$filename.html"
done

echo -e "$INDEX_CONTENT" | pandoc -s -f markdown+raw_html --template="./layout-archivo.html" -V lang="es" -V nav-menu="$NAV_LINKS" -o "$OUTPUT_DIR/index.html"

# 6. RECURSOS (Estilos, logo e imágenes)
echo "🎨 Sincronizando estilos y recursos..."
mkdir -p "$OUTPUT_DIR/css" "$OUTPUT_DIR/img"

LOAD_PATHS="--load-path=node_modules/foundation-sites/scss --load-path=node_modules/motion-ui/src"
if ! npx sass $LOAD_PATHS scss/app.scss "$OUTPUT_DIR/css/app.css" --no-source-map --quiet-deps --silence-deprecation=import,slash-div; then
    echo "⚠️  Sass falló; revisa scss/app.scss"
fi

# Logo fijo del layout + imágenes de posts
if [ -d "img" ]; then
    cp -Rpf img/. "$OUTPUT_DIR/img/" 2>/dev/null
fi
if [ -d "$SOURCE_DIR/img" ]; then
    cp -Rpf "$SOURCE_DIR/img/." "$OUTPUT_DIR/img/" 2>/dev/null
    echo "📷 Imágenes sincronizadas."
fi

echo "🚀 Todo actualizado."
    