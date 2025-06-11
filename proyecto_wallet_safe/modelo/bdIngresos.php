<?php
// archivo: modelo/bdingresos.php
require_once 'config.php';

class BDIngresos {
    private $conexion;

    public function __construct() {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $this->conexion = new PDO($dsn, DB_USER, DB_PASS);
            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            die(json_encode(["error" => "Error de conexión: " . $e->getMessage()]));
        }
    }

    public function registrarIngreso($monto, $automatico, $tipo, $rubro, $descripcion, $perfil_id) {
        try {
            $sql = "INSERT INTO ingresos (monto, automatico, tipo, rubro, descripcion,  perfil_id) 
                    VALUES (?, ?, ?, ?, ?,  ?)";
            $stmt = $this->conexion->prepare($sql);
            $stmt->execute([$monto, $automatico, $tipo, $rubro, $descripcion, $perfil_id]);
            return ["estado" => "ok", "mensaje" => "Ingreso registrado correctamente"];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }

    public function obtenerIngresosPorPerfil($perfil_id) {
        try {
            $sql = "SELECT * FROM ingresos WHERE perfil_id = ? ORDER BY fecha DESC";
            $stmt = $this->conexion->prepare($sql);
            $stmt->execute([$perfil_id]);
            return ["estado" => "ok", "ingresos" => $stmt->fetchAll(PDO::FETCH_ASSOC)];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }
}