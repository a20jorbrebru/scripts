#!/bin/bash

# Instalar inxi (si no está instalado ya)
if ! command -v inxi &> /dev/null
then
    echo "inxi no está instalado. Instalando..."
    sudo apt update
    sudo apt install -y inxi
fi

# Obtener el nombre de la máquina
nombre_maquina=$(hostname)

# Obtener la dirección MAC de la interfaz de red primaria (tomando la primera no vacía)
direccion_mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address | tr ':' '-')

# Fecha actual para el nombre del archivo
fecha=$(date +%Y-%m-%d)

# Directorio para los archivos de salida
output_dir="${nombre_maquina}-${direccion_mac}-${fecha}"
mkdir -p "$output_dir"

# Subdirectorio para los archivos del sistema
system_files_dir="${output_dir}/system_files"
mkdir -p "$system_files_dir"

# Función para ejecutar comandos y guardar la salida
save_output() {
    local command=$1
    local filename=$2
    local title=$3
    echo "==================== $title ====================" > "${output_dir}/${filename}.txt"
    eval $command >> "${output_dir}/${filename}.txt"
    echo -e "\n\n" >> "${output_dir}/${filename}.txt"
}
# Información del sistema
save_output "lsb_release -a" "system_info" "System Information"

# Hardware
save_output "inxi -C" "cpu_info" "CPU Information"
save_output "inxi -D" "disk_info" "Disk Information"
save_output "inxi -P" "partition_info" "Partition Information"
save_output "inxi -G" "graphics_card_info" "Graphics Card Information"
save_output "inxi -M" "machine_info" "Machine Model Information"
save_output "inxi -Mxx" "machine_detail_info" "Machine Detail Information"
save_output "inxi -MMS" "motherboard_info" "Motherboard Information"
save_output "inxi -B" "bios_info" "BIOS Information"

# Red
save_output "ip addr" "network_info" "Network Information"
save_output "sudo ss -tulwn" "network_connections" "Network Connections"
save_output "sudo ufw status verbose" "firewall_status" "Firewall Status"
save_output "sudo iptables -L -v -n" "iptables_rules" "IPTables Rules"

# Software
save_output "sudo apt list --upgradable" "upgradable_packages" "Upgradable Packages"

# Usuarios y Grupos
save_output "cut -d: -f1 /etc/passwd" "user_list" "User List"
save_output "sudo cat /etc/pam.d/common-auth" "pam_configuration" "PAM Configuration"
save_output "systemctl --failed" "failed_units" "Failed Systemd Units"

# Rendimiento y Monitoreo
save_output "du -sh /home /root /var | sort -h" "disk_usage" "Disk Usage"

# Logs del sistema
save_output "sudo tail -n 20 /var/log/syslog" "recent_syslog" "Recent System Log"

# Lista de archivos críticos del sistema a copiar
# Nota: Algunos archivos pueden requerir permisos de superusuario para ser accedidos
FILES=(
  "/etc/passwd"
  "/etc/shadow"
  "/etc/group"
  "/etc/sudoers"
  "/etc/fstab"
  "/etc/ssh/sshd_config"
  "/etc/apt/sources.list"
  "/etc/network/interfaces"
  "/etc/hosts"
  "/etc/resolv.conf"
  "/etc/crontab"
  "/etc/sysctl.conf"
  "/etc/iptables/rules.v4"
  "/etc/iptables/rules.v6"
  "/etc/lvm/lvm.conf"
)

# Copiar cada archivo a la carpeta 'system_files', manteniendo la estructura de directorios
for FILE in "${FILES[@]}"; do
  # Verificar si el archivo existe
  if [ -f "${FILE}" ]; then
    # Utilizar cp con la opción --parents para preservar la estructura del directorio
    cp --parents "${FILE}" "$system_files_dir"
  else
    echo "El archivo ${FILE} no existe y no será incluido en el respaldo."
  fi
done

# Comprimir todos los archivos en un archivo con nombre específico
tar -czvf "${nombre_maquina}-${direccion_mac}-${fecha}.tar.gz" -C "$output_dir" .

# Fin del script.
