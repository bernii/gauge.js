gauge.js
========

100% native and cool looking animated JavaScript/CoffeScript gauge.

 * No images, no external CSS - pure canvas
 * No dependencies
 * Highly configurable
 * Resolution independent
 * Animated gauge value changes
 * Works in all major browsers
 * MIT License

## Usage

```javascript
var opts = {
  angle: 0.15, /// The span of the gauge arc
  lineWidth: 0.44, // The line thickness
  pointer: {
    length: 0.9, // Relative to gauge radius
    strokeWidth: 0.035 // The thickness
  },
  colorStart: '#6FADCF',   // Colors
  colorStop: '#8FC0DA',    // just experiment with them
  strokeColor: '#E0E0E0'   // to see which ones work best for you
};
var target = document.getElementById('foo'); // your canvas element
var gauge = new Gauge(target).setOptions(opts); // create sexy gauge!
gauge.maxValue = 3000; // set max gauge value
gauge.setMinValue(0);  // set min value
gauge.set(1250); // set actual value
```

For an interactive demo and a list of all supported options please refer to the [project's homepage](http://bernii.github.io/gauge.js).

## Wrappers

gauge.js can be wrapped to a number of frameworks. Here are some examples:

* **Vue**
  * [vgauge](https://github.com/amroessam/vgauge)
* **React**
  * [react-gaugejs](https://github.com/keanemind/react-gaugejs)

## Build instructions

Build is a two-step process. First, the CoffeeScript source `gauge.coffee` is converted to `gauge.js`. Next, [terser](https://www.npmjs.com/package/terser) produces the minified distribution file `gauge.min.js`.

```bash
# Install development dependencies
npm install
# Run the build
npm run build
```
