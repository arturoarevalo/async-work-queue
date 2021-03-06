# async-work-queue
A time &amp; memory efficient asynchronous queue written in CoffeeScript.

## Installation
```
npm install async-work-queue
```

## Description
Creates a queue object with a given concurrency level. Tasks can be added to the queue and will be processed in parallel up to the concurrency limit by a configurable worker function. If the concurrency limit is reached, this is, there're no workers available to handle new tasks, they will be queued and processed as soon a worker ends its previous task. Once a worker completes a task, its callback function will be fired.

## Performance
`AsyncWorkQueue` is a lightweight implementation of a very specific data structure focused on memory usage and performance. Compared to more general solutions, like `async`, `AsyncWorkQueue` is up to 9 times faster, consumes less memory and imposes no limits (other than your physically available memory) on the number of tasks that can be queued.

Internally `AsyncWorkQueue` uses linked lists instead of arrays to manage the list of tasks.

The `playground/speed-test.iced` test measures the overhead of using `AsyncWorkQueue` and `async.queue` over directly running the worker function and firing a callback. The test repeats 1000 times the action of queuing 1000 tasks. The results on a 2.5 GHz i7-4710 are:

* Direct invocation: 133ms = taken as reference.
* AsyncWorkQueue: 2698ms (2565ms overhead = +2.6us per task invocation).
* async.queue: 23713ms (23580ms overhead = +23.6us per task invocation).

It can be seen that `async.queue` overhead is up to 9 times the overhead of `AsyncWorkQueue`. For most applications this overhead will be negligible, but there're some edge cases, like a real-time service that serializes parallel requests through a single worker, where `AsyncWorkQueue` can be helpful.

## Usage
You can create instances of the `AsyncWorkQueue` class and override the `processTask` method or directly pass the `worker` function as a parameter to the constructor.

In CoffeeScript:
```coffeescript
AsyncWorkQueue = require "async-work-queue"

# using class inheritance
class MyQueue extends AsyncWorkQueue
    processTask: (task, callback) ->
        # do something here with the task
        callback error, result

queue = new MyQueue
queue.push "task1", (error, result) -> console.log result
queue.push "task2", (error, result) -> console.log result
queue.push "task3", (error, result) -> console.log result

# using a function 
worker = (task, callback) ->
    # do something here with the task
    callback error, result

queue = new AsyncWorkQueue worker
queue.push "task1", (error, result) -> console.log result
queue.push "task2", (error, result) -> console.log result
queue.push "task3", (error, result) -> console.log result
```

In Javascript:
```javascript
var AsyncWorkQueue = require("async-work-queue");

var worker = function (task, callback) {
    // do something here with the task
    callback(error, result);
}

var queue = new AsyncWorkQueue(worker);
queue.push("task1", function (error, result) { console.log (result) });
queue.push("task2", function (error, result) { console.log (result) });
queue.push("task3", function (error, result) { console.log (result) });
```

## Concurrency
The concurrency limit can be passed to the class constructor as a parameter. By default its value is `1`.

```coffeescript
# using class inheritance
class MyQueue
    processTask: (task, callback) ->
        # do something here with the task
        callback error, result

queue = new MyQueue 5

# using a function
worker = (task, callback) ->
    # do something here with the task
    callback error, result

queue = new AsyncWorkQueue worker, 5
```

## Methods and properties
The `AsyncWorkQueue` class has the following properties and methods:

* `length` - a read-only property with the number of tasks waiting in the queue.
* `waiting` - an alias for `length`.
* `running` - a read-only property with the number of tasks being run at the moment.
* `working` - a read-only property with the tasks (as an array) being run at the moment (`running === working.length`).
* `push(task, [callback])` - add a new task, or an array of tasks, to the end of the queue. `callback` will be called once a worker has finished processing the task. `task` can be either a single object or an array of objects. If an array is passed, all tasks will fire the same `callback` when finished.
* `unshift(task, [callback]` - same as `push`, but tasks will be added to the beginning of the queue instead of the end.

## Error handling
Any exception fired in the `worker` function will be passed as the `error` parameter to the task `callback`. Also, an `error` event will be generated with the task and the catched exception.

If the `callback` function throws any exception it will be catched and emitted as an `callback exception` event.

Example:
```coffeescript
worker = (task, callback) ->
    # this will call the callback function with an error
    # and emit an "error" event in the queue
    undefined_function()

cb = (error, result) ->
    # this will emit an "callback exception" event in the queue
    undefined_function()

queue = new AsyncWorkQueue worker
queue.on "error", (task, error) -> console.log "something weird happened while processing the task ..."
queue.on "callback exception", (task, error) -> console.log "something weird happened during the task callback ..."
```