<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Metodo Post En PHP</title>
</head>
<body>
    <h1>Metodo Post en Formulario PHP</h1>
    <p>El metodo Post me permite el envio de datos mediante el
        navegador al servidor, estos datos se transmiten mediante
        la url del proyecto.
    </p>
    <h2>Formulario</h2>
    <form method="post">
        <p>Nombre: <input type="text" value="" name="nombre"/></p>
        <p><input type="submit" value="Enviar" name="b1"/></p>
    </form>

    <?php
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            $boton = $_POST['b1'];
            if($boton == "Enviar"){
                $nombre = $_POST['nombre'];
                echo "Hola como estas ".$nombre;
            }
        }
    ?>

    <h2>Formulario 2</h2>
    <form method="post">
        <p>Numero 1: <input type="number" value="" name="num1"/></p>
        <p>Numero 2: <input type="number" value="" name="num2"/></p>
        <p><input type="submit" value="Sumar" name="b1"/></p>
    </form>

    <?php
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            $boton = $_POST['b1'];
            if($boton == "Sumar"){
                $num1 = $_POST['num1'];
                $num2 = $_POST['num2'];
                $num1 = $num1 + $num2;
                echo "El resultado es ".$num1;
            }
        }
    ?>
</body>
</html>