%.swf: %.as
	mxmlc -static-link-runtime-shared-libraries $<

clean:
	rm -f *.swf

all: Board.swf
