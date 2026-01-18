# 1. 基础镜像：改为官方 DockerHub 的 devel 版本
# 虽然体积大，但在 GitHub Actions 里下载只需几十秒
FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel

# 2. 环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 3. 安装系统级依赖
# devel 镜像基础工具比较全，但为了稳妥还是把常用工具装上
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    openssh-server vim git wget curl unzip htop build-essential \
    && rm -rf /var/lib/apt/lists/*

# 4. SSH 配置 (密码 123456)
RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# 5. 安装 Python 科研全家桶
# devel 版本也需要自己装这些包
RUN pip install --no-cache-dir \
    pandas \
    numpy \
    matplotlib \
    scikit-learn \
    jupyterlab \
    transformers \
    requests \
    tqdm

# 6. 配置 Clash Meta (Mihomo) + Web面板 (yacd)
WORKDIR /opt/clash
# 下载内核
RUN wget https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz && \
    gzip -d mihomo-linux-amd64-v1.18.1.gz && \
    mv mihomo-linux-amd64-v1.18.1 clash && \
    chmod +x clash
# 下载 IP 数据库
RUN wget https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb
# 下载 Web 控制面板
RUN wget https://github.com/haishanh/yacd/archive/gh-pages.zip && \
    unzip gh-pages.zip && \
    mv yacd-gh-pages dashboard && \
    rm gh-pages.zip
# 创建空配置
RUN touch config.yaml

# 7. 端口暴露
EXPOSE 22 7890 9090

# 8. 启动 SSH
CMD ["/usr/sbin/sshd", "-D"]
