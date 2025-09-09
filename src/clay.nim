import std/[macros, genasts]

{.compile: "clay.c".}

type
  ClayContext = object

  ##  Note: ClayString is not guaranteed to be null terminated. It may be if created from a literal C string,
  ##  but it is also used to represent slices.
  ClayString* {.bycopy.} = object
    ##  Set this boolean to true if the char* data underlying this string will live for the entire lifetime of the program.
    ##  This will automatically be set for strings created with CLAY_STRING, as the macro requires a string literal.
    isStaticallyAllocated*: bool
    length*: int32
    ##  The underlying character memory. Note: this will not be copied and will not extend the lifetime of the underlying memory.
    chars*: ptr UncheckedArray[char]

  ##  ClayStringSlice is used to represent non owning string slices, and includes
  ##  a baseChars field which points to the string this slice is derived from.
  ClayStringSlice* {.bycopy.} = object
    length*: int32
    chars*: ptr UncheckedArray[char]
    baseChars*: ptr UncheckedArray[char]
    ##  The source string / char* that this slice was derived from

  ##  ClayArena is a memory arena structure that is used by clay to manage its internal allocations.
  ##  Rather than creating it by hand, it's easier to use ClayCreateArenaWithCapacityAndMemory()
  ClayArena* {.bycopy.} = object
    nextAllocation*: pointer
    capacity*: csize_t
    memory*: ptr UncheckedArray[uint8]

  ClayDimensions* {.bycopy.} = object
    width*: cfloat
    height*: cfloat

  ClayVector2* {.bycopy.} = object
    x*: cfloat
    y*: cfloat

  ##  Internally clay conventionally represents colors as 0-255, but interpretation is up to the renderer.
  ClayColor* {.bycopy.} = object
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  ClayBoundingBox* {.bycopy.} = object
    x*: cfloat
    y*: cfloat
    width*: cfloat
    height*: cfloat

  ##  Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
  ##  Represents a hashed string ID used for identifying and finding specific clay UI elements, required
  ##  by functions such as ClayPointerOver() and ClayGetElementData().
  ClayElementId* {.bycopy.} = object
    id*: uint32
    ##  The resulting hash generated from the other fields.
    offset*: uint32
    ##  A numerical offset applied after computing the hash from stringId.
    baseId*: uint32
    ##  A base hash value to start from, for example the parent element ID is used when calculating CLAY_ID_LOCAL().
    stringId*: ClayString
    ##  The string id to hash.

  ##  A sized array of ClayElementId.
  ClayElementIdArray* {.bycopy.} = object
    capacity*: int32
    length*: int32
    internalArray*: ptr UncheckedArray[ClayElementId]

  ##  Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
  ##  The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
  ClayCornerRadius* {.bycopy.} = object
    topLeft*: cfloat
    topRight*: cfloat
    bottomLeft*: cfloat
    bottomRight*: cfloat

  ##  Controls the direction in which child elements will be automatically laid out.
  ClayLayoutDirection* {.size: sizeof(uint8).} = enum
    LeftToRight,      ##  (Default) Lays out child elements from left to right with increasing x.
    TopToBottom       ##  Lays out child elements from top to bottom with increasing y.

  ##  Controls the alignment along the x axis (horizontal) of child elements.
  ClayLayoutAlignmentX* {.size: sizeof(uint8).} = enum
    CLAY_ALIGN_X_LEFT,        ##  (Default) Aligns child elements to the left hand side of this element, offset by padding.width.left
    CLAY_ALIGN_X_RIGHT,       ##  Aligns child elements to the right hand side of this element, offset by padding.width.right
    CLAY_ALIGN_X_CENTER       ##  Aligns child elements horizontally to the center of this element

  ##  Controls the alignment along the y axis (vertical) of child elements.
  ClayLayoutAlignmentY* {.size: sizeof(uint8).} = enum
    CLAY_ALIGN_Y_TOP,         ##  (Default) Aligns child elements to the top of this element, offset by padding.width.top
    CLAY_ALIGN_Y_BOTTOM,      ##  Aligns child elements to the bottom of this element, offset by padding.width.bottom
    CLAY_ALIGN_Y_CENTER       ##  Aligns child elements vertically to the center of this element

  ##  Controls how the element takes up space inside its parent container.
  ClaySizingType* {.size: sizeof(uint8).} = enum
    CLAY_SIZING_TYPE_FIT,     ##  (default) Wraps tightly to the size of the element's contents.
    CLAY_SIZING_TYPE_GROW,    ##  Expands along this axis to fill available space in the parent element, sharing it with other GROW elements.
    CLAY_SIZING_TYPE_PERCENT, ##  Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
    CLAY_SIZING_TYPE_FIXED    ##  Clamps the axis size to an exact size in pixels.

  ##  Controls how child elements are aligned on each axis.
  ClayChildAlignment* {.bycopy.} = object
    x*: ClayLayoutAlignmentX
    ##  Controls alignment of children along the x axis.
    y*: ClayLayoutAlignmentY
    ##  Controls alignment of children along the y axis.

  ##  Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to,
  ##  overriding sizing types such as FIT or GROW.
  ClaySizingMinMax* {.bycopy.} = object
    min*: cfloat
    ##  The smallest final size of the element on this axis will be this value in pixels.
    max*: cfloat
    ##  The largest final size of the element on this axis will be this value in pixels.

  ##  Controls the sizing of this element along one axis inside its parent container.
  ClaySizingAxisUnion* {.bycopy, union.} = object
    minMax*: ClaySizingMinMax
    ##  Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to, overriding sizing types such as FIT or GROW.
    percent*: cfloat
    ##  Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.

  ClaySizingAxis* {.bycopy.} = object
    size*: ClaySizingAxisUnion
    `type`*: ClaySizingType
    ##  Controls how the element takes up space inside its parent container.

  ##  Controls the sizing of this element along one axis inside its parent container.
  ClaySizing* {.bycopy.} = object
    width*: ClaySizingAxis
    ##  Controls the width sizing of the element, along the x axis.
    height*: ClaySizingAxis
    ##  Controls the height sizing of the element, along the y axis.

  ##  Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children
  ##  will be placed.
  ClayPadding* {.bycopy.} = object
    left*: uint16
    right*: uint16
    top*: uint16
    bottom*: uint16

  ##  Controls various settings that affect the size and position of an element, as well as the sizes and positions
  ##  of any child elements.
  ClayLayoutConfig* {.bycopy.} = object
    sizing*: ClaySizing
    ##  Controls the sizing of this element inside it's parent container, including FIT, GROW, PERCENT and FIXED sizing.
    padding*: ClayPadding
    ##  Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children will be placed.
    childGap*: uint16
    ##  Controls the gap in pixels between child elements along the layout axis (horizontal gap for LEFT_TO_RIGHT, vertical gap for TOP_TO_BOTTOM).
    childAlignment*: ClayChildAlignment
    ##  Controls how child elements are aligned on each axis.
    layoutDirection*: ClayLayoutDirection
    ##  Controls the direction in which child elements will be automatically laid out.

  ##  Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
  ClayTextElementConfigWrapMode* {.size: sizeof(uint8).} = enum
    CLAY_TEXT_WRAP_WORDS,     ##  (default) breaks on whitespace characters.
    CLAY_TEXT_WRAP_NEWLINES,  ##  Don't break on space characters, only on newlines.
    CLAY_TEXT_WRAP_NONE       ##  Disable text wrapping entirely.

  ##  Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
  ClayTextAlignment* {.size: sizeof(uint8).} = enum
    CLAY_TEXT_ALIGN_LEFT,     ##  (default) Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    CLAY_TEXT_ALIGN_CENTER,   ##  Horizontally aligns wrapped lines of text to the center of their bounding box.
    CLAY_TEXT_ALIGN_RIGHT     ##  Horizontally aligns wrapped lines of text to the right hand side of their bounding box.

  ##  Controls various functionality related to text elements.
  ClayTextElementConfig* {.bycopy.} = object
    ##  A pointer that will be transparently passed through to the resulting render command.
    userData*: pointer
    ##  The RGBA color of the font to render, conventionally specified as 0-255.
    textColor*: ClayColor
    ##  An integer transparently passed to ClayMeasureText to identify the font to use.
    ##  The debug view will pass fontId = 0 for its internal text.
    fontId*: uint16
    ##  Controls the size of the font. Handled by the function provided to ClayMeasureText.
    fontSize*: uint16
    ##  Controls extra horizontal spacing between characters. Handled by the function provided to ClayMeasureText.
    letterSpacing*: uint16
    ##  Controls additional vertical space between wrapped lines of text.
    lineHeight*: uint16
    ##  Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
    ##  CLAY_TEXT_WRAP_WORDS (default) breaks on whitespace characters.
    ##  CLAY_TEXT_WRAP_NEWLINES doesn't break on space characters, only on newlines.
    ##  CLAY_TEXT_WRAP_NONE disables wrapping entirely.
    wrapMode*: ClayTextElementConfigWrapMode
    ##  Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
    ##  CLAY_TEXT_ALIGN_LEFT (default) - Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    ##  CLAY_TEXT_ALIGN_CENTER - Horizontally aligns wrapped lines of text to the center of their bounding box.
    ##  CLAY_TEXT_ALIGN_RIGHT - Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    textAlignment*: ClayTextAlignment

  ##  Aspect Ratio --------------------------------
  ##  Controls various settings related to aspect ratio scaling element.
  ClayAspectRatioElementConfig* {.bycopy.} = object
    aspectRatio*: cfloat
    ##  A float representing the target "Aspect ratio" for an element, which is its final width divided by its final height.

  ##  Image --------------------------------
  ##  Controls various settings related to image elements.
  ClayImageElementConfig* {.bycopy.} = object
    imageData*: pointer
    ##  A transparent pointer used to pass image data through to the renderer.

  ##  Controls where a floating element is offset relative to its parent element.
  ##  Note: see https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce for a visual explanation.
  ClayFloatingAttachPointType* {.size: sizeof(uint8).} = enum
    CLAY_ATTACH_POINT_LEFT_TOP, CLAY_ATTACH_POINT_LEFT_CENTER,
    CLAY_ATTACH_POINT_LEFT_BOTTOM, CLAY_ATTACH_POINT_CENTER_TOP,
    CLAY_ATTACH_POINT_CENTER_CENTER, CLAY_ATTACH_POINT_CENTER_BOTTOM,
    CLAY_ATTACH_POINT_RIGHT_TOP, CLAY_ATTACH_POINT_RIGHT_CENTER,
    CLAY_ATTACH_POINT_RIGHT_BOTTOM

  ##  Controls where a floating element is offset relative to its parent element.
  ClayFloatingAttachPoints* {.bycopy.} = object
    element*: ClayFloatingAttachPointType
    ##  Controls the origin point on a floating element that attaches to its parent.
    parent*: ClayFloatingAttachPointType
    ##  Controls the origin point on the parent element that the floating element attaches to.

  ##  Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
  ClayPointerCaptureMode* {.size: sizeof(uint8).} = enum
    CLAY_POINTER_CAPTURE_MODE_CAPTURE,    ##  (default) "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH ##     CLAY_POINTER_CAPTURE_MODE_PARENT, TODO pass pointer through to attached parent
                                          ##  Transparently pass through pointer events like hover and click to elements underneath the floating element.

  ##  Controls which element a floating element is "attached" to (i.e. relative offset from).
  ClayFloatingAttachToElement* {.size: sizeof(uint8).} = enum
    CLAY_ATTACH_TO_NONE,            ##  (default) Disables floating for this element.
    CLAY_ATTACH_TO_PARENT,          ##  Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    CLAY_ATTACH_TO_ELEMENT_WITH_ID, ##  Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    CLAY_ATTACH_TO_ROOT             ##  Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".

  ##  Controls whether or not a floating element is clipped to the same clipping rectangle as the element it's attached to.
  ClayFloatingClipToElement* {.size: sizeof(uint8).} = enum
    CLAY_CLIP_TO_NONE,           ##  (default) - The floating element does not inherit clipping.
    CLAY_CLIP_TO_ATTACHED_PARENT ##  The floating element is clipped to the same clipping rectangle as the element it's attached to.

  ##  Controls various settings related to "floating" elements, which are elements that "float" above other elements, potentially overlapping their boundaries,
  ##  and not affecting the layout of sibling or parent elements.
  ClayFloatingElementConfig* {.bycopy.} = object
    ##  Offsets this floating element by the provided x,y coordinates from its attachPoints.
    offset*: ClayVector2
    ##  Expands the boundaries of the outer floating element without affecting its children.
    expand*: ClayDimensions
    ##  When used in conjunction with .attachTo = CLAY_ATTACH_TO_ELEMENT_WITH_ID, attaches this floating element to the element in the hierarchy with the provided ID.
    ##  Hint: attach the ID to the other element with .id = CLAY_ID("yourId"), and specify the id the same way, with .parentId = CLAY_ID("yourId").id
    parentId*: uint32
    ##  Controls the z index of this floating element and all its children. Floating elements are sorted in ascending z order before output.
    ##  zIndex is also passed to the renderer for all elements contained within this floating element.
    zIndex*: int16
    ##  Controls how mouse pointer events like hover and click are captured or passed through to elements underneath / behind a floating element.
    ##  Enum is of the form CLAY_ATTACH_POINT_foo_bar. See ClayFloatingAttachPoints for more details.
    ##  Note: see <img src="https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce />
    ##  and <img src="https://github.com/user-attachments/assets/ebe75e0d-1904-46b0-982d-418f929d1516 /> for a visual explanation.
    attachPoints*: ClayFloatingAttachPoints
    ##  Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
    ##  CLAY_POINTER_CAPTURE_MODE_CAPTURE (default) - "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    ##  CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH - Transparently pass through pointer events like hover and click to elements underneath the floating element.
    pointerCaptureMode*: ClayPointerCaptureMode
    ##  Controls which element a floating element is "attached" to (i.e. relative offset from).
    ##  CLAY_ATTACH_TO_NONE (default) - Disables floating for this element.
    ##  CLAY_ATTACH_TO_PARENT - Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    ##  CLAY_ATTACH_TO_ELEMENT_WITH_ID - Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    ##  CLAY_ATTACH_TO_ROOT - Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
    attachTo*: ClayFloatingAttachToElement
    ##  Controls whether or not a floating element is clipped to the same clipping rectangle as the element it's attached to.
    ##  CLAY_CLIP_TO_NONE (default) - The floating element does not inherit clipping.
    ##  CLAY_CLIP_TO_ATTACHED_PARENT - The floating element is clipped to the same clipping rectangle as the element it's attached to.
    clipTo*: ClayFloatingClipToElement

  ##  Controls various settings related to custom elements.
  ClayCustomElementConfig* {.bycopy.} = object
    ##  A transparent pointer through which you can pass custom data to the renderer.
    ##  Generates CUSTOM render commands.
    customData*: pointer

  ##  Controls the axis on which an element switches to "scrolling", which clips the contents and allows scrolling in that direction.
  ClayClipElementConfig* {.bycopy.} = object
    horizontal*: bool
    ##  Clip overflowing elements on the X axis.
    vertical*: bool
    ##  Clip overflowing elements on the Y axis.
    childOffset*: ClayVector2
    ##  Offsets the x,y positions of all child elements. Used primarily for scrolling containers.

  ##  Controls the widths of individual element borders.
  ClayBorderWidth* {.bycopy.} = object
    left*: uint16
    right*: uint16
    top*: uint16
    bottom*: uint16
    ##  Creates borders between each child element, depending on the .layoutDirection.
    ##  e.g. for LEFT_TO_RIGHT, borders will be vertical lines, and for TOP_TO_BOTTOM borders will be horizontal lines.
    ##  .betweenChildren borders will result in individual RECTANGLE render commands being generated.
    betweenChildren*: uint16

  ##  Controls settings related to element borders.
  ClayBorderElementConfig* {.bycopy.} = object
    color*: ClayColor
    ##  Controls the color of all borders with width > 0. Conventionally represented as 0-255, but interpretation is up to the renderer.
    width*: ClayBorderWidth
    ##  Controls the widths of individual borders. At least one of these should be > 0 for a BORDER render command to be generated.

  ##  Render command data when commandType == Text
  ClayTextRenderData* {.bycopy.} = object
    ##  A string slice containing the text to be rendered.
    ##  Note: this is not guaranteed to be null terminated.
    stringContents*: ClayStringSlice
    ##  Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    textColor*: ClayColor
    ##  An integer representing the font to use to render this text, transparently passed through from the text declaration.
    fontId*: uint16
    fontSize*: uint16
    ##  Specifies the extra whitespace gap in pixels between each character.
    letterSpacing*: uint16
    ##  The height of the bounding box for this line of text.
    lineHeight*: uint16

  ##  Render command data when commandType == Rectangle
  ClayRectangleRenderData* {.bycopy.} = object
    ##  The solid background color to fill this rectangle with. Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor*: ClayColor
    ##  Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    ##  The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius*: ClayCornerRadius

  ##  Render command data when commandType == Image
  ClayImageRenderData* {.bycopy.} = object
    ##  The tint color for this image. Note that the default value is 0,0,0,0 and should likely be interpreted
    ##  as "untinted".
    ##  Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor*: ClayColor
    ##  Controls the "radius", or corner rounding of this image.
    ##  The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius*: ClayCornerRadius
    ##  A pointer transparently passed through from the original element definition, typically used to represent image data.
    imageData*: pointer


  ##  Render command data when commandType == Custom
  ClayCustomRenderData* {.bycopy.} = object
    ##  Passed through from .backgroundColor in the original element declaration.
    ##  Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor*: ClayColor
    ##  Controls the "radius", or corner rounding of this custom element.
    ##  The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius*: ClayCornerRadius
    ##  A pointer transparently passed through from the original element definition.
    customData*: pointer

  ##  Render command data when commandType == ScissorStart || commandType == ScissorEnd
  ClayClipRenderData* {.bycopy.} = object
    horizontal*: bool
    vertical*: bool

  ##  Render command data when commandType == Border
  ClayBorderRenderData* {.bycopy.} = object
    ##  Controls a shared color for all this element's borders.
    ##  Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    color*: ClayColor
    ##  Specifies the "radius", or corner rounding of this border element.
    ##  The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius*: ClayCornerRadius
    ##  Controls individual border side widths.
    width*: ClayBorderWidth

  ##  A struct union containing data specific to this command's .commandType
  ClayRenderData* {.bycopy, union.} = object
    ##  Render command data when commandType == Rectangle
    rectangle*: ClayRectangleRenderData
    ##  Render command data when commandType == Text
    text*: ClayTextRenderData
    ##  Render command data when commandType == Image
    image*: ClayImageRenderData
    ##  Render command data when commandType == Custom
    custom*: ClayCustomRenderData
    ##  Render command data when commandType == Border
    border*: ClayBorderRenderData
    ##  Render command data when commandType == ScissorStart|END
    clip*: ClayClipRenderData


  ##  Data representing the current internal state of a scrolling element.
  ClayScrollContainerData* {.bycopy.} = object
    ##  Note: This is a pointer to the real internal scroll position, mutating it may cause a change in final layout.
    ##  Intended for use with external functionality that modifies scroll position, such as scroll bars or auto scrolling.
    scrollPosition*: ptr ClayVector2
    ##  The bounding box of the scroll element.
    scrollContainerDimensions*: ClayDimensions
    ##  The outer dimensions of the inner scroll container content, including the padding of the parent scroll container.
    contentDimensions*: ClayDimensions
    ##  The config that was originally passed to the clip element.
    config*: ClayClipElementConfig
    ##  Indicates whether an actual scroll container matched the provided ID or if the default struct was returned.
    found*: bool


  ##  Bounding box and other data for a specific UI element.
  ClayElementData* {.bycopy.} = object
    ##  The rectangle that encloses this UI element, with the position relative to the root of the layout.
    boundingBox*: ClayBoundingBox
    ##  Indicates whether an actual Element matched the provided ID or if the default struct was returned.
    found*: bool

  ##  Used by renderers to determine specific handling for each render command.
  ClayRenderCommandType* {.size: sizeof(uint8).} = enum
    None,  ##  This command type should be skipped.
    Rectangle,  ##  The renderer should draw a solid color rectangle.
    Border,  ##  The renderer should draw a colored border inset into the bounding box.
    Text,  ##  The renderer should draw text.
    Image,  ##  The renderer should draw an image.
    ScissorStart,  ##  The renderer should begin clipping all future draw commands, only rendering content that falls within the provided boundingBox.
    ScissorEnd,  ##  The renderer should finish any previously active clipping, and begin rendering elements in full again.
    Custom  ##  The renderer should provide a custom implementation for handling this render command based on its .customData

  ClayRenderCommand* {.bycopy.} = object
    ##  A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
    boundingBox*: ClayBoundingBox
    ##  A struct union containing data specific to this command's commandType.
    renderData*: ClayRenderData
    ##  A pointer transparently passed through from the original element declaration.
    userData*: pointer
    ##  The id of this element, transparently passed through from the original element declaration.
    id*: uint32
    ##  The z order required for drawing this command correctly.
    ##  Note: the render command array is already sorted in ascending order, and will produce correct results if drawn in naive order.
    ##  This field is intended for use in batching renderers for improved performance.
    zIndex*: int16
    ##  Specifies how to handle rendering of this command.
    ##  Rectangle - The renderer should draw a solid color rectangle.
    ##  Border - The renderer should draw a colored border inset into the bounding box.
    ##  Text - The renderer should draw text.
    ##  Image - The renderer should draw an image.
    ##  ScissorStart - The renderer should begin clipping all future draw commands, only rendering content that falls within the provided boundingBox.
    ##  ScissorEnd - The renderer should finish any previously active clipping, and begin rendering elements in full again.
    ##  Custom - The renderer should provide a custom implementation for handling this render command based on its .customData
    commandType*: ClayRenderCommandType

  ##  A sized array of render commands.
  ClayRenderCommandArray* {.bycopy.} = object
    ##  The underlying max capacity of the array, not necessarily all initialized.
    capacity*: int32
    ##  The number of initialized elements in this array. Used for loops and iteration.
    length*: int32
    ##  A pointer to the first element in the internal array.
    internalArray*: ptr UncheckedArray[ClayRenderCommand]

  ##  Represents the current state of interaction with clay this frame.
  ClayPointerDataInteractionState* {.size: sizeof(uint8).} = enum
    CLAY_POINTER_DATA_PRESSED_THIS_FRAME,  ##  A left mouse click, or touch occurred this frame.
    CLAY_POINTER_DATA_PRESSED,  ##  The left mouse button click or touch happened at some point in the past, and is still currently held down this frame.
    CLAY_POINTER_DATA_RELEASED_THIS_FRAME,  ##  The left mouse button click or touch was released this frame.
    CLAY_POINTER_DATA_RELEASED ##  The left mouse button click or touch is not currently down / was released at some point in the past.

  ##  Information on the current state of pointer interactions this frame.
  ClayPointerData* {.bycopy.} = object
    ##  The position of the mouse / touch / pointer relative to the root of the layout.
    position*: ClayVector2
    ##  Represents the current state of interaction with clay this frame.
    ##  CLAY_POINTER_DATA_PRESSED_THIS_FRAME - A left mouse click, or touch occurred this frame.
    ##  CLAY_POINTER_DATA_PRESSED - The left mouse button click or touch happened at some point in the past, and is still currently held down this frame.
    ##  CLAY_POINTER_DATA_RELEASED_THIS_FRAME - The left mouse button click or touch was released this frame.
    ##  CLAY_POINTER_DATA_RELEASED - The left mouse button click or touch is not currently down / was released at some point in the past.
    state*: ClayPointerDataInteractionState

  ClayElementDeclaration* {.bycopy.} = object
    ##  Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
    ##  Represents a hashed string ID used for identifying and finding specific clay UI elements, required by functions such as ClayPointerOver() and ClayGetElementData().
    id*: ClayElementId
    ##  Controls various settings that affect the size and position of an element, as well as the sizes and positions of any child elements.
    layout*: ClayLayoutConfig
    ##  Controls the background color of the resulting element.
    ##  By convention specified as 0-255, but interpretation is up to the renderer.
    ##  If no other config is specified, .backgroundColor will generate a RECTANGLE render command, otherwise it will be passed as a property to IMAGE or CUSTOM render commands.
    backgroundColor*: ClayColor
    ##  Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    cornerRadius*: ClayCornerRadius
    ##  Controls settings related to aspect ratio scaling.
    aspectRatio*: ClayAspectRatioElementConfig
    ##  Controls settings related to image elements.
    image*: ClayImageElementConfig
    ##  Controls whether and how an element "floats", which means it layers over the top of other elements in z order, and doesn't affect the position and size of siblings or parent elements.
    ##  Note: in order to activate floating, .floating.attachTo must be set to something other than the default value.
    floating*: ClayFloatingElementConfig
    ##  Used to create CUSTOM render commands, usually to render element types not supported by Clay.
    custom*: ClayCustomElementConfig
    ##  Controls whether an element should clip its contents, as well as providing child x,y offset configuration for scrolling.
    clip*: ClayClipElementConfig
    ##  Controls settings related to element borders, and will generate BORDER render commands.
    border*: ClayBorderElementConfig
    ##  A pointer that will be transparently passed through to resulting render commands.
    userData*: pointer

  ##  Represents the type of error clay encountered while computing layout.
  ClayErrorType* {.size: sizeof(uint8).} = enum
    TextMeasurementFunctionNotProvided,  ##  A text measurement function wasn't provided using ClaySetMeasureTextFunction(), or the provided function was null.
    ArenaCapacityExceeded, ##  Clay attempted to allocate its internal data structures but ran out of space.
                                                           ##  The arena passed to ClayInitialize was created with a capacity smaller than that required by ClayMinMemorySize().
    ElementsCapacityExceeded, ##  Clay ran out of capacity in its internal array for storing elements. This limit can be increased with ClaySetMaxElementCount().
    TextMeasurementCapacityExceeded, ##  Clay ran out of capacity in its internal array for storing elements. This limit can be increased with ClaySetMaxMeasureTextCacheWordCount().
    DuplicateId, ##  Two elements were declared with exactly the same ID within one layout.
    FloatingContainerParentNotFound, ##  A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
    PercentageOver1, ##  An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
    InternalError ##  Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!

  ##  Data to identify the error that clay has encountered.
  ClayErrorData* {.bycopy.} = object
    ##  Represents the type of error clay encountered while computing layout.
    ##  TextMeasurementFunctionNotProvided - A text measurement function wasn't provided using ClaySetMeasureTextFunction(), or the provided function was null.
    ##  ArenaCapacityExceeded - Clay attempted to allocate its internal data structures but ran out of space. The arena passed to ClayInitialize was created with a capacity smaller than that required by ClayMinMemorySize().
    ##  ElementsCapacityExceeded - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with ClaySetMaxElementCount().
    ##  TextMeasurementCapacityExceeded - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with ClaySetMaxMeasureTextCacheWordCount().
    ##  DuplicateId - Two elements were declared with exactly the same ID within one layout.
    ##  FloatingContainerParentNotFound - A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
    ##  PercentageOver1 - An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
    ##  InternalError - Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!
    errorType*: ClayErrorType
    ##  A string containing human-readable error text that explains the error in more detail.
    errorText*: ClayString
    ##  A transparent pointer passed through from when the error handler was first provided.
    userData*: pointer

  ##  A wrapper struct around Clay's error handler function.
  ClayErrorHandler* {.bycopy.} = object
    ##  A user provided function to call when Clay encounters an error during layout.
    errorHandlerFunction*: proc (errorText: ClayErrorData)
    ##  A pointer that will be transparently passed through to the error handler when it is called.
    userData*: pointer

