---
name: Field Workflow Design System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#464555'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#767586'
  outline-variant: '#c7c4d7'
  surface-tint: '#4849da'
  primary: '#4343d5'
  on-primary: '#ffffff'
  primary-container: '#5d5fef'
  on-primary-container: '#faf7ff'
  inverse-primary: '#c1c1ff'
  secondary: '#5a5e68'
  on-secondary: '#ffffff'
  secondary-container: '#dfe2ee'
  on-secondary-container: '#60646e'
  tertiary: '#006645'
  on-tertiary: '#ffffff'
  tertiary-container: '#008259'
  on-tertiary-container: '#e1ffec'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c1c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2e2bc2'
  secondary-fixed: '#dfe2ee'
  secondary-fixed-dim: '#c3c6d2'
  on-secondary-fixed: '#171c24'
  on-secondary-fixed-variant: '#434750'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 20px
  stack-gap: 16px
  inline-gap: 12px
  section-margin: 32px
---

## Brand & Style
The brand personality of this design system is built on reliability, efficiency, and professional precision. Designed specifically for field technicians and installation experts, the UI prioritizes clarity over decoration, ensuring that users can execute complex workflows without cognitive overload. 

The aesthetic follows a **Corporate / Modern** style, characterized by a structured layout, a balanced color palette, and a focus on high-readability. It evokes a sense of "digital tools for physical work"—clean, systematic, and utilitarian, yet polished enough to represent an enterprise-grade solution. The interface uses high-contrast primary actions to guide the user through a sequential path, while secondary information resides in subtle, well-organized card containers.

## Colors
The color palette is anchored by a vibrant **Indigo Primary**, specifically chosen for its visibility and "action-oriented" feel in various lighting conditions. 

- **Primary:** Reserved for the most important "Next Step" actions, such as "Proceed to Installation" or "Capture Photo."
- **Secondary:** Used for low-emphasis backgrounds and subtle button states, ensuring a soft visual hierarchy.
- **Surface & Background:** The design system utilizes a layered neutral approach. A soft cool-gray background (`#F8FAFC`) provides a canvas for pure white (`#FFFFFF`) cards, creating an immediate sense of depth and organization without heavy shadows.
- **Semantic Colors:** Green is utilized for completion states, while a warm amber is reserved for "Pending" status chips to draw attention without signaling an error.

## Typography
This design system utilizes **Inter** exclusively to leverage its exceptional legibility and systematic character. The typography is engineered for a mobile-first field environment.

Headlines use a tighter letter-spacing and heavier weights to establish a clear starting point for each screen. Body text is set with generous line heights to ensure readability during active movement. Labels use a slightly increased letter-spacing and medium-to-bold weights to distinguish metadata from actionable content. A strict scale ensures that the difference between "Client Details" (section header) and "Pending verifications" (metadata) is immediately obvious to the eye.

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for mobile devices, utilizing an 8px base unit rhythm. 

- **Margins:** A standard 20px horizontal margin is applied to the main viewport to prevent content from crowding the screen edges.
- **Card Spacing:** Vertical stacks use a 16px gap to maintain a relationship between related workflow steps while providing enough "breathable" space to avoid accidental taps.
- **Information Density:** Within cards, a tighter 12px or 8px padding is used to group icons with their respective data points, ensuring that the most important information remains "above the fold" on standard mobile displays.

## Elevation & Depth
Visual hierarchy in this design system is conveyed through **Tonal Layers** and **Ambient Shadows**. 

Instead of heavy skeuomorphism, the system uses a 1px border in a very light neutral shade (`#E2E8F0`) combined with a soft, diffused shadow (0px 4px 12px rgba(0,0,0,0.05)). This makes "Cards" feel like physical objects resting on the background. 

For interactive elements like dropdowns and modals, the elevation is increased with a slightly more pronounced shadow to indicate they are in a higher "z-index" layer. Background blurs are used sparingly for navigation overlays to maintain focus on the primary task.

## Shapes
The shape language is defined as **Rounded**, providing a modern and approachable feel that softens the "industrial" nature of a field app. 

Standard components like input fields and buttons utilize a 0.5rem (8px) corner radius. Larger containers, such as data cards, utilize `rounded-lg` (1rem / 16px) to create a distinct structural frame. Status chips and badges utilize a fully rounded "pill" shape to distinguish them from interactive buttons, signaling that they are purely informational.

## Components

- **Buttons:** Primary buttons are full-width, solid Indigo with white text for maximum hit area. Secondary buttons use a light blue tint background with indigo text.
- **Cards:** The primary container for information. They must have a white background, a 1px soft border, and a 16px internal padding. Content inside cards should be vertically aligned.
- **Status Chips:** Small, pill-shaped indicators. Use a desaturated background (e.g., light orange for "Pending") with a darker version of the same hue for the text to ensure high contrast and accessibility.
- **Input Fields:** Use a "filled" style with a bottom-only border or a light-gray stroke. Labels should always be visible (either above the input or as a floating label) to ensure the user doesn't lose context while typing.
- **Progress Indicators:** Use a step-based visual (e.g., "1 of 4") or a subtle progress bar at the top of the screen to indicate workflow completion.
- **Actionable Icons:** Icons used for status should be enclosed in a circular or soft-square background tint to increase their visual weight.