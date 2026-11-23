# syntax=docker/dockerfile:1
# agent-kit: Rust — release build, distroless runtime (non-root). Set BIN to your binary name.
FROM rust:1 AS build
ARG BIN=app
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/src/target \
    cargo build --release && cp target/release/${BIN} /out-app

FROM gcr.io/distroless/cc-debian12:nonroot AS runtime
COPY --from=build /out-app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
