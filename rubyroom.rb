#!/usr/bin/env ruby

require 'gtk2'

class String
	def count_words
		n = 0
		scan(/\b\S+\b/) { n += 1}
		n
	end 
end

def create_file
	Dir.chdir() {
		File.open('.rubyroomrc', 'a'){ |f|
			f << "cursor #ffffff \n"
			f << "front #ffffff \n"
			f << "back #000000 \n"
			f << "Sans 12 \n"
		}
	}
end


#read the preference file
a=[] #to store the pref data
#is the file existent?
Dir.chdir() {create_file unless File.exist?(".rubyroomrc")}
pref_file = Dir.chdir() {File.new(".rubyroomrc", "r")}

i=0
while (line = pref_file.gets)
	a[i] = line.split
	@font = line if i == 3
	i = i + 1
end
pref_file.close

s = "style \"color-cursor\" {   "
s << "GtkTextView::cursor-color =  \"" + a[0][1].to_s + "\" " 
s << "} \n class \"GtkWidget\" style \"color-cursor\" "
Gtk::RC.parse_string(s)

@color_bg = Gdk::Color.parse(a[2][1])
@color_fg = Gdk::Color.parse(a[1][1])

def save_file
	File.open(@filename, "w"){|f|
		f.write(@buffer.get_text(*@buffer.bounds)) 
	}
end

def read_file
	File.open(@filename){|f| ret = f.readlines.join}
end

