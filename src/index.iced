require "coffee-script-properties"
{EventEmitter} = require "events"

class AsyncWorkQueue extends EventEmitter

    constructor: (worker = null, @concurrency = 1) ->
        if "number" is typeof worker
            @concurrency = worker
            worker = null

        @worker = worker or @processTask

        if @concurrency <= 0
            throw new Error "Invalid initialization parameters"

        @queue =
            head: null
            tail: null
            length: 0

        @indices = []
        @slots = []

        for i in [0 .. @concurrency - 1]
            @indices[i] = null
            @slots.push i

    @getter "waiting", -> @queue.length
    @getter "length", -> @queue.length
    @getter "running", -> @concurrency - @slots.length
    @getter "working", -> (item for item in @indices when item isnt null)

    push: (task, callback) ->
        if Array.isArray task
            @push item, callback for item in task
        else
            tasklet = 
                task: task
                callback: callback
                next: null

            if @queue.tail
                @queue.tail.next = tasklet
                @queue.tail = tasklet

            if not @queue.head
                @queue.head = @queue.tail = tasklet

            @queue.length++
            @scheduleEventLoop()

    unshift: (task, callback) ->
        if Array.isArray task
            @unshift item, callback for item in task
        else
            tasklet =
                task: task
                callback: callback
                next: @queue.head

            @queue.head = tasklet
            @queue.length++

            @scheduleEventLoop()

    extractTasklet: ->
        item = @queue.head

        if @queue.head is @queue.tail
            @queue.head = @queue.tail = null
        else
            @queue.head = @queue.head.next

        @queue.length--
        return item

    scheduleEventLoop: ->
        if not @eventLoopScheduled
            @eventLoopScheduled = true
            process.nextTick @eventLoop

    eventLoop: => 
        @eventLoopScheduled = false
        while (@queue.head) and ((slot = @slots.pop()) isnt undefined)
            @runTask slot, @extractTasklet()

    runTask: (slot, tasklet) ->
        @indices[slot] = tasklet.task
        try
            @worker tasklet.task, (error, data) =>
                try
                    tasklet.callback? error, data
                catch cbex
                    @emit "callback exception", tasklet.task, cbex

                @indices[slot] = null
                @slots.push slot
                @scheduleEventLoop()
        catch ex
            @emit "error", tasklet.task, ex
            try
                tasklet.callback? ex
            catch cbex
                @emit "callback exception", tasklet.task, cbex

            @indices[slot] = null
            @slots.push slot
            @scheduleEventLoop()

    processTask: (task, callback) ->
        callback? null


module.exports = AsyncWorkQueue
