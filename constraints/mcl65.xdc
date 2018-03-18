# NOTE: -edge_shift takes durations rather than a phase angle. CORE_CLK's speed isn't known by this module
# so assume 50MHz.  If the target's clock is significantly faster, this may need to be adjusted.
# These settings have been tested up to 100MHz.

# CLK2 is CLK0 delayed by 2 CORE_CLK ticks
create_generated_clock -source [get_ports CLK0] -edges {1 2 3} -edge_shift {40 40 40} [get_ports CLK2]

# CLK1 is CLK2 inverted and delayed by an additional 1 CORE_CLK tick
create_generated_clock -source [get_ports CLK2] -edges {2 3 4} -edge_shift {20 20 20} [get_ports CLK1]