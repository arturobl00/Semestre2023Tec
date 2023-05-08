<?php
    $server = "sql300.byethost7.com";
    $user = "b7_34137885";
    $password = "ns9r4xc0";
    $db = "b7_34137885_tpv";

    $conn = mysqli_connect($server,$user,$password,$db);

    if(!$conn){
        echo "Error de Conexion";
    }
?>