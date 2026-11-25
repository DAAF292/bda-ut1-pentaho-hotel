# Las seis pruebas del apartado 8

**Cómo se ejecutan.** La forma recomendada es el script, que usa Kitchen/Pan reales, deja los logs en `evidencias/logs/` y restaura siempre lo que modifica:

```bash
export PDI_HOME=/ruta/a/data-integration     # carpeta con kitchen.sh y pan.sh
bash evidencias/ejecutar_pruebas.sh          # Linux/macOS/WSL/Git Bash
```

En Windows nativo, ejecutar a mano los mismos pasos con `kitchen.bat` / `pan.bat` (`/file:... /level:Basic`) y guardar la salida con `> evidencias\logs\NN_nombre.log 2>&1`.

**Estado: ejecutadas con Kitchen/Pan 9.4.0.0-343 (OpenJDK 11, modo consola, 25/11/2026 ~20:28 UTC); logs en `evidencias/logs/`.** Pendiente: repetirlas en vuestro equipo/aula y anotar cualquier diferencia. Los extractos de abajo son literales de los logs.

> Las pruebas 4 y 5 ejecutan **directamente la transformación de validación** sobre una copia alterada del provisional. Si se ejecutara antes el job completo, regeneraría el archivo y borraría el fallo que se quiere probar.

---

## Prueba 1 — Primera ejecución
- **Qué se hace:** borrar `temporal/*.csv` y `salida/*.csv`; ejecutar Kitchen sobre `cierre_hotel.kjb`.
- **Debe ocurrir:** las dos salidas en `salida/`; log `VALIDACION OK ...` (×2) y `CIERRE CORRECTO ...`; código de salida 0.
- **Log:** `evidencias/logs/01_primera_ejecucion.log`
- **Resultado obtenido:** Kitchen terminó con código 0. Log: `VALIDACION OK informe_hotel_canal.csv: 13 grupos, 15 reservas, 3965.50 EUR`, `VALIDACION OK reservas_sin_cobro.csv: 5 reservas esperadas, sin duplicados` y `CIERRE CORRECTO: validadas y publicadas en salida/ las dos salidas`. `salida/` quedó con 14 y 6 líneas (con cabecera).
- **Explicación:** Partiendo sin salidas, se generaron los provisionales, pasaron las dos validaciones y solo entonces se copiaron. El orden de entradas del log (`Informe de cobros` → `Reservas sin cobro` → `Validar…` → `Publicar…` → `Registrar exito`) confirma la secuencia del job.

## Prueba 2 — Repetición
- **Qué se hace:** ejecutar de nuevo el job con las mismas entradas.
- **Debe ocurrir:** mismos 13 grupos, mismas filas (14 líneas con cabecera y 6 con cabecera) y mismo total; el SHA-256 de `salida/*.csv` no cambia. No se acumulan filas porque *Text file output* no tiene *Append* y la copia sobrescribe.
- **Log:** `evidencias/logs/02_repeticion.log` y `resumen_pruebas.txt`
- **Resultado obtenido:** Código 0 otra vez; `salida/` con 14 y 6 líneas; las huellas SHA-256 de los dos archivos son idénticas a las de la primera ejecución («Huellas de salida IDÉNTICAS tras repetir»).
- **Explicación:** La repetición no acumula filas porque *Text file output* escribe sin *Append* (sobrescribe el provisional) y la copia a `salida/` sustituye el archivo. Mismas entradas, mismas salidas: el procedimiento es repetible.

## Prueba 3 — Falta una entrada
- **Qué se hace:** en una copia de trabajo, renombrar `entrada/cobros_pdi.csv` (el script lo hace y lo restaura) y ejecutar el job.
- **Debe ocurrir:** `File exists` de cobros falla → *Abort job* con `FALTA LA ENTRADA entrada/cobros_pdi.csv`; código de salida ≠ 0; las transformaciones ni se lanzan; `salida/` queda intacta (mismo SHA-256).
- **Log:** `evidencias/logs/03_falta_entrada.log`
- **Resultado obtenido:** Código 1. Log: `Abortar: falta cobros_pdi.csv - ERROR ... FALTA LA ENTRADA entrada/cobros_pdi.csv. No se publica ningun informe.` Las transformaciones no llegan a lanzarse (solo aparecen las entradas `Existe reservas_pdi.csv` y `Existe cobros_pdi.csv`) y la huella de `salida/` no cambia («salida/ intacta»).
- **Explicación:** La comprobación `File exists` previa corta el job antes de generar nada: no se escribe en `temporal/` ni se publica. El mensaje dice qué entrada falta. El archivo se restauró y su SHA-256 vuelve a coincidir con `asignacion.json`.

