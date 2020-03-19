#OpenVino Inferencing engine and tracking plugins to be included, also included Intel hardware accelaration software 
# stack such as media driver, media SDK, OpenVINO, gmmlib and libva. 
# Also conctains OpenCV 4.2.0-openvino compiled with Gstreamer and python3.

FROM openvisualcloud/vcaca-ubuntu1804-analytics-gst:latest

ARG TEMP_DIR=/tmp/openvino_installer
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    axel \
    cpio \
    sudo \
    bash \
    lsb-release && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p $TEMP_DIR && cd $TEMP_DIR

ARG INSTALL_DIR=/opt/intel/openvino/
# RUN cd $INSTALL_DIR/install_dependencies/ && ls && ./_install_all_dependencies.sh
RUN rm -rf /opt/intel/openvino/opencv/ && rm -rf /usr/local/lib/libopencv* && apt-get update && apt-get install -y python3-dev python3-setuptools python3-pip libeigen3-dev
RUN /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh" && pip3 install --upgrade pip

#gstreamer1.0-tools libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools libgstreamer-plugins-base1.0-dev 

ARG VERSION=4.1.2-openvino
RUN mkdir -p /app/scripts && cd /app/scripts && wget -c https://github.com/opencv/opencv/archive/${VERSION}.tar.gz -O opencv-${VERSION}.tar.gz && tar -xf opencv-${VERSION}.tar.gz

RUN cd /app/scripts && axel -n 10 https://github.com/Kitware/CMake/releases/download/v3.17.0-rc3/cmake-3.17.0-rc3-Linux-x86_64.tar.gz -o cmake.tar.gz
RUN cd /app/scripts && ls -l && tar -xvf cmake.tar.gz && cd cmake-3.17.0-rc3-Linux-x86_64 && cp -r bin /usr/ && cp -r share /usr/ && cp -r doc /usr/share/ && cp -r man /usr/share/
RUN apt-get -y install ffmpeg libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev liborc-0.4-dev && ln -s /usr/include/gstreamer-1.0 /usr/local/include/gstreamer-1.0 && ln -s /usr/include/orc-0.4 /usr/local/include/ && \
    cd /app/scripts/ && ls -l && cd opencv-${VERSION} && mkdir -p build && cd build

RUN apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libgtk2.0-dev libatlas-base-dev gfortran ffmpeg x264 libx264-dev && pip3 install numpy
RUN cd /app/scripts/opencv*/build/ && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D BUILD_SHARED_LIBS=ON\
	-D INSTALL_PYTHON_EXAMPLES=OFF -D INSTALL_C_EXAMPLES=OFF \
	-D PYTHON_DEFAULT_EXECUTABLE=$(which python3) -D PYTHON_EXECUTABLE=$(which python3) \
	-D WITH_CUDA=OFF \
	-D OPENCV_ENABLE_NONFREE=OFF \
	-D WITH_CUBLAS=OFF -D WITH_NVCUVID=OFF -D BUILD_EXAMPLES=OFF -D WITH_GSTREAMER=ON -D WITH_FFMPEG=ON -D BUILD_NEW_PYTHON_SUPPORT=ON -D BUILD_opencv_python3=ON -D HAVE_opencv_python3=ON -D OPENCV_PYTHON_VERSION=ON -D OPENCV_PYTHON3_INSTALL_PATH=/usr/lib/python3.6/dist-packages .. && make -j8 install
RUN rm -rf /app/scripts

#Install OpenVino dependencies
# OpenVINO verion
# 2020.1 and deployment manager script
ARG OPENVINO_BUNDLE=l_openvino_toolkit_p_2020.1.023
ARG OPENVINO_URL=http://registrationcenter-download.intel.com/akdlm/irc_nas/16345/l_openvino_toolkit_p_2020.1.023.tgz

#Download and unpack OpenVino
RUN mkdir /tmp2 && rm -rf /opt/intel/openvino/
RUN wget ${OPENVINO_URL} -P /tmp2
RUN if [ -f /tmp2/${OPENVINO_BUNDLE}.tgz ]; \
    then tar xzvf /tmp2/${OPENVINO_BUNDLE}.tgz -C /tmp2 && rm /tmp2/${OPENVINO_BUNDLE}.tgz; \
    else echo "Please prepare the OpenVino installation bundle"; \
fi

# Create a silent configuration file for install
RUN echo "ACCEPT_EULA=accept" > /tmp2/silent.cfg                        && \
    echo "CONTINUE_WITH_OPTIONAL_ERROR=yes" >> /tmp2/silent.cfg         && \
    echo "PSET_INSTALL_DIR=/opt/intel" >> /tmp2/silent.cfg              && \
    echo "CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes" >> /tmp2/silent.cfg   && \
    echo "COMPONENTS=DEFAULTS" >> /tmp2/silent.cfg                      && \
    echo "COMPONENTS=ALL" >> /tmp2/silent.cfg                           && \
    echo "PSET_MODE=install" >> /tmp2/silent.cfg                        && \
    echo "INTEL_SW_IMPROVEMENT_PROGRAM_CONSENT=no" >> /tmp2/silent.cfg  && \
    echo "SIGNING_ENABLED=no" >> /tmp2/silent.cfg

#Install OpenVino
RUN /tmp2/${OPENVINO_BUNDLE}/install.sh --ignore-signature --cli-mode -s /tmp2/silent.cfg && rm -rf /tmp2 && rm -rf /opt/intel/openvino/opencv && rm -rf /opt/intel/openvino/python/python2.7/cv2.so && rm -rf /opt/intel/openvino/python/python3/cv2.abi3.so

ENV IE_PLUGINS_PATH=/opt/intel/openvino/deployment_tools/inference_engine/lib/intel64
ENV HDDL_INSTALL_DIR=/opt/intel/openvino/deployment_tools/inference_engine/external/hddl
ENV InferenceEngine_DIR=/opt/intel/openvino/deployment_tools/inference_engine/share
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/intel/openvino/deployment_tools/ngraph/lib:/opt/intel/opencl:$HDDL_INSTALL_DIR/lib:/opt/intel/openvino/deployment_tools/inference_engine/external/gna/lib:/opt/intel/openvino/deployment_tools/inference_engine/external/mkltiny_lnx/lib:/opt/intel/openvino/deployment_tools/inference_engine/external/omp/lib:/opt/intel/openvino/deployment_tools/inference_engine/external/tbb/lib:/opt/intel/openvino/openvx/lib:$IE_PLUGINS_PATH
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
WORKDIR /
