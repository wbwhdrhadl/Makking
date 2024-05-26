# 디렉토리와 명령어를 정의합니다.
NODE_BACKEND_DIR=node_backend
MAKKING_APP_DIR=makking_app
NODE_CMD=node server.js
FLASK_CMD=flask run

# 프로세스 ID를 저장할 파일을 정의합니다.
NODE_PID_FILE=node_backend_pid.txt
FLASK_PID_FILE=flask_pid.txt

.PHONY: start stop

start: start_node start_flask

start_node:
	@echo "Starting Node.js server..."
	@cd $(NODE_BACKEND_DIR) && $(NODE_CMD) & echo $$! > ../$(NODE_PID_FILE)
	@echo "Node.js server started with PID `cat $(NODE_PID_FILE)`"

start_flask:
	@echo "Starting Flask app..."
	@cd $(MAKKING_APP_DIR) && $(FLASK_CMD) & echo $$! > ../$(FLASK_PID_FILE)
	@echo "Flask app started with PID `cat $(FLASK_PID_FILE)`"

stop: stop_node stop_flask

stop_node:
	@echo "Stopping Node.js server..."
	@if [ -f $(NODE_PID_FILE) ]; then \
		kill `cat $(NODE_PID_FILE)` && rm $(NODE_PID_FILE); \
		echo "Node.js server stopped"; \
	else \
		echo "Node.js server PID file not found"; \
	fi

stop_flask:
	@echo "Stopping Flask app..."
	@if [ -f $(FLASK_PID_FILE) ]; then \
		kill `cat $(FLASK_PID_FILE)` && rm $(FLASK_PID_FILE); \
		echo "Flask app stopped"; \
	else \
		echo "Flask app PID file not found"; \
	fi
