# Guía – Taller 01: Despliegue de Servicios de Red

## Estructura de la carpeta

```
Taller 01 - Despliegue de Servicios/
├── v1-script/          → imagen stock-market:1.0 (script por consola)
│   ├── read_value_yf.py
│   ├── requirements.txt
│   └── Dockerfile
├── v2-flask/           → imagen stock-market:2.0 (servicio web con Flask)
│   ├── app.py
│   ├── read_value_yf.py
│   ├── requirements.txt
│   └── Dockerfile
├── setup_vm.sh         → script para ejecutar dentro de la VM de AWS
└── GUIA.md
```

---

## ✅ Parte 1 – Ya hecha (local, con Docker)

Las dos imágenes ya están construidas y probadas en tu PC:

| Imagen | Qué hace | Probada |
|---|---|---|
| `stock-market:1.0` | Imprime las últimas 5 filas del stock (GOOGL por defecto) | ✔ GOOGL y AMZN |
| `stock-market:2.0` | Sirve la tabla en HTML en `http://localhost:5000` | ✔ |

Para repetirlo tú (y sacar capturas para el informe), abre una terminal en esta carpeta:

```bash
docker image build -t stock-market:1.0 v1-script
```
```bash
docker container run --rm stock-market:1.0
```
```bash
docker container run --rm -e STOCK=AMZN stock-market:1.0
```
```bash
docker image build -t stock-market:2.0 v2-flask
```
```bash
docker container run --rm --name stock-market -p 5000:5000 stock-market:2.0
```
Luego abre http://localhost:5000 en el navegador (Ctrl+C para detenerlo).

> 📸 Toma capturas de: salida GOOGL, salida AMZN y la tabla en localhost:5000.

---

## ✅ Parte 2 – Publicar en Docker Hub (hecha)

1. Crea una cuenta en https://hub.docker.com si no la tienes.
2. Ya publicada como **cadrojasl/stock-market:2.0** (pública): https://hub.docker.com/r/cadrojasl/stock-market. Comandos usados:

```bash
docker image tag stock-market:2.0 cadrojasl/stock-market:2.0
```
```bash
docker login
```
```bash
docker image push cadrojasl/stock-market:2.0
```

> 📸 Captura de la salida del `push` y de la imagen en tu perfil de Docker Hub.

---

## 🔲 Parte 3 – Crear la VM en AWS (EC2)

1. Entra a la consola de AWS → busca **EC2** → **Launch instance**.
2. **Name:** `demo_docker`
3. **AMI:** Ubuntu Server (LTS, *Free tier eligible*), arquitectura **64-bit (x86)**
   (tu imagen es `amd64`, no elijas ARM).
4. **Instance type:** `t2.micro` (o `t3.micro` si t2 no aparece) – *Free tier*.
5. **Key pair:** *Create new key pair* → nombre `demo_docker`, RSA, `.pem` → se descarga `demo_docker.pem`. Guárdalo en esta carpeta.
6. **Network settings:** marca ✅ *Allow SSH traffic* y ✅ **Allow HTTP traffic from the internet**.
7. **Launch instance** → ve a **Instances** y espera a que esté *Running* y *2/2 checks passed*.

> 📸 Captura de la instancia corriendo.

---

## 🔲 Parte 4 – Conectarse por SSH y montar el contenedor

1. Instancia → **Connect** → pestaña **SSH client** → copia el comando de ejemplo.
2. En Windows, protege la llave (PowerShell, en la carpeta donde está el `.pem`):

```powershell
icacls demo_docker.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```
3. Conéctate (cambia el DNS por el de tu instancia):

```bash
ssh -i demo_docker.pem ubuntu@ec2-X-X-X-X.compute-1.amazonaws.com
```
   *Alternativa más fácil:* pestaña **EC2 Instance Connect** → *Connect* (abre una terminal en el navegador).

4. Copia `setup_vm.sh` a la VM (desde tu PC, otra terminal):

```bash
scp -i demo_docker.pem setup_vm.sh ubuntu@ec2-X-X-X-X.compute-1.amazonaws.com:~
```
   O simplemente ábrelo, copia el contenido y pégalo en `nano setup_vm.sh` dentro de la VM.

5. Dentro de la VM:

```bash
bash setup_vm.sh cadrojasl
```
   Esto: instala Docker, agrega al usuario `ubuntu` al grupo `docker`, descarga tu imagen y la ejecuta.

> ⚠️ **Ojo con el puerto:** AWS solo abre el puerto **80** (HTTP), pero Flask escucha en el **5000**. Por eso en la VM se usa `-p 80:5000` (no `-p 5000:5000` como en local). Si usas `5000:5000` tendrías que abrir el puerto 5000 en el Security Group.

Si prefieres hacerlo a mano (como en el video del taller), los comandos clave son:
```bash
sudo docker run -d --name stock-market -p 80:5000 cadrojasl/stock-market:2.0
```

---

## 🔲 Parte 5 – Validar

1. Copia el **Public IPv4 DNS** de la instancia.
2. Ábrelo en el navegador como `http://ec2-....amazonaws.com` (con **http**, no https).
3. Deberías ver la tabla de GOOGL igual que en localhost. La primera carga puede tardar unos segundos.

> 📸 Captura del navegador mostrando la URL de AWS y la tabla.

---

## 🔲 Parte 6 – ⚠️ MUY IMPORTANTE: terminar la instancia

**Instances** → selecciona `demo_docker` → **Instance state** → **Terminate instance** → **Terminate**.

> 📸 Captura del mensaje *Successfully terminated*.

---

## Parte conceptual (sección "Contexto" del taller)

El taller pide **describir** qué es un proceso y cómo se vuelve un servicio de red, y **diseñar una gráfica**. Idea para tu respuesta:

- **Proceso:** programa en ejecución, con su memoria y recursos asignados por el sistema operativo (ej. `python3 read_value_yf.py` → corre, imprime y termina).
- **Servicio de red:** un proceso que abre un **socket** ligado a una IP y puerto (ej. Flask en `0.0.0.0:5000`) y se queda escuchando peticiones (HTTP) de clientes a través de la red, respondiendo a cada una.
- Gráfica sugerida: `Cliente (navegador) → Internet → [VM AWS: puerto 80] → [Docker: puerto 5000] → Proceso Flask → yfinance → Yahoo Finance`, y la respuesta de vuelta.

## Problemas comunes

| Problema | Solución |
|---|---|
| `permission denied ... docker.sock` en la VM | Usa `sudo docker ...` o cierra y vuelve a abrir la sesión SSH |
| El navegador no carga | Usa `http://` (no https); revisa que el Security Group permita HTTP (80) |
| `UNPROTECTED PRIVATE KEY FILE` | Ejecuta el `icacls` del paso 4.2 |
| `exec format error` en la VM | Elegiste una instancia ARM; usa x86 (t2/t3.micro) |
| `denied: requested access to the resource` al hacer push | El tag debe empezar con tu usuario exacto de Docker Hub |
