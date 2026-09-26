# Метаданные App Store — решение по данным US (26.09.2026)

Источник: Astro, 302 ключа по US, `data/astro-us-2026-09-26.csv`. Формат ниже — popularity/difficulty.

## Решение

| Поле | Значение | Символов |
|---|---|---|
| Name | `Image Size & Photo to PDF` | 25 / 30 |
| Subtitle | `Resize, JPG, HEIC Converter` | 27 / 30 |
| Keywords | `convert,picture,dpi,blur,compress,reduce,batch,crop,png,jpeg,maker,file,print,kb` | 80 / 100 |

Охват (сумма popularity × выигрываемость по всем покрытым ключам): **713** для трёх полей,
из них **434** дают название и сабтайтл. Прошлый черновик `Image Converter & Image Size` /
`Photo to PDF & Compressor` давал 304 при большем числе символов.

## Почему так

**PDF — самый сильный выигрываемый кластер, и он стабилен.** Четыре из пяти лучших ключей по
popularity × (1 − difficulty) — это PDF, и их цифры не сдвинулись между снимками 16.09 и 26.09:

| Ключ | US | Комментарий |
|---|---|---|
| jpg to pdf | 57/40 | лучший баланс во всём наборе |
| photos to pdf | 58/45 | |
| convert image to pdf | 38/17 | difficulty 17 — берётся сразу |
| convert photo to pdf | 36/21 | |
| image to pdf | 52/52 | |
| photo to pdf | 62/69 | самый большой спрос, дорогой |

**Два кластера обвалились за 10 дней** — поэтому ушли из названия:

| Ключ | 16.09 | 26.09 |
|---|---|---|
| square fit | 40 | 9 |
| photo compressor | 24 | 9 |
| watermark maker | 26 | 9 |
| background changer | 24 | 7 |

Compress как инструмент остаётся в приложении — он построен и работает. Но как якорь метаданных
он больше не тянет: весь кластер в US теперь 5–19.

**Стабильные якоря** (почти не изменились между снимками): photo to pdf 62, image converter 49,
image size 44, jpg to pdf 57. На них и строим.

## Что покрывает каждое поле

Apple склеивает слова из названия, сабтайтла и keyword field, поэтому слова не повторяются между полями.

- **Название** даёт слова image, size, photo, pdf → image size 44, photo to pdf 62, image to pdf 52, photo pdf 26.
- **Сабтайтл** даёт resize, jpg, heic, converter → jpg to pdf 57, image converter 49, photo converter 36,
  heic converter 22, convert heic to jpg 21, heic to jpg 13, resize 22.
- **Keyword field** добирает blur 56, pdf maker 43, pictures to pdf 36, dpi 24, picture converter 21,
  reduce photo size 19, batch resize 14. Слово `convert` продублировано намеренно: стемминг
  converter → convert у Apple не гарантирован, а на нём висят два ключа с difficulty 17 и 21.

## Оговорки

1. **Данные только по US.** CA/AU/GB — снимок от 16.09, а за 10 дней в US сдвинулись четыре кластера.
   Перед финальной заливкой стоит прогнать те же 302 ключа по трём остальным рынкам.
2. Популярность Astro шумит на краях: доверяем тому, что совпало в двух снимках, а не одиночному числу.
3. Слово «free» не используем — жёсткий пейвол плюс «free» в листинге даёт отказ по 3.1.2/5.6.

## Продуктовое следствие

Якорь метаданных — PDF, а в приложении он сейчас минимальный: одно фото на страницу A4, без
изменения порядка страниц и размера листа. По нашему же правилу отбора (popularity > 40) усиление
PDF обосновано данными: photos to pdf 58, jpg to pdf 57, image to pdf 52.
