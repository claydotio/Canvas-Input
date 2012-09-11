Canvas Input
===========
This library allows you to create input boxes without using the standard HTML DOM element <input>, instead through use of a <canvas> element. 

I initially created this for [Clay.io](http://clay.io), a hub for HTML5 games. We offer an API for game developers to implement features like high scores, achievements, data storage, payment
processing, etc. in their HTML5 games. There are a few services out there that boost performance for HTML5 games on mobile devices by eliminating the DOM completely, so we needed to develop
a version of our API that plays nicely *without* the DOM. In doing so, we also needed a way to let users login to their Clay.io accounts, and thus this library was born.

Another use-case for this might be to eliminate spammers without use of a captcha. At least at this point in time, they're not going to catch onto the fact that you are using 'fake' inputs
in a <canvas> rather than using a <input>s, and won't be able to insert of a bunch of junk.

Installation
-----------
Put the following inbetween <head> and </head> (or just before the end of </body>, just wait til the page is loaded to call the classes)
    <script type='text/javascript' src='src/canvasinput.js'></script>

Usage
-----
There are 3 classes you can use right now, `CanvasText`, `CavasPassword` and `CanvasSubmit`. When you call the class, pass the canvas DOM object for the first parameter, and an options object
for the second parameter. The following options are available:
* x (integer x position of the input in the canvas, pass 'center' to center it)
* y (integer y position of the input in the canvas)
* width (integer width value of box)
* height (integer height value of box)
* center (boolean, set `true` to align the text inside the box to the center. Default `false` for text and password, `true` for submit)
* placeholder (string, default text for the box, this is cleared out when the input is focused)
* onSubmit (function, only for CanvasSubmit, this function is called when the user clicks on the button, or the enter key is pressed from a CanvasInput)

Standard text input
    new CanvasText( canvas, {
        x: 'center',
        y: 120,
        width: 300,
        placeholder: 'Enter your username...'
    } );

Standard password input
    new CanvasPassword( canvas, {
        x: 'center',
        y: 155,
        width: 300,
        placeholder: 'Enter your password...'
    } );

Standard submit button
    new CanvasSubmit( canvas, {
        x: 'center',
        y: 195,
        width: 300,
        placeholder: 'Submit',
        onSubmit: ( function() {
            return alert( 'Submit button pressed' );
        } )
    } );