#!/usr/bin/env bash
# Automatiza las seis pruebas del apartado 8 con Kitchen/Pan REALES y guarda los logs
# en evidencias/logs/. Uso (Linux, macOS, WSL o Git Bash):
#
#     export PDI_HOME=/ruta/a/data-integration      # carpeta con kitchen.sh y pan.sh
#     bash evidencias/ejecutar_pruebas.sh
#
# Modifica entrada/ y temporal/ solo temporalmente y SIEMPRE las restaura (trap).
# No usa datos inventados: todo lo que se escribe en los logs lo imprime Pentaho.
set -u
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${PDI_HOME:?Define PDI_HOME con la carpeta data-integration}"
K="$PDI_HOME/kitchen.sh"; P="$PDI_HOME/pan.sh"
LOG="$RAIZ/evidencias/logs"; mkdir -p "$LOG" "$RAIZ/temporal" "$RAIZ/salida"
JOB="$RAIZ/procesos/cierre_hotel.kjb"
RES="$LOG/resumen_pruebas.txt"; : > "$RES"
dic() { echo "$*" | tee -a "$RES"; }
hash_salida() { (cd "$RAIZ/salida" && sha256sum informe_hotel_canal.csv reservas_sin_cobro.csv 2>/dev/null); }
restaurar() {
  [ -f "$RAIZ/entrada/cobros_pdi.csv.prueba" ] && mv -f "$RAIZ/entrada/cobros_pdi.csv.prueba" "$RAIZ/entrada/cobros_pdi.csv"
}
trap restaurar EXIT

dic "=== Prueba 1: primera ejecución (sin informes anteriores) ==="
rm -f "$RAIZ"/temporal/*.csv "$RAIZ"/salida/*.csv
"$K" -file="$JOB" -level=Basic > "$LOG/01_primera_ejecucion.log" 2>&1; dic "exit Kitchen = $? (esperado 0)"
dic "$(wc -l "$RAIZ"/salida/*.csv)"; H1="$(hash_salida)"
grep -E "CIERRE CORRECTO|VALIDACION OK" "$LOG/01_primera_ejecucion.log" | tee -a "$RES"

dic "=== Prueba 2: repetición con las mismas entradas ==="
"$K" -file="$JOB" -level=Basic > "$LOG/02_repeticion.log" 2>&1; dic "exit Kitchen = $? (esperado 0)"
dic "$(wc -l "$RAIZ"/salida/*.csv)"
[ "$H1" = "$(hash_salida)" ] && dic "Huellas de salida IDÉNTICAS tras repetir: no se acumulan filas" || dic "ATENCIÓN: las salidas han cambiado al repetir"

dic "=== Prueba 3: falta una entrada (cobros_pdi.csv) ==="
H3="$(hash_salida)"
mv "$RAIZ/entrada/cobros_pdi.csv" "$RAIZ/entrada/cobros_pdi.csv.prueba"
"$K" -file="$JOB" -level=Basic > "$LOG/03_falta_entrada.log" 2>&1; dic "exit Kitchen = $? (esperado distinto de 0)"
restaurar
grep -E "FALTA LA ENTRADA" "$LOG/03_falta_entrada.log" | tee -a "$RES"
[ "$H3" = "$(hash_salida)" ] && dic "salida/ intacta: no se publicó nada nuevo" || dic "ATENCIÓN: salida/ cambió"

dic "=== Prueba 4: salida incompleta (solo cabecera) en copia provisional ==="
head -1 "$RAIZ/salida/informe_hotel_canal.csv"  > "$RAIZ/temporal/informe_hotel_canal.csv"
head -1 "$RAIZ/salida/reservas_sin_cobro.csv"   > "$RAIZ/temporal/reservas_sin_cobro.csv"
"$P" -file="$RAIZ/procesos/validar_informe.ktr"    -level=Basic > "$LOG/04a_cabecera_informe.log" 2>&1; dic "validar_informe: exit Pan = $? (esperado distinto de 0)"
"$P" -file="$RAIZ/procesos/validar_sin_cobro.ktr"  -level=Basic > "$LOG/04b_cabecera_sin_cobro.log" 2>&1; dic "validar_sin_cobro: exit Pan = $? (esperado distinto de 0)"

dic "=== Prueba 5: total incorrecto en copia provisional ==="
sed 's/^Laredo;web;2;496.50$/Laredo;web;2;596.50/' "$RAIZ/salida/informe_hotel_canal.csv" > "$RAIZ/temporal/informe_hotel_canal.csv"
cp "$RAIZ/salida/reservas_sin_cobro.csv" "$RAIZ/temporal/reservas_sin_cobro.csv"
"$P" -file="$RAIZ/procesos/validar_informe.ktr" -level=Basic > "$LOG/05_total_incorrecto.log" 2>&1; dic "exit Pan = $? (esperado distinto de 0)"

dic "=== Prueba 6: recuperación (entradas restauradas, job completo) ==="
( cd "$RAIZ/entrada" && sha256sum reservas_pdi.csv cobros_pdi.csv hoteles_pdi.csv )  | tee -a "$RES"
"$K" -file="$JOB" -level=Basic > "$LOG/06_recuperacion.log" 2>&1; dic "exit Kitchen = $? (esperado 0)"
python3 "$RAIZ/evidencias/referencia.py" "$LOG/referencia" >/dev/null
for f in informe_hotel_canal.csv reservas_sin_cobro.csv; do
  diff -q "$LOG/referencia/$f" "$RAIZ/salida/$f" >/dev/null && dic "$f == referencia independiente (Python)" || dic "ATENCIÓN: $f difiere de la referencia"
done
dic "Fin. Logs en evidencias/logs/. Restaura/verifica con git status que entrada/ no ha cambiado."
