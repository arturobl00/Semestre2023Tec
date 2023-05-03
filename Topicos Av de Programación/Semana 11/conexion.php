<?php
    $server = "localhost";
    $user = "root";
    $pass = "";
    $bd = "tpv";

    $conn = mysqli_connect($server, $user, $pass, $bd);

    if(!$conn){
        echo "Error de conexion";
    }
?>