var CLAY_LAYOUT_DEFAULT* {.importc: "CLAY_LAYOUT_DEFAULT".}: ClayLayoutConfig

proc minMemorySize*(): uint32 {.cdecl, importc: "Clay_MinMemorySize".}
  ##  Returns the size, in bytes, of the minimum amount of memory Clay requires to operate at its current settings.

proc createArenaWithCapacityAndMemory*(capacity: csize_t; memory: pointer): ClayArena {.cdecl, importc: "Clay_CreateArenaWithCapacityAndMemory".}
  ##  Creates an arena for clay to use for its internal allocations, given a certain capacity in bytes and a pointer to an allocation of at least that size.
  ##  Intended to be used with ClayMinMemorySize in the following way:
  ##  uint32 minMemoryRequired = ClayMinMemorySize();
  ##  ClayArena clayMemory = ClayCreateArenaWithCapacityAndMemory(minMemoryRequired, malloc(minMemoryRequired));

proc setPointerState*(position: ClayVector2; pointerDown: bool) {.cdecl, importc: "Clay_SetPointerState".}
  ##  Sets the state of the "pointer" (i.e. the mouse or touch) in Clay's internal data. Used for detecting and responding to mouse events in the debug view,
  ##  as well as for ClayHovered() and scroll element handling.

