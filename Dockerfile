FROM alpine:latest

ARG PB_VERSION=0.23.3

RUN apk add --no-cache \
    unzip \
    ca-certificates

# Download and unzip PocketBase Linux version
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

# Copy migrations and hooks so they are applied on production
COPY ./pb_migrations /pb/pb_migrations
COPY ./pb_hooks /pb/pb_hooks

EXPOSE 8080

# Railway injects $PORT dynamically — use shell form so the variable is expanded at runtime
CMD /pb/pocketbase serve --http=0.0.0.0:${PORT:-8080}
