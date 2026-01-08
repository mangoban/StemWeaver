FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    libglib2.0-0 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Copy StemWeaver AppImage
COPY StemWeaver-v1.1-x86_64.AppImage /usr/bin/stemweaver

# Make executable
RUN chmod +x /usr/bin/stemweaver

# Create non-root user
RUN useradd -m -u 1000 stemweaver
USER stemweaver
WORKDIR /home/stemweaver

# Entry point
ENTRYPOINT ["/usr/bin/stemweaver"]
