# Description
#   A hubot script that silences sensu on servers
#
# Configuration:
#   HUBOT_SENSU_URL - the sensu url and port.
#
# Commands:
#   hubot sensu silence <server> <check>
#   hubot sensu silence <server>
#   hubot sensu clear <server>
#   hubot sensu get silenced
#   hubot sensu status <server>
# /silenced/subscriptions/:subscription
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   jony.cohenjo@gmail.com


sensu_url=process.env.HUBOT_SENSU_URL

module.exports = (robot) ->
    states = {}
    robot.brain.set 'states', states

    status_server = (res) ->
        smatch = res.match[1]
        server = smatch.replace(/^https?\:\/\//i, "");
        
        uri="http://"+sensu_url+"/silenced/subscriptions/client:"+server
        robot.logger.info "getting #{uri}"
        robot.http(uri)
            .header('Content-Type', 'application/json')
            .header('Accept', 'application/json')
            .get() (err, ress, body) ->
                if err
                    res.reply "Encountered an error :( #{err}"
                    return
                if ress.statusCode isnt 200
                    res.reply "Request didn't come back HTTP 200 :("
                    res.send "got " + ress.statusCode + " instead "
                    return
                
                # your code here, knowing it was successful
                if body.length is 0
                    # the array is defined and has at least one element
                    res.send "the server is not silenced"
                    return
                
                data = JSON.parse body
                res.send "The following checks are silenced:"
                checks = data.map (silenced) -> silenced.check
                res.send "#{checks}"   
    
    silence_check = (res) ->
        smatch = res.match[1]
        scheck = res.match[2]
        server = smatch.replace(/^https?\:\/\//i, "");
        
        data = JSON.stringify({
            subscription: 'client:'+server
            , check: scheck
            , reason: 'asked to'
            , creator: 'dbbot'
            , expire: 900 
        })        
        robot.logger.info "silencing check server  #{data}"
        robot.http("http://"+sensu_url+"/silenced")
            .header('Content-Type', 'application/json')
            .post(data) (err, ress, body) ->
                if err
                    res.reply "Encountered an error :( #{err}"
                    return
                if ress.statusCode isnt 201
                    res.reply "Request didn't come back HTTP 201 :("
                    res.send "got " + ress.statusCode + " instead "
                    return
                
                # your code here, knowing it was successful
                res.reply "server check silenced."
            res.reply "while we wait - it's important to remember that life is short."
    silence_server = (res) ->
        smatch = res.match[1]
        server = smatch.replace(/^https?\:\/\//i, "");        
        data = JSON.stringify({
            subscription: 'client:'+server
            , reason: "Asked to"
            , creator: "dbbot"
            , expire: 900 
        })
        robot.http("http://"+sensu_url+"/silenced")
            .header('Content-Type', 'application/json')
            .post(data) (err, ress, body) ->
                if err
                    res.reply "Encountered an error :( #{err}"
                    return
                if ress.statusCode isnt 201
                    res.reply "Request didn't come back HTTP 201 :("
                    res.send "got " + ress.statusCode + " instead "
                    return
                
                # your code here, knowing it was successful
                res.reply "server silenced."
            res.reply "while we wait - it's important to remember that life is short."

    clear_server = (res) ->
        smatch = res.match[1]
        server = smatch.replace(/^https?\:\/\//i, "");
        res.reply "Did you try turning " + server + " on  again?"
        data = JSON.stringify({
            subscription: 'client:'+server
        })
        robot.logger.info "clearing server  #{data}"
        robot.http("http://"+sensu_url+"/silenced/clear")
            .header('Content-Type', 'application/json')
            .post(data) (err, ress, body) ->
                if err
                    res.reply "Encountered an error :( #{err}"
                    return
                if ress.statusCode isnt 204
                    res.reply "Request didn't come back HTTP 204 :("
                    res.send "got " + ress.statusCode + " instead "
                    return
                
                # your code here, knowing it was successful
                res.reply "Cleared as requested."
            res.reply "while we wait - Did you try turning  off your head?"

    get_silenced = (res) ->        
        robot.http("http://"+sensu_url+"/silenced")
        .header('Accept', 'application/json')
        .get() (err, ress, body) ->
            if err
                res.reply "Encountered an error :( #{err}"
                return
            if ress.statusCode isnt 200
                res.reply "Request didn't come back HTTP 200 :("
                return
            
            # your code here, knowing it was successful
            data = JSON.parse body

            String::startsWith ?= (s) -> @[...s.length] is s
            data = data.filter (x) -> x.subscription?  and x.subscription.startsWith('client:db')
            message = 'The following db servers are silenced: \n '
            message = data.reduce(((message, silenced_server) ->  message = message+ silenced_server.subscription + '.\n')            
            , message)
            res.send message
        res.reply "while we wait - think about your mortality."

    silence_thread = (res) ->
        thread_t = res.message.thread_ts
        res.reply "the following servers are silenced: #{res.message.text}"
        res.reply "the following message was sent in a thread: #{thread_t}"

    # robot.respond /silence this$/, silence_thread
    robot.respond /sensu silence (.+) (.+)$/, silence_check
    robot.respond /sensu silence (.+)$/, silence_server
    robot.respond /sensu status (.+)$/, status_server
    robot.respond /sensu clear (.+)$/, clear_server
    robot.respond /sensu get silenced$/, get_silenced
    