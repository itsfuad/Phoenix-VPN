FROM elixir:1.14-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base

# Copy project files
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib

# Build release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=prod mix release

# Create final image
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    iptables \
    ppp

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/vpn_server /vpn_server

# Copy startup script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Expose PPTP port
EXPOSE 1723

# Set environment
ENV REPLACE_OS_VARS=true

# Start VPN server
ENTRYPOINT ["/docker-entrypoint.sh"] 