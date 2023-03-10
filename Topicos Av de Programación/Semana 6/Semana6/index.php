<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Trabajando con Sentencias</title>
</head>
<body>
    <h1>Sentencia IF</h1>
    <h2>IF Simple</h2>
    <?php
        $dato1 = 10;
        echo "<p>Preguntar si dato1 = 10 Respondiendo si es igual a 10</p>";
        if ($dato1 == 10){
            echo "<p>Respuesta: Si es Igual a 10</p>";
        }
    ?>
    <h2>IF ELSE Simple</h2>
    <?php
        $dato2 = 11;
        echo "<p>Preguntar si dato1 = 10 Respondiendo si es igual a 10 o no es igual</p>";
        if ($dato2 == 10){
            echo "<p>Respuesta: Si es Igual a 10</p>";
        }
        else{
            echo "<p>Respuesta: No es Igual a 10</p>";
        }
    ?>
    <h2>IF ANIDADO IF ELSEIF</h2>
    <?php
        $dato2 = 11;
        echo "<p>Preguntar si Dato es positivo, negativo o neutro</p>";
        if ($dato2 == 0){
            echo "<p>Respuesta: Es Neutro</p>";
        }
        else{
            if($dato2 > 1){
                echo "<p>Respuesta: Es Positivo</p>";
            }
            else{
                echo "<p>Respuesta: Es Negativo</p>";
            }
        }
    ?>
    <h2>IF CON OPERADORES LOGICOS</h2>
    <?php
        $dato2 = 1001;
        echo "<p>Preguntar si Dato es Unidad, Decena, Centena, Millar o Ninguno</p>";
        if($dato2 >= 1 and $dato2 <10){
            echo "<p>Es Unidad</p>";
        }
        else{
            if($dato2 >= 10 and $dato2 <100){
                echo "<p>Es Decena</p>";
            }
            else{
                if($dato2 >= 100 and $dato2 <1000){
                    echo "<p>Es Centena</p>";
                }
                else{
                    if($dato2 >= 1000 and $dato2 <10000){
                        echo "<p>Es Millar</p>";
                    }
                    else{
                        echo "no se que es";
                    }
                }
            }    
        } 
    ?>
</body>
</html>