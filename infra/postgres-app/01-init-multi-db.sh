#!/bin/sh
# ^ Shebang: diz ao Linux para executar este arquivo usando o interpretador /bin/sh.
# No postgres:16-alpine, /bin/sh existe e é o mais compatível.

set -eu
# set -e  -> se qualquer comando falhar (exit code != 0), o script para imediatamente
# set -u  -> se você usar uma variável não definida (ex: $TARGETING_DB vazio), o script falha
# Resultado: evita "meio funcionamento" e deixa erro óbvio no log.

echo "[init] FLAGS_DB=${FLAGS_DB}"
echo "[init] TARGETING_DB=${TARGETING_DB}"
# Apenas logs para você enxergar no docker compose logs se as variáveis chegaram
# e se o script realmente está sendo executado.

# cria targeting_db se não existir
if ! psql -U "$POSTGRES_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='${TARGETING_DB}'" | grep -q 1; then
  # psql                -> cliente do Postgres (CLI) para executar SQL
  # -U "$POSTGRES_USER" -> usuário (role) para autenticar no Postgres
  # -d postgres         -> conecta no banco padrão "postgres" (sempre existe)
  # -t                  -> "tuples only": remove cabeçalho/formatos, deixa saída enxuta
  # -A                  -> "unaligned": saída sem alinhamento (melhor pra usar em script)
  # -c "SQL"            -> executa o SQL passado na string
  #
  # SQL consulta o catálogo pg_database para ver se já existe um DB com aquele nome.
  #
  # O "!" na frente do psql significa: inverte o resultado do comando no if.
  # E o pipe "| grep -q 1" verifica se veio "1" na saída.
  # Se NÃO veio 1, significa "não existe ainda", então entra no bloco.

  echo "[init] Creating database ${TARGETING_DB}..."
  createdb -U "$POSTGRES_USER" "$TARGETING_DB"
  # createdb -> utilitário CLI que cria um database.
  # -U       -> usuário que executa a criação.
  # "$TARGETING_DB" -> nome do banco a ser criado.
fi

echo "[init] Applying schema to ${FLAGS_DB}..."
psql -U "$POSTGRES_USER" -d "$FLAGS_DB" -v ON_ERROR_STOP=1 -f /opt/schema/flags.sql
# psql -f /opt/schema/flags.sql  -> executa o arquivo SQL montado no container
# -d "$FLAGS_DB"                 -> executa no banco flags_db
# -v ON_ERROR_STOP=1             -> se qualquer comando SQL der erro, o psql termina com erro
#                                  (sem isso, alguns erros podem não abortar como você espera)

echo "[init] Applying schema to ${TARGETING_DB}..."
psql -U "$POSTGRES_USER" -d "$TARGETING_DB" -v ON_ERROR_STOP=1 -f /opt/schema/targeting.sql
# Mesma ideia, mas aplicando o schema no banco targeting_db.

echo "[init] Done."
# Log final pra confirmar que passou por tudo sem falhar.