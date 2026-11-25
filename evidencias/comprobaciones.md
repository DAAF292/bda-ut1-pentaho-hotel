# Comprobaciones: esperado / obtenido / conclusión

Paquete **A008**, conjunto `cierre_aula_01`. Hay dos columnas de «obtenido»:

- **Referencia independiente (Python)**: calculada con `evidencias/referencia.py`, sin Pentaho. Ya verificada.
- **Obtenido en Pentaho**: recuentos reales que imprime Kitchen (`I/O/R/W` de cada paso) en `evidencias/logs/01_primera_ejecucion.log`, ejecutado en modo consola con PDI 9.4.0.0-343 y OpenJDK 11 (ver «Entorno de la ejecución»). Está pendiente repetir la revisión visual en Spoon con vista previa.

| # | Comprobación | Esperado | Referencia independiente (Python) | Obtenido en Pentaho | Conclusión |
|---|---|---|---|---|---|
| 1 | Reservas / cobros / hoteles leídos | 20 / 15 / 5 | 20 / 15 / 5 | 20 / 15 / 5 (`Leer reservas W=20`, `Leer cobros W=15`, `Leer hoteles W=5`; sin errores de conversión, E=0) | Correcto (Kitchen) |
| 2 | Claves únicas (`id_reserva` en reservas, `id_reserva` en cobros, `id_hotel`) | Sin duplicados | 20, 15 y 5 valores distintos | Sin duplicados: las uniones no multiplican filas (15 → 15) y el control del listado detecta duplicados | Correcto (Kitchen) |
| 3 | Filas tras unir reservas y cobros | 15 | 15 | 15 (`Unir reservas con cobros (INNER)`: R=35, W=15) | Correcto (Kitchen) |
| 4 | Filas tras añadir hoteles | 15 | 15 (todos los `id_hotel` tienen hotel) | 15 (`Unir con hoteles (INNER)`: R=20, W=15) | Correcto (Kitchen) |
| 5 | Filas del informe (sin cabecera) | 13 grupos | 13 | 13 (`Agrupar por hotel y canal`: R=15, W=13; `Escribir`: 13 filas + cabecera) | Correcto (Kitchen) |
| 6 | Suma de `n_reservas` | 15 | 15 | 15 (log de validación: `suma_reservas = 15`) | Correcto (Kitchen) |
| 7 | Suma de `cobrado_total` | 3965.50 € | 3965.50 | 3965.5 (log de validación: `suma_cobrado = 3965.5`) | Correcto (Kitchen) |
| 8 | Laredo, canal web | 2 reservas; 496.50 € | `Laredo;web;2;496.50` | `Laredo;web;2;496.50` en `salida/informe_hotel_canal.csv` | Correcto (Kitchen) |
| 9 | Reservas sin cobro | 5: 4, 9, 11, 15, 18 | [4, 9, 11, 15, 18] | 4, 9, 11, 15, 18 (`reservas_sin_cobro.csv`) | Correcto (Kitchen) |
| 10 | Filas del LEFT OUTER (antes del filtro) | 20 | 20 | 20 (`LEFT OUTER`: R=35, W=20) | Correcto (Kitchen) |
| 11 | Reconciliación de reservas | 15 + 5 = 20 | 15 + 5 = 20 | 15 + 5 = 20 | Correcto (Kitchen) |
| 12 | Importes del listado sin cobro (precio de reserva) | 89.90, 140.00, 72.00, 268.00, 70.00 (suma 639.90) | idem | 89.90, 140.00, 72.00, 268.00, 70.00 | Correcto (Kitchen) |

## Contraste de cada grupo hotel/canal

Un total correcto puede ocultar importes asignados al hotel equivocado, por eso se contrasta cada fila (esta es la tabla esperada, calculada desde las entradas):

| hotel | canal | n_reservas | cobrado_total |
|---|---|---|---|
| Comillas | ota | 1 | 132.00 |
| Comillas | recepcion | 1 | 525.00 |
| Comillas | web | 2 | 642.00 |
| Laredo | ota | 1 | 124.00 |
| Laredo | web | 2 | 496.50 |
| Noja | ota | 1 | 195.00 |
| Noja | web | 1 | 280.00 |
| Potes | ota | 1 | 260.00 |
| Potes | recepcion | 1 | 201.00 |
| Potes | web | 1 | 150.00 |
| Santander | ota | 1 | 390.00 |
| Santander | recepcion | 1 | 410.00 |
| Santander | web | 1 | 160.00 |

> Con Pentaho, `salida/` se contrastó con `diff` y es idéntica a esta tabla. Falta contrastar con «la tabla de referencia del taller 2» del enunciado, que no está en el repositorio: comparar manualmente esta tabla con la del aula.

## Comprobación automática de equivalencia

Tras ejecutar Kitchen, `salida/` debe ser idéntica a la referencia:

```bash
python3 evidencias/referencia.py
diff evidencias/referencia_out/informe_hotel_canal.csv salida/informe_hotel_canal.csv && echo IGUAL
diff evidencias/referencia_out/reservas_sin_cobro.csv  salida/reservas_sin_cobro.csv  && echo IGUAL
```

## Entorno de la ejecución
Ejecutado en un contenedor Linux sin interfaz gráfica: **Kitchen y Pan de PDI Community 9.4.0.0-343** (`pdi-ce-9.4.0.0-343.zip`, SHA-1 `bd89671a9d6f95948d3fbbfd33102710f3e004e0`, el publicado por el proyecto *legacy-pentaho-ce*) con **OpenJDK 11.0.33**, el 25/11/2026 sobre las 20:28 UTC. Esto prueba que los procesos cargan y se ejecutan con esa versión; **no** sustituye abrirlos en Spoon en el aula (aspecto del lienzo, notas, vista previa).

Resultado del contraste con `diff` tras esa ejecución: `salida/informe_hotel_canal.csv` y `salida/reservas_sin_cobro.csv` son **idénticos** a la referencia en Python.

## Apertura fuera de Spoon

☐ Abrir `salida/informe_hotel_canal.csv` en una hoja de cálculo importando con separador `;`, UTF-8 y punto decimal. Confirmar: cabecera `hotel;canal;n_reservas;cobrado_total`, 13 filas, sin filas vacías ni columnas extra. Anotar aquí el resultado: _______

## Observación sobre este paquete

Con A008, `cobrado` es igual a `importe` en las 15 reservas cobradas (ambas sumas dan 3965.50). La regla «sumar cobrado, no importe» no se puede distinguir numéricamente con estos datos; hay que defenderla por principio (precio ≠ dinero cobrado), no con el resultado.
