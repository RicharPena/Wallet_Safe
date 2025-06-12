<?php
session_start();
$mensaje = "";
$estado = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'];
    $data = [];

    if ($accion === 'registrar') {
        $data = [
            'nombre' => $_POST['nombre'],
            'correo' => $_POST['correo'],
            'contrasena' => $_POST['contrasena']
        ];
    } elseif ($accion === 'login') {
        $data = [
            'correo' => $_POST['correo'],
            'contrasena' => $_POST['contrasena']
        ];
    } elseif ($accion === 'editar') {
        $data = [
            'id' => $_SESSION['usuario']['id'],
            'nombre' => $_POST['nombre'] ?? null,
            'correo' => $_POST['correo'] ?? null,
            'contrasena' => $_POST['contrasena'] ?? null
        ];
    } elseif ($accion === 'registrarIngreso') {
         $data = [ 
            'monto' => $_POST['monto'], 
            'automatico' => $_POST['automatico'], 
            'tipo' => $_POST['tipo'], 
            'rubro' => $_POST['rubro'], 
            'descripcion' => $_POST['descripcion'], 
            'perfil_id' => $_SESSION['usuario']['id'] 
        ]; 
    }elseif ($accion === 'registrarGasto') { 
        $data = [ 
            'monto' => $_POST['monto'], 
            'automatico' => $_POST['automatico'], 
            'tipo' => $_POST['tipo'],
             'rubro' => $_POST['rubro'], 
             'descripcion' => $_POST['descripcion'], 
             'perfil_id' => $_SESSION['usuario']['id'] 
            ];
        
        }elseif ($accion === 'perfil') { 
    $data = [ 
        'nombre' => $_POST['nombre_perfil'], 
        'cuenta_id' => $_SESSION['usuario']['id'] 
    ];


    }



    $options = [
        'http' => [
            'header'  => "Content-type: application/json",
            'method'  => 'POST',
            'content' => json_encode($data),
        ]
    ];

    $context = stream_context_create($options);
    $url = "http://localhost/proyecto_wallet_safe/controlador/broker.php?accion=$accion";
    $result = file_get_contents($url, false, $context);
    $response = json_decode($result, true);
echo '<pre>';
var_dump($result);
echo '</pre>';
    $estado = $response["estado"];
    $mensaje = $response["mensaje"];

    if ($estado === "ok" && $accion === 'login') {
        $_SESSION["usuario"] = $response["usuario"];
        $_SESSION["usuario"];
        header("Location: probar_api.php");
        exit;
    }

    if ($estado === "ok" && $accion === 'editar') {
        $_SESSION["usuario"]["nombre"] = $data["nombre"] ?? $_SESSION["usuario"]["nombre"];
        $_SESSION["usuario"]["correo"] = $data["correo"] ?? $_SESSION["usuario"]["correo"];
        header("Location: probar_api.php");
        exit;
    }
}

if (isset($_GET["logout"])) {
    session_destroy();
    header("Location: probar_api.php");
    exit;
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Wallet Safe - Probar API</title>
</head>
<body>
    <h2>Wallet Safe - Probar API</h2>
    <?php if (!empty($mensaje)): ?>
        <p><strong><?= strtoupper($estado) ?>:</strong> <?= $mensaje ?></p>
    <?php endif; ?>

    <?php if (isset($_SESSION["usuario"])): ?>
        <h3>Bienvenido, <?= htmlspecialchars($_SESSION["usuario"]["nombre"]) ?>!</h3>
        <form method="POST">
            <h4>Editar Perfil</h4>
            <input type="hidden" name="accion" value="editar">
            <label>Nuevo Nombre:</label><br>
            <input type="text" name="nombre"><br>
            <label>Nuevo Correo:</label><br>
            <input type="email" name="correo"><br>
            <label>Nueva Contraseña:</label><br>
            <input type="password" name="contrasena"><br>
            <button type="submit">Guardar Cambios</button>
        </form>


        <hr>
        <form method="POST">
        <h4>Crear Perfil</h4>
        <input type="hidden" name="accion" value="perfil">
        <label>Nombre del perfil:</label><br>
        <input type="text" name="nombre_perfil" required><br>
        <button type="submit">Crear Perfil</button>
    </form>

    <hr>


         <form method="POST">
        <h4>Registrar Ingreso</h4>
        <input type="hidden" name="accion" value="registrarIngreso">
        <label>Monto:</label><br>
        <input type="number" step="0.01" name="monto" required><br>
        <label>Automático (0 o 1):</label><br>
        <input type="number" name="automatico" min="0" max="1" required><br>
        <label>Tipo:</label><br>
        <select name="tipo" required>
            <option value="Fijo">Fijo</option>
            <option value="Variable">Variable</option>
        </select><br>
        <label>rubro:</label><br>
        <input type="text" name="rubro" required><br>
        <label>Descripción:</label><br>
        <input type="text" name="descripcion"><br>
        <button type="submit">Registrar Ingreso</button>
    </form>

      <hr>

    <form method="POST">
        <h4>Registrar Gasto</h4>
        <input type="hidden" name="accion" value="registrarGasto">
        <label>Monto:</label><br>
        <input type="number" step="0.01" name="monto" required><br>
        <label>Automático (0 o 1):</label><br>
        <input type="number" name="automatico" min="0" max="1" required><br>
        <label>Tipo:</label><br>
        <select name="tipo" required>
            <option value="Fijo">Fijo</option>
            <option value="Variable">Variable</option>
        </select><br>
        <label>Rubro:</label><br>
        <input type="text" name="rubro" required><br>
        <label>Descripción:</label><br>
        <input type="text" name="descripcion"><br>
        <button type="submit">Registrar Gasto</button>
    </form>


    <br>




        <a href="?logout=true">Cerrar sesión</a>

    <?php else: ?>
        <h3>Registrarse</h3>
        <form method="POST">
            <input type="hidden" name="accion" value="registrar">
            <label>Nombre</label><br>
            <input type="text" name="nombre" required><br>
            <label>Correo</label><br>
            <input type="email" name="correo" required><br>
            <label>Contraseña</label><br>
            <input type="password" name="contrasena" required><br>
            <button type="submit">Registrarme</button>
        </form>

        <h3>Iniciar Sesión</h3>
        <form method="POST">
            <input type="hidden" name="accion" value="login">
            <label>Correo</label><br>
            <input type="email" name="correo" required><br>
            <label>Contraseña</label><br>
            <input type="password" name="contrasena" required><br>
            <button type="submit">Iniciar sesión</button>
        </form>
    <?php endif; ?>
</body>
</html>
