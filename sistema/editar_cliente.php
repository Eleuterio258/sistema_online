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

            $idCliente = $_POST['id'];
            $rfc = $_POST['rfc'];
            $nombre = $_POST['nombre'];
            $telefono = $_POST['telefono'];
            $email = ($_POST['correo']);
            $direccion = $_POST['direccion'];

            $result= 0;
            if(($rfc))
            {
                $query = mysqli_query($conection,"SELECT * FROM cliente 
                                                                WHERE (rfc = '$rfc' AND idcliente != $idCliente) 
                                                                ");
                $result = mysqli_fetch_array($query);
                
        }
                    if($result > 0){
                $alert='<p class="msg_error">El RFC ya existe, ingrese otro.</p>';
            }else{
                    $sql_update = mysqli_query($conection, "UPDATE cliente
                                                            SET rfc = '$rfc', nombre = '$nombre', telefono = '$telefono', correo = '$email', direccion = '$direccion'
                                                            WHERE idcliente= $idCliente");
            
                if($sql_update){
                    $alert='<p class="msg_save">Cliente actualizado correctamente.</p>';
                }else{
                    $alert='<p class="msg_error">Error al actualizar el cliente.</p>';
                }
            }
    }
}

//Mostrar datos
    if(empty($_REQUEST['id']))
    {
        header('Location: lista_cliente.php');
        mysqli_close($conection);
    }
    $idcliente = $_REQUEST['id'];

    $sql = mysqli_query($conection,"SELECT * FROM cliente WHERE idcliente= $idcliente and estatus = 1");

    mysqli_close($conection);
    $result_sql = mysqli_num_rows($sql);

    if($result_sql == 0){
            header('Location: lista_cliente.php');
    }else{
        while($data = mysqli_fetch_array($sql)){

            $idcliente = $data['idcliente'];
            $rfc = $data['rfc'];
            $nombre = $data['nombre'];
            $telefono = $data['telefono'];
            $email = $data['correo'];
            $direccion = $data['direccion'];
    
        }
    }
?>

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<?php include "includes/scripts.php"; ?>
	<title>Actualizar Cliente</title>
</head>
<body>
<?php include "includes/header.php"; ?>
	<section id="container">

		<div class="form_register">
        <h1>Actualizar Cliente</h1>
        <hr> 
        <div class="alert"><?php echo isset($alert) ? $alert : ''; ?></div>

        <form action="" method="post">
            <input type="hidden" name="id" value="<?php echo $idcliente; ?>">
            <label for="rfc">Nuit</label>
            <input type="text" name="rfc" id="rfc" placeholder="Numero de nuit" value="<?php echo $rfc; ?>">
            <label for="nombre">Nome</label>
            <input type="text" name="nombre" id="nombre" placeholder="Nome Completo" value="<?php echo $nombre; ?>">
            <label for="telefono">Telefono</label>
            <input type="number" name="telefono" id="telefono" placeholder="Telefono" value="<?php echo $telefono; ?>">
            <label for="correo">Email</label>
            <input type="email" name="correo" id="correo" placeholder="Email" value="<?php echo $email; ?>">
            <label for="direccion">Endereço</label>
            <input type="text" name="direccion" id="direccion" placeholder="Endereço" value="<?php echo $direccion; ?>">
           
         
            <input type="submit" value="Actualizar Cliente" class="btn_save">
            
        </form>
</div>
    	</section>

	<?php include "includes/footer.php"; ?>
</body>
</html>