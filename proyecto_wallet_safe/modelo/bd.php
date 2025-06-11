<?php
require_once 'config.php';

class BD {
    private $conexion;

    public function __construct() {
        try {
            $dsn = "mysql:host=".DB_HOST.";dbname=".DB_NAME.";charset=utf8mb4";
            $this->conexion = new PDO($dsn, DB_USER, DB_PASS);
            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            die(json_encode(["error" => "Error de conexión: " . $e->getMessage()]));
        }
    }

    public function registrarUsuario($nombre, $correo, $contrasena) {
        try {
            $sql = "INSERT INTO cuenta (nombre, correo, contrasena) VALUES (?, ?, ?)";
            $stmt = $this->conexion->prepare($sql);
            $hash = password_hash($contrasena, PASSWORD_BCRYPT);
            $stmt->execute([$nombre, $correo, $hash]);
            return ["estado" => "ok", "mensaje" => "Usuario registrado correctamente"];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }

    public function iniciarSesion($correo, $contrasena) {
        $sql = "SELECT * FROM cuenta WHERE correo = ?";
        $stmt = $this->conexion->prepare($sql);
        $stmt->execute([$correo]);
        $cuenta = $stmt->fetch(PDO::FETCH_ASSOC);
    
        if ($cuenta && password_verify($contrasena, $cuenta['contrasena'])) {
            unset($cuenta['contrasena']); // No enviamos la contraseña al frontend
            return ["estado" => "ok", "mensaje" => "Inicio de sesión exitoso", "usuario" => $cuenta];
        }
    
        return ["estado" => "error", "mensaje" => "Correo o contraseña incorrectos"];
    }

    public function editarPerfil($id, $nombre = null, $correo = null, $contrasena = null) {
        $campos = [];
        $valores = [];
    
        if (!empty($nombre)) {
            $campos[] = "nombre = ?";
            $valores[] = $nombre;
        }
        if (!empty($correo)) {
            $campos[] = "correo = ?";
            $valores[] = $correo;
        }
        if (!empty($contrasena)) {
            $campos[] = "contrasena = ?";
            $valores[] = password_hash($contrasena, PASSWORD_DEFAULT);
        }
    
        if (empty($campos)) {
            return ["estado" => "error", "mensaje" => "No se enviaron datos para actualizar"];
        }
    
        $valores[] = $id;
        $sql = "UPDATE cuenta SET " . implode(', ', $campos) . " WHERE id = ?";
        $stmt = $this->conexion->prepare($sql);
    
        if ($stmt->execute($valores)) {
            return ["estado" => "ok", "mensaje" => "Perfil actualizado"];
        }
        return ["estado" => "error", "mensaje" => "Error al actualizar perfil"];
    }
    
    
}
?>
