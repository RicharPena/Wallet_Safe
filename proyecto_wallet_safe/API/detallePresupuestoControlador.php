<?php

require_once __DIR__ . '/../modelo/bdDetallePresupuesto.php';
class DetallePresupuestoControlador {
    private $bd;

    public function __construct() {
        $this->bd = new BDDetallePresupuesto();
    }

    public function registrar($data) {
        if (!isset($data['perfil_id'], $data['rubro'], $data['monto'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }

        // asignacion_id puede venir o no, si no viene será null
        $asignacion_id = $data['asignacion_id'] ?? null;

        return $this->bd->registrarDetalle(
            $asignacion_id,
            $data['perfil_id'],
            $data['rubro'],
            $data['monto']
        );
    }
}
?>
