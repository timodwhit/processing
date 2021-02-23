FROM ubuntu:20.04
SHELL ["/bin/bash", "-c"] 

ENV TZ=America/Denver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get -y install cmake \
	g++ \
	git \ 
	wget \
	libtbb-dev \
	gcc-10 \
	build-essential \
	libsparsehash-dev \
	libopenblas-dev

ENV HOME /root
ENV PROCESSING $HOME/processing

# Install Potree Converter
RUN mkdir $PROCESSING
WORKDIR $PROCESSING
RUN git clone --depth 1 --branch 2.1 https://github.com/potree/PotreeConverter.git PotreeConverter
RUN mkdir PotreeConverter/build
WORKDIR $PROCESSING/PotreeConverter/build
RUN cmake ../ && make

# Install miniconda3
WORKDIR $HOME
ENV MINICONDA3 $HOME/miniconda3
RUN mkdir -p $MINICONDA3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $MINICONDA3/miniconda.sh
RUN chmod +x $MINICONDA3/miniconda.sh
RUN $MINICONDA3/miniconda.sh -b -u -p $MINICONDA3
RUN rm -rf $MINICONDA3/miniconda.sh

ENV PATH="$MINICONDA3/bin:$PATH"

RUN conda init bash
RUN conda install -c conda-forge pdal python-pdal gdal proj-data

# Install LAS Tools.
WORKDIR $HOME
RUN git clone https://github.com/LAStools/LAStools.git $HOME/LAStools
WORKDIR $HOME/LAStools

# This is a random point in time. Useful to lock down the version,
# since there are no tags.
RUN git checkout 150e6c23bb2ced93083b5ba656c5f8e55403b81b
RUN make .

# Install Python extras
WORKDIR $HOME
RUN pip install -U -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-20.04 wxPython

## Install Requirements.
ADD requirements.txt requirements.txt
RUN pip install -r requirements.txt

RUN pip install torch==1.7.0+cpu torchvision==0.8.1+cpu -f https://download.pytorch.org/whl/torch_stable.html
RUN pip install MinkowskiEngine==v0.4.3 -v
RUN pip install torch-geometric
RUN pip install wandb hydra-core==0.11.3 laspy torchnet tqdm tensorboard plyfile
RUN pip install pytorch-metric-learning==0.9.96.dev1 --no-deps -U
RUN pip install --no-index torch-scatter -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html --no-cache-dir
RUN pip install --no-index torch-cluster -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html --no-cache-dir
RUN pip install --no-index torch-spline-conv -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html --no-cache-dir
RUN pip install --no-index torch-sparse -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html --no-cache-dir
RUN pip install torch-points-kernels --no-cache-dir