proc initialize*(arena: ClayArena; layoutDimensions: ClayDimensions;
                     errorHandler: ClayErrorHandler): ptr ClayContext {.cdecl, importc: "Clay_Initialize".}
  ##  Initialize Clay's internal arena and setup required data before layout can begin. Only needs to be called once.
  ##  - arena can be created using ClayCreateArenaWithCapacityAndMemory()
  ##  - layoutDimensions are the initial bounding dimensions of the layout (i.e. the screen width and height for a full screen layout)
  ##  - errorHandler is used by Clay to inform you if something has gone wrong in configuration or layout.

proc getCurrentContext*(): ptr ClayContext {.cdecl, importc: "Clay_GetCurrentContext".}
  ##  Returns the Context that clay is currently using. Used when using multiple instances of clay simultaneously.

proc setCurrentContext*(context: ptr ClayContext) {.cdecl, importc: "Clay_SetCurrentContext".}
  ##  Sets the context that clay will use to compute the layout.
  ##  Used to restore a context saved from ClayGetCurrentContext when using multiple instances of clay simultaneously.

proc updateScrollContainers*(enableDragScrolling: bool;
                                 scrollDelta: ClayVector2; deltaTime: cfloat) {.cdecl, importc: "Clay_UpdateScrollContainers".}
  ##  Updates the state of Clay's internal scroll data, updating scroll content positions if scrollDelta is non zero, and progressing momentum scrolling.
  ##  - enableDragScrolling when set to true will enable mobile device like "touch drag" scroll of scroll containers, including momentum scrolling after the touch has ended.
  ##  - scrollDelta is the amount to scroll this frame on each axis in pixels.
  ##  - deltaTime is the time in seconds since the last "frame" (scroll update)

