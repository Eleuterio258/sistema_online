<?php
	session_start();
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<?php include "includes/scripts.php"; ?>
	<title>Sistema Ventas</title>
</head>
<body>
<?php 
include "includes/header.php"; 
include "../conexion.php";

//Dados da empresa
	$rfc = '';
	$nomEmpresa = '';
	$razonSocial = '';
	$telEmpresa = '';
	$emailEmpresa = '';
	$dirEmpresa = '';
	$iva = '';

	$query_empresa = mysqli_query($conection,"SELECT * FROM configuracion");
	$row_empresa = mysqli_num_rows($query_empresa);
	if($row_empresa > 0){
		
		while ($arrInfoEmpresa = mysqli_fetch_assoc($query_empresa)){
			$rfc = $arrInfoEmpresa['rfc'];
			$nomEmpresa = $arrInfoEmpresa['nombre'];
			$razonSocial = $arrInfoEmpresa['razon_social'];
			$telEmpresa = $arrInfoEmpresa['telefono'];
			$emailEmpresa = $arrInfoEmpresa['email'];
			$dirEmpresa = $arrInfoEmpresa['direccion'];
			$iva = $arrInfoEmpresa['iva'];
		}
	}

$query_dash = mysqli_query($conection,"CALL dataDashboard();");
$result_dash = mysqli_num_rows($query_dash);
if($result_dash > 0){
	$data_dash = mysqli_fetch_assoc($query_dash);
	mysqli_close($conection);
}
?>

	<section id="container">
		<div class="divContainer">
			<div>
				<h1 class="titlePanelControl">Panel de Control</h1>
			</div>
			<div class="dashboard">
				<?php if($_SESSION['rol'] == 1 || $_SESSION['rol'] == 2)
				{ ?>
				<a href="lista_usuario.php">
				<i class="fa fa-user"></i>
					<p>
						<strong>Usuarios</strong><br>
						<span><?= $data_dash['usuarios']; ?></span>
					</p>
				</a>
				<?php } ?>
				<a href="lista_cliente.php">
				<i class="fas fa-users"></i>
					<p>
						<strong>Clientes</strong><br>
						<span><?= $data_dash['clientes']; ?></span>
					</p>
				</a>
				<?php if($_SESSION['rol'] == 1 || $_SESSION['rol'] == 2)
				{ ?>
				<a href="lista_proveedor.php">
				<i class="fas fa-industry"></i>
					<p>
						<strong>Fornecedores</strong><br>
						<span><?= $data_dash['proveedores']; ?></span>
					</p>
				</a>
				<?php } ?>
				<a href="lista_producto.php">
				<i class="fas fa-boxes"></i>
					<p>
						<strong>Produtos</strong><br>
						<span><?= $data_dash['productos']; ?></span>
					</p>
				</a>
				<a href="ventas.php">
				<i class="fas fa-coins"></i>
					<p>
						<strong>Vendas</strong><br>
						<span><?= $data_dash['ventas']; ?></span>
					</p>
				</a>
			</div>
		</div>

		<div class="divInfoSistema">
			<div>
				<h1 class="titlePanelControl">Configuração</h1>
			</div>
			<div class="containerPerfil">
				<div class="containerDataUser">
					<div class="divDataUser">
						<h4>Informação pessoal</h4>
						
						<div>
							<label>Nome:</label><span><?= $_SESSION['nombre']; ?></span>
						</div>
						<div>
							<label>Email:</label><span><?= $_SESSION['email']; ?></span>
						</div>

						<h4>Dados do usuário</h4>
						<div>
							<label>Rol:</label><span><?= $_SESSION['rol_name']; ?></span>
						</div>
						<div>
							<label>Usuario:</label><span><?= $_SESSION['user']; ?></span>
						</div>

						<h4>Mudar senha</h4>
						<form action="" method="post" name="frmChangePass" id="frmChangePass">
							<div>
								<input type="password" name="txtPassUser" id="txtPassUser"
								placeholder="Senha atual" required>
							</div>
							<div>
								<input class="newPass" type="password" name="txtNewPassUser" id="txtNewPassUser"
								placeholder="Nova senha" required>
							</div>
							<div>
								<input class="newPass" type="password" name="txtPassConfirm" id="txtPassConfirm"
								placeholder="Confirmar senha" required>
							</div>
							<div class="alertChangePass" style="display: none;"></div>
							<div>
								<button type="submit" class="btn_save btnChangePass"><i class="fas fa-key"></i> Cambiar Contraseña</button>
							</div>

						</form>

					</div>
				</div>
				<?php if($_SESSION['rol'] == 1){ ?>
				<div class="containerDataEmpresa">
				<div class="logoEmpresa">
					<img src="img/logoEmp.png">
					</div>
					<h4>Dados da empresa</h4>
					<form action="" method="post" name="frmEmpresa" id="frmEmpresa">
						<input type="hidden" name="action" value="updateDataEmpresa">

							<div>
								<label>Nuit:</label><input type="text" name="txtRfc" id="txtRfc"
								placeholder="Nuit da empresa" value="<?= $rfc; ?>" required>
							</div>
							<div>
								<label>Nome:</label><input type="text" name="txtNombre" id="txtNombre"
								placeholder="Nome da empresa" value="<?= $nomEmpresa; ?>" required>
							</div>
							<div>
								<label>Razão social:</label><input type="text" name="txtRSocial" id="txtRSocial"
								placeholder="Razão social" value="<?= $razonSocial; ?>">
							</div>
							<div>
								<label>Telefone:</label><input type="text" name="txtTelEmpresa" id="txtTelEmpresa"
								placeholder="Número de telefone" value="<?= $telEmpresa; ?>" required>
							</div>
							<div>
								<label>Email:</label><input type="email" name="txtEmailEmpresa" id="txtEmailEmpresa"
								placeholder="Email" value="<?= $emailEmpresa; ?>" required>
							</div>
							<div>
								<label>Endereço:</label><input type="text" name="txtDirEmpresa" id="txtDirEmpresa"
								placeholder="Direção da empresa" value="<?= $dirEmpresa; ?>" required>
							</div>
							<div>
								<label>IVA (%):</label><input type="text" name="txtIva" id="txtIva"
								placeholder="Imposto sobre o Valor Agregado (IVA)" value="<?= $iva; ?>" required>
							</div>

							<div class="alertFormEmpresa" style="display: none;"></div>
							<div>
								<button type="submit" class="btn_save btnChangePass"><i class="fas fa-save fa-lg"></i> Guardar dados</button>
							</div>
					</form>
				</div>
				<?php } ?>
			</div>
		</div>
	</section>

	<?php include "includes/footer.php"; ?>
</body>
</html>