<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-GLhlTQ8iRABdZLl6O3oVMWSktQOp6b7In1Zl3/Jr59b6EGGoI1aFkw7cmDA6j6gD" crossorigin="anonymous">
    <title>Semana 7 Unidad 3 Programación Concurrente</title>
</head>
<body>
    <div class="container">
        <h1 class="display-3 text-center">Semana 7 Ejemplo 1 - Programación Concurrente</h1>
        <h2 class="display-6 text-center">Ejecución de Ciclo Para mostrar un mensaje en varios estilos</h2>
        <form method="post">
            <div class="form-floating mb-3">
                <input type="text" class="form-control" name="mensaje" 
                id="floatingInput" placeholder="Coloque su Mensaje Aqui"/>
                <label for="floatingInput">Coloque su Mensaje Aqui</label>
            </div>
            <div class="form-floating mb-3">
                <input type="number" class="form-control" name="ciclos" 
                id="floatingInput" placeholder="Coloque un número"/>
                <label for="floatingInput">Coloque un número</label>
            </div>
            <div>
                <input type="submit" class="btn btn-primary" name="boton" value="Enviar"/>
            </div>
        </form>
    </div>

    <?php
        if($_POST){
            $boton = $_POST["boton"];
            if($boton == "Enviar"){
                $texto = $_POST["mensaje"];
                $numero = $_POST["ciclos"];
                $color = [
                        "text-primary", 
                        "text-secondary", 
                        "text-warning", 
                        "text-danger",
                        "text-light",
                        "text-success",
                        "text-info",
                        "text-dark",
                        "text-mute",
                        ];

                    $y = 0;
                    for($x=0; $x<$numero; $x++){
                        if($y==9){
                            $y=0;
                        }
                        echo "<p class=".$color[$y].">".$texto."</p>";
                        $y++;
                    }
            }
        }
    ?>

    <h2 class="display-5">Segunda Parte de Demostración</h2>
    <form method="post">
            <div class="form-floating mb-3">
                <input type="number" class="form-control" name="val1" 
                id="floatingInput" placeholder="Escriba el Valor 1"/>
                <label for="floatingInput">Valor 1</label>
            </div>
            <div class="form-floating mb-3">
                <input type="number" class="form-control" name="val2" 
                id="floatingInput" placeholder="Escriba el Valor 2"/>
                <label for="floatingInput">Valor 2</label>
            </div>
            <div>
                <input type="submit" class="btn btn-primary" name="boton" value="Calcular"/>
            </div>
    </form>

    <?php
        if($_POST){
            $boton = $_POST["boton"];
            if($boton == "Calcular"){
                $val1 = $_POST["val1"];
                $val2 = $_POST["val2"];
                $suma = sumar($val1, $val2);
                $restar = restar($val1,$val2);
                $dividir = dividir($val1,$val2);
                $multiplicar = multiplicar($val1,$val2);

                echo "<p>Los nuemeros capturados generan los siguiente resultados</p>";
                echo "<lo><li>Suma: ".$suma."</li>";
                echo "<li>Resta: ".$restar."</li>";
                echo "<li>División: ".$dividir."</li>";
                echo "<li>Multiplicación: ".$multiplicar."</li></lo>";
            }
        }

        function sumar($num1, $num2){
            return $num1 + $num2;
        }

        function restar($num1, $num2){
            return $num1 - $num2;
        }

        function dividir($num1, $num2){
            return $num1 / $num2;
        }

        function multiplicar($num1, $num2){
            return $num1 * $num2;
        }
    ?>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js" integrity="sha384-oBqDVmMz9ATKxIep9tiCxS/Z9fNfEXiDAYTujMAeBAsjFuCZSmKbSSUnQlmh/jp3" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.min.js" integrity="sha384-mQ93GR66B00ZXjt0YO5KlohRA5SY2XofN4zfuZxLkoj1gXtW8ANNCe9d5Y3eG5eD" crossorigin="anonymous"></script>
</body>
</html>