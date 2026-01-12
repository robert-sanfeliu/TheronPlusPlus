# Docker Setup for AMQDistribution

This directory contains Docker configuration files to build and run the AMQDistribution example.

## Prerequisites

- Docker

## Building the Docker Image

```bash
docker build -t theron-amq .
```

## Running with Docker


```bash
docker run --network=host theron ./Examples/AMQDistribution -I HelloResponder --endpoint Responder --broker localhost --port 61616 --user ^Cmin --password admin --topics TestTopic
```
