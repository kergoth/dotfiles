# `formatter` [![Build Status](https://travis-ci.org/atom-community/formatter.svg?branch=master)](https://travis-ci.org/atom-community/formatter) [![Build status](https://ci.appveyor.com/api/projects/status/p7o66o3jx9uxa1qd/branch/master?svg=true)](https://ci.appveyor.com/project/joefitzgerald/formatter/branch/master)

The core dependency you need to support formatting services.

Provides a service API that you can register by scope name to send Async formatting edits.

* Provides unified keyboard shortcuts
* Takes care of command resolution to the correct scope and therefore provider
* Takes care of applying the code edits in a manner that they can be easily undone (transactional)

# Providers

* [formatter-coffeescript](https://atom.io/packages/formatter-coffeescript)
* [TypeScript](https://atom.io/packages/atom-typescript)

# Keybindings

Default (inspired from IntelliJ):
```cson
'atom-text-editor':
  'alt-ctrl-l': 'formatter:format-code'
  'alt-cmd-l': 'formatter:format-code'
```

# API for Providers

Given you understand these simple concepts:
```ts
/** 0 based */
interface EditorPosition {
    line: number;
    col: number;
}

interface CodeEdit {
    start: EditorPosition;
    end: EditorPosition;
    newText: string;
}

interface Selection {
    start: EditorPosition;
    end: EditorPosition;
}
```

The Provider really needs to be a `FormatterProvider`. It needs to provide a selector for which it will work. And then Either of the two:
 * a `getCodeEdits` function that gets passed in `FormattingOptions` and returns a bunch of `CodeEdit[]` or a promise thereof. This method is preferred as we do not create a `string`.
 * a `getNewText` function that gets passed in text and then returns
 formatted text. This is slower as we create and pass around strings.

```ts
interface CodeEditOptions {
    editor: AtomCore.IEditor;

    // only if there is a selection
    selection: Selection;
}

interface FormatterProvider {
    selector: string;
    disableForSelector?: string;

    // One of:
    getCodeEdits: (options: CodeEditOptions) => CodeEdits[] | Promise<CodeEdit[]>;
    getNewText: (oldText: string) => string | Promise<string>;
}
```


## Sample Provider

### **package.json**:

```json
"providedServices": {
  "formatter": {
    "versions": {
      "1.0.0": "provideFormatter"
    }
  }
}
```

### Providers:
**Sample Coffeescript**
```coffee
module.exports = FormatterCoffeescript =
  activate: (state) ->
    return

  provideFormatter: ->
    {
      selector: '.source.coffee',
      getNewText: (text) =>
        CF = require 'coffee-formatter'
        lines = text.split('\n');
        resultArr = [];
        for curr in lines
          p = CF.formatTwoSpaceOperator(curr);
          p = CF.formatOneSpaceOperator(p);
          p = CF.shortenSpaces(p);
          resultArr.push(p);
        result = resultArr.join('\n')
        return result
    }
```

**Sample TypeScript**

```ts
export function provideFormatter() {
    var formatter: FormatterProvider;
    formatter = {
        selector: '.source.ts',
        getCodeEdits: (options: FormattingOptions): Promise<CodeEdit[]> => {
            var filePath = options.editor.getPath();
            if (!options.selection) {
                return parent.formatDocument({ filePath: filePath }).then((result) => {
                    return result.edits;
                });
            }
            else {
                return parent.formatDocumentRange({
                  filePath: filePath,
                  start: options.selection.start,
                  end: options.selection.end })
                    .then((result) => {
                        return result.edits;
                    });
            }
        }
    };
    return formatter;
}
```
