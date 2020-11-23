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
read -p "Procedemos a crear la nueva base de datos? (s/n): " new_db
echo "============================================"

[ "$new_db" != s ] && echo "Proceso cancelado." && exit

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
#clear
echo "=========================================="
echo "Elija el modo de instalación de Wordpress:"
echo "=========================================="
echo ""
echo "1. Instalar Wordpress usando wp-cli"
echo "2. Salir"
echo ""
read -p "Elija el método de instalación: " install_method

[ "$install_method" != 1 ] && echo "Hasta luego." && exit

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
echo
read -p "Email del Admin: " admin_email
echo
read -p "Ejecutar instalación? [s/n]: " run_wp_install

[ "$run_wp_install" == n ] && echo "Hasta luego." && exit

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

#otras acciones para limpiar instalaciones de temas/plugins
wp post delete 1 2 --force --allow-root # borra los posts/paginas de ejemplo
wp plugin delete akismet --allow-root
wp plugin delete hello --allow-root
wp theme delete twentyseventeen --allow-root
wp theme delete twentynineteen --allow-root
wp theme update twentytwenty --allow-root

#algunos ajustes default necesarios
wp option update  --allow-root blogdescription ""
wp option update  --allow-root start_of_week 0
wp option update  --allow-root timezone_string "America/Panama"
wp option update --allow-root permalink_structure "/%postname%"

wp plugin install better-wp-security --allow-root
wp plugin install go-live-update-urls --activate --allow-root
wp plugin install classic-editor --allow-root

cat > .htaccess<<EOF
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF

echo ""
echo "================================================"
echo "Asignando usuario y grupo de linux"
echo "================================================"
read -p "Host usuario: " hostuser
read -p "Host grupo: " hostgroup
chown -R $hostuser:$hostgroup $dir_name
echo "Permisos cambiados a: $hostuser:$hostgroup $dir_name"
ls -la $dir_name

echo "================================================"
echo "Limpiando un poco..."
echo "================================================"
rm -rf readme.html license.txt wp-config-sample.php;
echo "Proceso completado!"

fi
