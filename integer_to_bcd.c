unsigned int integer_to_bcd (unsigned int  in){
	unsigned int out = 0;
	unsigned int i;
	for (i=0;in;i++) {
		out |= (in%10)<<(4*i);
		in /=10;
        }
        return out;
}
