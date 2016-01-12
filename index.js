var sqlite3 = require('sqlite3').verbose()
var db = new sqlite3.Database('v2ex.sqlite')
var got = require('got')
var waterfall = require('waterfall-then')
var interval = process.argv[2] || 60000

db.serialize(function() {
  db.run('CREATE TABLE IF NOT EXISTS v2ex(id INTEGER, created INTEGER, user, title, node, content, PRIMARY KEY(id ASC))', function (err) {
    if (err) throw err
  })
})

process.on('exit', function () {
  db.close()
})

function insert(obj) {
  return new Promise(function(resolve, reject) {
    db.run('INSERT OR REPLACE INTO v2ex (id, user, created, title, node, content) VALUES (?, ?, ?, ?, ?, ?)',
      [obj.id, obj.member.username, obj.created, obj.title, obj.node.title, obj.content], function (err) {
      if (err) return reject(err)
      resolve()
    })
  })
}

function getMax() {
  return new Promise(function(resolve, reject) {
    db.get('SELECT MAX(created) as max FROM v2ex', function (err, data) {
      if (err) return reject(err)
      resolve(data)
    })
  })
}

function format(obj) {
  var d = new Date(obj.created*1000)
  var time = ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2)
  var tag = pad('[' +obj.node.title + ']', 14)
  return  obj.id + '|' + time + ' ' + tag + ' ' + obj.title
}

function pad(str, total) {
  var l = str.replace(/[^\x00-\xff]/g,"**").length
  if (l > total) return '...' + Array(total - 3).join(' ')
  return str + Array(total - l).join(' ')
}

var first = true
var latest = 0
var run = waterfall([function (opt) {
  return Promise.all([got('http://v2ex.com/api/topics/latest.json', opt), getMax()])
}, function (arr) {
  var response = arr[0]
  if (!response.body) return Promise.reject(new Error('no response'))
  var list = arr[0].body
  var max = arr[1] == null ? 0 : arr[1].max
  list.reverse()
  var arr = list.map(function (obj) {
    if (first || obj.created > max) console.log(format(obj))
    return insert(obj)
  })
  first = false
  return Promise.all(arr)
}])

function start() {
  run({json: true, timeout: 10000}).then(function (data) {
    setTimeout(function () {
      start()
    }, interval)
  }).catch(function (err) {
    var msg
    if (err.response && err.response.body) {
      process.stderr.write(err.response.body)
    } else {
      process.stderr.write(err.message)
    }
  })
}

start()
