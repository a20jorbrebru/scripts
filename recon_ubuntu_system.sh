#!/bin/bash

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
save_output "lsb_release -a && echo '================================================' && uname -a && echo '================================================' && uptime" "system_info" "System Information"

# Hardware
save_output "echo 'CPU Info:' && cat /proc/cpuinfo && echo '================================================' && echo 'CPU Details:' && lscpu && echo '================================================' && echo 'Memory Info:' && cat /proc/meminfo && echo '================================================' && echo 'Block Devices:' && lsblk && echo '================================================' && echo 'Disk Usage:' && df -h && echo '================================================' && echo 'Graphics Card:' && lspci | grep VGA && echo '================================================' && echo 'Video Hardware:' && lshw -c video && echo '================================================' && echo 'USB Devices:' && lsusb" "hardware_info" "Hardware Information"

# Red
save_output "echo 'Network Configuration:' && ifconfig && echo '================================================' && echo 'IP Addresses:' && ip a && echo '================================================' && echo 'Network Statistics:' && netstat && echo '================================================' && echo 'Socket Statistics:' && ss && echo '================================================' && echo 'Firewall Status:' && sudo ufw status" "network_info" "Network Information"

# Software
save_output "echo 'Installed Packages:' && dpkg -l && echo '================================================' && echo 'Apt Packages:' && apt list --installed && echo '================================================' && echo 'Service Status:' && service --status-all && echo '================================================' && echo 'Systemd Units:' && systemctl list-units" "software_info" "Software Information"

# Usuarios y Grupos
save_output "echo 'User Accounts:' && cat /etc/passwd && echo '================================================' && echo 'Password Entries:' && getent passwd && echo '================================================' && echo 'Groups:' && cat /etc/group && echo '================================================' && echo 'Group Entries:' && getent group && echo '================================================' && echo 'Logged-in Users:' && w && echo '================================================' && echo 'Currently Logged Users:' && who" "users_groups_info" "Users and Groups Information"

# Rendimiento y Monitoreo
save_output "echo 'Top Processes:' && top -b -n 1 && echo '================================================' && echo 'Process List:' && ps aux && echo '================================================' && echo 'Process Tree:' && pstree" "performance_monitoring_info" "Performance and Monitoring Information"

# Periféricos
save_output "echo 'Printer Status:' && lpstat -p && echo '================================================' && echo 'Printer Devices:' && lpinfo -v && echo '================================================' && echo 'Input Devices:' && xinput list" "peripherals_info" "Peripherals Information"

# Entorno de Escritorio
save_output "echo 'Desktop Configuration Dump:' && dconf dump /" "desktop_environment_info" "Desktop Environment Information"

# Información de arranque
save_output "echo 'Boot Messages:' && dmesg && echo '================================================' && echo 'Boot Log:' && cat /var/log/boot.log && echo '================================================' && echo 'Boot Services:' && systemctl list-unit-files --type=service" "boot_info" "Boot Information"

# Información del BIOS/UEFI
save_output "echo 'BIOS/UEFI Information:' && dmidecode" "bios_uefi_info" "BIOS/UEFI Information"

# Logs del sistema
save_output "echo 'System Log:' && cat /var/log/syslog && echo '================================================' && echo 'Journal Log:' && journalctl" "system_logs" "System Logs"

# Tareas programadas
save_output "echo 'User Cron Jobs:' && crontab -l && echo '================================================' && echo 'System Cron Jobs:' && cat /etc/crontab" "scheduled_tasks_info" "Scheduled Tasks Information"

# Variables de entorno
save_output "echo 'Environment Variables:' && printenv" "environment_variables_info" "Environment Variables Information"

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



# Enviar los datos al correo

# Limpiar los archivos de texto, si no se desean mantener después de la compresión
# rm -r "$output_dir"

# Fin del script