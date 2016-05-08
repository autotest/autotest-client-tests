function display(x,str,  i,res) {
	for (i = 0; i < n; i++) {
		if ((res = sprintf(formats[i],x)) != str)
			printf "sprintf(%s,%s) = %s (!= %s)\n",
			       formats[i],x,res,str
	}
}

BEGIN {
	nan = sqrt(-1)
	nan_str = sprintf("%f",nan)
	nnan_str = sprintf("%f",-nan)
	inf = -log(0)
	inf_str = sprintf("%f",inf)

	n = 0
	formats[n++] = "%f"
	formats[n++] = "%s"
	formats[n++] = "%g"
	formats[n++] = "%x"
	formats[n++] = "%d"
	display(nan,nan_str)
	display(-nan,nnan_str)
	display(inf,inf)
	display(-inf,"-"inf_str)
}
