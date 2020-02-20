FROM alpine/helm:3.0.3

LABEL authors="Krzysztof Semenowicz <krzysztof.semenowicz@ticketmaster.co.uk"

COPY . /generic-chart

WORKDIR /apps
