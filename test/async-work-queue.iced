AsyncWorkQueue = require "../src/index"
assert = require "assert"

### JSHINT ###
### global describe:true, it:true ###

describe "AsyncWorkQueue", () ->

    timer = (duration, callback) -> setTimeout callback, duration


    it "should create", (done) ->
        queue = new AsyncWorkQueue
        done()

    
    it "should fail if concurrency is less or equal to zero", (done) ->
        try
            queue = new AsyncWorkQueue 0
        catch e
            done()
        

    it "should call each task callback with a valid result", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        worker = (task, callback) -> callback null, task
        cb = (error, result) -> 
            if "number" isnt typeof result
                return ko "invalid callback result"

            processed++
            if processed is 1000
                ok()

        queue = new AsyncWorkQueue worker
        queue.push i, cb for i in [1 .. 1000]

    
    it "should accept arrays of tasks", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        expected = 1
        worker = (task, callback) -> callback null, task
        cb = (error, result) -> 
            if result isnt expected
                return ko "out of order"

            expected = result + 1                

            processed++
            if processed is 1000
                ok()

        tasks = [1 .. 1000]

        queue = new AsyncWorkQueue worker
        queue.push tasks, cb


    it "should respect queue order", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        expected = 1
        worker = (task, callback) -> callback null, task
        cb = (error, result) -> 
            if result isnt expected
                return ko "out of order"

            expected = result + 1                

            processed++
            if processed is 1000
                ok()

        queue = new AsyncWorkQueue worker
        queue.push i, cb for i in [1 .. 1000]


    it "should work with concurrency higher than 1", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        worker = (task, callback) -> 
            if task is 11
                try
                    assert.deepEqual queue.waiting, 4
                    assert.deepEqual queue.running, 10
                    assert.deepEqual queue.working, [10, 9, 8, 7, 6, 5, 4, 3, 2, 11]
                catch e
                    ko e

            await timer 10 + (task * 5), defer error

            callback null, task

        cb = (error, result) -> 
            processed++

            if processed is 15
                return ok()


        queue = new AsyncWorkQueue worker, 10
        queue.push i, cb for i in [1 .. 15]


    it "should work if the worker function throws an exception", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        errors = 0
        worker = (task, callback) -> 
            fn = undefined
            fn()

        cb = (error, result) -> 
            if not error or result
                return ko "expecting an error in callback"

            processed++
            if processed is 1000
                if errors is 1000
                    ok()
                else
                    ko "expecting 1000 errors"

        queue = new AsyncWorkQueue worker
        queue.on "error", -> errors++
        queue.push i, cb for i in [1 .. 1000]


    it "should work if the callback function throws an exception", (done) ->
        ok = -> done()
        koCalled = false
        ko = (message) ->
            if not koCalled
                koCalled = true
                done message

        processed = 0
        errors = 0
        worker = (task, callback) -> callback null, task
        cb = (error, result) -> 
            processed++

            if result < 10
                fn = undefined
                fn()

            if processed is 10
                if errors is 9
                    ok()
                else
                    ko "expecting 9 errors"

        queue = new AsyncWorkQueue worker
        queue.on "callback exception", -> errors++
        queue.push i, cb for i in [1 .. 10]
