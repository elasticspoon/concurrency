# Concurrency

A Ruby server implementation demonstrating concurrency patterns.

## Running via Mise

This project uses mise for task management. Here are the available tasks:

### Build the Docker image

```bash
mise run build
```

### Run the built Docker image (with 1GB memory limit)

```bash
mise run run
```

### Build and run the server (one command, with 1GB memory limit)

```bash
mise run server
```

### Run benchmarks against the server

```bash
mise run benchmark
```

Note: Make sure the server is running before executing the benchmark.

## Environment Variables

- `SLOW=1`: Add a 1-second delay to each request (useful for testing)

## Example Usage

1. Start the server:

```bash
mise run server
```

2. In another terminal, test the server:

```bash
curl http://localhost:3000/
```

3. Run benchmarks:

```bash
mise run benchmark
```