def select_file_save
	dialog = Gtk::FileChooserDialog.new("Save File", @window, Gtk::FileChooser::ACTION_SAVE, nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
	if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
		@filename = dialog.filename
	end
	dialog.destroy
end

def on_save_as_file
	select_file_save
	if @filename
		save_file
		status_text(@filename + " saved.")
		@changed = false
	end
end
  
def on_save_file
	if @filename
		save_file
	else
		on_save_as_file
	end
	if @filename
    		status_text(@filename + " saved.")
    		@changed = false
	end
end
  
def select_file_open
	dialog = Gtk::FileChooserDialog.new("Open File", @window, Gtk::FileChooser::ACTION_OPEN, nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
	dialog.has_focus=true	
	if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
		@filename = dialog.filename
	end
	dialog.destroy
end

def read_file
	File.open(@filename){|f| ret = f.readlines.join }
end

def open_file
	@window.title = @filename
	text = read_file
	@buffer.text = text
end

def on_open_as_file
	select_file_open
	if @filename
		open_file
		status_text(@filename + " opened")
	end
end

def show_help
	statustext = "  Help: F1 | Save: F2 | Open: F3 | Save as: F4 | Status ["
	if @verbose_status
		statustext=statustext+"ON"
	else 
		statustext=statustext+"OFF"
	end
	statustext=statustext+"]: F5 | Background: F6 | Foreground: F7 | Font: F8 | Fade ["
	if @fade_active
		statustext=statustext+"ON"
	else 
		statustext=statustext+"OFF"
	end
	statustext=statustext+"]: F9 | Quit: F10 | Fullscreen: F11 | Fortune: F12"
	status_text(statustext, false)
end

def on_status_toggle
	if @verbose_status
		@verbose_status = false
		status_text("Status text while typing is now turned off.")
	else
		@verbose_status = true
		status_text("Status text while typing is now turned on.")
	end
end

def on_fade_toggle
	if @fade_active
		@fade_active = false
		status_text("The text fade effect is now turned off.")
	else
		@fade_active = true
		status_text("The text fade effect is now turned on.")
	end
end

def on_quit
	if !@changed 
		Gtk.main_quit 
	else
		status_text("This text is not saved. Save (F2), " +
			"cancel (ESC) or quit wihout saving (F10 or close window)?", false)
		@exit_on_f10=true
	end
end

def write_color(a)
	red = a.red
	green = a.green
	blue = a.blue
	red /= 256
	green /= 256
	blue /= 256
	s = sprintf("#%02x%02x%02x", red, green, blue)
	return s
end

def write_pref
	Dir.chdir() {
		File.open('.rubyroomrc', 'w'){|f|
			f << "cursor " + write_color(@color_fg)  + "\n"
			f << "front " + write_color(@color_fg) + "\n"
			f << "back " + write_color(@color_bg) + "\n"
			f << @font + "\n"
		}
	}
end

def change_bg_color
	dialog = Gtk::ColorSelectionDialog.new("Select background color")
	dialog.has_focus = true
	dialog.set_transient_for(@window)
	dialog.colorsel.set_current_color(@color_bg)
	dialog.run do |response|
		case response
			when -5
    	   			@color_bg = dialog.colorsel.current_color
				@main.modify_base(Gtk::STATE_NORMAL, @color_bg)
				@main2.modify_base(Gtk::STATE_NORMAL, @color_bg)		
    		end
		dialog.destroy
	end
	write_pref
end

def change_fg_color
	dialog = Gtk::ColorSelectionDialog.new("Select foreground color")
	dialog.has_focus = true
	dialog.set_transient_for(@window)
	dialog.colorsel.set_current_color(@color_fg)
	dialog.run do |response|
		case response
			when -5
    	   			@color_fg = dialog.colorsel.current_color
				@main.modify_text(Gtk::STATE_NORMAL, @color_fg)
				@main2.modify_text(Gtk::STATE_NORMAL, @color_fg)
		end
		dialog.destroy
	end
	write_pref
end

def change_font
	dialog = Gtk::FontSelectionDialog.new("Select font")
	dialog.font_name = @font
	dialog.has_focus = true
	dialog.set_transient_for(@window)
	dialog.run do |response|
		case response
			when -5
				@main.modify_font(Pango::FontDescription.new(dialog.font_name))
	    			@font = dialog.font_name   	
	    	end
		dialog.destroy
	end
	write_pref
end

def status_color(color)
	@main2.modify_text(Gtk::STATE_NORMAL, color) if @main2
end

def  status_text(text, should_fade_out=true)
	@status.text = text
	fade_in
	fade_out if should_fade_out
end

def fade_out_thread
	if @fade_active
		sleep(0.2)
		while @sleep_amount > 0
			@sleep_amount -= 1
			return if !@fade_out_now
			ratio1 = @sleep_amount.to_f / @default_sleep_amount.to_f
			ratio2 = Math.log(ratio1 * 1.6 + 1)
			ratio =  Math.log(ratio2 * 1.6 + 1)
			@status_color.red =
				(@color_fg.red * ratio + @color_bg.red * (1 - ratio)).to_i
			@status_color.green =
				(@color_fg.green * ratio + @color_bg.green * (1 - ratio)).to_i
			@status_color.blue =
				(@color_fg.blue * ratio + @color_bg.blue * (1 - ratio)).to_i
			status_color(@status_color)
			sleep(ratio2 / 10.0)
		end
	else
		if @sleep_amount > 0
			sleep(4)
		end
	end
	status_color(@color_bg)
	@fade_out_now = false
end

def fade_out
	@fade_out_now = true
	@sleep_amount = @default_sleep_amount
end

def clear_status
	status_color(@color_bg)
end

def fade_in
	@fade_out_now = false
	status_color(@color_fg)
end

def info_status_text
	status_text(@buffer.line_count.to_s + " lines, " + @buffer.text.count_words.to_s + " words, " + @buffer.char_count.to_s + " characters") if @verbose_status
end

def toggle_fullscreen
	if @fullscreen
		@window.unfullscreen
		@fullscreen = false
	else
		@window.fullscreen
		@fullscreen = true
	end
	
end

def resize_margins
	@main.left_margin = @window.size[0] / 4
	@main.right_margin = @window.size[0] / 3
end

def init_stuff
	toggle_fullscreen
	show_help
end

def fortune
	if !@changed or @buffer.text.strip.empty?
		@buffer.text = "\n\n\n\n\n\n" + `fortune`
		@changed = false
		@filename = nil
	end
end

def main
	Gtk.init
	@changed = false
	@sleep_amount = 0	
	@default_sleep_amount = 26 # The time it takes to fade out measured in 0.1 seconds
	window = Gtk::Window.new("RubyRoom v0.4")
	@window = window
	@width = 1024
	@height = 768
	window.set_default_size(@width, @height)

	window.signal_connect("delete_event") do
		if @exit_on_f10
			Gtk.main_quit
	  	else
	    		on_quit
	  	end
	end

	window.signal_connect("destroy") do
	  Gtk.main_quit
	end

	ag = Gtk::AccelGroup.new

	ag.connect(Gdk::Keyval::GDK_Escape, 0, Gtk::ACCEL_VISIBLE) {
		if @exit_on_f10
			@exit_on_f10 = false
			clear_status
		else
			if @verbose_status
				clear_status
			else
				@verbose_status = true			
				info_status_text
				@verbose_status = false
			end
		end
	}

	ag.connect(Gdk::Keyval::GDK_F1, 0,
		  Gtk::ACCEL_VISIBLE) {
		show_help
	}

	ag.connect(Gdk::Keyval::GDK_F2, 0,
		  Gtk::ACCEL_VISIBLE) {
		on_save_file
	}

	ag.connect(Gdk::Keyval::GDK_F3, 0,
		  Gtk::ACCEL_VISIBLE) {
		on_open_as_file
	}

	ag.connect(Gdk::Keyval::GDK_F4, 0,
		  Gtk::ACCEL_VISIBLE) {
		on_save_as_file
	}

	ag.connect(Gdk::Keyval::GDK_F5, 0,
		  Gtk::ACCEL_VISIBLE) {
		on_status_toggle
	}

	ag.connect(Gdk::Keyval::GDK_F6, 0,
		  Gtk::ACCEL_VISIBLE) {
		change_bg_color
	}

	ag.connect(Gdk::Keyval::GDK_F7, 0,
		  Gtk::ACCEL_VISIBLE) {
		change_fg_color
	}

	ag.connect(Gdk::Keyval::GDK_F8, 0,
		  Gtk::ACCEL_VISIBLE) {
		change_font
	}

	ag.connect(Gdk::Keyval::GDK_F9, 0,
		  Gtk::ACCEL_VISIBLE) {
		on_fade_toggle
	}

	ag.connect(Gdk::Keyval::GDK_F10, 0,
		  Gtk::ACCEL_VISIBLE) {
		if @exit_on_f10
	 		Gtk.main_quit
		else
			on_quit
		end
	}

	ag.connect(Gdk::Keyval::GDK_F11, 0,
		  Gtk::ACCEL_VISIBLE) {
		toggle_fullscreen
		
	}

	ag.connect(Gdk::Keyval::GDK_F12, 0,
		  Gtk::ACCEL_VISIBLE) {
		fortune
		
	}

	window.add_accel_group(ag)

	box0 = Gtk::VBox.new(false, 0)
	window.add(box0)

	view = Gtk::TextView.new
	@buffer = view.buffer
	view.pixels_below_lines = 11 # Between "paragraphs"
	view.pixels_inside_wrap = 2 # Between lines in "paragraphs"
	view.wrap_mode = Gtk::TextTag::WRAP_WORD

	sw = Gtk::ScrolledWindow.new(nil, nil)
	sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
	box0.add(sw)
	sw.add(view)
	view.modify_base(Gtk::STATE_NORMAL, @color_bg)
	view.modify_text(Gtk::STATE_NORMAL, @color_fg)
	@main = view
	@main.modify_font(Pango::FontDescription.new(@font))

	@buffer.signal_connect("changed") do
		info_status_text
		@changed = true
		@exit_on_f10 = false
	end

	view2 = Gtk::TextView.new
	@status = view2.buffer
	@verbose_status = true
	view2.set_height_request(25)
	view2.modify_base(Gtk::STATE_NORMAL, @color_bg)
	view2.modify_text(Gtk::STATE_NORMAL, @color_fg)
	@status_color = @color_fg.dup
	box0.pack_end(view2,false,false,0)
	@main2 = view2

	resize_margins

	window.show_all

	@fade_active = true
	@fade_out_now = false

	@fullscreen = false

	init_stuff

	if ARGV.length > 0
		@filename = ARGV[0]
		open_file
		@changed = false
	end

	threads = []
	# One thread for running the main program
	threads << Thread.new {
		Gtk.main
		exit
	}
	# One thread for taking care of fadeouts
	threads << Thread.new {
		while true
			if @fade_out_now
				fade_out_thread
			else
				sleep(0.05)
			end
		end
	}
	threads.each { |aThread| aThread.join }
end

main
