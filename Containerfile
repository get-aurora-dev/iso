# run with --cap-add sys_admin --security-opt label=disable --squash
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ENV BASE_IMAGE=${BASE_IMAGE}

COPY iso_files/ /src/iso_files/
RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/flatpak \
    bash /src/iso_files/build.sh
