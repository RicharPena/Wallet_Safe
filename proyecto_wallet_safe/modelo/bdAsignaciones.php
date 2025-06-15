<?php
// archivo: modelo/bdGastos.php
require_once 'config.php';

class BDAsignaciones {
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

        public function registrarAsignacion($monto_asignado, $perfil_asignado_id, $rubro, $perfil_id) {
        try {

            $this->conexion->beginTransaction();
            $sql = "INSERT INTO asignacion_presupuesto (monto_asignado, perfil_asignado_id, rubro, perfil_id) VALUES (?, ?, ?, ?)";
            $stmt = $this->conexion->prepare($sql);
            $stmt->execute([$monto_asignado, $perfil_asignado_id, $rubro, $perfil_id]);

             $sqlGasto = "INSERT INTO gastos (monto, tipo, rubro, perfil_id, descripcion) 
                         VALUES (?, 'Variable', ?,  ?, ?)";
            $stmtGasto = $this->conexion->prepare($sqlGasto);
            $stmtGasto->execute([
                $monto_asignado,
                $rubro, // Puedes usar el mismo rubro como categoría
                $perfil_id,
                "Creación de presupuesto"
            ]);


         $this->conexion->commit();

            return ["estado" => "ok", "mensaje" => "Asignación registrada correctamente"];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }

 
}