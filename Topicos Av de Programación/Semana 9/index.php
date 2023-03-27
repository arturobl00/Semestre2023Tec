<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <?php
        $servidor = "localhost";
        $usuario = "root";
        $contraseña = "";
        $basedatos = "unidad3";

        $conexion = mysqli_connect($servidor, $usuario, $contraseña, $basedatos);

        if (mysqli_connect_errno()) {
        echo "Falló la conexión a la base de datos: " . mysqli_connect_error();
        }else{
            echo "Conexion exitosa";
        }

        $consulta = "SELECT * FROM ejemplo";
        $resultado = mysqli_query($conexion, $consulta);

        while ($fila = mysqli_fetch_assoc($resultado)) {
        echo "<p>".$fila["id"] . " " . $fila["nombre"]."</p>";
}
    ?>
</body>
</html>