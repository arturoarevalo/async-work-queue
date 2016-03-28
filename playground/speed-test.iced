AsyncWorkQueue = require "../src/index"
async = require "async"

ITEMS = 1000
REPETITIONS = 10000
TESTS = []
TEST = null
DONE = 0
REPETITION = 0


scheduleNextTest = ->
    if TEST
        console.timeEnd TEST.name

    TEST = TESTS.pop()

    if TEST
        DONE = 0
        REPETITION = 0
        console.time TEST.name
        TEST.fn()

worker = (task, callback) ->
    callback null

taskCallback = (error, result) ->
    DONE++
    if DONE is ITEMS
        REPETITION++
        DONE = 0
        if REPETITION is REPETITIONS
            process.nextTick scheduleNextTest
        else
            # prevent stack from growing
            process.nextTick TEST.fn


# AsyncWorkQueue test
TESTS.push
    name: "AsyncWorkQueue"
    fn: ->
        queue = new AsyncWorkQueue worker
        for i in [1 .. ITEMS]
            queue.push i, taskCallback

# async.queue test
TESTS.push
    name: "async.queue"
    fn: ->
        queue = async.queue worker
        for i in [1 .. ITEMS]
            queue.push i, taskCallback

# DIRECT invokation test
TESTS.push
    name: "direct"
    fn: ->
        for i in [1 .. ITEMS]
            worker i, taskCallback



scheduleNextTest()
