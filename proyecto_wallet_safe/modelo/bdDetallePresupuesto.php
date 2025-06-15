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

            $this->conexion->beginTransaction();

            $sql = "INSERT INTO detalle_presupuesto (asignacion_id, perfil_id, rubro, monto) VALUES (?, ?, ?, ?)";
            $stmt = $this->conexion->prepare($sql);

            // Si no hay asignación, enviamos null explícitamente
            //tipos de gasto
            //gastos libres,no tienen asignacion id, y descripcion libre
            //gastos creacion de presupuesto, no tienencasignacion id pero la descripcioon es: creacion de presupuesto
            //gastos de un presupuesto SI tiene asignacion id y descripcion libre
            //aqui como es registrar detalle registro  un gasto de creacion de presupuesto





            $asignacion_id = $asignacion_id !== null ? $asignacion_id : null;

            $stmt->execute([$asignacion_id, $perfil_id, $rubro, $monto]);



                    if ($asignacion_id === null) {
            $sqlGasto = "INSERT INTO gastos (monto, tipo, rubro, perfil_id, descripcion) 
                         VALUES (?, 'Variable', ?,  ?, ?)";
            $stmtGasto = $this->conexion->prepare($sqlGasto);
            $stmtGasto->execute([
                $monto,
                $rubro, // Puedes usar el mismo rubro como categoría
                $perfil_id,
                "Creación de presupuesto"
            ]);
        }
        $this->conexion->commit();

            return ["estado" => "ok", "mensaje" => "Detalle de presupuesto registrado correctamente"];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }
}
?>
