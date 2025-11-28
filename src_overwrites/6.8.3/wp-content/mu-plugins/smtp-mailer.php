<?php
/**
 * Plugin Name: SMTP Configuration Loader
 * Description: Configures WordPress to use SMTP settings defined in wp-config.php.
 */

add_action( 'phpmailer_init', 'configure_wp_mail_smtp' );

function configure_wp_mail_smtp( $phpmailer ) {
    // Only configure if SMTP_HOST is defined
    if ( !defined( 'SMTP_HOST' ) ) {
        return;
    }

    $phpmailer->isSMTP();
    $phpmailer->Host       = SMTP_HOST;
    $phpmailer->SMTPAuth   = defined( 'SMTP_AUTH' ) ? SMTP_AUTH : false;

    if ( $phpmailer->SMTPAuth ) {
        $phpmailer->Port       = defined( 'SMTP_PORT' ) ? SMTP_PORT : 587;
        $phpmailer->Username   = defined( 'SMTP_USERNAME' ) ? SMTP_USERNAME : '';
        $phpmailer->Password   = defined( 'SMTP_PASSWORD' ) ? SMTP_PASSWORD : '';
        $phpmailer->SMTPSecure = defined( 'SMTP_SECURE' ) ? SMTP_SECURE : 'tls';
    }

    $phpmailer->From       = defined( 'SMTP_FROM' ) ? SMTP_FROM : get_option( 'admin_email' );
    $phpmailer->FromName   = defined( 'SMTP_FROM_NAME' ) ? SMTP_FROM_NAME : get_option( 'blogname' );
}