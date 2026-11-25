# Las seis pruebas del apartado 8

**Cómo se ejecutan.** La forma recomendada es el script, que usa Kitchen/Pan reales, deja los logs en `evidencias/logs/` y restaura siempre lo que modifica:

```bash
export PDI_HOME=/ruta/a/data-integration     # carpeta con kitchen.sh y pan.sh
bash evidencias/ejecutar_pruebas.sh          # Linux/macOS/WSL/Git Bash
```

En Windows nativo, ejecutar a mano los mismos pasos con `kitchen.bat` / `pan.bat` (`/file:... /level:Basic`) y guardar la salida con `> evidencias\logs\NN_nombre.log 2>&1`.

**Estado: pendiente de ejecutar.** Debajo está lo que se hace y lo que **debe** ocurrir (diseño de cada proceso). Las filas «Resultado obtenido» se rellenan con lo que muestren los logs reales; hasta entonces no hay prueba superada. Para cada una: pegar el extracto de log y *explicarlo* (qué se ejecutó, qué ocurrió y por qué).

> Las pruebas 4 y 5 ejecutan **directamente la transformación de validación** sobre una copia alterada del provisional. Si se ejecutara antes el job completo, regeneraría el archivo y borraría el fallo que se quiere probar.

---

## Prueba 1 — Primera ejecución
- **Qué se hace:** borrar `temporal/*.csv` y `salida/*.csv`; ejecutar Kitchen sobre `cierre_hotel.kjb`.
- **Debe ocurrir:** las dos salidas en `salida/`; log `VALIDACION OK ...` (×2) y `CIERRE CORRECTO ...`; código de salida 0.
- **Log:** `evidencias/logs/01_primera_ejecucion.log`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

## Prueba 2 — Repetición
- **Qué se hace:** ejecutar de nuevo el job con las mismas entradas.
- **Debe ocurrir:** mismos 13 grupos, mismas filas (14 líneas con cabecera y 6 con cabecera) y mismo total; el SHA-256 de `salida/*.csv` no cambia. No se acumulan filas porque *Text file output* no tiene *Append* y la copia sobrescribe.
- **Log:** `evidencias/logs/02_repeticion.log` y `resumen_pruebas.txt`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

## Prueba 3 — Falta una entrada
- **Qué se hace:** en una copia de trabajo, renombrar `entrada/cobros_pdi.csv` (el script lo hace y lo restaura) y ejecutar el job.
- **Debe ocurrir:** `File exists` de cobros falla → *Abort job* con `FALTA LA ENTRADA entrada/cobros_pdi.csv`; código de salida ≠ 0; las transformaciones ni se lanzan; `salida/` queda intacta (mismo SHA-256).
- **Log:** `evidencias/logs/03_falta_entrada.log`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

## Prueba 4 — Salida incompleta (solo cabecera)
- **Qué se hace:** dejar solo la cabecera en `temporal/informe_hotel_canal.csv` (y en `reservas_sin_cobro.csv`) y ejecutar con Pan `validar_informe.ktr` y `validar_sin_cobro.ktr`.
- **Debe ocurrir:** ambas validaciones terminan con **error** aunque el CSV exista: *Group by* con *Always give back a result row* emite una fila con 0 grupos / 0 identificadores, el filtro no se cumple y llega una fila a *Abort* (umbral 0).
- **Logs:** `evidencias/logs/04a_cabecera_informe.log`, `04b_cabecera_sin_cobro.log`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

## Prueba 5 — Total incorrecto
- **Qué se hace:** en una copia provisional cambiar `Laredo;web;2;496.50` por `Laredo;web;2;596.50` y ejecutar `validar_informe.ktr`.
- **Debe ocurrir:** el total pasa a 4065.50 → no cumple 3965.50 → *Abort* con error.
- **Log:** `evidencias/logs/05_total_incorrecto.log`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

## Prueba 6 — Recuperación
- **Qué se hace:** restaurar entradas (comprobar SHA-256 con `asignacion.json`) y ejecutar el job completo.
- **Debe ocurrir:** se generan, validan y publican otra vez las dos salidas correctas, idénticas a la referencia (`diff` vacío).
- **Log:** `evidencias/logs/06_recuperacion.log`
- **Resultado obtenido:** ☐ _______
- **Explicación:** ☐ _______

---

## Prueba complementaria: fallo durante la copia (no puntúa como las seis, pero la rúbrica la pide)
La rúbrica pide conservar el log que muestra el aviso de posible estado parcial. Para provocarlo en una copia de trabajo: quitar permisos de escritura al archivo de destino (`chmod a-w salida/reservas_sin_cobro.csv` en Linux; en Windows, atributo «solo lectura») y ejecutar el job.
- **Debe ocurrir:** la segunda copia falla → log `ERROR EN LA PUBLICACION ... resultado PARCIAL` → *Abort job* `PUBLICACION INCOMPLETA`; **no** aparece `CIERRE CORRECTO`; código de salida ≠ 0. Restaurar permisos después.
- **Log:** `evidencias/logs/07_copia_fallida.log`
- **Resultado obtenido:** ☐ _______ (si el sistema de ficheros no permite forzar el fallo, indicarlo y explicar la rama de error en Spoon)
