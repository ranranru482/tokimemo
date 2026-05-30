#!/usr/bin/env python3
"""立ち絵アセット受け入れ検証スクリプト（Claude/CI/手動 共通）。

assets/characters/ に投入された立ち絵 PNG が、命名規約・解像度・透過の
受け入れ条件を満たすか検証する。Flutter コードには一切依存しない
（標準ライブラリのみ）。仮素材・本番素材どちらの検証にも使える。

使い方:
    python tools/verify_character_assets.py [対象ディレクトリ]
    # 省略時は assets/characters/

終了コード:
    0 = 必須15枚すべて OK（警告はあっても可）
    1 = 不足 or 不正（PNG破損 / 命名不一致 / 致命的問題）

検証内容:
    - 命名規約: <id>_<expression>.png（id=akari|uta|toru|sayo|yui,
      expression=normal|smile|troubled）の 15 通りが過不足なく揃うか
    - PNG 署名（先頭8バイト）
    - 解像度（推奨 1024x1536・縦長。逸脱は警告）
    - 透過（IHDR colorType が 4/6、または tRNS チャンクを持つこと。
      無ければ警告：立ち絵は透過 PNG 前提）
"""
import os
import struct
import sys

IDS = ["akari", "uta", "toru", "sayo", "yui"]
EXPRESSIONS = ["normal", "smile", "troubled"]
EXPECTED = [f"{i}_{e}.png" for i in IDS for e in EXPRESSIONS]

PNG_SIG = b"\x89PNG\r\n\x1a\n"
RECOMMENDED = (1024, 1536)


def inspect_png(path):
    """(ok, width, height, color_type, has_trns, error) を返す。"""
    try:
        with open(path, "rb") as fh:
            sig = fh.read(8)
            if sig != PNG_SIG:
                return (False, 0, 0, None, False, "PNG署名が不正")
            # IHDR: length(4)+type(4)+data(13)
            fh.read(4)  # length
            ctype = fh.read(4)
            if ctype != b"IHDR":
                return (False, 0, 0, None, False, "IHDRが見つからない")
            w, h, _bitdepth, color_type = struct.unpack(">IIBB", fh.read(10))
            # tRNS チャンクの有無を走査（palette透過/グレースケール透過用）
            has_trns = False
            data = fh.read()
            has_trns = b"tRNS" in data
            return (True, w, h, color_type, has_trns, None)
    except Exception as exc:  # noqa: BLE001
        return (False, 0, 0, None, False, f"読み込み失敗: {exc}")


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "assets/characters"
    if not os.path.isdir(target):
        print(f"[FATAL] ディレクトリが存在しない: {target}")
        return 1

    present = {f for f in os.listdir(target) if f.lower().endswith(".png")}
    missing = [f for f in EXPECTED if f not in present]
    unexpected = sorted(f for f in present if f not in EXPECTED)

    print(f"== 立ち絵検証: {target} ==")
    print(f"検出 PNG: {len(present)} / 必須: {len(EXPECTED)}")

    errors = 0
    warnings = 0

    for name in EXPECTED:
        path = os.path.join(target, name)
        if name not in present:
            continue
        ok, w, h, color_type, has_trns, err = inspect_png(path)
        size_kb = os.path.getsize(path) // 1024
        if not ok:
            print(f"  [NG] {name}: {err}")
            errors += 1
            continue
        notes = []
        alpha_ok = color_type in (4, 6) or has_trns
        if not alpha_ok:
            notes.append("透過なし(要透過PNG)")
            warnings += 1
        if (w, h) != RECOMMENDED:
            notes.append(f"解像度{w}x{h}(推奨{RECOMMENDED[0]}x{RECOMMENDED[1]})")
            warnings += 1
        tag = "OK" if not notes else "WARN"
        suffix = f" | {' / '.join(notes)}" if notes else ""
        print(f"  [{tag}] {name}: {w}x{h} colorType={color_type} {size_kb}KB{suffix}")

    if missing:
        print(f"-- 不足 {len(missing)} 件: {', '.join(missing)}")
        errors += len(missing)
    if unexpected:
        print(f"-- 規約外 {len(unexpected)} 件(無視されます): {', '.join(unexpected)}")
        warnings += len(unexpected)

    print(f"== 結果: errors={errors} warnings={warnings} ==")
    if errors:
        print("NG: 不足/不正があります。投入を中止してください。")
        return 1
    print("OK: 必須15枚を確認（warnings は仮素材なら許容、本番では要解消）。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
