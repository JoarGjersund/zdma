#include "common.h"
#include "ap_int.h"

#define KERN_DIM 3

int CORE_NAME(axi_stream_t& src, axi_stream_t& dst, ap_uint<LINE_WIDTH_BITS> line_width)
{
#pragma HLS INTERFACE axis port=src bundle=INPUT_STREAM
#pragma HLS INTERFACE axis port=dst bundle=OUTPUT_STREAM
#ifdef CLK_AXILITE
#  pragma HLS INTERFACE s_axilite clock=axi_lite_clk port=line_width bundle=control offset=0x10
#  pragma HLS INTERFACE s_axilite clock=axi_lite_clk port=return bundle=control offset=0x38
#else
#  pragma HLS INTERFACE s_axilite port=line_width bundle=control offset=0x10
#  pragma HLS INTERFACE s_axilite port=return bundle=control offset=0x38
#endif
#pragma HLS INTERFACE ap_stable port=line_width
	axi_elem_t data_in, data_out;
	ap_uint<LINE_WIDTH_BITS> col;
	int ret;
	hls::LineBuffer<KERN_DIM, MAX_LINE_WIDTH+KERN_DIM, uint8_t> linebuf;
	hls::Window<KERN_DIM, KERN_DIM, ap_int<10> > win;
	ap_int<10> acc[AXI_TDATA_NBYTES];
	union {
		axi_data_t all;
		uint8_t at[AXI_TDATA_NBYTES];
	} pixel;

	int8_t kern[KERN_DIM][KERN_DIM] =	// kernel sum is 0
		{{ 0, -1,  0},
		 {-1,  5, -1},
		 { 0, -1,  0}};

	ret = 0;
	if (line_width < 0 || line_width > MAX_LINE_WIDTH) {
		line_width = MAX_LINE_WIDTH;
		ret = -1;
	}

	col = 0;
	do {
#pragma HLS loop_tripcount min=153600 max=518400
#pragma HLS pipeline
		src >> data_in;
		data_out.last = data_in.last;
		data_out.keep = data_in.keep;
		data_out.strb = data_in.strb;
		pixel.all = data_in.data;

		for (int px = 0; px < AXI_TDATA_NBYTES; px++) {

			linebuf.shift_up(col+px);
			linebuf.insert_top(pixel.at[px], col+px);

			for (int i = 0; i < KERN_DIM; i++) {
				for (int j = 0; j < KERN_DIM; j++) {
					win.insert(kern[i][j] * linebuf.getval(i, j+col+px), i, j);
				}
			}

			acc[px] = 0;
			for (int i = 0; i < KERN_DIM; i++) {
				for (int j = 0; j < KERN_DIM; j++) {
					acc[px] += win.getval(i, j);
				}
			}

			pixel.at[px] = (uint8_t)acc[px];
			if (acc[px] > 255) pixel.at[px] = 255;
			if (acc[px] < 0) pixel.at[px] = 0;
		}

		data_out.data = pixel.all;
		col += AXI_TDATA_NBYTES;

		if (col >= line_width)
			col = 0;

		dst << data_out;
	} while (!data_out.last);
	return ret;
}

