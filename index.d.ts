// Type definitions for gauge.js (gaugeJS)
// Project: https://github.com/razorness/gauge.js (forked from https://github.com/bernii/gauge.js)
// Definitions by: Volker Nauruhn <https://github.com/razorness>
// TypeScript Version: 2.1

declare module 'gaugeJS' {

	interface BaseOptions {

		/**
		 * High resolution support
		 */
		highDpiSupport?: boolean

		/**
		 * Size of font
		 *
		 * @default 40
		 */
		fontSize?: number;

		/**
		 * Speed of animation
		 *
		 * @default 32
		 */
		 animationSpeed?: number;

	}

	export interface GaugeOptions extends BaseOptions {

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default "#6fadcf"
		 */
		colorStart?: string

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default undefined
		 */
		colorStop?: string

		/**
		 * 0 : radial, 1 : linear
		 *
		 * @default 0
		 */
		gradientType?: 0 | 1;

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default "#e0e0e0"
		 */
		strokeColor?: string

		/**
		 * General pointer settings
		 */
		pointer?: {

			/**
			 * Relative to gauge radius
			 *
			 * @default 0.8
			 */
			length?: number

			/**
			 * The thickness
			 *
			 * @default 0.035
			 */
			strokeWidth?: number

			/**
			 * Fill color
			 */
			color?: string

			/**
			 * Icon image source
			 */
			iconPath?: string

			/**
			 * Size scaling factor
			 *
			 * @default 1.0
			 */
			iconScale?: number

			/**
			 * Rotation offset angle, degrees
			 */
			iconAngle?: number
		}

		
		/**
		 * General render tick settings
		 */
		 renderTicks?: {
			/**
			 * This is the number of major divisions around your arc.
			 *
			 * @default 5
			 */
			divisions?: number

			/**
			 * This is to set the width of the indicator.
			 *
			 * @default 5
			 */
			divWidth?: number

			/**
			 * This is a fractional percentage of the height of your arc line (0.5 = 50%).
			 *
			 * @default 0.7
			 */
			divLength?: number

			/**
			 * This sets the color of the division markers
			 *
			 * @default #333333
			 */
			divColor?: number

			/**
			 * This sets the minor tick marks count between major ticks.
			 *
			 * @default 3
			 */
			subDivisions?: number

			/**
			 * This is a fractional percentage of the height of your arc line (0.5 = 50%)
			 *
			 * @default 0.5
			 */
			subLength?: number

			/**
			 * This is to set the width of the indicator.
			 *
			 * @default 0.6
			 */
			subWidth?: number

			/**
			 * This sets the color of the subdivision markers
			 *
			 * @default #666666
			 */
			subColor?: number
		}

		/**
		 * The span of the gauge arc
		 *
		 * @default 0.15
		 */
		angle?: number


		/**
		 * The line thickness
		 *
		 * @default 0.44
		 */
		lineWidth?: number

		/**
		 * Relative radius
		 *
		 * @default 1.0
		 */
		radiusScale?: number

		/**
		 * If false, max value increases automatically if value > maxValue
		 *
		 * @default false
		 */
		limitMax?: boolean

		/**
		 * If true, the min value of the gauge will be fixed
		 *
		 * @default false
		 */
		limitMin?: boolean


		/**
		 * no documentation
		 */
		generateGradient?: boolean


		/**
		 * Percentage color
		 *
		 * If you want to control how Gauge behavaes in relation to the displayed value you can use the Guage option called
		 * percentColors. To use it add following entry to the options
		 *
		 * @example
		 *    <code>
		 *        percentColors = [[0.0, "#a9d70b" ], [0.50, "#f9c802"], [1.0, "#ff0000"]];
		 *    </code>
		 * @see http://jsfiddle.net/berni/Yb4d7/
		 */
		percentColors?: [ [ number, string ] ]

		/**
		 * Value labels
		 *
		 * For displaying value labels, enable the staticLabels option. A label will be printed at the given value just
		 * outside the display arc.
		 *
		 * @example
		 *    <code>
		 *    staticLabels: {
		 *     		font: "10px sans-serif",
		 *     		labels: [100, 130, 150, 220.1, 260, 300],
		 *     		color: "#000000",
		 *     		fractionDigits: 0
		 *    },
		 *    </code>
		 */
		staticLabels?: {

			/**
			 * Specifies font
			 */
			font: string

			/**
			 * Print labels at these values
			 */
			labels: [ number ]

			/**
			 * Label text color
			 */
			color?: string

			/**
			 * Numerical precision. 0=round off.
			 */
			fractionDigits?: number

		}

