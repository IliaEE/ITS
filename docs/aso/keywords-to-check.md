# Что снять в Astro для финальных метаданных

**Зачем.** Apple индексирует только **название (30), сабтайтл (30) и keyword field (100)**.
Описание в App Store на ранжирование не влияет — это текст на конверсию, не под ключи.
Поэтому: короткие запросы решают название и сабтайтл, длинные — keyword field.

**Что записывать на каждый ключ:** popularity, difficulty и, если видно, рейтинг и число отзывов текущего топ-3
(отчёт по нишам показал, что в resize и compress лидеры стареют — это и есть окно).

Формат ячейки — popularity/difficulty. «—» = ещё не снимали, надо снять.


## C1 Size / Resize


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| image size | 45/49 | 46/35 | 34/21 | 48/15 |
| photo size | 5/45 | 5/44 | 5/42 | 5/41 |
| resize | — | — | — | — |
| resize image | 9/50 | 7/21 | 9/21 | 9/40 |
| resize photo | 6/48 | 9/21 | 8/17 | 7/37 |
| image resizer | 7/48 | 8/17 | 6/21 | 7/21 |
| photo resizer | 9/59 | 9/40 | 9/17 | 9/19 |
| picture size | — | — | — | — |
| picture resizer | — | — | — | — |
| change photo size | 5/43 | 5/23 | 5/38 | 5/37 |
| image dimensions | — | — | — | — |
| photo dimensions | 5/15 | 5/15 | 5/23 | 5/15 |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| resize image without losing quality | — | — | — | — |
| resize photo to size | — | — | — | — |
| change photo size in kb | — | — | — | — |
| make photo smaller | 5/46 | 5/23 | 5/44 | 5/21 |
| reduce photo size | 19/21 | 5/13 | 5/15 | 5/19 |
| resize picture for instagram | — | — | — | — |
| photo size reducer app | — | — | — | — |
| resize image to exact size | — | — | — | — |
| resize multiple photos | 5/23 | 5/9 | 5/11 | 5/15 |

## C2 Compress


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| compress | — | — | — | — |
| compress image | 5/19 | 5/17 | 5/13 | 5/15 |
| compress photo | 5/19 | 5/11 | 5/11 | 5/17 |
| image compressor | 7/19 | 5/15 | 7/9 | 7/19 |
| photo compressor | 24/19 | 25/11 | 24/11 | 24/15 |
| compressor | — | — | — | — |
| reduce size | — | — | — | — |
| photo size reducer | 13/23 | 5/15 | 12/17 | 12/19 |
| shrink image | — | — | — | — |
| image optimizer | — | — | — | — |
| compress picture | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| compress photo without losing quality | — | — | — | — |
| reduce image file size | — | — | — | — |
| compress jpeg file size | — | — | — | — |
| make image file smaller | — | — | — | — |
| compress photos for email | — | — | — | — |
| reduce photo size for upload | — | — | — | — |

## C3 Convert / форматы


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| image converter | 50/42 | 9/15 | 6/13 | 51/13 |
| photo converter | 36/23 | 17/19 | 5/23 | 5/17 |
| picture converter | 21/39 | 5/21 | 5/19 | 5/19 |
| converter | — | — | — | — |
| convert image | — | — | — | — |
| jpg converter | 9/21 | 25/19 | 9/11 | 9/9 |
| png converter | 7/48 | 6/23 | 6/19 | 9/13 |
| heic converter | 22/17 | 5/11 | 5/5 | 5/9 |
| format converter | — | — | — | — |
| image format | — | — | — | — |
| convert photo | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| heic to jpg converter | — | — | — | — |
| convert heic to jpg | — | — | — | — |
| png to jpg converter | — | — | — | — |
| jpg to png converter | — | — | — | — |
| convert photo to png | — | — | — | — |
| image format converter app | — | — | — | — |
| convert iphone photos to jpg | — | — | — | — |

## C4 PDF


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| photo to pdf | 62/69 | 58/39 | 32/43 | 36/42 |
| image to pdf | 54/52 | 8/19 | 8/17 | 8/23 |
| pdf converter | — | — | — | — |
| pdf maker | — | — | — | — |
| jpg to pdf | 57/40 | 31/38 | 7/23 | 7/15 |
| pictures to pdf | — | — | — | — |
| photo pdf | — | — | — | — |
| scan to pdf | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| photo to pdf converter | — | — | — | — |
| convert image to pdf | — | — | — | — |
| multiple photos to pdf | — | — | — | — |
| jpg to pdf converter | — | — | — | — |
| combine photos into pdf | — | — | — | — |
| photos into one pdf | — | — | — | — |

