<?php

require_once __DIR__ . '/../modelo/bdAsignaciones.php';
class AsignacionesControlador {
    private $bd;

    public function __construct() {
        $this->bd = new BDAsignaciones();
    }

    public function registrar($data) {
        if (!isset($data['monto_asignado'], $data['perfil_asignado_id'], $data['rubro'], $data['perfil_id'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }

        return $this->bd->registrarAsignacion(
            $data['monto_asignado'],
            $data['perfil_asignado_id'],
            $data['rubro'],
            $data['perfil_id']
        );
    }
}
?>
