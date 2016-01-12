var sqlite3 = require('sqlite3').verbose()
var path = require('path')
var file = path.resolve(__dirname, 'v2ex.sqlite')
var db = new sqlite3.Database(file)
var id = process.argv[2]

db.get('SELECT * FROM v2ex WHERE id = ?', [id] , function (err, data) {
  if (err) return console.error(err.message)
  var d = new Date(data.created*1000)
  var time = d.getHours() + ':' + d.getMinutes()
  console.log('Title: ' + data.title)
  console.log('User:  ' + data.user)
  console.log('Tag:   ' + data.node)
  console.log('Time:  ' + time)
  console.log('')
  console.log(data.content.replace(/\r/g, ''))
})
