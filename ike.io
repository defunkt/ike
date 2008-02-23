////
// ike: io make
Ike := Object clone do(
  tasks    := list()
  nextDesc := nil
  logging  := false
  currentNamespace := nil
)

Ike do(
  ////
  // Task object
  Task := Object clone do(
    with := method(name, body, desc,
      self setSlot("name", name) 
      self setSlot("body", body) 
      self setSlot("desc", desc)
      self setSlot("dependency")
      self
    )

    invoke := method(doMessage(body))

    after := method(dependency, 
      self dependency = dependency 
    )
  )

  ////
  // api
  task := method(name,
    if(currentNamespace) then(name = "#{currentNamespace}:#{name}" interpolate)
    tasks << Ike Task clone with(name, call message arguments last, nextDesc)
    nextDesc = nil
  )

  desc := method(description,
    nextDesc = description  
  )

  namespace := method(space,
    currentNamespace = space
    call message argAt(1) doInContext(Ike)
    currentNamespace = nil
  )

  invoke := method(target,
    log("Invoking `#{target}`")
    task := tasks detect(name == target) 
    if(target == "default" and task isNil) then(return noDefault)
    task ?invoke or invoke("default")
  )

  ////
  // guts
  log := method(line,
    if(logging) then(("=> " .. line interpolate(call sender)) println)
  )

  showTasks := method(
    longest := tasks map(name size) max
    space   := " #" 

    tasks foreach(task,
      // rake style hiding of tasks without descriptions
      if(task desc isNil) then(continue)

      ("ike " .. task name) print
      diff := longest - task name size
      " " repeated(diff + 7) print " # " print
      task desc println
    )  
  )

  noDefault := method(
    "Please define a default task, like this: task(\"default\", stuff)" println
  )

  help := method("Help en route." println)

  version := method("version -50" println)
)

////
// ext
List << := method(other, append(other))

////
// setup our dsl
list("task", "desc", "namespace") foreach(slot,
    setSlot(slot, method(call delegateTo(Ike))
  )
)

////
// built-in tasks
task("-T", Ike showTasks)
task("-h", Ike help)
task("--help", Ike help)
task("-v", Ike version)
task("--version", Ike version)

////
// load the ikefile
doFile("Ikefile")

////
// execute
if(
  System args size == 1, 
  Ike invoke("default"), 
  System args slice(1) foreach(a, Ike invoke(a))
)
