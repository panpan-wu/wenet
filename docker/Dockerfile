# FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-runtime
FROM pytorch/pytorch:1.10.0-cuda11.3-cudnn8-runtime as asr_base

RUN sed -i s@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list \
    && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ \
    && conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ \
    && conda config --set show_channel_urls yes \
    && apt-get update && apt-get install -y --no-install-recommends \
        git \
        wget \
        build-essential \
        software-properties-common \
        lsb-release \
        gawk \
    && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null \
    && apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    && apt-get update \
    && apt-get install -y --no-install-recommends cmake \
    && rm -rf /var/lib/apt/lists/*

RUN conda install -y torchaudio -c pytorch -c conda-forge \
    && conda clean -ya


FROM asr_base as builder

# git checkout 到指定的 commit，防止 wenet 有不兼容的更新时出错。
RUN git clone https://github.com/mobvoi/wenet.git /opt/wenet --branch main --single-branch \
    && cd /opt/wenet \
    && git checkout df342adaabb2ab992904f1c0d9d8217dae5f6194 \
    && pip install -r requirements.txt
ARG wenet_dir=/opt/wenet/runtime/server/x86/fc_base
# 提前下载好依赖的包的代码，防止编译时下载失败导致编译错误。
COPY src_code/boost_1_75_0.tar.gz ${wenet_dir}/boost-subbuild/boost-populate-prefix/src/boost_1_75_0.tar.gz
COPY src_code/glog-0.4.0.zip ${wenet_dir}/glog-subbuild/glog-populate-prefix/src/v0.4.0.zip
COPY src_code/googletest-release-1.10.0.zip ${wenet_dir}/googletest-subbuild/googletest-populate-prefix/src/release-1.10.0.zip
COPY src_code/libtorch-cxx11-abi-shared-with-deps-1.10.0+cpu.zip ${wenet_dir}/libtorch-subbuild/libtorch-populate-prefix/src/libtorch-cxx11-abi-shared-with-deps-1.10.0%2Bcpu.zip
COPY src_code/openfst-1.6.5.zip /opt/wenet/runtime/server/x86/build/openfst-prefix/src/1.6.5.zip
COPY src_code/gflags/v2.2.1.zip ${wenet_dir}/gflags-subbuild/gflags-populate-prefix/src/v2.2.1.zip
RUN cd /opt/wenet/runtime/server/x86 \
   && mkdir -p build && cd build && cmake .. && cmake --build .
# srilm
COPY srilm /opt/tools
RUN cd /opt/tools && ./install_liblbfgs.sh && ./install_srilm.sh


FROM asr_base

COPY --from=builder /opt/wenet/requirements.txt /opt/wenet/requirements.txt
COPY --from=builder /opt/tools/liblbfgs-1.10 /opt/tools/liblbfgs-1.10
COPY --from=builder /opt/tools/srilm /opt/tools/srilm
COPY --from=builder /opt/wenet/wenet /opt/wenet/wenet
COPY --from=builder /opt/wenet/tools /opt/wenet/tools
COPY --from=builder /opt/wenet/runtime/server/x86/fc_base/openfst-subbuild /opt/wenet/runtime/server/x86/fc_base/openfst-subbuild
COPY --from=builder /opt/wenet/runtime/server/x86/fc_base/openfst-build /opt/wenet/runtime/server/x86/fc_base/openfst-build
COPY --from=builder /opt/wenet/runtime/server/x86/fc_base/libtorch-src/lib /opt/wenet/runtime/server/x86/fc_base/libtorch-src/lib
COPY --from=builder /opt/wenet/runtime/server/x86/fc_base/gflags-build /opt/wenet/runtime/server/x86/fc_base/gflags-build
COPY --from=builder /opt/wenet/runtime/server/x86/fc_base/glog-build /opt/wenet/runtime/server/x86/fc_base/glog-build
COPY --from=builder /opt/wenet/runtime/server/x86/build/kaldi /opt/wenet/runtime/server/x86/build/kaldi
COPY --from=builder /opt/wenet/runtime/server/x86/build/lib /opt/wenet/runtime/server/x86/build/lib
COPY --from=builder /opt/wenet/runtime/server/x86/build/*.a /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/ctc_prefix_beam_search_test /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/decoder_main /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/label_checker_main /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/post_processor_test /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/websocket_client_main /opt/wenet/runtime/server/x86/build/
COPY --from=builder /opt/wenet/runtime/server/x86/build/websocket_server_main /opt/wenet/runtime/server/x86/build/
RUN cd /opt/wenet && pip install -r requirements.txt
COPY entrypoint.sh /opt/

ENTRYPOINT ["/opt/entrypoint.sh"]
WORKDIR /workspace
