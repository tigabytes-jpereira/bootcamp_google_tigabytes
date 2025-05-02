from flask import Flask, render_template, request
import requests

app = Flask(__name__)
BACKEND_URL = environ.get('BACKEND_URL') or 'http://localhost:8080'

@app.route('/')
def index():
    response = requests.get(f'{BACKEND_URL}/tarefas')
    tarefas = response.json()
    return render_template('index.html', tarefas=tarefas)

@app.route('/adicionar', methods=['POST'])
def adicionar_tarefa():
    descricao = request.form['descricao']
    requests.post(f'{BACKEND_URL}/tarefas', json={'descricao': descricao})
    return redirect('/')

@app.route('/atualizar/<int:id>', methods=['POST'])
def atualizar_tarefa(id):
    descricao = request.form.get('descricao')
    concluida = 'concluida' in request.form
    requests.put(f'{BACKEND_URL}/tarefas/{id}', json={'descricao': descricao, 'concluida': concluida})
    return redirect('/')

@app.route('/deletar/<int:id>')
def deletar_tarefa(id):
    requests.delete(f'{BACKEND_URL}/tarefas/{id}')
    return redirect('/')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)   