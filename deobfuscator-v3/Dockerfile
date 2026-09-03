FROM python:3.12-slim

WORKDIR /app

# Runtime deps: lune (Luau), node (Prometheus deobfuscator), lua (Prometheus obfuscator)
ARG LUNE_VERSION=0.8.9
ARG NODE_MAJOR=20
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates gnupg unzip lua5.1 \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && curl -fsSL "https://github.com/lune-org/lune/releases/download/v${LUNE_VERSION}/lune-${LUNE_VERSION}-linux-x86_64.zip" -o /tmp/lune.zip \
 && unzip /tmp/lune.zip -d /usr/local/bin \
 && chmod +x /usr/local/bin/lune \
 && rm /tmp/lune.zip \
 && apt-get purge -y gnupg && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# Install lute (hookOp executor)
# Copy the native Linux Lute binary supplied at the repository root.
COPY lute ./lute
RUN chmod +x /app/lute

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Node deps for the Prometheus deobfuscator
COPY v1sexy/package.json v1sexy/package-lock.json ./v1sexy/
RUN cd v1sexy && npm install --omit=dev

# Copy the rest of the project
COPY . .

# Default env vars (override via docker run -e or docker-compose)
ENV HOOKOP_BIN=lute

CMD ["python3", "bot.py", "bot"]
