#!/usr/bin/env bash
#
#------------------------------- CABEÇALHO -------------------------------------------- #
# backup_na_nuvem.sh - realiza backup dos diretorios especificados em um serviço de cloud
#
# Site:    	https://github.com/Condottieri96
# Autor:   	Thales Martim Coutinho
# Manutenção:  Thales Martim Coutinho
# Licença: 	GNU v3.0
#
# ------------------------------------------------------------------------ #
#  Descrição:
#  Este programa realiza a compactação com tar e a compressão com gunzip dos
#  diretórios especificados, enviando o resultado para um diretório remoto
#  na nuvem com o uso do Rclone, também permite a remoção automatica de arquivos
#  Obsoletos.
#
#  Exemplos:
#  	$ ./backup.sh
#  	Com este comando o backup é executado
# ------------------------------------------------------------------------ #
# Changelog/ Registro de Alteração:
#
#   v1.0 12/08/2022, Thales Martim Coutinho:
#   	- Inicio do programa.
#
#   v1.1 15/09/2022, Thales Martim Coutinho;
#   	- remoção automática de backups antigos.
#   	- correção de problemas na conexão do Rclone.
#
#   v1.2 04/03/2023, Thales Martim Coutinho;
#   	- Envio automático para o Repositório remoto,
#     	dispensando arquivo intermediário local e aumentando a performance.
#   	- Dispensa a necessidade de constar a data de criação no Nome do arquivo.
# ------------------------------------------------------------------------ #
#
#  Testado em:   bash 5.2.15
#
# ------------------------------- VARIÁVEIS ------------------------------------------ #

# Informe os diretórios que deseja fazer backup
DIRETORIOS_INCLUSOS=(
'/Caminho/absoluto/aqui'
'/Caminho/absoluto/aqui'
'/Caminho/absoluto/aqui'
)

# Informe o nome do remote do Rclone que será utilizado
RCLONE_REMOTE='Nome_Remote:Caminho/absoluto/aqui'

# Onde os logs serão armazenados
ARQUIVO_LOG='/Caminho/absoluto/aqui'

# Informe o número de backups que deseja armazenar
NUMERO_BACKUPS='7'

# Formato de Hora que será utilizado no nome do backup.
DATA=$(date "+%d-%m-%Y")
NOME_ARQUIVO=bkpTeste-$DATA.tar.gz


# ------------------------------- TESTES -------------------------------------------- #

# Rclone está instalado?
if ! command -v rclone &> /dev/null; then
	echo "Rclone não esta instalado, instale com o gerenciador de pacotes de sua distribuição
	ou consulte a documentação oficial URL: https://rclone.org/install/"
	exit 1
fi

# Rclone remote está configurado?
if ! test -f ~/.config/rclone/rclone.conf; then
	echo "Rclone não está configurado para o usuario $USER, utilize o comando (rclone config),
	caso não saiba como configurar consulte URL: https://rclone.org/docs/ "
	exit 1
fi
# ------------------------------- FUNÇÕES ------------------------------------------ #

# função para printar e registrar no log mensagem de erro e encerrar programa
die() { echo "$*" | tee -a $ARQUIVO_LOG ; exit 1; }

# ------------------------------- EXECUÇÃO ----------------------------------------- #

# Criação do arquivo de Backup e enviando para diretorio remoto
tar -cpPzf - "${DIRETORIOS_INCLUSOS[@]}" | rclone rcat "$RCLONE_REMOTE""$NOME_ARQUIVO" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: falha ao gerar arquivo"

echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo de backup "$NOME_ARQUIVO" enviado"| tee -a $ARQUIVO_LOG

# número atual de arquivos na nuvem
TOTAL_ARQUIVOS=$(rclone lsf "$RCLONE_REMOTE" | wc -l)

# remoção de arquivos obsoletos
if [[ $TOTAL_ARQUIVOS -ge  $NUMERO_BACKUPS ]]; then
   ARQUIVOS_REMOVER=$(( $TOTAL_ARQUIVOS - $NUMERO_BACKUPS ))
   for (( n=0;n<$ARQUIVOS_REMOVER;n++ )); do
  	REMOVER=$(rclone lsjson "$RCLONE_REMOTE" --files-only | jq -r '.[] | "\(.ModTime) \(.Name)"' | sort | head -n 1 | cut -d' ' -f2-)
  	rclone deletefile "$RCLONE_REMOTE""$REMOVER"
  	echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo obsoleto $RCLONE_REMOTE$REMOVER removido"| tee -a $ARQUIVO_LOG
   done
   echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo obsoletos removidos"| tee -a $ARQUIVO_LOG
fi

echo " **Backup finalizado com sucesso!**"

# ---------------------------------------------------------------------------------- #


