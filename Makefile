%.swf: %.as
	mxmlc $<

clean:
	rm -f *.swf

all: Board.swf