proc getScrollOffset*(): ClayVector2 {.cdecl, importc: "Clay_GetScrollOffset".}
  ##  Returns the internally stored scroll offset for the currently open element.
  ##  Generally intended for use with clip elements to create scrolling containers.

proc setLayoutDimensions*(dimensions: ClayDimensions) {.cdecl, importc: "Clay_SetLayoutDimensions".}
  ##  Updates the layout dimensions in response to the window or outer container being resized.

proc beginLayout*() {.cdecl, importc: "Clay_BeginLayout".}
  ##  Called before starting any layout declarations.

proc endLayout*(): ClayRenderCommandArray {.cdecl, importc: "Clay_EndLayout".}
  ##  Called when all layout declarations are finished.
  ##  Computes the layout and generates and returns the array of render commands to draw.

proc getElementId*(idString: ClayString): ClayElementId {.cdecl, importc: "Clay_GetElementId".}
  ##  Calculates a hash ID from the given idString.
  ##  Generally only used for dynamic strings when CLAY_ID("stringLiteral") can't be used.

proc getElementIdWithIndex*(idString: ClayString; index: uint32): ClayElementId {.cdecl, importc: "Clay_GetElementIdWithIndex".}
  ##  Calculates a hash ID from the given idString and index.
  ##  - index is used to avoid constructing dynamic ID strings in loops.
  ##  Generally only used for dynamic strings when CLAY_IDI("stringLiteral", index) can't be used.

