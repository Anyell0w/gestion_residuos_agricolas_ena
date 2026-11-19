# Guía paso a paso: publicar datos y código en Zenodo y obtener los DOI

Esta guía explica cómo publicar **dos registros** en Zenodo y cómo insertar sus DOI en el artículo y el repositorio:

| Registro | Contenido | Cómo se crea | Marcador en los archivos |
|---|---|---|---|
| **Datos** | CSV crudo, extracto depurado, asignaciones de clúster, diccionario, tablas | Subida manual (formulario web) | `10.5281/zenodo.XXXXXXX` |
| **Código** | Este repositorio completo (scripts, artículo, configuración) | Integración GitHub → Zenodo (automática al publicar un *release*) | `10.5281/zenodo.YYYYYYY` |

> **Recomendación:** haga primero una prueba completa en el **entorno de pruebas** <https://sandbox.zenodo.org> (es idéntico, pero sus DOI no son reales). Un registro publicado en Zenodo **no se puede borrar**; solo se pueden publicar versiones nuevas.

---

## 0. Preparación (una sola vez)

1. Cree una cuenta en <https://zenodo.org> (puede iniciar sesión con GitHub u ORCID; se recomienda vincular su ORCID).
2. Suba este repositorio a GitHub (público):
   ```bash
   cd ena-cap600-clustering
   git init && git add . && git commit -m "Versión inicial del pipeline y artículo"
   git branch -M main
   git remote add origin https://github.com/<SU_USUARIO>/ena-cap600-clustering.git
   git push -u origin main
   ```
3. Genere el paquete de datos para Zenodo:
   ```bash
   make zenodo        # crea zenodo/upload/ con los archivos y checksums.md5
   ```

## 1. Registro de DATOS (subida manual)

1. En Zenodo pulse **“New upload”** (o el botón **+** → *New upload*).
2. **Files:** arrastre todos los archivos de `zenodo/upload/`.
3. **“Do you already have a DOI for this upload?”** → elija **No** y pulse **“Get a DOI now!”**. Zenodo **reserva** el DOI antes de publicar: anótelo (p. ej., `10.5281/zenodo.15123456`). El número final (`15123456`) es el **ID del registro**.
4. Complete los metadatos (puede copiarlos de `zenodo/zenodo_data_metadata.json`):
   * *Resource type:* **Dataset**
   * *Title:* Gestión de residuos agrícolas y pecuarios en productores agropecuarios del Perú: datos depurados de la ENA (Cap. 600) y asignaciones de grupo
   * *Creators:* los cuatro autores (Zamora Valencia, Angello Marcelo; Mamani Mena, Ronaldo Carlos; Cáceres Tacora, Lizbeth Estefany; Butrón Maquera, Tania Karin) — Universidad Nacional del Altiplano (añada los ORCID)
   * *Description:* pegue la descripción del JSON
   * *Licenses:* **Creative Commons Attribution 4.0 International**
   * *Keywords:* ENA, INEI, Perú, residuos agrícolas, estiércol, quema de rastrojos, análisis de conglomerados
   * *Version:* 1.0.0 · *Language:* Spanish
5. Pulse **Publish**. El DOI reservado queda activo.

## 2. Registro de CÓDIGO (integración GitHub)

1. En Zenodo: menú de su usuario → **GitHub** → pulse **“Sync now”** y active (interruptor **ON**) el repositorio `ena-cap600-clustering`.
2. Zenodo leerá automáticamente el archivo `.zenodo.json` del repositorio para los metadatos.
3. En GitHub: **Releases → Draft a new release** → *Tag* `v1.0.0` → *Title* `v1.0.0` → **Publish release**.
4. En unos minutos aparecerá el registro en Zenodo con **dos DOI**:
   * **DOI de la versión** (solo v1.0.0).
   * **DOI de concepto** (*“Cite all versions”*): resuelve siempre a la última versión. **Use este en el artículo.**

> La integración con GitHub **no permite reservar el DOI antes del release**. Por eso el primer release (v1.0.0) todavía contiene el marcador `YYYYYYY`; el paso 3 lo corrige con un segundo release.

## 3. Insertar los DOI en el repositorio y el artículo

```bash
# bash scripts/set_doi.sh <ID_DATOS> <ID_CODIGO_CONCEPTO> <USUARIO_GITHUB>
bash scripts/set_doi.sh 15123456 15123999 angellozamora
make paper                        # recompila el PDF con los DOI reales
git add -A && git commit -m "DOI de Zenodo para datos y código"
git push
```

Luego publique en GitHub el release **`v1.0.1`**: Zenodo creará automáticamente la nueva versión del código, que ya contiene los DOI correctos. El DOI de concepto no cambia.

Opcional: en el registro de datos de Zenodo pulse **Edit** y añada en *Related works* el DOI del código con la relación **“Is supplement to”**.

## 4. Verificación final

* Abra `https://doi.org/10.5281/zenodo.<ID_DATOS>` y `https://doi.org/10.5281/zenodo.<ID_CODIGO>`: ambos deben resolver.
* Compruebe que `make data` descarga el CSV y que la suma MD5 coincide.
* Revise la sección **Disponibilidad de datos y código** y las referencias [10]–[11] del PDF.

## Preguntas frecuentes

* **¿Puedo subir los microdatos del INEI?** Son datos públicos; se incluyen citando al INEI como fuente original y aclarando que los indicadores y asignaciones son derivados (ver `LICENSE-DATA`). Si su institución exige otra cosa, publique solo los archivos derivados y deje el enlace al portal del INEI.
* **¿Qué pasa si me equivoco?** Edite los metadatos (siempre posible) o publique una **nueva versión** (*New version*) con archivos corregidos; el DOI de concepto se mantiene.
* **Límite de tamaño:** 50 GB por registro; este paquete ocupa unos 40 MB.
