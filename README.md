# Diferencias entre Docker Build y Docker Buildx o BuildKit

Desde la versión 18.09 de Docker, se introdujo una nueva funcionalidad llamada BuildKit, que es un nuevo motor de construcción de imágenes de Docker. Este motor de construcción es más rápido y eficiente que el motor de construcción de imágenes de Docker tradicional. BuildKit es un proyecto de código abierto que se puede encontrar en GitHub.

De hecho, cuando ejecutas el comando `docker build` en Docker 18.09 o posterior, en realidad estás utilizando BuildKit. 

Sin embargo, BuildKit tiene una serie de características adicionales que no están disponibles en el motor de construcción de imágenes de Docker tradicional. Para acceder a estas características adicionales, debes utilizar el comando `docker buildx` en lugar del comando `docker build`.

En este artículo, veremos las diferencias entre `docker build` y `docker buildx` o BuildKit, y cómo puedes utilizar BuildKit para mejorar tus flujos de trabajo de construcción de imágenes de Docker.

## Diferencias entre Docker Build y Docker Buildx o BuildKit

A continuación se presentan algunas de las diferencias clave entre `docker build` y `docker buildx` o BuildKit:

### **Soporte para múltiples plataformas**: BuildKit tiene soporte integrado para la construcción de imágenes de Docker para múltiples plataformas. Esto significa que puedes construir una sola imagen de Docker que funcione en diferentes arquitecturas de CPU, como x86, ARM y PPC. Con BuildKit, puedes construir imágenes de Docker para diferentes plataformas utilizando un solo comando, lo que simplifica el proceso de construcción de imágenes multiplataforma.

¿Y para qué sirve esto? Pues por ejemplo, si tienes una aplicación que quieres ejecutar en diferentes arquitecturas de CPU, como x86 y ARM, puedes construir una sola imagen de Docker que funcione en ambas arquitecturas. Esto te permite distribuir una sola imagen de Docker en lugar de tener que construir y mantener imágenes separadas para cada arquitectura.

Para que lo veas con un ejemplo, aquí tienes un comando de `docker buildx` que construye una imagen de Docker para las arquitecturas x86 y ARM:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t halloween:v1 .
```

Si ahora ejecutas `docker images`, verás que tienes una sola imagen de Docker que es compatible con las arquitecturas x86 y ARM.

```bash
docker images
```

Si añadimos al comando anterior la opción `--tree`, veremos un árbol con las diferentes plataformas soportadas.

```bash
docker images --tree
```


### **Crear/Configurar tus propios builders**: BuildKit tiene soporte integrado para plugins de construcción, lo que te permite extender las capacidades de construcción de imágenes de Docker con plugins personalizados. Con BuildKit, puedes utilizar plugins de construcción para realizar tareas específicas durante la construcción de imágenes de Docker, como la compilación de código, la generación de documentación o la ejecución de pruebas.

Buildx a día de hoy soporta los siguientes plugins:

- `docker`: Es la implementación predeterminada de BuildKit que utiliza Docker para ejecutar los procesos de construcción.
- `docker-container`: ejecuta los procesos de construcción en contenedores Docker.
- `kubernetes`: ejecuta los procesos de construcción en clústeres de Kubernetes.
- `remote`: ejecuta los procesos de construcción en un servidor remoto.

Sin embargo cuando instalas Docker Desktop solo tienes disponible el plugin `docker`. Para ver los que tienes disponibles puedes ejecutar el siguiente comando:

```bash
docker buildx ls
```

Si quisieras crear un nuevo builder podrías hacerlo con el siguiente comando:

```bash
docker buildx create --driver cloud 0gis0/returngis
```

Si ahora echo un vistazo a los builders que tengo disponibles, veré que tengo uno nuevo llamado `cloud-0gis0-returngis`:

```bash
docker buildx ls
```


Y ahora para poder usar este driver, que no es el que tenemos configurado por defecto, podríamos hacerlo de forma sencilla utilizando la opción `--builder`:

```bash
docker buildx build --builder cloud-0gis0-returngis -t halloween:v3 .
```

### **Cache de construcción mejorado**: BuildKit tiene un sistema de caché de construcción mejorado que es más rápido y eficiente que el sistema de caché de construcción de Docker tradicional. Con BuildKit, puedes utilizar el sistema de caché de construcción de Docker de forma más eficiente, lo que te permite reducir el tiempo de construcción de tus imágenes de Docker.

Para que lo veas con un ejemplo, aquí tienes un comando de `docker buildx` que utiliza el sistema de caché de construcción de Docker para acelerar la construcción de una imagen de Docker:

```bash
docker buildx build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-to type=local,dest=./cache -t halloween:v1 .
```

Y ahora podemos construir la imagen de Docker utilizando la caché de construcción de Docker:

```bash
docker buildx build --cache-from type=local,src=./cache -t halloween:v2 .
```

Esta funcionalidad es particularmente útil para grandes proyectos de construcción de imágenes de Docker, donde la construcción de imágenes puede llevar mucho tiempo.


También puedes usar otros backends para tu cache como Azure  o Github Actions entre otros 😇

Este es un ejemplo con Azure Blob Storage Cache (Documentación aquí: https://github.com/moby/buildkit#azure-blob-storage-cache-experimental):

Primero creamos una cuenta de Azure Storage:

```bash
STORAGE_ACCOUNT_NAME=fordockercache
RESOURCE_GROUP=youtube-docker-buildx
LOCATION=spaincentral

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS

STORAGE_ACCOUNT_URL=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query primaryEndpoints.blob -o tsv)

STORAGE_ACCOUNT_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query "[0].value" -o tsv)
```

No se puede utilizar el builder por defecto, por lo que necesitamos crear uno nuevo:

```bash
docker buildx create --use --name mybuilder
```

Cuando no le especificamos el driver utiliza el que se llama `docker-container` que es el que se utiliza por defecto.


```bash
docker buildx build --cache-to type=azblob,name=halloween:v1,account_url=$STORAGE_ACCOUNT_URL,secret_access_key=$STORAGE_ACCOUNT_KEY,mode=max -t halloween:v1 --builder mybuilder .
```


### **Poder tener multiples contextos de construcción**: BuildKit te permite tener múltiples contextos de construcción, lo que te permite construir imágenes de Docker en diferentes entornos de construcción. Con BuildKit, puedes tener múltiples contextos de construcción que contienen diferentes configuraciones de construcción, como variables de entorno, argumentos de construcción y opciones de construcción.

Para que lo veas con un ejemplo, aquí tienes un comando de `docker buildx` que construye una imagen de Docker utilizando un contexto de construcción personalizado:

```bash
docker buildx build \
--build-context app=./halloween-content \
--build-context config=./configuration \
-t halloween:multicontext \
-f Dockerfile.multicontext .
```

Let's test it:

```bash
docker run -d -p 8080:80 halloween:multicontext
```

```bash
docker buildx build \
--build-context app=./halloween-content \
--build-context config=https://github.com/0GiS0/youtube-docker-buildx.git#main \
-t halloween:multicontext-remote \
-f Dockerfile.multicontext.remote .
```

y lo probamos:

```bash
docker run -d -p 8081:80 halloween:multicontext-remote
```


5. **Montaje directo de datos**: BuildKit te permite montar datos directamente en el proceso de construcción, lo que te permite acceder a los datos de forma más eficiente durante la construcción de imágenes de Docker. Con BuildKit, puedes montar datos directamente en el proceso de construcción utilizando la opción `--mount`.

Para ello vamos a verlo con un ejemplo común como puede ser una aplicación en node.js

```bash
docker build -t nodejs-app nodejs-app
```

```bash