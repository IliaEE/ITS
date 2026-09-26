#!/usr/bin/env python3
"""Создаёт дашборд PostHog из docs/analytics/dashboard.md.

Ключ не хранится в репозитории: скрипт читает personal API key (scopes insight:write,
dashboard:write) из ~/.posthog/personal_api_key или из переменной POSTHOG_PERSONAL_KEY.
Запуск повторно создаст новый дашборд — существующий не трогает.
"""
import json, os, sys, urllib.request, urllib.error

PROJECT = os.environ.get("POSTHOG_PROJECT", "284992")
BASE = f"https://eu.posthog.com/api/projects/{PROJECT}"
KEY = os.environ.get("POSTHOG_PERSONAL_KEY") or open(os.path.expanduser("~/.posthog/personal_api_key")).read().strip()

def call(path, data=None, method=None):
    req = urllib.request.Request(
        BASE + path, method=method or ("POST" if data else "GET"),
        data=json.dumps(data).encode() if data else None,
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, (json.load(r) if r.status != 204 else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")

def ev(event, props=None, math="total"):
    node = {"kind": "EventsNode", "event": event, "name": event, "math": math}
    if props:
        node["properties"] = [{"key": k, "value": v if isinstance(v, list) else [v],
                               "operator": "exact", "type": "event"} for k, v in props.items()]
    return node

def trend(series, breakdown=None, display="ActionsBarValue", days="-30d"):
    src = {"kind": "TrendsQuery", "series": series, "dateRange": {"date_from": days},
           "trendsFilter": {"display": display}}
    if breakdown:
        src["breakdownFilter"] = {"breakdown": breakdown, "breakdown_type": "event"}
    return {"kind": "InsightVizNode", "source": src}

def funnel(events, days="-30d"):
    return {"kind": "InsightVizNode", "source": {
        "kind": "FunnelsQuery", "series": events, "dateRange": {"date_from": days},
        "funnelsFilter": {"funnelVizType": "steps"}}}

PANELS = [
    ("1 · Путь по инструменту",
     funnel([ev("tool_opened"), ev("photos_picked"), ev("job_started"), ev("job_finished"), ev("result_saved")])),
    ("2 · Чем пользуются", trend([ev("job_finished")], breakdown="tool")),
    ("3 · Открыли против сделали", trend([ev("tool_opened"), ev("job_started")], breakdown="tool")),
    ("4 · Convert: форматы", trend([ev("job_started", {"tool": "convert"})], breakdown="format")),
    ("5 · Image Size: режимы", trend([ev("job_started", {"tool": "size"})], breakdown="mode")),
    ("6 · Image Size: пресеты", trend([ev("job_started", {"tool": "size"})], breakdown="preset")),
    ("7 · Image Size: DPI", trend([ev("job_started", {"tool": "size"})], breakdown="dpi")),
    ("8 · Compress: качество", trend([ev("job_started", {"tool": "compress"})], breakdown="quality")),
    ("9 · Blur: сила", trend([ev("job_started", {"tool": "blur"})], breakdown="strength")),
    ("10 · Blur: размер кисти", trend([ev("job_started", {"tool": "blur"})], breakdown="brush")),
    ("11 · Пакет или одно фото", trend([ev("job_started")], breakdown="count")),
    ("12 · Куда сохраняют", trend([ev("result_saved")], breakdown="method")),
    ("13 · Ошибки", trend([ev("job_failed")], breakdown="reason")),
    ("14 · Пейвол: показы по триггеру", trend([ev("paywall_shown")], breakdown="trigger")),
    ("15 · Пейвол: показ → покупка",
     funnel([ev("paywall_shown"), ev("paywall_closed", {"purchased": True})])),
    ("16 · Запросы функций", trend([ev("feature_requested")], breakdown="features")),
    ("17 · Динамика работ по дням", trend([ev("job_finished")], breakdown="tool", display="ActionsLineGraph")),
    ("18 · Возвраты", {"kind": "InsightVizNode", "source": {
        "kind": "RetentionQuery", "dateRange": {"date_from": "-30d"},
        "retentionFilter": {"targetEntity": {"id": "tool_opened", "type": "events"},
                            "returningEntity": {"id": "tool_opened", "type": "events"},
                            "retentionType": "retention_first_time", "period": "Week"}}}),
]

def main():
    st, dash = call("/dashboards/", {
        "name": "Image Tools — продукт",
        "description": "Воронка по инструментам, выбор опций внутри каждого, пейвол и запросы функций."})
    if st not in (200, 201):
        print("не удалось создать дашборд:", st, dash); sys.exit(1)
    print(f"дашборд {dash['id']}: https://eu.posthog.com/project/{PROJECT}/dashboard/{dash['id']}")

    for name, query in PANELS:
        st, ins = call("/insights/", {"name": name, "query": query, "dashboards": [dash["id"]]})
        print(("  ok  " if st in (200, 201) else " FAIL "), name, "" if st in (200, 201) else f"{st} {str(ins)[:160]}")

if __name__ == "__main__":
    main()
