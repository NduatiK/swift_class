"button-style-" <> button_style do
  buttonStyle(style: to_atom(button_style))
end

"p-" <> padding do
  padding(edges: :all, length: to_integer(padding))
end

"ph-" <> padding do
  padding(edges: :horizontal, length: to_integer(padding))
end

"pv-" <> padding do
  padding(edges: :veritcal, length: to_integer(padding))
end

"w-full" do
  frame(maxWidth: :infinity, width: :infinity)
end

"h-full" do
  frame(maxHeight: :infinity, height: :infinity)
end

"h-" <> height do
  frame(height: to_integer(height))
end

"offset-x-" <> offset do
  offset(x: to_integer(offset))
end

"offset-y-" <> offset do
  offset(y: to_integer(offset))
end

"hidden" do
  hidden(true)
end

"stretch" do
  resizable(resizing_mode: :stretch)
end

"italic" do
  italic(isActive: true)
end

"capitalize" do
  textCase(uppercase: true)
end

"type-size-" <> size do
  dynamicTypeSize(to_atom(size))
end

"kerning" <> kerning do
  kerning(kerning: to_float(kerning))
end

"tracking-" <> tracking do
  tracking(to_float(tracker))
end

"font-weight-" <> weight do
  fontWeight(to_atom(weight))
end

"font-" <> font do
  font(font: {"system", font})
end

"line-spacing-" <> line_spacing do
  lineSpacing(to_float(line_spacing))
end

"scroll-disabled" do
  scrollDisabled(disabled: true)
end

"align-" <> alignment do
  frame(maxWidth: :infinity, alignment: to_atom(alignment))
  multilineTextAlignment(to_atom(alignment))
end

"autocapitalize-" <> autocapitalize do
  textInputAutocapitalization(autocapitalization: to_atom(autocapitalization))
end

"disable-autocorreect" do
  autocorrectionDisabled(disable: true)
end

"text-field-" <> style do
  textFieldStyle(style: to_atom(style))
end

"background:" <> content do
  background() { to_atom(content) }
end

"overlay:" <> content do
  overlay() { to_atom(content) }
end

"fg-color-" <> fg_color do
  foregroundColor(color: to_atom(fg_color))
end

"fg-color:" <> fg_color do
  foregroundColor(color: to_atom(fg_color))
end

"tint-" <> tint do
  tint(color: to_atom(tint))
end

"tint:" <> tint do
  tint(color: to_atom(tint))
end

"border-" <> border_color do
  stroke(width: 1, {:Color, to_atom(border_color)})
end

"border:" <> border_color do
  stroke(width: 1, {:Color, border_color})
end

"stroke-" <> stroke_color do
  stroke(style: [lineWidth: 1], {:Color, to_atom(stroke_color)})
end

"stroke:" <> stroke_color do
  stroke(style: [lineWidth: 1], {:Color, stroke_color})
end

"line-limit-" <> number do
  lineLimit(number: to_integer(number))
end

"keyboard-type-" <> keyboard_type do
  keyboardType(keyboardType: to_atom(keyboard_type))
end

"opacity-" <> number do
  opacity(opacity: to_float(number))
end

"full-screen-cover:" <> content do
  fullScreenCover(isPresented: true) { to_atom(content) }
end

"image-scale-" <> image_scale do
  imageScale(to_atom(image_scale))
end
