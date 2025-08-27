TARGET = Top_tb

VCS_FILES = Top.v Top_tb.v

LIB_PATH = include


compile: $(TARGET).out

$(TARGET).out: $(VCS_FILES)
	iverilog -g2012 -o $(TARGET).out -y $(LIB_PATH) $(VCS_FILES)

all: run wave

test:
	python PythonTests/GradientDescent.py

run: $(TARGET).out
	vvp $(TARGET).out

wave:
	gtkwave $(TARGET).vcd -a $(TARGET).gtkw

clean:
	-rm *.out *.vcd
