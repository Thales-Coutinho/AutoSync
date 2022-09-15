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
#      $ ./backup.sh
#      Com este comando o backup é executado
# ------------------------------------------------------------------------ #
# Changelog/ Registro de Alteração:
#
#   v1.0 12/08/2022, Thales Martim Coutinho:
#       - Inicio do programa
#
#   v2.0 15/09/2022, Thales Martim Coutinho;
#       - remoção automatica de backups antigos
#       - correção de problemas na conecção do Rclone
# ------------------------------------------------------------------------ #
#
# Testado em:   bash 5.1.16
#
# ------------------------------- VARIÁVEIS ------------------------------------------ #

# Informe os diretorios que deseja fazer backup
DIRETORIOS_INCLUSOS=(
'caminho/absoluto/aqui'
'caminho/absoluto/aqui'
'caminho/absoluto/aqui'
)

# Informe do ponto de montagem 
#(IMPORTANTE:certifiquise que o mesmo não esta incluso nos diretorios de Backup)
DIRETORIO_BACKUP='caminho/absoluto/aqui'

# Informe o nome do remote do Rclone que sera utilizado
RCLONE_REMOTE='backup:'

# Informe o numero de backups que deseja armazenar
NUMERO_BACKUPS='7'

# Onde os logs serão armazenados
ARQUIVO_LOG='/var/log/backup-nuvem.log'

# Formato de Hora que sera utilizado no nome do backup. (NÃO ALTERAR)
DATA=$(date "+%Y-%m-%d")
NOME_ARQUIVO=bkp-$DATA.tar.gz


# ------------------------------- TESTES -------------------------------------------- #
# É o usuario root?
[[ $(id -u) -ne "0" ]] && echo "necessario root" && exit 1

# Rclone esta instalado?
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

# Existe o diretorio de backup?
if ! test -d $DIRETORIO_BACKUP; then
    mkdir $DIRETORIO_BACKUP
    echo "diretorio $DIRETORIO_BACKUP criado"
fi
# ------------------------------- FUNÇÕES ------------------------------------------ #

# função para printar e registrar no log mensagem de erro e encerrar programa
die() { echo "$*" | tee -a $ARQUIVO_LOG ; exit 1; }

# ------------------------------- EXECUÇÃO ----------------------------------------- #

# Criação do arquivo de Backup
tar -cpPzf "$DIRETORIO_BACKUP"/"$NOME_ARQUIVO" "${DIRETORIOS_INCLUSOS[@]}" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: falha ao gerar arquivo"

echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo de backup "$NOME_ARQUIVO" gerado"| tee -a $ARQUIVO_LOG

# Envio do backup para repositorio remoto
rclone copyto "$DIRETORIO_BACKUP"/"$NOME_ARQUIVO" "$RCLONE_REMOTE""$NOME_ARQUIVO" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: falha ao enviar arquivo $NOME_ARQUIVO para a nuvem"

echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo de backup "$NOME_ARQUIVO" enviado para a nuvem"| tee -a $ARQUIVO_LOG

# numero atual de arquivos na nuvem
TOTAL_ARQUIVOS=$(rclone lsf "$RCLONE_REMOTE" | wc -l)

# remoção de arquivos obsoletos
if [[ $TOTAL_ARQUIVOS -ge  $NUMERO_BACKUPS ]]; then
   ARQUIVOS_REMOVER=$(( $TOTAL_ARQUIVOS - $NUMERO_BACKUPS ))
   for (( n=0;n<$ARQUIVOS_REMOVER;n++ )); do
      REMOVER=$(rclone lsf "$RCLONE_REMOTE" | head -n 1)
      rclone deletefile $RCLONE_REMOTE$REMOVER 
      echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo obsoleto $RCLONE_REMOTE$REMOVER removido"| tee -a $ARQUIVO_LOG
   done
   echo "[$(date +'%d-%m-%Y %T')] SUCESSO: arquivo obsoletos removidos"| tee -a $ARQUIVO_LOG
fi

echo " **Backup finalizado com sucesso!**"

# ---------------------------------------------------------------------------------- #
