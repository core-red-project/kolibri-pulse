# Dockerfile para compilar KolibriPulse con FASM en cualquier arquitectura (incluyendo Apple Silicon M1/M2/M3)
FROM --platform=linux/amd64 debian:bookworm-slim

RUN apt-get update -qq && \
    apt-get install -y -qq fasm && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

ENTRYPOINT ["fasm"]
CMD ["src/pulse.asm", "bin/pulse.kex"]
