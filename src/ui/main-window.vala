namespace ValaGL {
    
    
    [GtkTemplate (ui = "/valagl/ui/window.ui")]
    public class MainWindow : Adw.ApplicationWindow {
        [GtkChild]
        public unowned Gtk.GLArea area;
        [GtkChild]
        public unowned Adw.SwitchRow autorender;
        [GtkChild]
        private unowned Adw.SpinRow eye_x;
        [GtkChild]
        private unowned Adw.SpinRow eye_y;
        [GtkChild]
        private unowned Adw.SpinRow eye_z;
        [GtkChild]
        private unowned Adw.SpinRow center_x;
        [GtkChild]
        private unowned Adw.SpinRow center_y;
        [GtkChild]
        private unowned Adw.SpinRow center_z;
        [GtkChild]
        private unowned Adw.SpinRow up_x;
        [GtkChild]
        private unowned Adw.SpinRow up_y;
        [GtkChild]
        private unowned Adw.SpinRow up_z;
        
        private Canvas canvas;
        private bool rotating;
        
        public MainWindow(Gtk.Application app) {
            Object(application: app);
            
            eye_x.notify["value"].connect(() => update_eye());
            eye_y.notify["value"].connect(() => update_eye());
            eye_z.notify["value"].connect(() => update_eye());
            center_x.notify["value"].connect(() => update_eye());
            center_y.notify["value"].connect(() => update_eye());
            center_z.notify["value"].connect(() => update_eye());
            up_x.notify["value"].connect(() => update_eye());
            up_y.notify["value"].connect(() => update_eye());
            up_z.notify["value"].connect(() => update_eye());
            
            area.add_tick_callback(() => {
                if (autorender.active)
                    area.queue_render();
                
                return true;
            });
        }
        
        private void update_eye() {
            canvas.eye = Core.Vec3.from_data((float) eye_x.value, (float) eye_y.value, (float) eye_z.value);
            canvas.center = Core.Vec3.from_data((float) center_x.value, (float) center_y.value, (float) center_z.value);
            canvas.up = Core.Vec3.from_data((float) up_x.value, (float) up_y.value, (float) up_z.value);
            canvas.update_camera();
        }
        
        [GtkCallback]
        public void on_rotate(double x, double y) {
            if (rotating) {
                canvas.arc_camera.current_pos.x = (float) ((x - (area.get_width() / 2) ) / (area.get_width()/2)) * 1;
                canvas.arc_camera.current_pos.y = (float) (((area.get_height()/2) - y) / (area.get_height()/2)) * 1;
                canvas.arc_camera.current_pos.z = canvas.arc_camera.z_axis(canvas.arc_camera.current_pos.x, canvas.arc_camera.current_pos.y);
                canvas.arc_camera.rotation();
            }
        }
        
        [GtkCallback]
        public void on_start_rotate(int n_clicks, double x, double y) {
            canvas.arc_camera.start_pos.x = (float) ((x - (area.get_width() / 2) ) / (area.get_width() / 2)) * 1;
		    canvas.arc_camera.start_pos.y = (float) (((area.get_height() / 2) - y) / (area.get_height() / 2)) * 1;
		    canvas.arc_camera.start_pos.z = canvas.arc_camera.z_axis(canvas.arc_camera.start_pos.x, canvas.arc_camera.start_pos.y);
            rotating = true;
        }
        
        [GtkCallback]
        public void on_stop_rotate(int n_clicks, double x, double y) {
            canvas.arc_camera.replace();
            rotating = false;
        }
        
        [GtkCallback]
        public bool on_render(Gtk.GLArea area, Gdk.GLContext ctx) {
            area.make_current();
            
            canvas.paint_gl();
            return true;
        }
        
        [GtkCallback]
        public void on_realize(Gtk.Widget area) {
            (area as Gtk.GLArea)?.make_current();
            try {
                canvas = new Canvas();
            } catch (AppError e) {
                print("error %s", e.message);
            }
        }
        
        [GtkCallback]
        public void on_resize(int width, int height) {
            canvas.resize_gl(width, height);
        }
    }
}
