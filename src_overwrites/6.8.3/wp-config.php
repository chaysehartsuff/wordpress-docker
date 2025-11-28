<?php
/**
 * The base configuration for WordPress
 *
 * This file reads configuration from environment variables passed by Docker.
 *
 * @package WordPress
 */

// ** Handle HTTPS behind reverse proxy ** //
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// ** SMTP Configuration for Zoho Mail ** //
define( 'SMTP_HOST', getenv('SMTP_HOST') ?: 'smtp.zoho.com' );
define( 'SMTP_PORT', getenv('SMTP_PORT') ?: '465' ); // Use 587 for TLS, 465 for SSL
define( 'SMTP_SECURE', getenv('SMTP_SECURE') ?: 'ssl' ); // 'ssl' or 'tls'
define( 'SMTP_AUTH', true );
define( 'SMTP_USERNAME', getenv('SMTP_USERNAME') ?: 'noreply@yourdomain.com' );
define( 'SMTP_PASSWORD', getenv('SMTP_PASSWORD') ?: '' );
define( 'SMTP_FROM', getenv('SMTP_FROM') ?: 'noreply@yourdomain.com' );
define( 'SMTP_FROM_NAME', getenv('SMTP_FROM_NAME') ?: 'Your Site Name' );

// Force WordPress to use HTTPS URLs
define('FORCE_SSL_ADMIN', true);

// Set the correct site URL scheme
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    define('WP_HOME', 'https://' . $_SERVER['HTTP_HOST']);
    define('WP_SITEURL', 'https://' . $_SERVER['HTTP_HOST']);
}

// ** Database settings - Read from environment variables ** //
/** The name of the database for WordPress */
define( 'DB_NAME', getenv('DB_DATABASE') ?: 'wordpress' );

/** Database username */
define( 'DB_USER', getenv('DB_USERNAME') ?: 'wordpress' );

/** Database password */
define( 'DB_PASSWORD', getenv('DB_PASSWORD') ?: 'wordpress' );

/** Database hostname - using service name from docker-compose */
define( 'DB_HOST', getenv('DB_HOST') . ':' . getenv('DB_PORT') );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress database table prefix.
 */
$table_prefix = getenv('WP_TABLE_PREFIX') ?: 'wp_';

/**
 * For developers: WordPress debugging mode.
 */
define( 'WP_DEBUG', (bool) getenv('WORDPRESS_DEBUG') );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

/**
 * Increase memory limit
 */
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

/* Add any custom values between this line and the "stop editing" line. */

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';