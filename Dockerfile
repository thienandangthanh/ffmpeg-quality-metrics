FROM python:3.11-slim
LABEL maintainer="Werner Robitza <werner.robitza@gmail.com>"
LABEL name="ffmpeg_quality_metrics"

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive \
    FFMPEG_VERSION=7.1.1

# Install dependencies for building FFmpeg
RUN sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && apt-get install -y \
    build-essential \
    nasm \
    yasm \
    cmake \
    pkg-config \
    libtool \
    autoconf \
    automake \
    git \
    curl \
    ca-certificates \
    zlib1g-dev \
    libx264-dev \
    libx265-dev \
    libvpx-dev \
    libfdk-aac-dev \
    libmp3lame-dev \
    libopus-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory for building FFmpeg
WORKDIR /usr/local/src

# Clone and build FFmpeg
RUN git clone --depth 1 --branch n$FFMPEG_VERSION https://git.ffmpeg.org/ffmpeg.git && \
    cd ffmpeg && \
    ./configure --prefix=/usr/local \
                --disable-debug \
                --disable-doc \
                --disable-static \
                --enable-nonfree \
                --enable-shared \
                --enable-gpl \
                --enable-libx264 \
                --enable-libx265 \
                --enable-libvpx \
                --enable-libfdk-aac \
                --enable-libmp3lame \
                --enable-libopus \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf ffmpeg

# Verify FFmpeg installation
RUN ffmpeg -version

# Set the working directory for the application
WORKDIR /app

# Copy the requirements file and install Python dependencies
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY ffmpeg_quality_metrics ffmpeg_quality_metrics

CMD ["python3", "-m", "ffmpeg_quality_metrics"]
