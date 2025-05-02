from flask import Flask, jsonify, request
from google.cloud import spanner
import uuid
import os

app = Flask(__name__)

SPANNER_PROJECT = os.environ.get('SPANNER_PROJECT')
SPANNER_INSTANCE = os.environ.get('SPANNER_INSTANCE')
SPANNER_DATABASE = os.environ.get('SPANNER_DATABASE')

client = spanner.Client(project=SPANNER_PROJECT)
instance = client.instance(SPANNER_INSTANCE)
database = instance.database(SPANNER_DATABASE)

def listar_tarefas_spanner():
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql("SELECT id, descricao, concluida FROM Tarefas")
        tarefas = [{"id": row[0], "descricao": row[1], "concluida": row[2]} for row in results]
        return tarefas

def criar_tarefa_spanner(descricao):
    tarefa_id = str(uuid.uuid4())
    with database.transaction() as transaction:
        transaction.execute_update(
            "INSERT INTO Tarefas (id, descricao, concluida) VALUES (@id, @descricao, FALSE)",
            params={"id": tarefa_id, "descricao": descricao},
        )
    return tarefa_id

def atualizar_tarefa_spanner(tarefa_id, descricao=None, concluida=None):
    updates = []
    params = {"id": tarefa_id}
    if descricao is not None:
        updates.append("descricao = @descricao")
        params["descricao"] = descricao
    if concluida is not None:
        updates.append("concluida = @concluida")
        params["concluida"] = concluida

    if not updates:
        return False

    update_statement = f"UPDATE Tarefas SET {', '.join(updates)} WHERE id = @id"
    with database.transaction() as transaction:
        row_count = transaction.execute_update(update_statement, params=params)
    return row_count > 0

def deletar_tarefa_spanner(tarefa_id):
    with database.transaction() as transaction:
        row_count = transaction.execute_update("DELETE FROM Tarefas WHERE id = @id", params={"id": tarefa_id})
    return row_count > 0

@app.route('/tarefas', methods=['GET'])
def listar_tarefas():
    tarefas = listar_tarefas_spanner()
    return jsonify(tarefas)

@app.route('/tarefas', methods=['POST'])
def criar_tarefa():
    data = request.get_json()
    tarefa_id = criar_tarefa_spanner(data['descricao'])
    return jsonify({'mensagem': 'Tarefa criada com sucesso!', 'id': tarefa_id}), 201

@app.route('/tarefas/<string:id>', methods=['PUT'])
def atualizar_tarefa(id):
    data = request.get_json()
    atualizado = atualizar_tarefa_spanner(id, data.get('descricao'), data.get('concluida'))
    if atualizado:
        return jsonify({'mensagem': 'Tarefa atualizada com sucesso!'})
    return jsonify({'mensagem': 'Tarefa não encontrada!'}), 404

@app.route('/tarefas/<string:id>', methods=['DELETE'])
def deletar_tarefa(id):
    deletado = deletar_tarefa_spanner(id)
    if deletado:
        return jsonify({'mensagem': 'Tarefa deletada com sucesso!'})
    return jsonify({'mensagem': 'Tarefa não encontrada!'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)