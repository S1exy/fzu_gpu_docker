# 1. 基础镜像：适配 RTX 3090 (CUDA 11.3)
FROM harbor.fzu.edu.cn/docker-hub/siaimes/pytorch:1.12.1-cuda11.3-cudnn8-devel

# 2. 设置环境
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 3. 安装基础工具
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    openssh-server vim git wget curl unzip htop \
    && rm -rf /var/lib/apt/lists/*

# 4. SSH 配置 (密码 123456)
RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# 5. Python 环境
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN pip install --no-cache-dir pandas numpy matplotlib scikit-learn jupyterlab transformers requests

# ==========================================
# 6. 配置 Clash Meta (Mihomo) + Web面板
# ==========================================
WORKDIR /opt/clash

# 下载内核
RUN wget https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz && \
    gzip -d mihomo-linux-amd64-v1.18.1.gz && \
    mv mihomo-linux-amd64-v1.18.1 clash && \
    chmod +x clash

# 下载 IP 数据库
RUN wget https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb

# 下载 Web 控制面板 (Yacd) - 让你能远程选节点
RUN wget https://github.com/haishanh/yacd/archive/gh-pages.zip && \
    unzip gh-pages.zip && \
    mv yacd-gh-pages dashboard && \
    rm gh-pages.zip

# 创建空配置
RUN touch config.yaml

# 7. 暴露端口
# 22(SSH), 7890(HTTP代理), 9090(控制面板API)
EXPOSE 22 7890 9090

# 8. 启动脚本
CMD ["/usr/sbin/sshd", "-D"]
