import atexit
from flask import Flask
from logging.handlers import RotatingFileHandler
import time
import datetime
import time
import sys
import os
import csv
import os.path
import logging
import requests

def create_app():
	app = Flask(__name__)

	def interrupt():
		print('yello')

	def startJob():
		# main function to start the job and kep calling job queue for next job
		print('hey')

	def startJobConsumer():
		# start the job process here 
		print('Calling Queue for jobs..')
		url = 'http://localhost:4567/job'
		#url = 'http://requestb.in/17e4chq1'
		headers = {'hashValue': 'c2eed9b6c9ce28c0c96e77a2897a87de', 'agent': 1}
		stuff = requests.get(url, headers=headers).content
		# save job to list
		print(stuff)

	@app.route("/test", methods=['GET'])
	def test():
		interrupt()
		return 'ok'

	@app.route("/start", methods=['GET'])
	def test():
		# start job 
		startJob()

	@app.route("/status", methods=['GET'])
	def test():
		# get status of the job; interrupt function(?) 
		interrupt()

	# Initiate
	startJobConsumer()
	# When you kill Flask (SIGTERM), clear the trigger for the next thread
	atexit.register(interrupt)
	return app

if __name__ == "__main__":
	app = create_app()
	handler = RotatingFileHandler('error_log.log', maxBytes=10000, backupCount=1)
	handler.setLevel(logging.INFO)
	app.logger.addHandler(handler)
	app.run()
     
