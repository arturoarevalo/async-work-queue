# async-work-queue
A time &amp; memory efficient asynchronous queue written in CoffeeScript.

## Installation
```
npm install async-work-queue
```

## Description
Creates a queue object with a given concurrency level. Tasks can be added to the queue and will be processed in parallel up to the concurrency limit by a configurable worker function. If the concurrency limit is reached, this is, there're no workers available to handle new tasks, they will be queued and processed as soon a worker ends its previous task. Once a worker completes a task, its callback function will be fired.

## Performance
`AsyncWorkQueue` is a lightweight implementation of a very specific data structure focused on memory and performance. Compared to more general solutions, like `async`, `AsyncWorkQueue` is 3 to 5 times faster, consumes less memory and imposes no limits (other than your physically available memory) on the number of tasks that can be added.

Internally `AsyncWorkQueue` uses linked lists instead of arrays to manage the list of tasks.

## Usage
You can create instances of the AsyncWorkQueue class and override the *processTask* method or directly pass the worker function as a parameter to the constructor.

In CoffeeScript:
```coffeescript
AsyncWorkQueue = require "async-work-queue"

# using class inheritance
class MyQueue
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
var AsyncWorkQueue = require "async-work-queue"

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
The concurrency limit can be passed to the class constructor as a parameter. By default its value is *1*.

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
The AsyncWorkQueue class has the following properties and methods:

* `length` - a read-only property with the number of tasks waiting in the queue.
* `waiting` - an alias for `length`.
* `running` - a read-only property with the number of tasks being run at the moment.
* `working` - a read-only property with the tasks (as an array) being run at the moment (`running === working.length`).
* `push(task, [callback])` - add a new task to the end of the queue. `callback` will be called once a worker has finished processing the task.

## Error handling
Any exception fired in the `worker` function will be passed as the `error` parameter to the Task `callback`.
