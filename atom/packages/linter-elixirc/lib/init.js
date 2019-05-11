'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable, Range } from 'atom';
import { find, generateRange, exec } from 'atom-linter';
import { dirname, join, relative, sep, isAbsolute } from 'path';
import { existsSync, readFileSync, readdirSync } from 'fs';

const tmp = require('tmp');

// Internal values
const elixirProjectPathCache = new Map();
let elixircPath;
let mixPath;
let forceElixirc;
let mixEnv;

function regexp(string, flags) {
  return new RegExp(
    string
      .replace(/\\ /gm, 'randomstring123')
      .replace(/\s/gm, '')
      .replace(/randomstring123/gm, '\\ '),
    flags,
  );
}

// Find elixir project in the file path by locating mix.exs, otherwise
//  fallback to project path or file path
const findElixirProjectPath = async (editorPath) => {
  const editorDir = dirname(editorPath);
  const mixexsPath = find(editorDir, 'mix.exs');
  if (mixexsPath !== null) {
    const pathArray = mixexsPath.split(sep);
    if (pathArray.length > 3 && pathArray[pathArray.length - 3] === 'apps') {
      //  Treat this as an umbrella app. This may be wrong -
      //  If you happen to keep your code in a directory called 'apps'
      pathArray.splice((pathArray.length - 3), 3);
      const umbrellaProjectPath = pathArray.join(sep);

      //  Safety check by looking for a `mix.exs` file in the same directory as
      //  'apps'. If it exists, then it's likely an umbrella project
      if (existsSync(join(umbrellaProjectPath, 'mix.exs'))) {
        return umbrellaProjectPath;
      }
    }
    return dirname(mixexsPath);
  }
  const projPath = atom.project.relativizePath(editorPath)[0];
  if (projPath !== null) {
    return projPath;
  }
  return editorDir;
};

// Memoize the project path per file (traversing is quite expensive)
const elixirProjectPath = async (filePath) => {
  if (elixirProjectPathCache.has(filePath)) {
    return elixirProjectPathCache.get(filePath);
  }
  const projectPath = await findElixirProjectPath(filePath);
  elixirProjectPathCache.set(filePath, projectPath);
  return projectPath;
};

const isMixProject = async (filePath) => {
  const project = await elixirProjectPath(filePath);
  return existsSync(join(project, 'mix.exs'));
};

const isUmbrellaProject = async (filePath) => {
  const project = await elixirProjectPath(filePath);
  return existsSync(join(project, 'apps'));
};

const isTestFile = async (filePath) => {
  const umbrellaProject = await isUmbrellaProject(filePath);
  const project = await elixirProjectPath(filePath);
  const relativePath = relative(project, filePath);

  if (umbrellaProject) {
    // Is the structure "apps/app_name/test/..."
    return relativePath.split(sep)[2] === 'test';
  }
  // Is the structure "test/..."
  return relativePath.split(sep)[0] === 'test';
};

const isForcedElixirc = () => forceElixirc;

const isExsFile = filePath => filePath.endsWith('.exs');

const isPhoenixProject = async (filePath) => {
  const project = await elixirProjectPath(filePath);
  const mixLockPath = join(project, 'mix.lock');
  try {
    const mixLockContent = readFileSync(mixLockPath, 'utf-8');
    return mixLockContent.indexOf('"phoenix"') > 0;
  } catch (error) {
    return false;
  }
};

const findTextEditor = (filePath) => {
  const allEditors = atom.workspace.getTextEditors();
  const matchingEditor = allEditors.find(
    textEditor => textEditor.getPath() === filePath);
  if (matchingEditor !== undefined) {
    return matchingEditor;
  }
  return false;
};

const ensureAbsolutePath = (projectPath, filePath) => {
  if (isAbsolute(filePath)) {
    return filePath;
  }
  return join(projectPath, filePath);
};