proc getElementData*(id: ClayElementId): ClayElementData {.cdecl, importc: "Clay_GetElementData".}
  ##  Returns layout data such as the final calculated bounding box for an element with a given ID.
  ##  The returned ClayElementData contains a `found` bool that will be true if an element with the provided ID was found.
  ##  This ID can be calculated either with CLAY_ID() for string literal IDs, or ClayGetElementId for dynamic strings.

proc hovered*(): bool {.cdecl, importc: "Clay_Hovered".}
  ##  Returns true if the pointer position provided by ClaySetPointerState is within the current element's bounding box.
  ##  Works during element declaration, e.g. CLAY({ .backgroundColor = ClayHovered() ? BLUE : RED });

proc onHover*(onHoverFunction: proc (elementId: ClayElementId;
                                       pointerData: ClayPointerData;
                                       userData: pointer) {.cdecl.}; userData: pointer) {.cdecl, importc: "Clay_OnHover".}
  ##  Bind a callback that will be called when the pointer position provided by ClaySetPointerState is within the current element's bounding box.
  ##  - onHoverFunction is a function pointer to a user defined function.
  ##  - userData is a pointer that will be transparently passed through when the onHoverFunction is called.

proc pointerOver*(elementId: ClayElementId): bool {.cdecl, importc: "Clay_PointerOver".}
  ##  An imperative function that returns true if the pointer position provided by ClaySetPointerState is within the element with the provided ID's bounding box.
  ##  This ID can be calculated either with CLAY_ID() for string literal IDs, or ClayGetElementId for dynamic strings.

