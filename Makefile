Board.swf: *.as
	mxmlc -static-link-runtime-shared-libraries Board.as

all: Board.swf

clean:
	rm -f *.swf
