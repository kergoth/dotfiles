var PhaseList = require('../lib/phase-list');

var phaseOrder = [
  'initial',
  'preprocess',
  'parse',
  'respond'
];

var express = require('express');
var app = express();
var phases = new PhaseList();
phases.add(phaseOrder);

app.use(function(req, res, next) {
  // Run all handers in the phase list
  phases.run({
    req: req,
    res: res
  }, next);
});

function createLoggerForPhase(name) {
  return function logger(req, res, next) {
    console.log('Phase: %s, url: %s', name, req.url);
    next();
  };
}

phases.find('initial').use(function(ctx, cb) {
  createLoggerForPhase('intial')(ctx.req, ctx.res, cb);
});

phases.find('preprocess').use(function(ctx, cb) {
  createLoggerForPhase('preprocess')(ctx.req, ctx.res, cb);
});

app.get('/', function(req, res, next) {
  res.status(200).send('OK');
});

app.listen(3000);