		/**
		 * Static zones
		 *
		 * When separating the background sectors or zones to have static colors, you must supply the staticZones property
		 * in the Gauge object's options.
		 * StaticZones, percentColors and gradient are mutually exclusive. If staticZones is defined, it will take
		 * precedence.
		 * Note: Zones should always be defined within the gauge objects .minValue and .maxValue limits.
		 *
		 * @example
		 *    <code>
		 *        staticZones: [
		 *            {strokeStyle: "#F03E3E", min: 100, max: 130}, // Red from 100 to 130
		 *            {strokeStyle: "#FFDD00", min: 130, max: 150}, // Yellow
		 *            {strokeStyle: "#30B32D", min: 150, max: 220}, // Green
		 *            {strokeStyle: "#FFDD00", min: 220, max: 260}, // Yellow
		 *            {strokeStyle: "#F03E3E", min: 260, max: 300}  // Red
		 *        ],
		 *    </code>
		 */
		staticZones?: [ {

			/**
			 * Color
			 */
			strokeStyle: string

			/**
			 * Beginn
			 */
			min: number

			/**
			 * End
			 */
			max: number

		} ]

	}

	export interface DonutOptions extends BaseOptions {

		/**
		 * The line thickness
		 *
		 * @default 0.10
		 */
		lineWidth?: number

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default "#6f6ea0"
		 */
		colorStart: string

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default "#c0c0db"
		 */
		colorStop: string

		/**
		 * Colors. Just experiment with them to see which ones work best for you
		 *
		 * @default "#eeeeee"
		 */
		strokeColor?: string

		/**
		 * @default "#d5d5d5"
		 */
		shadowColor?: string

		/**
		 * The span of the gauge arc
		 *
		 * @default 0.35
		 */
		angle?: number

		/**
		 * Relative radius
		 *
		 * @default 1.0
		 */
		radiusScale?: number

		lineCap?: 'round' | 'butt' | 'square'

	}

	class BaseGauge {

		/**
		 * @default 1
		 */
		displayScale: number;

		/**
		 * @default true
		 */
		forceUpdate: boolean;

		/**
		 * Set animation speed
		 *
		 * @default 32
		 */
		animationSpeed: number;

		constructor(addToAnimationQueue?: true, clear?: true)

		update(force?: false): boolean

		setTextField(textField: TextRenderer | HTMLElement, fractionDigits?: number): void

		/**
		 * Set options
		 *
		 * @param {GaugeOptions} opts
		 */
		setOptions(opts?: GaugeOptions): void

		/**
		 * Prefer setter over gauge.minValue = 0
		 *
		 * @param {number} val
		 * @param {true} updateStartValue
		 */
		setMinValue(val: number, updateStartValue?: true): void

	}

	export class Gauge extends BaseGauge {

		elem: HTMLCanvasElement;

		/**
		 * We support multiple pointers
		 */
		value: [ number ];

		/**
		 * Set max gauge value
		 */
		maxValue: number;

		/**
		 * Set min gauge value
		 *
		 * @deprecated better use setMinValue()
		 */
		minValue: number;

		displayedAngle: number;
		displayedValue: number;
		lineWidth: number;

		/**
		 * @default 0.1
		 */
		paddingTop: number;

		/**
		 * @default 0.1
		 */
		paddingBottom: number;

		percentColors: any;

		options: GaugeOptions;

		/**
		 * @param {HTMLElement} target
		 */
		constructor(target: HTMLCanvasElement)

		/**
		 * Set actual value
		 *
		 * @param {number} val
		 */
		set(val: number): void

		render(): void

	}

	class BaseDonut extends BaseGauge {

		/**
		 * @default 15
		 */
		lineWidth: number;
		/**
		 * @default 0
		 */
		displayedValue: number;
		/**
		 * @default 33
		 */
		value: number;
		/**
		 * @default 80
		 */
		maxValue: number;
		/**
		 * @default 0
		 */
		minValue: number;

		options: DonutOptions;

		/**
		 * @param {HTMLElement} target
		 */
		constructor(target: HTMLCanvasElement)

		/**
		 * Set options
		 *
		 * @param {DonutOptions} opts
		 */
		setOptions(opts?: DonutOptions): void

		/**
		 * Set actual value
		 *
		 * @param {number} val
		 */
		set(val: number): void

		render(): void

	}

	export class Donut extends BaseDonut {
	}

	export class TextRenderer {

		constructor(el: HTMLElement, fractionDigits: number)

		/**
		 * Default behaviour, override to customize rendering
		 */
		render(): void

	}

}
