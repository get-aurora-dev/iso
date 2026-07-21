export image_name := env("IMAGE_NAME", "aurora")
export env_file := env("ENV_FILE", ".env")
default_tag := "testing"
default_flavor := "main"
default_registry := "ghcr.io/ublue-os"

convert-brewfile-flatpak-to-titanoboa $brewfile="common/system_files/shared/usr/share/ublue-os/homebrew/system-flatpaks.Brewfile":
  #!/usr/bin/env bash
  set -eou pipefail

  mkdir -p iso_files
  grep -v '#' "${brewfile}" | grep -F -e "flatpak" | sed 's/flatpak //' | tr -d '"' | tee iso_files/flatpaks.list

[arg("flavor", long="flavor", short="f")]
[arg("tag", long="tag", short="t")]
[arg("registry", long="registry")]
[arg("variant", long="variant")]
setup-env $tag=default_tag $flavor=default_flavor $registry=default_registry $variant="webui":
  #!/usr/bin/env bash
  set -eou pipefail

  rm -f .env

  if [[ "${flavor}" =~ main ]]; then
    image_name="aurora"
  else
    image_name="aurora-${flavor}"
  fi

  echo flavor="${flavor}" >> "${env_file}"
  echo tag="${tag}" >> "${env_file}"
  echo image_name="${image_name}" >> "${env_file}"

  image_ref="${registry}"/"${image_name}":"${tag}"
  echo image_ref="${image_ref}" >> "${env_file}"

  artifact_format="${image_name}"-"${tag}"-"${variant}"-"$(arch)"
  echo artifact_format="${artifact_format}" >> "${env_file}"

  kargs="NONE"
  echo kargs="${kargs}" >> "${env_file}"

  container_image_name="${image_name}-live-${flavor}:${tag}"
  echo container_image_name="${container_image_name}" >> "${env_file}"

  cat "${env_file}"

build-container: setup-env convert-brewfile-flatpak-to-titanoboa
  #!/usr/bin/env bash
  set -eoux pipefail

  source .env

  podman build \
    --pull=newer \
    --cap-add sys_admin \
    --security-opt label=disable \
    --build-arg BASE_IMAGE=${image_ref} \
    --tag "${container_image_name}" \
    -f Containerfile \
    .

build-iso:
  #!/usr/bin/env bash
  set -eoux pipefail

  source .env

  TITANOBOA_CTR_IMAGE="${container_image_name}" bash -x ./titanoboa/main.sh