proc getPointerOverIds*(): ClayElementIdArray {.cdecl, importc: "Clay_GetPointerOverIds".}
  ##  Returns the array of element IDs that the pointer is currently over.

proc getScrollContainerData*(id: ClayElementId): ClayScrollContainerData {.cdecl, importc: "Clay_GetScrollContainerData".}
  ##  Returns data representing the state of the scrolling element with the provided ID.
  ##  The returned ClayScrollContainerData contains a `found` bool that will be true if a scroll element was found with the provided ID.
  ##  An imperative function that returns true if the pointer position provided by ClaySetPointerState is within the element with the provided ID's bounding box.
  ##  This ID can be calculated either with CLAY_ID() for string literal IDs, or ClayGetElementId for dynamic strings.

proc setMeasureTextFunction*(measureTextFunction: proc (
    text: ClayStringSlice; config: ptr ClayTextElementConfig; userData: pointer): ClayDimensions {.cdecl.};
                                 userData: pointer) {.cdecl, importc: "Clay_SetMeasureTextFunction".}
  ##  Binds a callback function that Clay will call to determine the dimensions of a given string slice.
  ##  - measureTextFunction is a user provided function that adheres to the interface ClayDimensions (ClayStringSlice text, ClayTextElementConfig *config, void *userData);
  ##  - userData is a pointer that will be transparently passed through when the measureTextFunction is called.

