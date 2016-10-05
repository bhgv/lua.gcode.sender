#!/usr/bin/python

import GCode

def test():
    #f = open("_pcb_promicro_ca3306.gcode", "r")
    f = open("tst_pars.gcode", "r")
    #f = open("1st-bottom.gcode", "r")
    gtxt = f.read() 
    f.close()

    def cmd_cb(op, par1, par2):
        print "op=%s: %s %s" % (op, par1, par2)
        return None

    def eol_cb(op, par1):
        print "op=%s: %s" % (op, par1)
        return None

    #GCode.set_out_type_by_line()
    GCode.set_out_type_by_cmd()

    GCode.set_callback_dict(
        {
            "cmd": cmd_cb,
	    "eol": eol_cb,
        }
    )

    a = GCode.do_parse(gtxt) 

    print a


if __name__ == "__main__":
    test()
    
