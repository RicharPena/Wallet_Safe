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
       

    public function crearPerfil($nombre, $cuenta_id) {
        try {
            $sql = "INSERT INTO perfil (nombre, cuenta_id) VALUES (?, ?)";
            $stmt = $this->conexion->prepare($sql);
            $stmt->execute([$nombre, $cuenta_id]);
            $idPerfilNuevo = $this->conexion->lastInsertId();

            
            
            return ["estado" => "ok", "mensaje" => "Perfil registrado correctamente","id_perfil_creado" => $idPerfilNuevo];
        } catch (PDOException $e) {
            return ["estado" => "error", "mensaje" => $e->getMessage()];
        }
    }


    public function obtenerInformacionCompletaPerfil($perfil_id) {
    try {
        // Obtener datos del perfil
        $stmt = $this->conexion->prepare("SELECT * FROM perfil WHERE id = ?");
        $stmt->execute([$perfil_id]);
        $perfil = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$perfil) {
            return ["estado" => "error", "mensaje" => "Perfil no encontrado"];
        }

        // Obtener ingresos
        $stmt = $this->conexion->prepare("SELECT * FROM ingresos WHERE perfil_id = ?");
        $stmt->execute([$perfil_id]);
        $ingresos = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Obtener gastos
        $stmt = $this->conexion->prepare("SELECT * FROM gastos WHERE perfil_id = ?");
        $stmt->execute([$perfil_id]);
        $gastos = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Obtener presupuestos asignados
       if($perfil['titular']==1){
        $stmt = $this->conexion->prepare("SELECT * FROM asignacion_presupuesto WHERE perfil_id = ?");
        $stmt->execute([$perfil_id]);
        $presupuestos = $stmt->fetchAll(PDO::FETCH_ASSOC);


       }
else{
        $stmt = $this->conexion->prepare("SELECT * FROM asignacion_presupuesto WHERE perfil_asignado_id = ?");
        $stmt->execute([$perfil_id]);
        $presupuestos = $stmt->fetchAll(PDO::FETCH_ASSOC);
}
        
    foreach ($presupuestos as &$presupuesto) {
        // Consulta para saber si tiene detalles
        $stmtDetalle = $this->conexion->prepare("SELECT COUNT(*) FROM detalle_presupuesto WHERE asignacion_id = ?");
        $stmtDetalle->execute([$presupuesto['id']]);
        $tieneDetalle = $stmtDetalle->fetchColumn() > 0;

        // Agrega el campo "dividido"
        $presupuesto['dividido'] = $tieneDetalle;

         // Calcular gastos totales asociados a sus detalles
    $stmtMonto = $this->conexion->prepare("
        SELECT SUM(g.monto) 
        FROM gastos g
        INNER JOIN detalle_presupuesto d ON g.detalle_id = d.id
        WHERE d.asignacion_id = ?
    ");
    $stmtMonto->execute([$presupuesto['id']]);
    $montoGastos = $stmtMonto->fetchColumn() ?? 0;

    //$presupuesto['gastosTotales'] = number_format($montoGastos, 2, '.', '');
    $presupuesto['montoTotal'] = number_format($presupuesto['monto_asignado'] - $montoGastos, 2, '.', '');



    }

       //$info['presupuestos'] = $presupuestos;



  // Obtener detalles de presupuestos
    $stmt = $this->conexion->prepare("SELECT * FROM detalle_presupuesto WHERE perfil_id = ?");
    $stmt->execute([$perfil_id]);
     $detalles = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($detalles as &$detalle) {
                // Consulta para saber si tiene detalles
    $stmtgasto = $this->conexion->prepare("SELECT SUM(monto) FROM gastos WHERE detalle_id = ?");
    $stmtgasto->execute([$detalle['id']]);
    $gastosTotales = $stmtgasto->fetchColumn(); // <- Aquí extraes el valor real

            // Si no hay gastos, SUM(monto) será null → lo convertimos a 0
            $gastosTotales = $gastosTotales ?? 0;

            $montoTotal = $detalle['monto'] - $gastosTotales;
            //$detalle['montoTotal'] = $montoTotal;
        $detalle['montoTotal'] = number_format($montoTotal, 2, '.', '');
        
    }
  
        // Obtener suma de ingresos
$stmt = $this->conexion->prepare("SELECT SUM(monto) FROM ingresos WHERE perfil_id = ?");
$stmt->execute([$perfil_id]);
$totalIngresos = $stmt->fetchColumn() ?? 0;

// Obtener suma de gastos libres y de creación de presupuesto (los que no tienen detalle_id)
$stmt = $this->conexion->prepare("
    SELECT SUM(monto) FROM gastos 
    WHERE perfil_id = ? AND detalle_id IS NULL
");
$stmt->execute([$perfil_id]);
$gastosNoAsociados = $stmt->fetchColumn() ?? 0;

// Calcular balance libre
$balanceLibre = $totalIngresos - $gastosNoAsociados;
$perfil['balance'] = number_format($balanceLibre, 2, '.', '');









        return [
            "estado" => "ok",
            "mensaje" => "Datos del perfil obtenidos correctamente",
            "perfil" => $perfil,
            "ingresos" => $ingresos,
            "gastos" => $gastos,
            "presupuestos" => $presupuestos,
            "detalles_presupuesto" => $detalles
 
        ];
    } catch (PDOException $e) {
        return ["estado" => "error", "mensaje" => "Error: " . $e->getMessage()];
    }
}


    
   



    public function iniciarSesion($correo, $contrasena) {
        $sql = "SELECT * FROM cuenta WHERE correo = ?";
        $stmt = $this->conexion->prepare($sql);
        $stmt->execute([$correo]);
        $cuenta = $stmt->fetch(PDO::FETCH_ASSOC);
    
        if ($cuenta && password_verify($contrasena, $cuenta['contrasena'])) {
            unset($cuenta['contrasena']); // No enviamos la contraseña al frontend
             
             $perfiles = $this->obtenerPerfilesPorCuenta($cuenta['id']); //cogemos los perfiles asociados a la cuenta
             $cuenta['perfiles']= $perfiles;

            return ["estado" => "ok", "mensaje" => "Inicio de sesión exitoso aqui esta", "cuenta" => $cuenta];
        }

        

    
        return ["estado" => "error", "mensaje" => "Correo o contraseña incorrectos"];
    }


    public function obtenerPerfilesPorCuenta($cuenta_id) {
    $sql = "SELECT id, nombre FROM perfil WHERE cuenta_id = ?";
    $stmt = $this->conexion->prepare($sql);
    $stmt->execute([$cuenta_id]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
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