## C5 Crop / Fit


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| crop | — | — | — | — |
| crop photo | 9/81 | 6/46 | 9/43 | 9/47 |
| crop image | 5/42 | 5/23 | 5/39 | 5/23 |
| crop pic | — | — | — | — |
| photo cropper | 13/46 | 5/53 | 13/41 | 13/21 |
| image cropper | — | — | — | — |
| square fit | 40/43 | 37/39 | 36/15 | 41/19 |
| aspect ratio | — | — | — | — |
| fit photo | 5/57 | 5/17 | 5/21 | 5/13 |
| no crop | 7/57 | 9/39 | 7/15 | 7/21 |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| crop photo to square | — | — | — | — |
| crop image to size | — | — | — | — |
| fit photo to instagram | — | — | — | — |
| add white border to photo | — | — | — | — |
| resize without cropping | — | — | — | — |
| crop picture to shape | — | — | — | — |

## C6 Blur


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| blur | — | — | — | — |
| blur photo | 55/65 | 32/21 | 8/21 | 58/50 |
| blur image | 6/42 | 5/19 | 6/13 | 10/38 |
| blur picture | — | — | — | — |
| censor photo | 5/43 | 5/13 | 5/13 | 5/13 |
| pixelate | 8/21 | 9/15 | 8/15 | 8/21 |
| hide face | 5/21 | 5/7 | 5/7 | 5/23 |
| blur tool | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| blur face in photo | — | — | — | — |
| blur part of photo | 5/50 | 5/23 | 5/23 | 5/40 |
| blur license plate | — | — | — | — |
| hide personal information in photo | — | — | — | — |
| censor text in photo | — | — | — | — |
| pixelate face in picture | — | — | — | — |

## C7 Batch / DPI / печать


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| batch resize | 14/17 | 8/15 | 14/11 | 14/9 |
| bulk resize | 5/13 | 5/21 | 5/5 | 5/17 |
| batch convert | 5/5 | 5/7 | 5/7 | 5/7 |
| dpi | 24/13 | 24/9 | 5/7 | 5/7 |
| change dpi | 5/31 | 5/9 | 5/15 | 5/11 |
| print size | 5/41 | 5/15 | 5/19 | 5/15 |
| photo dpi | — | — | — | — |
| image dpi | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| batch resize images | — | — | — | — |
| bulk image resizer | — | — | — | — |
| resize photos in bulk | — | — | — | — |
| change dpi of image | — | — | — | — |
| set dpi for printing | — | — | — | — |
| 300 dpi photo for print | — | — | — | — |

## C8 Generic / бренд


**Короткие → кандидаты в название и сабтайтл**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| image tools | 5/5 | 5/9 | 5/11 | 5/9 |
| photo tools | 5/57 | 5/39 | 5/39 | 5/21 |
| photo utility | — | — | — | — |
| image editor | — | — | — | — |
| photo editor | 73/89 | 70/74 | 70/71 | 72/76 |
| picture editor | 59/90 | 42/73 | 46/71 | 53/74 |
| photo app | — | — | — | — |
| image app | — | — | — | — |

**Длинные → кандидаты в keyword field**

| Ключ | US | CA | AU | GB |
|---|---|---|---|---|
| all in one photo tools | — | — | — | — |
| photo editing tools app | — | — | — | — |
| simple photo editor app | — | — | — | — |

## Как решаем по цифрам

1. **Название (30).** Два-три слова с popularity ≥ 40 и наименьшей difficulty. Слово не повторяется внутри полей — Apple склеивает слова из названия и сабтайтла сам.
2. **Сабтайтл (30).** Следующие по силе слова, не пересекающиеся с названием.
3. **Keyword field (100).** Всё с popularity ≥ 8, чьи слова ещё не заняты; целыми фразами, через запятую, без пробелов после запятых.
4. **Слово «free» не используем нигде** — жёсткий пейвол плюс «free» в листинге даёт отказ по 3.1.2/5.6.
5. Описание пишем под конверсию: первые три строки видны без раскрытия, дальше — список инструментов.

