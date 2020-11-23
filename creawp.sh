#!/bin/bash -e
clear
echo "============================================"
echo "Script de instalación de WordPress - Centos"
echo "============================================"

# Recopilación de credenciales de inicio de sesión de la base de datos a partir de la entrada del usuario
read -p "Host de BD: " dbhost
read -p "Nombre de BD: " dbname
read -p "Usuario de BD: " dbuser
read -sp "Password de BD: " dbpass
echo ""

# Crear una nueva base de datos con las credenciales proporcionadas
echo "============================================"
echo "Crearemos una nueva base de datos con las credenciales proporcionadas."
echo "Si la base de datos y el usuario ya existen, se borran y crean nuevamente."
read -p "Procedemos a crear la nueva base de datos? (s/n): " -n 1 -r
echo "============================================"

[[ $REPLY =~ ^[^Ss]$ ]] && echo "Proceso cancelado." && exit

echo "Ejecutando creacion de base de datos y usuario."

mysql -u root<<EOF
DROP DATABASE IF EXISTS $dbname;
CREATE DATABASE IF NOT EXISTS $dbname;
DROP USER IF EXISTS '$dbuser'@'localhost';
CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';
ALTER DATABASE $dbname CHARACTER SET utf8 COLLATE utf8_general_ci;
FLUSH PRIVILEGES;
EOF

echo
echo "Creación de base de datos terminada"
echo

# Inicio del proceso de instalación de Wordpress
cat <<EOF
==========================================
Elija el modo de instalación de Wordpress:
==========================================

1. Instalar Wordpress usando wp-cli
2. Salir

EOF

read -p "Elija el método de instalación: " -n 1 -r
[ "$REPLY" != 1 ] && echo "Hasta luego." && exit

# Inicio del proceso de instalación de Wordpress usando wp-cli
echo "==================================="
echo "Uno momento... instalando wp-cli"
echo "==================================="
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
cp wp-cli.phar /usr/bin/wp

echo "=========================="
echo "Terminé de instalar wp-cli"
echo "=========================="
echo


# Ingresando detalles del nuevo sitio de Wordpress
#clear
echo ""
echo "==================================================================="
echo "Listo para instalar Wordpress, solo ingrese algunos detalles más"
echo "==================================================================="

wp_dir_install()
{
	echo
	read -p "Nombre del directorio para instalar WordPress: " dir_name
	if [[ -d $dir_name ]]; then
		echo "El directorio '$dir_name' ya existe:"
  		echo "  1. Escoger otro nombre"
  		echo "  2. Usar este directorio y BORRAR TODO su contenido"
		echo
		read -p "Seleccione una opción: " -n 1 -r
		if [ $REPLY == 1 ]; then
			wp_dir_install
		else
			rm -rf $dir_name/*
		fi
	else
		read -p "El directorio '$dir_name' no existe, desea crearlo [s/n]: " -n 1 -r
		if [[ $REPLY =~ ^[Ss]$ ]]; then
			mkdir $dir_name
		else
			wp_dir_install
		fi
	fi
}

cd $dir_name
read -p "url del sitio: " url
read -p "Título del sitio: " title
read -p "Nombre de usuario del Admin: " admin_name
read -sp "Password del Admin: " admin_pass
read -p "Email del Admin: " admin_email
echo
read -p "Ejecutar instalación? [s/n]: " -n 1 -r
[[ $REPLY =~ ^[^Ss]$ ]] && echo "Hasta luego." && exit

echo "=================================================="
echo "Un robot ahora está instalando WordPress por ti."
echo "=================================================="
echo ""
# Descargando el último paquete de WordPress usando wp-cli
wp core download --locale=es_ES --allow-root

#asignamos un nuevo prefijo para nuestras tablas, aumentando la seguridad
newdbprefix="wp_"
read -p "Nuevo prefijo de las tablas par la base de datos ej. wpol33_ [default: wp_]: " newdbprefix

# Crear un archivo wp-config usando las credenciales definidas
wp core config --dbhost=$dbhost --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --dbprefix=$newdbprefix --allow-root
chmod 644 wp-config.php

# Instalación del sitio de Wordpress usando las credenciales definidas
wp core install --url=$url --title="$title" --admin_name=$admin_name --admin_password=$admin_pass --admin_email=$admin_email --allow-root

echo
echo "Instalación de WordPress completa!"
echo
echo
echo "================================================"
echo "Asignando usuario y grupo de linux"
echo "================================================"
read -p "Host usuario: " hostuser
read -p "Host grupo: " hostgroup
chown -R $hostuser:$hostgroup $dir_name
echo "Permisos cambiados a: $hostuser:$hostgroup $dir_name"
ls -la $dir_name

echo
read -p "Continuamos con los ajustes post-instalación? (s/n): " -n 1 -r
if [[ $REPLY =~ ^[^Ss]$ ]] && echo "Disfruta WordPress!." && exit

bash <(curl -sL https://raw.githubusercontent.com/ernestoamg/wpcli-post-instalacion/main/wp_post_instalacion.sh)
