<?php
// archivo: controlador/ingresoscontrolador.php
require_once __DIR__ . '/../modelo/bdingresos.php';

class IngresosControlador {
    private $db;

    public function __construct() {
        $this->db = new BDIngresos();
    }

    public function registrarIngresos($data) {
        if (!isset($data['monto'], $data['automatico'], $data['tipo'], $data['rubro'], $data['descripcion'], $data['perfil_id'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }

        return $this->db->registrarIngreso(
            $data['monto'],
            $data['automatico'],
            $data['tipo'],
            $data['rubro'],
            $data['descripcion'],
            $data['perfil_id']
        );
    }

    public function obtenerIngresos($data) {
        if (!isset($data['perfil_id'])) {
            return ["estado" => "error", "mensaje" => "Falta el ID del perfil"];
        }

        return $this->db->obtenerIngresosPorPerfil($data['perfil_id']);
    }
}

