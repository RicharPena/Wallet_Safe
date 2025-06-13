<?php
header('Content-Type: application/json');
require_once '../API/cuentaControlador.php';
require_once '../API/ingresosControlador.php';
require_once '../API/gastosControlador.php';
require_once '../API/asignacionesControlador.php';  
require_once '../API/detallePresupuestoControlador.php';// AÑADIDO

$input = json_decode(file_get_contents('php://input'), true);
$accion = $_GET['accion'] ?? '';

error_log("Accion recibida: " . $accion);


$cuentaControlador = new CuentaControlador();

switch ($accion) {
    case 'registrar':
        
        echo json_encode($cuentaControlador->registrar($input));
        break;

    case 'login':
        
        echo json_encode($cuentaControlador->login($input));
        break;

    case 'perfil':
        
        echo json_encode($cuentaControlador->perfil($input));
        break;
        
    case 'perfilCompleto':
    
       echo json_encode($cuentaControlador->obtenerPerfilCompleto($input));
       break;
    

    case 'editar':
        
        echo json_encode($cuentaControlador->editarPerfil($input));
        break;

    case 'registrarIngreso':  // NUEVA ACCIÓN
        $ingresosControlador = new IngresosControlador();
        echo json_encode($ingresosControlador->registrarIngresos($input));
        break;

    case 'registrarGasto':  // NUEVA ACCIÓN
        $gastosControlador = new GastosControlador();
        echo json_encode($gastosControlador->registrarGastos($input));
        break;

    case 'registrarAsignacion':
        $asignacionescontrolador = new AsignacionesControlador();
        echo json_encode($asignacionescontrolador->registrar($input));
        break;
    case 'registrarDetalle':
        $detallepresupuestocontrolador = new DetallePresupuestoControlador();
        echo json_encode($detallepresupuestocontrolador->registrar($input));
        break;


    default:
        echo json_encode(["estado" => "error", "mensaje" => $accion]);
}
?>

