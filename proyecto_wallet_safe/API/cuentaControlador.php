<?php
require_once __DIR__ . '/../modelo/bd.php';

class CuentaControlador {
    private $db;

    public function __construct() {
        $this->db = new BD();
    }

    public function registrar($data) {
        if (!isset($data['nombre'], $data['correo'], $data['contrasena'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }
        return $this->db->registrarUsuario($data['nombre'], $data['correo'], $data['contrasena']);
    }

    public function login($data) {
        if (!isset($data['correo'], $data['contrasena'])) {
            return ["estado" => "error", "mensaje" => "Datos incompletos"];
        }
        return $this->db->iniciarSesion($data['correo'], $data['contrasena']);
    }

    public function editarPerfil($data) {
        if (!isset($data['id'])) {
            return ["estado" => "error", "mensaje" => "Falta el ID de la cuenta"];
        }
    
        $id = $data['id'];
        $nombre = $data['nombre'] ?? null;
        $correo = $data['correo'] ?? null;
        $contrasena = $data['contrasena'] ?? null;
    
        return $this->db->editarPerfil($id, $nombre, $correo, $contrasena);
    }
    

}
?>
