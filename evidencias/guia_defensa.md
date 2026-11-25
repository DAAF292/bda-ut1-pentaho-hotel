# Guía para preparar la defensa individual

Para defender hay que comprender lo construido. Esta guía resume qué hace cada proceso, qué abrir en Spoon antes de la defensa y las preguntas probables con su respuesta. **Los procesos se han generado con ayuda de IA y se han ejecutado con Kitchen/Pan (consola), pero no se han abierto en la interfaz de Spoon**: antes de defender, abrirlos todos, guardarlos y recorrerlos paso a paso. Los logs reales están en `evidencias/logs/`.

## 1. Checklist antes de la defensa (en Spoon)
1. Abrir `informe_cobros.ktr` → guardar → *Run*. Comprobar que no hay pasos en rojo. Vista previa tras cada *Merge join* (15 filas) y tras *Group by* (13). Si un paso marca error de campo, revisar nombres de campos en la pestaña de campos de ese paso.
2. Abrir `reservas_sin_cobro.ktr` → vista previa tras el LEFT OUTER (20 filas), tras el filtro (5) y al final (5 columnas).
3. Abrir `validar_informe.ktr` y `validar_sin_cobro.ktr` → ejecutar con el provisional correcto (pasan) y con uno solo con cabecera (fallan).
4. Abrir `cierre_hotel.kjb` → ejecutar → comprobar el orden y que cada rama roja lleva a un *Abort job*.
5. Ejecutar `ejecutar_pruebas.sh` (o las seis pruebas a mano) y leer los logs.
6. Si algún paso no abre o falla en Spoon, **anotarlo en la sesión y corregirlo**. Kitchen ya los carga y ejecuta bien con 9.4.0.0-343, así que lo esperable es que solo cambie algo visual (posición de pasos, notas).

## 2. Qué hace cada proceso
| Proceso | Entrada | Salida | Idea clave |
|---|---|---|---|
| `informe_cobros.ktr` | 3 CSV | `temporal/informe_hotel_canal.csv` | INNER reservas⋈cobros (15), INNER ⋈hoteles (15), agrupar → 13 |
| `reservas_sin_cobro.ktr` | reservas, cobros, hoteles | `temporal/reservas_sin_cobro.csv` | LEFT OUTER + `id_reserva_cobro` nulo → 5 |
| `validar_informe.ktr` | provisional del informe | log OK o Abort | resumen sin claves: 13 grupos, 15 reservas, 3965.50 € |
| `validar_sin_cobro.ktr` | provisional sin cobro | log OK o Abort | ids permitidos, sin duplicados, exactamente 5 |
| `cierre_hotel.kjb` | — | `salida/` | comprobar → generar → validar → publicar → éxito |

## 3. Preguntas probables
- **¿Por qué se ordena antes de *Merge join*?** Porque recorre las dos entradas a la vez, ordenadas por la clave; si no lo están, deja de emparejar filas y el resultado sale incompleto sin dar error.
- **¿Por qué 13 filas y no 20?** Solo entran las 15 reservas con cobro (INNER) y varias comparten hotel y canal: una fila por combinación. Las 5 sin cobro van a otro listado.
- **¿Por qué sumar `cobrado` y no `importe`?** `importe` es el precio de la reserva; `cobrado` es lo que ha entrado. En este paquete coinciden (3965.50 en ambos), pero la regla es por significado, y un pago parcial las separaría.
- **¿Por qué `id_reserva_cobro` nulo y no `cobrado = 0`?** Un cobro de 0 es un registro existente; la ausencia es no tener registro. El LEFT OUTER deja nulos los campos de la derecha cuando no hay pareja.
- **¿Qué demuestra la repetición?** Que el procedimiento es idempotente: mismas entradas → mismas salidas, sin acumular (sin *Append* y copia con sobrescritura).
- **¿Qué fallos impiden iniciar la publicación?** Falta de una entrada, fallo de cualquier transformación, ausencia de un provisional o fallo de una validación. Terminan en *Abort job* antes de copiar.
- **¿Qué pasa si falla una copia?** Puede quedar `salida/` con un archivo nuevo y otro anterior o ausente (no es atómico). El job registra el aviso de resultado parcial y termina con error; nunca anuncia éxito.
- **¿Por qué un CSV con solo cabecera debe fallar?** Un grupo sin claves devuelve «sin fila» si no llegan datos y el filtro no se evalúa; *Always give back a result row* fuerza una fila con 0 y *Abort* con umbral 0 falla al recibir la primera.
- **¿Por qué el control del total puede ser peligroso?** Fija valores de este cierre; en uno real se reconciliaría con las entradas.
- **¿Por qué este informe no mide ocupación?** Faltan habitaciones disponibles y ocupadas por periodo (y fechas de estancia).
- **¿Seguiría valiendo con 500 GB?** Habría que revisar memoria de *Sort rows* (ordenación a disco), tiempo de lectura de CSV (formato columnar como Parquet, particionado), si cabe en la ventana de la madrugada y qué necesidad real hay antes de pensar en un clúster; eso es la UT2.

## 4. Pequeñas comprobaciones que puede pedir el profesor
- Seguir la reserva 12 (Santander, ota, cobrado 390.00) desde `reservas_pdi.csv` hasta `Santander;ota;1;390.00`.
- Mostrar qué pasa si falta `hoteles_pdi.csv` (*Abort job* con mensaje) o si se desordena una rama (menos filas).
- Localizar la rama que impide publicar y la que avisa del estado parcial.
