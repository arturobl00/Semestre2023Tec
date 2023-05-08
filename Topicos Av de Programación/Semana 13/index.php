<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Proyecto</title>
</head>
<body>
    <h1>Demo de como se trabaja en servidor</h1>
    <h2>Hola solo muestro contenido html</h2>
    <h3>Edición desde Servidor</h3>
    <?php
        include "conn.php";
        $leer = "Select * from demo";
        $ejecutar = mysqli_query($conn, $leer);

        //Lectura de Datos desde Servidor

        if (mysqli_num_rows($ejecutar) > 0) {
            // Recorrer los registros y mostrarlos en la página
            while($fila = mysqli_fetch_assoc($ejecutar)) {
              echo "ID: " . $fila["id"]. " - Nombre: " . $fila["nombre"]."<br>";
            }
          } else {
            echo "No hay registros en la tabla.";
          }
          
          // Cerrar la conexión con la base de datos
          mysqli_close($conn);
    ?>
</body>
</html>