proc setQueryScrollOffsetFunction*(queryScrollOffsetFunction: proc (
    elementId: uint32; userData: pointer): ClayVector2 {.cdecl.}; userData: pointer) {.cdecl, importc: "Clay_SetQueryScrollOffsetFunction".}
  ##  Experimental - Used in cases where Clay needs to integrate with a system that manages its own scrolling containers externally.
  ##  Please reach out if you plan to use this function, as it may be subject to change.

proc renderCommandArray_Get*(array: ptr ClayRenderCommandArray; index: int32): ptr ClayRenderCommand {.cdecl, importc: "Clay_RenderCommandArray_Get".}
  ##  A bounds-checked "get" function for the ClayRenderCommandArray returned from ClayEndLayout().

proc setDebugModeEnabled*(enabled: bool) {.cdecl, importc: "Clay_SetDebugModeEnabled".}
  ##  Enables and disables Clay's internal debug tools.
  ##  This state is retained and does not need to be set each frame.

proc isDebugModeEnabled*(): bool {.cdecl, importc: "Clay_IsDebugModeEnabled".}
  ##  Returns true if Clay's internal debug tools are currently enabled.

proc setCullingEnabled*(enabled: bool) {.cdecl, importc: "Clay_SetCullingEnabled".}
  ##  Enables and disables visibility culling. By default, Clay will not generate render commands for elements whose bounding box is entirely outside the screen.

proc getMaxElementCount*(): int32 {.cdecl, importc: "Clay_GetMaxElementCount".}
  ##  Returns the maximum number of UI elements supported by Clay's current configuration.

proc setMaxElementCount*(maxElementCount: int32) {.cdecl, importc: "Clay_SetMaxElementCount".}
  ##  Modifies the maximum number of UI elements supported by Clay's current configuration.
  ##  This may require reallocating additional memory, and re-calling ClayInitialize();

