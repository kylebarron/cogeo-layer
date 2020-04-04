# cogeo-layer

[![CircleCI](https://circleci.com/gh/RemotePixel/cogeo-layer.svg?style=svg)](https://circleci.com/gh/RemotePixel/cogeo-layer)

#### Python package

```
lambda-proxy~=5.1
numpy
pygeos
pyproj==2.4.1 (only with GDAL 3.0)
rasterio>=1.1.3
requests
rio-cogeo
rio-color
rio-tiler
rio_tiler_mosaic
rio_tiler_mvt
shapely
supermercado
```

#### Arns

Current ARNs are listed in [`arns.json`](arns.json).

#### Version

##### GDAL 3.0
- Layer Version: **9**
- Package size: 46.9Mb (137.1Mb)
- Python Version: 3.7.2
- GDAL Version: 3.0.3
- PROJ Version: 6.2.1

##### GDAL 2.4
- Layer Version: **6**
- Package size: 37.2Mb (123.1Mb)
- Python Version: 3.7.2
- GDAL Version: 2.4.4
- PROJ Version: 5.2.0

## How To

### Create package

#### Simple app (no dependency)

```bash
zip -r9q /tmp/package.zip app.py
```

#### Complex (dependencies)

- Create a docker file
```dockerfile
FROM remotepixel/amazonlinux:gdal3.0-py3.7-cogeo

ENV PYTHONUSERBASE=/var/task

# Install dependencies
COPY handler.py $PYTHONUSERBASE/handler.py
RUN pip install mercantile --user

RUN mv ${PYTHONUSERBASE}/lib/python3.7/site-packages/* ${PYTHONUSERBASE}/
RUN rm -rf ${PYTHONUSERBASE}/lib

echo "Create archive"
RUN cd $PYTHONUSERBASE && zip -r9q /tmp/package.zip *
```

- create package

```bash
docker build --tag package:latest .
docker run --name lambda -w /var/task -itd package:latest bash scripts/create-lambda-layer.sh
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
```

#### Update layer

```bash
docker build --tag package:latest --build-arg GDAL_VERSION=2.4 .
docker run --name lambda -w /var/task -itd package:latest bash
docker cp scripts/create-lambda-layer.sh lambda:/create-lambda-layer.sh
docker exec -it lambda bash /create-lambda-layer.sh
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
```

Publish layer

```bash
# cp package.zip gdal3.0-py3.7-cogeo.zip
cp package.zip gdal2.4-py3.7-cogeo.zip

# layer name, gdal version, python version
# bash scripts/deploy-layer.sh "cogeo" "3.0" "3.7"
bash scripts/deploy-layer.sh "cogeo" "2.4" "3.7"
```

List ARNs

```bash
python scripts/list_layers.py > arns.json
```
