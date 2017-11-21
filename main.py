from flask import Flask, render_template, request
from werkzeug.exceptions import BadRequest
import sqlite3
import time

app = Flask(__name__)

@app.route('/', methods = ['POST', 'GET'])
def add_or_view():
	if request.method == 'POST':
		name = request.form['name']
		score = request.form['score']
		return post_new_score(name, score)
	elif request.method == 'GET':
		return get_table()

def post_new_score(name, score):
	try:
		if len(name) > 8 or int(score) > 999999:
			raise BadRequest("invalid parameters (1)")
	except:
		raise BadRequest("invalid parameters (1)")
	try:
		with sqlite3.connect("highscores.db") as con:
			cur = con.cursor()
			cur.execute("INSERT INTO scores (name,date,score) VALUES (?,?,?)",(name,int(time.time()),score))
			con.commit()
	except:
		con.rollback()
		raise
	finally:
		con.close()
		return get_table()

def get_table():
	con = sqlite3.connect("highscores.db")
	con.row_factory = sqlite3.Row
	cur = con.cursor()
	cur.execute("select name,score from scores order by score desc limit 5")
	rows = cur.fetchall()
	names = [str(row["name"]) for row in rows]
	scores = [row["score"] for row in rows]
	return '{"names":%s,"scores":%s}' % (str(names), str(scores))

if __name__ == '__main__':
  app.run()
