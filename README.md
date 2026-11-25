# Informe del hotel con Pentaho (UT1)

Práctica integradora de la UT1 (Big Data Aplicado): informe de cobros del grupo hotelero de Cantabria con Pentaho Data Integration (PDI).

- **Autor:** NOMBRE_ALUMNO <!-- TODO: nombre completo (sustituir también NOMBRE_ALUMNO en las notas de los procesos, ver §11) -->
- **Código de paquete asignado:** **A008** (conjunto `cierre_aula_01`, ver `asignacion.json`)
- **Repositorio:** `bda-ut1-pentaho-hotel`

> **Estado de la verificación (leer primero).** Los cinco procesos se han ejecutado de verdad con **Kitchen y Pan de PDI 9.4.0.0-343 y OpenJDK 11** (modo consola, 25/11/2026 ~20:28 UTC): el job termina con éxito y código 0, `salida/` coincide con un cálculo independiente en Python (`evidencias/referencia.py`) y las siete pruebas de fallo dan el resultado esperado (logs reales en `evidencias/logs/`). **Aún no se han abierto en la interfaz gráfica de Spoon**: antes de defender conviene abrirlos, revisar el lienzo y las notas, y repetir las pruebas en el equipo del aula.

## 1. Objetivo y alcance

Dirección necesita el **importe cobrado y el número de reservas cobradas por hotel y canal**, un CSV claro del cierre y un listado de las **reservas que todavía no tienen cobro asociado**. El procedimiento debe poder repetirse y avisar —sin publicar nada— si no puede generar el informe.

**Explicación para gerencia** (sin lenguaje de Spoon):

> El cierre **`cierre_aula_01`** es un conjunto cerrado de 20 reservas, 15 cobros y 5 hoteles (Laredo, Santander, Potes, Comillas y Noja). Los archivos no traen fechas, así que no corresponde a un día concreto: es el cierre de aula ya seleccionado. Los resultados de este cierre se generaron el **25/11/2026** (última ejecución con Kitchen: **20:28 UTC**; repetirla en el aula y actualizar la hora si procede); esa es la fecha de generación del informe, **no** la fecha de los cobros.
> **15 de las 20 reservas tienen un cobro asociado y suman 3 965,50 euros cobrados**, repartidos en 13 combinaciones de hotel y canal (web, OTA o recepción); por ejemplo, Laredo por web: 2 reservas y 496,50 €. Todas las cantidades están **en euros**.
> **Las otras 5 reservas** (números 4, 9, 11, 15 y 18; 639,90 € de precio de reserva en total) **no tienen cobro asociado en el archivo recibido**. Hay que revisarlas, pero **no demuestran un impago**: puede haber un pago pendiente o un plazo de pago que estos archivos no describen.
> **No se calcula la ocupación**: para ello faltan las habitaciones disponibles y ocupadas por periodo (y las fechas de estancia de cada reserva). Pediríamos esa información a cada hotel.

**Límites de los datos:** un solo cierre sin fechas; un único cobro como máximo por reserva; no hay devoluciones, pagos parciales ni fechas de pago; `importe` es el precio de la reserva, `cobrado` es el dinero que ha entrado. Con el paquete A008, `cobrado` coincide con `importe` en las 15 reservas cobradas; por eso la regla «sumar cobrado» no se distingue numéricamente de sumar el precio aquí, pero sigue siendo la regla correcta (en un cierre real un pago parcial las separaría).

## 2. Recorrido de los datos

```
reservas_pdi.csv + cobros_pdi.csv + hoteles_pdi.csv      (entrada/, originales intactos)
        ↓
Lectura con separador/tipos propios de cada archivo; ordenación por clave
        ↓
informe_cobros.ktr:      INNER reservas⋈cobros → INNER ⋈hoteles → agrupar por hotel/canal
reservas_sin_cobro.ktr:  LEFT OUTER reservas⟕cobros → filtrar id_reserva_cobro nulo → ⋈hoteles
        ↓
informe_hotel_canal.csv + reservas_sin_cobro.csv         (temporal/, provisionales)
        ↓
validar_informe.ktr + validar_sin_cobro.ktr              (Abort con error si algo no cuadra)
        ↓
Copia a salida/ (solo si ambas validaciones pasan) y registro de éxito
```

El job `cierre_hotel.kjb` orquesta todo el recorrido; las transformaciones tratan las filas.

## 3. Versiones y requisitos

