#!/usr/bin/env bash
#
#------------------------------- CABAÇALHO -------------------------------------------- #
# backup_na_nuvem.sh - realiza backup dos diretorios especificados em um serviço de cloud
#
# Site:        https://github.com/Condottieri96
# Autor:       Thales Martim Coutinho
# Manutenção:  Thales Martim Coutinho
# Licença:     GNU v3.0
#
# ------------------------------------------------------------------------ #
#  Descrição:
#  Este programa realiza a compactação com tar e a compressão com gunzip dos
#  diretorios especificados, enviando o resultado para um diretorio de backup
#  e para um diretorio remoto na nuvem com o uso do Rclone, com as informação 
#  da data de criação em seu titulo.
#
#  Exemplos:
#      $ ./backup_na_nuvem.sh
#      Com este comando o backup é executado
# ------------------------------------------------------------------------ #
# Changelog/ Registro de Alteração:
#
#   v1.0 12/08/2022, Thales Martim Coutinho:
#       - Inicio do programa
# ------------------------------------------------------------------------ #
# Testado em:   bash 5.1.16
#
# ------------------------------- VARIÁVEIS ------------------------------------------ #
# Informe os diretorios que deseja fazer backup
DIRETORIOS_INCLUSOS=(
'/caminho/absoluto/aqui'
'/caminho/absoluto/aqui'
)

# Informe o diretorio onde o backup será armazenado
DIRETORIO_DESTINO='/caminho/absoluto/aqui'

# Formato de Hora que sera utilizado no nome do backup.
DATA=$(date "+%d-%m-%Y")
NOME_ARQUIVO="bkp-$DATA.tar.gz"

# Nome do remote do Rclone que sera utilizado
RCLONE_REMOTE='nome-da-configuração-aqui:'

# Onde os logs serão armazenados
ARQUIVO_LOG='/var/log/backup-nuvem.log'

# ------------------------------- TESTES -------------------------------------------- #
# É o usuario root?
[[ $(id -u) -ne "0" ]] && echo "necessario root" && exit 1

# Rclone esta instalado?
if ! command -v rclone &> /dev/null; then
    echo "Rclone não esta instalado, instale com o gerenciador de pacotes de sua preferencia
    ou consulte a documentação oficial URL: https://rclone.org/install/"
    exit 1
fi

# Rclone remote está configurado?
if ! test -f ~/.config/rclone/rclone.conf; then
    echo "Rclone não está configurado para o usuario $USER, utilize o comando (rclone config)
    caso não saiba como configurar consulte URL: https://rclone.org/docs/ "
    exit 1
fi

# Existe o diretorio onde o backup será armazenado?
if ! test -d $DIRETORIO_DESTINO; then
    mkdir $DIRETORIO_DESTINO
    echo "diretorio $DIRETORIO_DESTINO criado"
fi
# ------------------------------- FUNÇÕES ------------------------------------------ #

die() { echo "$*" | tee -a $ARQUIVO_LOG ; exit 1; }

# ------------------------------- EXECUÇÃO ----------------------------------------- #
# Criação do arquivo de Backup
tar -cpzf "$DIRETORIO_DESTINO"/"$NOME_ARQUIVO" "${DIRETORIOS_INCLUSOS[@]}" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: falha ao executar o tar"

echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo de backup gerado"| tee -a $ARQUIVO_LOG

# Envio do arquivo de Backup para a nuvem
rclone sync "$DIRETORIO_DESTINO/$NOME_ARQUIVO" "$RCLONE_REMOTE" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: falha ao utilizar o Rclone"

echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo de Backup enviado para a nuvem" | tee -a $ARQUIVO_LOG

echo " **Backup finalizado!**"

# ---------------------------------------------------------------------------------- #
