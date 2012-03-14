%.swf: %.as
	mxmlc -static-link-runtime-shared-libraries $<

all: Board.swf

clean:
	rm -f *.swf