proc getMaxMeasureTextCacheWordCount*(): int32 {.cdecl, importc: "Clay_GetMaxMeasureTextCacheWordCount".}
  ##  Returns the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.

proc setMaxMeasureTextCacheWordCount*(maxMeasureTextCacheWordCount: int32) {.cdecl, importc: "Clay_SetMaxMeasureTextCacheWordCount".}
  ##  Modifies the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.
  ##  This may require reallocating additional memory, and re-calling ClayInitialize();

proc resetMeasureTextCache*() {.cdecl, importc: "Clay_ResetMeasureTextCache".}
  ##  Resets Clay's internal text measurement cache. Useful if font mappings have changed or fonts have been reloaded.

proc internal_OpenElement*() {.cdecl, importc: "Clay__OpenElement".}
proc internal_ConfigureOpenElement*(config: ClayElementDeclaration) {.cdecl, importc: "Clay__ConfigureOpenElement".}
proc internal_ConfigureOpenElementPtr*(config: ptr ClayElementDeclaration) {.cdecl, importc: "Clay__ConfigureOpenElementPtr".}
proc internal_CloseElement*() {.cdecl, importc: "Clay__CloseElement".}
proc internal_HashString*(key: ClayString; seed: uint32): ClayElementId {.cdecl, importc: "Clay__HashString".}
proc internal_HashStringWithOffset*(key: ClayString; offset: uint32; seed: uint32): ClayElementId {.cdecl, importc: "Clay__HashStringWithOffset".}
proc internal_OpenTextElement*(text: ClayString; textConfig: ptr ClayTextElementConfig) {.cdecl, importc: "Clay__OpenTextElement".}
proc internal_StoreTextElementConfig*(config: ClayTextElementConfig): ptr ClayTextElementConfig {.cdecl, importc: "Clay__StoreTextElementConfig".}
proc internal_GetParentElementId*(): uint32 {.cdecl, importc: "Clay__GetParentElementId".}

var ClaydebugViewHighlightColor* {.importc: "Clay_debugViewHighlightColor".}: ClayColor
var ClaydebugViewWidth* {.importc: "Clay_debugViewWidth".}: uint32
var ClaydebugMaxElementsLatch* {.importc: "Clay_debugMaxElementsLatch".}: bool

func clayColor*(r, g, b: float32, a: float32 = 1): ClayColor =
  ClayColor(
    r: (r * 255).cfloat,
    g: (g * 255).cfloat,
    b: (b * 255).cfloat,
    a: (a * 255).cfloat,
  )

func cornerRadius*(topLeft, topRight, bottomLeft, bottomRight: float): ClayCornerRadius =
  ClayCornerRadius(
    topLeft: topLeft.cfloat,
    topRight: topRight.cfloat,
    bottomLeft: bottomLeft.cfloat,
    bottomRight: bottomRight.cfloat,
  )

proc `$`*(str: ClayString): string =
  result = newStringUninit(str.length.int)
  for i in 0..<str.length.int:
    result[i] = str.chars[i]

macro UI*(args: varargs[untyped]): untyped =
  # defer:
  #   echo result.repr

  var children = nnkStmtList.newTree()

  var elementDecl = nnkObjConstr.newTree(ident"ClayElementDeclaration")
  for k in 0..<args.len:
    let arg = args[k]
    if k == args.len - 1 and arg.kind == nnkStmtList:
      children = arg
    else:
      elementDecl.add(nnkExprColonExpr.newTree(arg[0], arg[1]))

  result = genAst(children, elementDecl):
    try:
      internal_OpenElement()
      internal_ConfigureOpenElement(elementDecl)
      children
    finally:
      internal_CloseElement()

converter toUncheckedArray*[T](arr: openArray[T]): ptr UncheckedArray[T] =
  if arr.len > 0:
    cast[ptr UncheckedArray[T]](arr[0].addr)
  else:
    nil

macro clayText*(str: openArray[char], args: varargs[untyped]): untyped =
  defer:
    echo result.repr

  var call = nnkCall.newTree(ident"internal_OpenTextElement")
  let strConv = if str.kind == nnkStrLit:
    genAst(str):
      ClayString(length: str.len.cint, chars: cast[ptr UncheckedArray[char]](str.cstring))
  else:
    genAst(str):
      ClayString(length: str.len.cint, chars: str.toUncheckedArray)
  call.add(strConv)

  proc parseArgsInto(into: var NimNode, arg: NimNode) =
    if arg.len == 1 and arg[0].kind != nnkExprEqExpr:
      into = arg[0]
    else:
      for k in 0..<arg.len:
        let prop = arg[k]
        into.add(nnkExprColonExpr.newTree(prop[0], prop[1]))

  var textConfig = nnkObjConstr.newTree(ident"ClayTextElementConfig")
  textConfig.parseArgsInto(args)
  let configPtr = genAst(textConfig):
    internal_StoreTextElementConfig(textConfig)
  call.add(configPtr)

  return call

iterator items*(self: ClayRenderCommandArray): ptr ClayRenderCommand =
  for i in 0..<self.length.int:
    yield self.internalArray[i].addr

template toOpenArray*(s: ClayStringSlice): openArray[char] =
  s.chars.toOpenArray(0, s.length - 1)
