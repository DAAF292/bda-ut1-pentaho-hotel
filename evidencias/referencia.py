#!/usr/bin/env python3
"""Cálculo de referencia INDEPENDIENTE de Pentaho (solo biblioteca estándar).

Reproduce con Python las reglas del encargo sobre entrada/ y escribe los CSV
esperados. Sirve para contrastar la salida real de Kitchen:

    python3 evidencias/referencia.py            # escribe en evidencias/referencia_out/
    diff evidencias/referencia_out/informe_hotel_canal.csv salida/informe_hotel_canal.csv

No forma parte del procedimiento Pentaho: es solo un contraste.
"""
import csv, sys
from decimal import Decimal
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DEST = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "evidencias" / "referencia_out"

def leer(nombre, sep):
    with open(RAIZ / "entrada" / nombre, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter=sep))

reservas = leer("reservas_pdi.csv", ",")
cobros = leer("cobros_pdi.csv", ";")
hoteles = leer("hoteles_pdi.csv", ";")
assert (len(reservas), len(cobros), len(hoteles)) == (20, 15, 5)
assert len({r["id_reserva"] for r in reservas}) == 20       # clave única
assert len({c["id_reserva"] for c in cobros}) == 15         # como máximo un cobro por reserva
assert len({h["id_hotel"] for h in hoteles}) == 5

cobro_de = {c["id_reserva"]: Decimal(c["cobrado"]) for c in cobros}
nombre_hotel = {h["id_hotel"]: h["hotel"] for h in hoteles}

grupos = {}
for r in reservas:
    if r["id_reserva"] in cobro_de:                          # INNER con cobros
        k = (nombre_hotel[r["id_hotel"]], r["canal"])        # INNER con hoteles
        n, s = grupos.get(k, (0, Decimal("0")))
        grupos[k] = (n + 1, s + cobro_de[r["id_reserva"]])   # se suma COBRADO, no importe

sin_cobro = sorted((r for r in reservas if r["id_reserva"] not in cobro_de),
                   key=lambda r: int(r["id_reserva"]))

DEST.mkdir(parents=True, exist_ok=True)
with open(DEST / "informe_hotel_canal.csv", "w", encoding="utf-8", newline="") as f:
    f.write("hotel;canal;n_reservas;cobrado_total\n")
    for (h, c), (n, s) in sorted(grupos.items()):
        f.write(f"{h};{c};{n};{s:.2f}\n")
with open(DEST / "reservas_sin_cobro.csv", "w", encoding="utf-8", newline="") as f:
    f.write("id_reserva;hotel;canal;importe;motivo\n")
    for r in sin_cobro:
        f.write(f"{r['id_reserva']};{nombre_hotel[r['id_hotel']]};{r['canal']};"
                f"{Decimal(r['importe']):.2f};Sin cobro asociado en el archivo recibido\n")

tot_n = sum(n for n, _ in grupos.values()); tot_s = sum(s for _, s in grupos.values())
print(f"grupos={len(grupos)} reservas_cobradas={tot_n} cobrado_total={tot_s:.2f} "
      f"sin_cobro={[int(r['id_reserva']) for r in sin_cobro]} "
      f"reconciliacion={tot_n}+{len(sin_cobro)}={tot_n+len(sin_cobro)}")
print("importe de las 15 reservas cobradas (NO es lo cobrado):",
      sum(Decimal(r['importe']) for r in reservas if r['id_reserva'] in cobro_de))
