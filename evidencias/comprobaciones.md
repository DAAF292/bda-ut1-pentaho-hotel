# Comprobaciones: esperado / obtenido / conclusión

Paquete **A008**, conjunto `cierre_aula_01`. Hay dos columnas de «obtenido»:

- **Referencia independiente (Python)**: calculada con `evidencias/referencia.py`, sin Pentaho. Ya verificada.
- **Obtenido en Pentaho**: se rellena tras ejecutar los procesos (vista previa en Spoon o `ejecutar_pruebas.sh`). **Pendiente** hasta entonces; no se da por comprobado lo que no se ha ejecutado.

| # | Comprobación | Esperado | Referencia independiente (Python) | Obtenido en Pentaho | Conclusión |
|---|---|---|---|---|---|
| 1 | Reservas / cobros / hoteles leídos | 20 / 15 / 5 | 20 / 15 / 5 | ☐ | Pendiente de Pentaho |
| 2 | Claves únicas (`id_reserva` en reservas, `id_reserva` en cobros, `id_hotel`) | Sin duplicados | 20, 15 y 5 valores distintos | ☐ | Pendiente de Pentaho |
| 3 | Filas tras unir reservas y cobros | 15 | 15 | ☐ (paso *Unir reservas con cobros*) | Pendiente de Pentaho |
| 4 | Filas tras añadir hoteles | 15 | 15 (todos los `id_hotel` tienen hotel) | ☐ (paso *Unir con hoteles*) | Pendiente de Pentaho |
| 5 | Filas del informe (sin cabecera) | 13 grupos | 13 | ☐ | Pendiente de Pentaho |
| 6 | Suma de `n_reservas` | 15 | 15 | ☐ | Pendiente de Pentaho |
| 7 | Suma de `cobrado_total` | 3965.50 € | 3965.50 | ☐ | Pendiente de Pentaho |
| 8 | Laredo, canal web | 2 reservas; 496.50 € | `Laredo;web;2;496.50` | ☐ | Pendiente de Pentaho |
| 9 | Reservas sin cobro | 5: 4, 9, 11, 15, 18 | [4, 9, 11, 15, 18] | ☐ | Pendiente de Pentaho |
| 10 | Filas del LEFT OUTER (antes del filtro) | 20 | 20 | ☐ (paso *Unir reservas con cobros (LEFT OUTER)*) | Pendiente de Pentaho |
| 11 | Reconciliación de reservas | 15 + 5 = 20 | 15 + 5 = 20 | ☐ | Pendiente de Pentaho |
| 12 | Importes del listado sin cobro (precio de reserva) | 89.90, 140.00, 72.00, 268.00, 70.00 (suma 639.90) | idem | ☐ | Pendiente de Pentaho |

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

> Falta contrastar con «la tabla de referencia del taller 2» del enunciado, que no está en el repositorio: comparar manualmente esta tabla con la del aula.

## Comprobación automática de equivalencia

Tras ejecutar Kitchen, `salida/` debe ser idéntica a la referencia:

```bash
python3 evidencias/referencia.py
diff evidencias/referencia_out/informe_hotel_canal.csv salida/informe_hotel_canal.csv && echo IGUAL
diff evidencias/referencia_out/reservas_sin_cobro.csv  salida/reservas_sin_cobro.csv  && echo IGUAL
```

## Apertura fuera de Spoon

☐ Abrir `salida/informe_hotel_canal.csv` en una hoja de cálculo importando con separador `;`, UTF-8 y punto decimal. Confirmar: cabecera `hotel;canal;n_reservas;cobrado_total`, 13 filas, sin filas vacías ni columnas extra. Anotar aquí el resultado: _______

## Observación sobre este paquete

Con A008, `cobrado` es igual a `importe` en las 15 reservas cobradas (ambas sumas dan 3965.50). La regla «sumar cobrado, no importe» no se puede distinguir numéricamente con estos datos; hay que defenderla por principio (precio ≠ dinero cobrado), no con el resultado.
