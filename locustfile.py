# This is a "configuration" file for the Locust load tester. http://locust.io

# Quick Start:
#   * pip3 install locust
#   * cd into the directory containing this file
#   * locust
#   * go to http://localhost:8089

import time
from locust import HttpUser, task, between

class PlaygroundUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def index_page(self):
        self.client.get('/')

    @task
    def error(self):
        self.client.get('/error')

    @task
    def compile(self):
        self.client.post('/run', data={'main-code': 'format-out("test")'})

    # @task(3)
    # def view_item(self):
    #     for item_id in range(10):
    #         self.client.get(f"/item?id={item_id}", name="/item")
    #         time.sleep(1)

    # def on_start(self):
    #     self.client.post("/login", json={"username":"foo", "password":"bar"})
