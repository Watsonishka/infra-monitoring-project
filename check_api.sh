#!/bin/bash
URL="$1"

if [ -z "$URL" ]; then
    echo "Ошибка! Не указан URL или указана пустая строка!"
    echo "Использование: $0 <url>"
    exit 1
fi


if [[ ! "$URL" =~ ^https?:// ]]; then
    echo "Ошибка! '$URL' не является URL, он должен начинаться с http:// или https://"
    exit 1
fi

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
if [ "$STATUS" == 200 ]; then
    echo "API доступен"
    exit 0
else
    echo "API недоступен, код ответа: $STATUS"
    exit 1
fi
