<?php
    session_start();

    include "../conexion.php";

    if(!empty($_POST))
    {
        $alert='';
        if(empty($_POST['nombre']) || empty($_POST['telefono']) || empty($_POST['direccion']))
        {
            $alert='<p class="msg_error">Todos los campos son obligatorios.</p>';
        }else{

            $rfc = $_POST['rfc'];
            $nombre = $_POST['nombre'];
            $telefono = $_POST['telefono'];
            $direccion = $_POST['direccion'];
            $email = $_POST['correo'];
            $usuario_id = ($_SESSION['idUser']);
            
            $result = 0;

            if(($rfc))
            {
                $query = mysqli_query($conection,"SELECT * FROM cliente WHERE rfc = '$rfc' ");
                $result = mysqli_fetch_array($query);
                }
            if($result > 0){
                $alert='<p class="msg_error">El número de RFC ya existe.</p>';
            }else{
                $query_insert = mysqli_query($conection,"INSERT INTO cliente(rfc,nombre,telefono,correo,direccion,usuario_id)
                                                        VALUES('$rfc','$nombre','$telefono','$email','$direccion','$usuario_id')");

                if($query_insert){
                    $alert='<p class="msg_save">Cliente guardado correctamemte.</p>';
                }else{
                    $alert='<p class="msg_error">Error al guardar cliente.</p>';
                }
            }
    }
    mysqli_close($conection);     
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<?php include "includes/scripts.php"; ?>
	<title>Registro Cliente</title>
</head>
<body>
<?php include "includes/header.php"; ?>
	<section id="container">

		<div class="form_register">
        <h1><i class="fas fa-user-plus"></i> Registro Cliente</h1>
        <hr> 
        <div class="alert"><?php echo isset($alert) ? $alert : ''; ?></div>

        <form action="" method="post">
            <label for="rfc">Nuit</label>
            <input type="text" name="rfc" id="rfc" placeholder="Número de Nuit">
            <label for="nombre">Nome</label>
            <input type="text" name="nombre" id="nombre" placeholder="Nome Completo">
            <label for="telefono">Telefone</label>
            <input type="number" name="telefono" id="telefono" placeholder="Telefone">
            <label for="correo">Email</label>
            <input type="email" name="correo" id="correo" placeholder="Email">
            <label for="direccion">Endereço</label>
            <input type="text" name="direccion" id="direccion" placeholder="Endereço completo">
           
         
            <input type="submit" class="btn_save"  value= "Guardar Cliente">
            
        </form>

    	</section>

	<?php include "includes/footer.php"; ?>
</body>
</html>