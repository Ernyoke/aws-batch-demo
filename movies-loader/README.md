# movies-loader

## Development

### Create a venv

```bash
python3 -m venv venv
```

### Activate venv

```bash
.\venv\Scripts\Activate.sh
```

## Build and Deploy

### Generate requirements.txt

```bash
pip3 install pipreqs
pip3 install pip-tools

pipreqs --savepath=requirements.in && pip-compile
```

### Build the Docker Image

```bash
docker build -t movies-loader .
```
