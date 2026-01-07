from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Hello from DevOps — Auto-Deployed!",
        "status": "success",
        "project": "flask-hello-devops"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
print('CI/CD test')
