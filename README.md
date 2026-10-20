# Informe del hotel con Pentaho (UT1)

Práctica integradora de la UT1 (Big Data Aplicado): informe de cobros del grupo hotelero de Cantabria con Pentaho Data Integration.

- **Autor:** <!-- TODO: tu nombre completo -->
- **Código de paquete asignado:** **A008** (conjunto `cierre_aula_01`)
- **Repositorio:** bda-ut1-pentaho-hotel

## 1. Objetivo

Dirección necesita el **importe cobrado y el número de reservas cobradas por hotel y canal**, un CSV claro del cierre y un listado de las **reservas que todavía no tienen cobro asociado**. El procedimiento debe poder repetirse y avisar si no puede generar el informe.

## 2. Recorrido de los datos

```
reservas_pdi.csv + cobros_pdi.csv + hoteles_pdi.csv   (entrada/, originales)
        ↓
Lectura y comprobación de tipos y claves
        ↓
informe_hotel_canal.csv + reservas_sin_cobro.csv      (temporal/, provisionales)
        ↓
Validación automática de los dos archivos
        ↓
Copia a salida/ y registro del resultado              (salida/, publicados)
```

## 3. Versiones y requisitos

- Pentaho Data Integration Community **9.4.0.0-343**
- Java: <!-- TODO: salida de `java -version` -->
- Sistema: <!-- TODO: Windows 10/11 -->
- No se usan bases de datos, controladores JDBC, servicios de pago ni plugins adicionales.

## 4. Estructura del repositorio

```
bda-ut1-pentaho-hotel/
├── README.md
├── .gitignore
├── asignacion.json   # código del paquete y huellas SHA-256 de los originales
├── entrada/          # los tres CSV originales, sin modificar
├── procesos/         # informe_cobros.ktr, reservas_sin_cobro.ktr,
│                     # validar_informe.ktr, validar_sin_cobro.ktr, cierre_hotel.kjb
├── temporal/         # resultados provisionales (NO se sube a Git)
├── salida/           # los dos CSV finales comprobados
└── evidencias/       # registros de sesión, tabla de comprobaciones y pruebas
```

Todos los procesos están directamente en `procesos/` y usan rutas relativas con
`${Internal.Transformation.Filename.Directory}` y `${Internal.Job.Filename.Directory}`.
**Hay que guardar el proceso antes de probarlo** para que esas variables se resuelvan.

## 5. Datos de entrada

Procedencia: paquete personal **A008** entregado por el profesor (`cierre_aula_01`). No contienen datos personales.

| Archivo | Separador | Filas | Integer | String | BigNumber |
|---|---|---|---|---|---|
| `reservas_pdi.csv` | `,` | 20 | id_reserva, id_hotel, noches | canal | importe |
| `cobros_pdi.csv` | `;` | 15 | id_reserva | medio | cobrado |
| `hoteles_pdi.csv` | `;` | 5 | id_hotel, id_cadena | hotel, comarca | — |

Lectura: cabecera activada, UTF-8, punto como símbolo decimal y sin separador de miles.

## 6. Cómo ejecutarlo desde una copia recién descargada

1. Clonar el repositorio.
2. **Crear las carpetas que Git no conserva:**
   ```
   mkdir temporal
   mkdir salida
   ```
3. Ejecutar el job con Kitchen (ajustar la ruta de PDI y del repositorio):
   ```
   kitchen.bat /file="C:/ruta/bda-ut1-pentaho-hotel/procesos/cierre_hotel.kjb" /level:Basic
   ```
4. Resultados:
   - `salida/informe_hotel_canal.csv` (`hotel;canal;n_reservas;cobrado_total`)
   - `salida/reservas_sin_cobro.csv` (`id_reserva;hotel;canal;importe;motivo`)

Para probar una transformación suelta: `pan.bat /file="C:/ruta/procesos/informe_cobros.ktr" /level:Basic`.

Kitchen no queda programado por ejecutarlo a mano: de madrugada lo lanzaría el programador de tareas del sistema.

## 7. Decisiones de diseño

- **Uniones:** reservas ⋈ cobros por `id_reserva` (INNER) y después ⋈ hoteles por `id_hotel` (INNER). Ambas entradas de cada Merge join se ordenan por la clave.
- **Se suma `cobrado`, no `importe`:** `importe` es el precio de la reserva; `cobrado` es el dinero que ha entrado.
- **Una fila por hotel y canal:** `n_reservas` (recuento de `id_reserva`) y `cobrado_total` (suma de `cobrado`). Se pueden contar filas porque hay como máximo un cobro por reserva; si hubiera varios pagos por reserva, habría que contar reservas distintas y sumar cobros por separado.
- **Reservas sin cobro:** LEFT OUTER (reservas a la izquierda) y filtro `id_reserva_cobro` nulo. No se usa `cobrado = 0`: un cobro de cero y un cobro ausente son situaciones distintas.
- **Repetición sin acumular:** *Text file output* sin *Append*; cada ejecución sobrescribe.
- **Generar → validar → publicar:** los resultados se escriben en `temporal/`, se validan y solo entonces se copian a `salida/`. No se borra el último informe publicado al empezar.
- **Publicación no atómica:** copiar dos archivos no es atómico. Si falla la segunda copia, `salida/` puede quedar con un archivo nuevo y otro anterior o ausente; el job termina en error y lo advierte.
- **Por qué CSV:** el volumen es pequeño, lo abre cualquier herramienta de oficina y dirección puede leerlo sin software específico. Para un histórico grande consultado por columnas se estudiaría un formato columnar como Parquet.

## 8. Comprobaciones y pruebas

- Tabla esperado / obtenido / conclusión: `evidencias/comprobaciones.md` <!-- TODO: crear -->
- Seis pruebas (primera ejecución, repetición, falta de entrada, salida incompleta, total incorrecto, recuperación): `evidencias/pruebas.md` <!-- TODO: crear -->
- Registros de sesión: `evidencias/sesion-01.md`, `sesion-02.md`, …

Resultados de referencia con este paquete: 20 / 15 / 5 filas leídas, 15 filas tras cada unión, **13 grupos**, **15 reservas cobradas**, **3965.50 €** y **5 reservas sin cobro** (4, 9, 11, 15 y 18).

## 9. Explicación para gerencia

<!-- TODO: redactar al terminar, sin nombres de pasos de Spoon. Debe incluir:
- qué representa el cierre `cierre_aula_01` y la fecha y hora de generación (no es la fecha de cobro)
- cuántas reservas tienen cobro (15) y cuánto suman (3965.50 €, en euros)
- que 5 reservas no tienen cobro asociado y requieren revisión; no demuestran por sí solas un impago
- que no se calcula ocupación y qué datos adicionales se pedirían (habitaciones disponibles y ocupadas por periodo)
-->

## 10. Fuentes y ayudas

<!-- TODO: indicar apuntes de la UT1 (1.8), ayudas recibidas y qué se ha adaptado -->
