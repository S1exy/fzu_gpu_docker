# 1. 基础镜像
FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel

# 2. 环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 3. 安装系统级依赖
RUN apt-get update && apt-get install -y \
    openssh-server vim git wget curl unzip htop build-essential \
    && rm -rf /var/lib/apt/lists/*

# 4. SSH 配置
RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# ==========================================
# 5. 【重点修改】分步安装 Python 包，防止内存溢出
# ==========================================

# 第一步：先单独升级 pip，打好基础
RUN pip install --no-cache-dir --upgrade pip

# 第二步：安装数据处理三剑客 (比较稳)
RUN pip install --no-cache-dir numpy pandas matplotlib

# 第三步：安装机器学习库 (Scikit-learn)
RUN pip install --no-cache-dir scikit-learn

# 第四步：安装工具库
RUN pip install --no-cache-dir requests tqdm jupyterlab

# 第五步：单独安装最大的 Transformers (最容易崩，单独放最后)
RUN pip install --no-cache-dir transformers

# ==========================================

# 6. 配置 Clash Meta + Web面板
WORKDIR /opt/clash
RUN wget https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz && \
    gzip -d mihomo-linux-amd64-v1.18.1.gz && \
    mv mihomo-linux-amd64-v1.18.1 clash && \
    chmod +x clash
RUN wget https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb
RUN wget https://github.com/haishanh/yacd/archive/gh-pages.zip && \
    unzip gh-pages.zip && \
    mv yacd-gh-pages dashboard && \
    rm gh-pages.zip
RUN touch config.yaml

# 7. 端口暴露
EXPOSE 22 7890 9090

# 8. 启动 SSH
CMD ["/usr/sbin/sshd", "-D"]
