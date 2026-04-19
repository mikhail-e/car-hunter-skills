# Шаблон сообщения дилеру

Язык: немецкий, в конце — просьба перейти на английский.

## Структура

### 1. Вводная часть + безаварийность

```
Sehr geehrtes Verkaufsteam von {{DEALER_NAME}},

ich interessiere mich für den {{CAR_MODEL}} (Fahrzeugnummer {{VEHICLE_NUMBER}}, Inserat-Nr. {{LISTING_ID}}).

Könnten Sie bitte bestätigen, dass das Fahrzeug unfallfrei ist?
```

### 2. Уточняющие вопросы по конкретному автомобилю

```
Außerdem hätte ich noch folgende Fragen:

{{QUESTIONS}}
```

Вопросы формируются на основе ❓ в dealbreakers и nice-to-have карточки оценки. Например:
- SoH батареи → "Können Sie Informationen zum Batteriezustand (State of Health) mitteilen?"
- Батарейный сертификат → "Liegt ein Batteriezertifikat (z.B. AVILOO) vor?"
- Другие ❓ → соответствующий вопрос на немецком

Если уточняющих вопросов нет (все dealbreakers ✅), этот блок пропускается.

### 3. Резервирование и осмотр

```
Wäre es möglich, das Fahrzeug für einige Tage zu reservieren? Wann könnte ich für eine Besichtigung und Probefahrt vorbeikommen?
```

### 4. Просьба о переходе на английский

```
Wäre es außerdem möglich, die weitere Kommunikation auf Englisch fortzuführen?

Vielen Dank im Voraus!

Mit freundlichen Grüßen,
{{SENDER_NAME}}
```
