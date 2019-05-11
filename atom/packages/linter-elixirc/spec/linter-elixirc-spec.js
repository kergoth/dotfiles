'use babel';

import { join } from 'path';
// eslint-disable-next-line import/no-extraneous-dependencies
import { remove } from 'fs-extra';

const validPathElixirc = join(__dirname, 'fixtures', 'elixirc', 'valid.ex');
const warningPathElixirc = join(__dirname, 'fixtures', 'elixirc', 'warning.ex');
const errorMode1PathElixirc = join(__dirname, 'fixtures', 'elixirc', 'error-mode1.ex');
const errorMode2PathElixirc = join(__dirname, 'fixtures', 'elixirc', 'error-mode2.ex');
const exsFilePathElixirc = join(__dirname, 'fixtures', 'elixirc', 'script.exs');

const errorMode2PathMix = join(__dirname, 'fixtures', 'mix-proj', 'lib', 'error-mode2.ex');
const exsFilePathMix = join(__dirname, 'fixtures', 'mix-proj', 'lib', 'script.exs');

const mixBuildDirectory = join(__dirname, 'fixtures', 'mix-proj', '_build');
remove(mixBuildDirectory);

describe('The elixirc provider for Linter', () => {
  describe('when not working inside a Mix project', () => {
    describe('and using the standard configuration', () => {
      let lint;

      beforeEach(() => {
        lint = require('../lib/init.js').provideLinter().lint;
        atom.workspace.destroyActivePaneItem();

        waitsForPromise(() =>
          Promise.all([
            atom.packages.activatePackage('linter-elixirc'),
            atom.packages.activatePackage('language-elixir'),
          ]),
        );
      });

      it('works with mode 1 errors', () => {
        waitsForPromise(() =>
          atom.workspace.open(errorMode1PathElixirc).then(editor =>
            lint(editor)).then((messages) => {
              expect(messages.length).toBe(1);
              expect(messages[0].severity).toBe('error');
              expect(messages[0].html).not.toBeDefined();
              expect(messages[0].excerpt).toBe('(ArgumentError) Dangerous is not available');
              expect(messages[0].location.file).toBe(errorMode1PathElixirc);
              expect(messages[0].location.position).toEqual([[1, 0], [1, 32]]);
            }),
        );
      });

      it('works with mode 2 errors', () => {
        waitsForPromise(() =>
          atom.workspace.open(errorMode2PathElixirc).then(editor =>
            lint(editor)).then((messages) => {
              expect(messages.length).toBe(1);
              expect(messages[0].severity).toBe('error');
              expect(messages[0].html).not.toBeDefined();
              expect(messages[0].excerpt).toBe('(CompileError) module Usefulness is not loaded and could not be found');
              expect(messages[0].location.file).toBe(errorMode2PathElixirc);
              expect(messages[0].location.position).toEqual([[3, 2], [3, 20]]);
            }),
        );
      });

      it('works with warnings', () => {
        waitsForPromise(() =>
          atom.workspace.open(warningPathElixirc).then(editor => lint(editor)).then((messages) => {
            expect(messages.length).toBe(1);
            expect(messages[0].severity).toBe('warning');
            expect(messages[0].html).not.toBeDefined();
            expect(messages[0].excerpt).toBe('variable "prepare_for_call" does not exist and is being expanded to "prepare_for_call()", please use parentheses to remove the ambiguity or change the variable name');
            expect(messages[0].location.file).toBe(warningPathElixirc);
            expect(messages[0].location.position).toEqual([[20, 4], [20, 20]]);
          }),
        );
      });

      it('works with .exs files', () => {
        waitsForPromise(() =>
          atom.workspace.open(exsFilePathElixirc).then(editor => lint(editor)).then((messages) => {
            expect(messages.length).toBe(1);
            expect(messages[0].severity).toBe('warning');
            expect(messages[0].html).not.toBeDefined();
            expect(messages[0].excerpt).toBe('function simple_function/0 is unused');
            expect(messages[0].location.file).toBe(exsFilePathElixirc);
            expect(messages[0].location.position).toEqual([[1, 2], [1, 25]]);
          }),
        );
      });

      it('finds nothing wrong with a valid file', () => {
        waitsForPromise(() =>
          atom.workspace.open(validPathElixirc).then(editor => lint(editor)).then((messages) => {
            expect(messages.length).toBe(0);
          }),
        );
      });
    });
  });

  describe('when working inside a Mix project', () => {
    describe('and using the standard configuration', () => {
      let lint;

      beforeEach(() => {
        lint = require('../lib/init.js').provideLinter().lint;
        atom.workspace.destroyActivePaneItem();

        waitsForPromise(() =>
          Promise.all([
            atom.packages.activatePackage('linter-elixirc'),
            atom.packages.activatePackage('language-elixir'),
          ]),
        );
      });

      it('works with mode 2 errors', () => {
        waitsForPromise(() =>
          atom.workspace.open(errorMode2PathMix).then(editor =>
            lint(editor)).then((messages) => {
              expect(messages.length).toBe(1);
              expect(messages[0].severity).toBe('error');
              expect(messages[0].html).not.toBeDefined();
              expect(messages[0].excerpt).toBe('(CompileError) Identicon.Image.__struct__/1 is undefined, cannot expand struct Identicon.Image');
              expect(messages[0].location.file).toBe(errorMode2PathMix);
              expect(messages[0].location.position).toEqual([[11, 4], [11, 30]]);
            }),
        );
      });

      it('works with .exs files', () => {
        waitsForPromise(() =>
          atom.workspace.open(exsFilePathMix).then(editor => lint(editor)).then((messages) => {
            expect(messages.length).toBe(1);
            expect(messages[0].severity).toBe('warning');
            expect(messages[0].html).not.toBeDefined();
            expect(messages[0].excerpt).toBe('function simple_function/0 is unused');
            expect(messages[0].location.file).toBe(exsFilePathMix);
            expect(messages[0].location.position).toEqual([[1, 2], [1, 25]]);
          }),
        );
      });
    });
  });
});

describe('when using the setting forceElixirc', () => {
  let lint;

  beforeEach(() => {
    atom.config.set('linter-elixirc.forceElixirc', true);
    lint = require('../lib/init.js').provideLinter().lint;
    atom.workspace.destroyActivePaneItem();

    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-elixirc'),
        atom.packages.activatePackage('language-elixir'),
      ]),
    );
  });

  it('works with warnings', () => {
    waitsForPromise(() =>
      atom.workspace.open(errorMode2PathMix).then(editor => lint(editor)).then((messages) => {
        expect(messages.length).toBe(1);
        expect(messages[0].severity).toBe('error');
        expect(messages[0].html).not.toBeDefined();
        expect(messages[0].excerpt).toBe('(CompileError) Identicon.Image.__struct__/1 is undefined, cannot expand struct Identicon.Image');
        expect(messages[0].location.file).toBe(errorMode2PathMix);
        expect(messages[0].location.position).toEqual([[11, 4], [11, 30]]);
      }),
    );
  });
});
