<?php
// archivo: controlador/gastoscontrolador.php
require_once __DIR__ . '/../modelo/bdGastos.php';

class GastosControlador {
    private $db;

    public function __construct() {
        $this->db = new BDGastos();
    }

    public function registrarGastos($data) {
        if (!isset($data['monto'],  $data['rubro'], $data['descripcion'], $data['perfil_id'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }


        $detalle_id = $data['detalle_id'] ?? null;
        $tipo = $data['tipo'] ?? null;
        $automatico = $data['automatico'] ?? null;

        return $this->db->registrarGastos(
            $data['monto'],
            $automatico,
            $tipo,
            $data['rubro'],
            $data['descripcion'],
            $data['perfil_id'],
            $detalle_id
        );
    }

    public function obtenerGastos($data) {
        if (!isset($data['perfil_id'])) {
            return ["estado" => "error", "mensaje" => "Falta el ID del perfil"];
        }

        return $this->db->obtenerIngresosPorPerfil($data['perfil_id']);
    }
}