const parseError = async (toParse, sourceFilePath) => {
  const messages = [];
  const re = regexp(
    `
    \\*\\*[\\ ]+
    \\((\\w+)\\)                   ${''/* 1 - (TypeOfError)*/}
    [\\ ](?:                       ${''/* Two message formats.... mode one*/}
      ([\\w\\ ]+)                  ${''/* 2 - Message*/}
      [\\r\\n]{1,2}.+[\\r\\n]{1,2} ${''/* Internal elixir code*/}
      [\\ ]+(.+)                   ${''/* 3 - File*/}
      :(\\d+):                     ${''/* 4 - Line*/}
    |                              ${''/* Or... mode two*/}
      (.+)                         ${''/* 5 - File*/}
      :(\\d+):                     ${''/* 6 - Line*/}
      [\\ ](.+)                    ${''/* 7 - Message*/}
    )
  `,
    'gm',
  );
  const projectPath = await elixirProjectPath(sourceFilePath);
  let reResult = re.exec(toParse);
  while (reResult !== null) {
    let excerpt;
    let filePath;
    let range;
    if (reResult[2] !== undefined) {
      excerpt = `(${reResult[1]}) ${reResult[2]}`;
      filePath = ensureAbsolutePath(projectPath, reResult[3]);
      const fileEditor = findTextEditor(filePath);
      if (fileEditor) {
        // If there is an open TextEditor instance for the file from the Error,
        // we can get a better range using generateRange, otherwise
        // generate a 1 character range that can be updated to a proper range
        // if/when the file is opened.
        range = generateRange(fileEditor, reResult[4] - 1);
      } else {
        range = new Range([reResult[4] - 1, 0], [reResult[4] - 1, 1]);
      }
    } else {
      excerpt = `(${reResult[1]}) ${reResult[7]}`;
      filePath = ensureAbsolutePath(projectPath, reResult[5]);
      const fileEditor = findTextEditor(filePath);
      if (fileEditor) {
        range = generateRange(fileEditor, reResult[6] - 1);
      } else {
        range = new Range([reResult[6] - 1, 0], [reResult[6] - 1, 1]);
      }
    }
    messages.push({
      severity: 'error',
      excerpt,
      location: { file: filePath, position: range },
    });
    reResult = re.exec(toParse);
  }
  return messages;
};

// Only Elixir 1.3+
const parseWarning = async (toParse, sourceFilePath) => {
  const messages = [];
  const re = regexp(
    `
    warning:\\ (.*)\\n  ${''/* warning */}
    \\ \\ (.*):([0-9]+) ${''/* file and file number */}
    `,
    'g',
  );
  const projectPath = await elixirProjectPath(sourceFilePath);
  let reResult = re.exec(toParse);

  while (reResult != null) {
    const filePath = ensureAbsolutePath(projectPath, reResult[2]);
    try {
      let range;
      const fileEditor = findTextEditor(filePath);
      if (fileEditor) {
        range = generateRange(fileEditor, reResult[3] - 1);
      } else {
        range = new Range([reResult[3] - 1, 0], [reResult[3] - 1, 1]);
      }
      messages.push({
        severity: 'warning',
        excerpt: reResult[1],
        location: { file: filePath, position: range },
      });
    } catch (Error) {
      // eslint-disable-next-line no-console
      console.error('linter-elixirc:', Error);
    }
    reResult = re.exec(toParse);
  }
  return messages;
};

// Parses warning for elixir 1.2 and below
const parseLegacyWarning = async (toParse, sourceFilePath) => {
  const messages = [];
  const re = regexp(
    `
    ([^:\\n]*)   ${''/* 1 - File name */}
    :(\\d+)      ${''/* 2 - Line */}
    :\\ warning
    :\\ (.*)     ${''/* 3 - Message */}
    `,
    'g',
  );
  const projectPath = await elixirProjectPath(sourceFilePath);
  let reResult = re.exec(toParse);
  while (reResult !== null) {
    const filePath = ensureAbsolutePath(projectPath, reResult[1]);
    try {
      let range;
      const fileEditor = findTextEditor(filePath);
      if (fileEditor) {
        range = generateRange(fileEditor, reResult[3] - 1);
      } else {
        range = new Range([reResult[3] - 1, 0], [reResult[3] - 1, 1]);
      }
      messages.push({
        severity: 'warning',
        excerpt: reResult[3],
        location: { file: filePath, position: range },
      });
    } catch (Error) {
      // eslint-disable-next-line no-console
      console.error('linter-elixirc:', Error);
    }
    reResult = re.exec(toParse);
  }
  return messages;
};