- Pentaho Data Integration Community **9.4.0.0-343**.
- Java: OpenJDK 11 (11.0.33) en las pruebas de este repositorio; usar el Java indicado por el aula (PDI 9.4 pide Java 8 u 11, no 21).
- Sistema: las pruebas se hicieron en Linux (consola); en el aula, Windows con `kitchen.bat`.
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
├── temporal/         # resultados provisionales (NO se sube a Git; Git no guarda carpetas vacías)
├── salida/           # los dos CSV finales comprobados
└── evidencias/       # sesiones, comprobaciones, pruebas, guía de defensa y scripts de contraste
```

Todos los procesos están directamente en `procesos/` y usan rutas relativas con `${Internal.Transformation.Filename.Directory}` y `${Internal.Job.Filename.Directory}`. **Hay que guardar el proceso antes de probarlo** para que esas variables se resuelvan; no hay rutas propias de ningún equipo.

## 5. Datos de entrada

Procedencia: paquete personal **A008** entregado por el profesor (`cierre_aula_01`). No contienen datos personales de huéspedes.

| Archivo | Separador | Filas | Integer | String | BigNumber |
|---|---|---|---|---|---|
| `reservas_pdi.csv` | `,` | 20 | id_reserva, id_hotel, noches | canal | importe |
| `cobros_pdi.csv` | `;` | 15 | id_reserva | medio | cobrado |
| `hoteles_pdi.csv` | `;` | 5 | id_hotel, id_cadena | hotel, comarca | — |

Lectura: cabecera activada, UTF-8, punto como símbolo decimal, sin separador de miles, *Lazy conversion* desactivado. Las huellas SHA-256 de los tres originales coinciden con `asignacion.json`.

## 6. Cómo ejecutarlo desde una copia recién descargada

1. Clonar el repositorio.
2. **Crear las carpetas que Git no conserva** (los procesos las crean si faltan, pero conviene dejarlas hechas):
   ```bash
   mkdir -p temporal salida
   ```
3. Ejecutar el job con Kitchen (ajustar la ruta de PDI y del repositorio):
   ```bash
   kitchen.bat /file="C:/ruta/bda-ut1-pentaho-hotel/procesos/cierre_hotel.kjb" /level:Basic
   ```
   En Linux: `kitchen.sh -file=/ruta/bda-ut1-pentaho-hotel/procesos/cierre_hotel.kjb -level=Basic`.
4. Resultados (códigos de salida de Kitchen: 0 = éxito, distinto de 0 = fallo):
   - `salida/informe_hotel_canal.csv` → `hotel;canal;n_reservas;cobrado_total`
   - `salida/reservas_sin_cobro.csv` → `id_reserva;hotel;canal;importe;motivo`

Para probar una transformación suelta: `pan.bat /file="C:/ruta/procesos/informe_cobros.ktr" /level:Basic`.
Kitchen no queda programado por ejecutarlo a mano: de madrugada lo lanzaría el programador de tareas del sistema (cron o Programador de tareas de Windows) con el mismo comando.

## 7. Decisiones de diseño

- **Uniones:** reservas ⋈ cobros por `id_reserva` (INNER, 15 filas) y después ⋈ hoteles por `id_hotel` (INNER, 15 filas). *Merge join* exige entradas ordenadas por la clave: sin ordenar, el resultado sería silenciosamente incompleto. En la rama de cobros y en la de hoteles se renombra la clave (`id_reserva_cobro`, `id_hotel_hotel`) con *Select values* para que no haya dos campos con el mismo nombre en la unión y se distinga qué clave viene de cada lado.
- **Se suma `cobrado`, no `importe`:** `importe` es el precio de la reserva; `cobrado` es el dinero que ha entrado.
- **Una fila por hotel y canal:** `n_reservas` (recuento de `id_reserva`) y `cobrado_total` (suma de `cobrado`). Hay 13 grupos y no 20 porque solo se incluyen las 15 reservas con cobro y varias comparten hotel y canal. Se pueden contar filas porque hay como máximo un cobro por reserva; con varios pagos por reserva el cruce duplicaría filas y habría que contar `id_reserva` distintos y sumar los cobros por separado (o agregar los cobros por reserva antes de unir).
- **Reservas sin cobro:** LEFT OUTER (reservas a la izquierda) y filtro `id_reserva_cobro` nulo. No se usa `cobrado = 0`: un cobro de cero es un cobro registrado; un cobro ausente es la ausencia de registro. Es un control interno, no una prueba de impago.
- **Repetición sin acumular:** *Text file output* con *Append* desactivado; cada ejecución sobrescribe el provisional y la copia sobrescribe `salida/`.
- **Generar → validar → publicar:** los resultados se escriben en `temporal/`, se validan automáticamente y solo entonces se copian a `salida/`. No se borra el último informe publicado al empezar.
- **Qué impide iniciar la publicación:** falta de una entrada (`File exists`), fallo de cualquiera de las dos transformaciones, ausencia de un provisional, o fallo de cualquiera de las dos validaciones. Todos terminan en *Abort job* antes de copiar nada.
- **Publicación no atómica:** copiar dos archivos no es atómico. Si falla la segunda copia, `salida/` puede tener un archivo nuevo y otro anterior o ausente; el job registra el aviso de resultado parcial, termina con error y **no** anuncia éxito. Ampliación posible (no exigida): publicar por versiones y señalar la nueva versión solo cuando esté completa.
- **Validación automática:** los controles fijan los valores de `cierre_aula_01` (13 grupos, 15 reservas, 3965.50 €; reservas 4, 9, 11, 15, 18). En un cierre real se compararía con totales calculados desde las entradas, no con constantes. Un CSV con solo cabecera o con valores nulos falla gracias a *Always give back a result row* y *Abort* con umbral 0.
- **Por qué CSV:** el volumen es pequeño, lo abre cualquier herramienta de oficina y dirección puede leerlo sin software específico; es texto plano versionable en Git. Para un histórico grande consultado por columnas se estudiaría un formato columnar como Parquet (compresión y lectura solo de las columnas necesarias).
- **Por qué un proceso por lotes:** el cierre es un conjunto cerrado y se procesa de una vez, iniciado por una persona o un programador de tareas (no por un evento); no hay requisito de tiempo real.

Relación con el tema: almacenamiento (1.3: originales, provisionales y publicados en carpetas separadas), procesamiento (1.4: lotes), arquitectura (1.5: lectura → transformación → validación → publicación), ingesta (1.6: lectura con tipos, claves y comprobación de entradas) y formatos (1.7: CSV frente a columnar).

## 8. Comprobaciones y pruebas

- Tabla esperado / obtenido / conclusión: [`evidencias/comprobaciones.md`](evidencias/comprobaciones.md)
- Seis pruebas (primera ejecución, repetición, falta de entrada, salida incompleta, total incorrecto, recuperación): [`evidencias/pruebas.md`](evidencias/pruebas.md). Se ejecutan y quedan registradas con `evidencias/ejecutar_pruebas.sh` (logs en `evidencias/logs/`).
- Contraste independiente de Pentaho: `python3 evidencias/referencia.py` y `diff` con `salida/`.
- Registros de sesión: [`sesion-01`](evidencias/sesion-01.md), [`sesion-02`](evidencias/sesion-02.md), [`sesion-03`](evidencias/sesion-03.md).
- Preparación de la defensa: [`evidencias/guia_defensa.md`](evidencias/guia_defensa.md).

**Al repetir la ejecución** con las mismas entradas se obtienen los mismos 13 grupos, las mismas 15 reservas y el mismo total; los archivos se sobrescriben y no crecen (prueba 2).

Resultados de referencia con este paquete: 20 / 15 / 5 filas leídas, 15 filas tras cada unión, **13 grupos**, **15 reservas cobradas**, **3965.50 €** y **5 reservas sin cobro** (4, 9, 11, 15 y 18).

## 9. Qué pediríamos para medir ocupación

Habitaciones disponibles y ocupadas por hotel y por periodo (día/mes), o bien el inventario de habitaciones y las fechas de entrada/salida de cada reserva (incluidas cancelaciones). Con `noches` no basta: sin periodo ni capacidad no se puede dividir.

## 10. Fuentes y ayudas

- Apuntes y talleres de la UT1 (1.3–1.8) y enunciado de la práctica.
- Se ha recibido ayuda de una herramienta de IA (Claude Code) para generar el esqueleto de los procesos `.ktr`/`.kjb`, el cálculo de referencia en Python y la documentación; el equipo los revisa, los abre en Spoon y los ejecuta en el aula. La IA ejecutó los procesos en modo consola y generó los logs de `evidencias/logs/`. <!-- TODO: añadir ayudas de compañeros/profesor y qué se ha adaptado -->

## 11. Pendiente de completar antes de entregar

1. Sustituir `NOMBRE_ALUMNO` (README y notas de los lienzos): `grep -rl NOMBRE_ALUMNO .` y reemplazar.
2. Abrir cada proceso en Spoon, guardarlo y comprobar vistas previas (ver `evidencias/guia_defensa.md`).
3. Repetir en el equipo del aula `ejecutar_pruebas.sh` (o las pruebas a mano) y anotar diferencias con los logs de `evidencias/logs/`.
4. Actualizar la hora de generación en §1 si repetís la ejecución, y completar las ayudas en §10.
5. Entregar en Moodle URL del repositorio + hash completo del commit.
