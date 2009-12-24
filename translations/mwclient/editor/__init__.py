import tempfile
import codecs
import os
import sys

try:
    import readline
except:
    pass #handled at the end

def edit (text, command=None, default='vi %s', codec='utf-8'):
    """
        Edits a string using an editor. Is binary safe for strings,
        will maintain unicodeness for unicode.

        A custom editor may be specified, and may contain a %s
        to be replaced by the filename. If it doesn't then " %s"
        will be appended to what you specify.

        The default editor will be used if there is no custom command
        and the EDITOR environment variable is not set.

        Be careful that some editors will add a newline to a file.
        If you want to auto-strip the trailing newline, use editline.

        The codec is used to convert unicode strings to byte strings
        for the file. (Normal strings are not encoded or decoded)
    """
    
    editor = command
    if not editor: editor = os.getenv ('EDITOR')
    if not editor: editor = default

    if not "%s" in editor: editor += " %s"
    
    try:
        path = tempfile.mktemp ()
        if type(text) == unicode:
            file = codecs.open (path, 'w', codec)
        else:
            file = open(path, 'w')

        file.write(text)
        file.close ()
        os.system (editor % path)

        if type(text) == unicode:
            file = codecs.open (path, 'r', codec)
        else:
            file = open(path, 'r')

        return file.read ()

    finally:
        if not file.closed:
            file.close ()
            os.remove (path)


def editline (text, notempty=True, usereadline=True, **kwargs):
    """
        Edits a line of text. By default it will use the readline
        library, but you can set ask it to use the same parameters
        as edit() by setting readline to False either manually
        or with .setreadline ()

        If the notempty parameter is True, then a blank input
        will cause the original string to be returned.
    """
    if usereadline:
        if type(text) == unicode:
            toedit = text.encode(sys.stdout.encoding)
        else:
            toedit = text

        def readline_hook ():
            readline.insert_text (toedit)
            readline.redisplay ()
            readline.set_pre_input_hook(lambda: False)

        readline.set_pre_input_hook (readline_hook)
        
        if type(text) == unicode:
            edited = raw_input ().decode(sys.stdout.encoding)
        else:
            edited = raw_input ()

    else:
        edited = edit (text, **kwargs)

    while edited.endswith('\n'):
        edited = edited[:-1]

    if len(edited)== 0 and notempty:
        return text
    else:
        return edited


def setcommand (neweditor):
    """
        Changes the default value of the custom editor paramter.
    """
    # We do it this way so that help(editor) shows the current status.
    edit.func_defaults = (neweditor, edit.func_defaults[1], edit.func_defaults[2])

def setdefault (neweditor):
    """
        Changes the default value of the default editor parameter.
        This will only take effect if the EDITOR environment variable
        is not set.
    """
    edit.func_defaults = (edit.func_defaults[0], neweditor, edit.func_defaults[2])

def setcodec (newcodec):
    """
        Changes the default value of the encoding parameter.
        This is only needed if you have a wierd editor that
        can't handle utf-8 and you want to edit unicode strings.
    """
    edit.func_defaults = (edit.func_defaults[0], edit.func_defaults[1], newcodec)

def setreadline (use):
    """
        Change the default argument for editline () to use readline or not.
    """
    editline.func_defaults = (editline.func_defaults[0], use)

def setnotempty (notempty):
    """
        Set the default value of the notempty parameter for editline()
        If notempty is True, then if the user inputs an empty string
        it will be assumed they mean "no changes", not "null input"
    """
    editline.func_defaults = (notempty, editline.func_defaults[1])

try:
    readline
except:
    setreadline (False)
    del setreadline
    editline.__doc__ = """
    Edits a line of text with the same parameters as edit().

    If notempty is True entering an empty string is equivalent
    to returning the input value.

    readline is not available on your system, attempts to use it will raise an exception.
    """
