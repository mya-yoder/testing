# syntax=docker/dockerfile:1

FROM golang:1.19 AS build-stage

# Set destination for COPY
WORKDIR /app

# Download Go modules
RUN go env -w GOPROXY=direct && go env -w GOSUMDB=off
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code. Note the slash at the end, as explained in
# https://docs.docker.com/engine/reference/builder/#copy
COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping

FROM build-stage as run-test-stage
RUN go test -v ./...

FROM gcr.io/distroless/base-debian11 AS build-release-stage
WORKDIR /
COPY --from=build-stage /docker-gs-ping /docker-gs-ping

# To bind to a TCP port, runtime parameters must be supplied to the docker command.
# But we can (optionally) document in the Dockerfile what ports
# the application is going to listen on by default.
# https://docs.docker.com/engine/reference/builder/#expose
EXPOSE 8080
USER nonroot:nonroot

# Run
CMD [ "/docker-gs-ping" ]