## Prueba 4 — Salida incompleta (solo cabecera)
- **Qué se hace:** dejar solo la cabecera en `temporal/informe_hotel_canal.csv` (y en `reservas_sin_cobro.csv`) y ejecutar con Pan `validar_informe.ktr` y `validar_sin_cobro.ktr`.
- **Debe ocurrir:** ambas validaciones terminan con **error** aunque el CSV exista: *Group by* con *Always give back a result row* emite una fila con 0 grupos / 0 identificadores, el filtro no se cumple y llega una fila a *Abort* (umbral 0).
- **Logs:** `evidencias/logs/04a_cabecera_informe.log`, `04b_cabecera_sin_cobro.log`
- **Resultado obtenido:** Ambas validaciones terminan con código 1. En el informe: `Resumen sin claves ... W=1` y `Row nr 1 causing abort: [0], [null], [null], [100], [null]`; en sin cobro: `Row nr 1 causing abort: [0]` y `VALIDACION FALLIDA: ... (o está vacío)`.
- **Explicación:** Con solo la cabecera no llegan filas al resumen, pero *Always give back a result row* emite una fila con 0 grupos y sumas nulas; el filtro no se cumple y esa fila llega a *Abort* (umbral 0). Sin esa opción no habría fila, nada llegaría a *Abort* y el CSV vacío pasaría por válido.

## Prueba 5 — Total incorrecto
- **Qué se hace:** en una copia provisional cambiar `Laredo;web;2;496.50` por `Laredo;web;2;596.50` y ejecutar `validar_informe.ktr`.
- **Debe ocurrir:** el total pasa a 4065.50 → no cumple 3965.50 → *Abort* con error.
- **Log:** `evidencias/logs/05_total_incorrecto.log`
- **Resultado obtenido:** Código 1. `Row nr 1 causing abort: [13], [15], [4065.5], [100], [406550]` y `VALIDACION FALLIDA: informe_hotel_canal.csv no tiene 13 grupos, 15 reservas y 3965.50 EUR`.
- **Explicación:** Cambiar un importe de Laredo web de 496.50 a 596.50 subió el total a 4065.5 (406550 céntimos ≠ 396550). Los recuentos coinciden (13 y 15), así que lo detecta el control del total: un conteo correcto no basta.

## Prueba 6 — Recuperación
- **Qué se hace:** restaurar entradas (comprobar SHA-256 con `asignacion.json`) y ejecutar el job completo.
- **Debe ocurrir:** se generan, validan y publican otra vez las dos salidas correctas, idénticas a la referencia (`diff` vacío).
- **Log:** `evidencias/logs/06_recuperacion.log`
- **Resultado obtenido:** Código 0; las huellas de las tres entradas coinciden con `asignacion.json`; el job regeneró y publicó otra vez; `salida/informe_hotel_canal.csv` y `salida/reservas_sin_cobro.csv` son idénticos a la referencia independiente (Python).
- **Explicación:** Tras los fallos provocados, restaurar las entradas y relanzar el job basta para volver al estado correcto: el procedimiento no depende de estado previo de `salida/`.

---

## Prueba complementaria: fallo durante la copia (no puntúa como las seis, pero la rúbrica la pide)
La rúbrica pide conservar el log que muestra el aviso de posible estado parcial. Para provocarlo en una copia de trabajo: quitar permisos de escritura al archivo de destino (`chmod a-w salida/reservas_sin_cobro.csv` en Linux; en Windows, atributo «solo lectura») y ejecutar el job.
- **Debe ocurrir:** la segunda copia falla → log `ERROR EN LA PUBLICACION ... resultado PARCIAL` → *Abort job* `PUBLICACION INCOMPLETA`; **no** aparece `CIERRE CORRECTO`; código de salida ≠ 0. Restaurar permisos después.
- **Log:** `evidencias/logs/07_copia_fallida.log`
- **Resultado obtenido:** Ejecutada como usuario sin privilegios (como root los permisos no se aplican), con `salida/` de solo lectura, `informe_hotel_canal.csv` existente con contenido «VIEJO» y `reservas_sin_cobro.csv` ausente. Código 1. Log: la 1.ª copia se completa; la 2.ª falla (`Could not write to ... Permission denied`); después `Aviso: posible resultado parcial - ERROR EN LA PUBLICACION: una copia ha fallado. salida/ puede contener un archivo nuevo y otro anterior o ausente (resultado PARCIAL). No se anuncia exito.` y `PUBLICACION INCOMPLETA`. No aparece `CIERRE CORRECTO`.
- **Explicación:** Es el estado parcial descrito en el enunciado: `salida/` acabó con el informe nuevo (323 bytes, sustituyó a «VIEJO») y sin el listado sin cobro. El job lo avisa y falla, sin deshacer la primera copia (no se exige publicación atómica). Log: `evidencias/logs/07_copia_fallida.log`.

> **Aviso metodológico.** El primer intento de forzar el fallo de copia convirtiendo el destino en una *carpeta* con el nombre del CSV **no** produjo error: Pentaho copió el archivo dentro de esa carpeta y el job anunció `CIERRE CORRECTO` con código 0, aunque `salida/reservas_sin_cobro.csv` no era un archivo. Es una limitación del tipo de fallo provocado, no de la prueba válida de arriba; conviene saberlo si el profesor pregunta qué tipos de fallo detecta la copia (los de escritura sí; un destino mal formado puede pasar).
