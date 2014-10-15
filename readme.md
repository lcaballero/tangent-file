[![Build Status](https://travis-ci.org/lcaballero/tangent-file.svg?branch=master)](https://travis-ci.org/) [![NPM version](https://badge.fury.io/js/tangent-file.svg)](http://badge.fury.io/js/tangent-file)

# Introduction

This lib produces what I would call a separate, one off, log files for some
specific error or purpose.  The idea is to output 'more' information to
this file and prevent the normal log from becoming too noisy.

To prevent this new 'tangent' logging from becoming too noisy this lib
debounces the number of writes it attempts during a period of time.
There are a number of configuration properties, so take a look at the usage.


## Installation

```
%> npm install tangent-file --save
```


## Usage

A simple and typical usage is below.  This uses the default values to setup
the TangentFile and then calls .write(String) to push data into a file.

```
config = {}

t = new TangentFile(config)

/**
 *  This check and bit of code then might get hit often as a process or web
 *  server is running.  The tangent file will bounce the request to write
 *  and only write once during a given period.
 */
if err?
  t.write(...some json..., (err, isWritten) -> )
```

### Configuration

The defaults:

```
defaults =
  outDirectory      : '~/tmp'
  startingNumber    : 1
  name              : 'tangent'
  number            : null
  maxFiles          : 10
  debounceDelay     : 1000      # 1 second
  filenameTemplate  : "{name}-{number}.log"
```

The `TangentFile` constructor can accept a configuration object and will
recognize the following properties:

#### outDirectory
The directory where new tangent files will be written for this instance

#### startingNumber
The default template for the tangent file is something like
'{name}-{number}.log' and `startingNumber` will be the value used as
the first 'number'

#### name
This value will be interpolated into the file name.  The default filename
template is '{name}-{number}.log' and so given a `name` of 'activity-errors'
and a `number` of `12` would produce a new long name 'activity-errors-12.log'.

#### number
This value will be interpolated into the file name.  The default filename
template is '{name}-{number}.log' and so given a `name` of 'tangent'
and a `number` of `12` would produce a new long name 'tangent-12.log'.

#### maxFiles
When the number of logs exceeds this number the value interpolated into the
log file name will roll and start again at the value held by `startingNumber`.

#### debounceDelay
A file is writen only if it's outside this delay.  So given a delay of 10seconds
then ten seconds after the last write will another write actually occur.

#### filenameTemplate
This value is a string which will be used to create new file names.  It
it uses a mini templating system that will substitute the keys surrounding
by '{' and '}' with the values for those keys.  Right now the map/object
that is used is the consists only of the 'name' provided during instantiation
and a number that increments internally.  (May include more in the future).


## License

See license file.

The use and distribution terms for this software are covered by the
[Eclipse Public License 1.0][EPL-1], which can be found in the file 'license' at the
root of this distribution. By using this software in any fashion, you are
agreeing to be bound by the terms of this license. You must not remove this
notice, or any other, from this software.


[EPL-1]: http://opensource.org/licenses/eclipse-1.0.txt

