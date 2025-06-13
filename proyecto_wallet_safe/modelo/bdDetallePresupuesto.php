<?php
require_once 'config.php';

class BDDetallePresupuesto {
    private $conexion;

    public function __construct() {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $this->conexion = new PDO($dsn, DB_USER, DB_PASS);
            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            die(json_encode(["estado" => "error", "mensaje" => "Error de conexión: " . $e->getMessage()]));
        }
    }

    public function registrarDetalle($asignacion_id, $perfil_id, $rubro, $monto) {
        try {
            $sql = "INSERT INTO detalle_presupuesto (asignacion_id, perfil_id, rubro, monto) VALUES (?, ?, ?, ?)";
            $stmt = $this->conexion->prepare($sql);

            // Si no hay asignación, enviamos null explícitamente
            $asignacion_id = $asignacion_id !== null ? $asignacion_id : null;

            $stmt->execute([$asignacion_id, $perfil_id, $rubro, $monto]);

            return ["estado" => "ok", "mensaje" => "Detalle de presupuesto registrado correctamente"];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }
}
?>