const handleResult = async (compileResult, filePath) => {
  const resultString = `${compileResult.stdout}\n${compileResult.stderr}`;
  try {
    const errorStack = await parseError(resultString, filePath);
    const warningStack = await parseWarning(resultString, filePath);
    const legacyWarningStack = await parseLegacyWarning(resultString, filePath);

    const results = errorStack.concat(warningStack).concat(legacyWarningStack)
      .filter(error => error !== null)
      .map(error => error);

    return results;
  } catch (Error) {
    // eslint-disable-next-line no-console
    console.error('linter-elixirc:', Error);
    return []; // Error is in a different file, just suppress
  }
};

const getOpts = async filePath => ({
  cwd: await elixirProjectPath(filePath),
  throwOnStderr: false,
  stream: 'both',
  allowEmptyStderr: true,
  env: { MIX_ENV: mixEnv },
});

const getDepsPa = async (filePath) => {
  const env = (await isTestFile(filePath)) ? 'test' : 'dev';
  const buildDir = join('_build', env, 'lib');
  const projectPath = await elixirProjectPath(filePath);
  try {
    return readdirSync(join(projectPath, buildDir))
      .map(
        item =>
          join(projectPath, buildDir, item, 'ebin'),
      );
  } catch (e) {
    return [];
  }
};

const lintElixirc = async (textEditor) => {
  const filePath = textEditor.getPath();
  const tempDir = tmp.dirSync({ unsafeCleanup: true });
  const elixircArgs = [
    '--ignore-module-conflict',
    '--app',
    'mix',
    '--app',
    'ex_unit',
    '-o',
    tempDir.name,
  ];
  const paDeps = await getDepsPa(filePath);
  paDeps.forEach((item) => {
    elixircArgs.push('-pa', item);
  });
  elixircArgs.push(filePath);

  const fileText = textEditor.getText();
  const execOpts = await getOpts(filePath);

  const result = await exec(elixircPath, elixircArgs, execOpts);

  // Cleanup the temp dir
  tempDir.removeCallback();
  if (textEditor.getText() !== fileText) {
    // File contents have changed since the run was triggered, don't update messages
    return null;
  }
  return handleResult(result, filePath);
};

const lintMix = async (textEditor) => {
  const filePath = textEditor.getPath();
  const fileText = textEditor.getText();
  const execOpts = await getOpts(filePath);

  const result = await exec(mixPath, ['compile'], execOpts);
  if (textEditor.getText() !== fileText) {
    // File contents have changed since the run was triggered, don't update messages
    return null;
  }
  return handleResult(result, filePath);
};

export default {
  activate() {
    require('atom-package-deps').install('linter-elixirc');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-elixirc.elixircPath', (value) => {
        elixircPath = value;
      }),
    );
    this.subscriptions.add(
      atom.config.observe('linter-elixirc.mixPath', (value) => {
        mixPath = value;
      }),
    );
    this.subscriptions.add(
      atom.config.observe('linter-elixirc.forceElixirc', (value) => {
        forceElixirc = value;
      }),
    );
    this.subscriptions.add(
      atom.config.observe('linter-elixirc.mixEnv', (value) => {
        mixEnv = value;
      }),
    );
  },

  deactivate() {
    this.subscriptions.dispose();
  },

  provideLinter() {
    return {
      grammarScopes: ['source.elixir'],
      scope: 'project',
      lintsOnChange: false,
      name: 'Elixir',
      async lint(textEditor) {
        const filePath = textEditor.getPath();
        if (
          isForcedElixirc() ||
            !(await isMixProject(filePath)) ||
            isExsFile(filePath) ||
            (await isPhoenixProject(filePath)) ||
            (await isUmbrellaProject(filePath))
        ) {
          return lintElixirc(textEditor);
        }
        return lintMix(textEditor);
      },
    };
  },
};
