#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <cstring>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#if __has_include(<X11/extensions/scrnsaver.h>) && __has_include(<X11/Xlib.h>)
#define STRUCTURAL_HAS_XSCREENSAVER 1
#include <X11/Xlib.h>
#include <X11/extensions/scrnsaver.h>
#endif
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static constexpr char kSystemIdleChannel[] = "structural/system_idle";

static bool g_mutter_idle_available = false;
static bool g_x11_idle_available = false;
static bool g_idle_support_probed = false;
static const char* g_mutter_idle_path = nullptr;
static const char* g_mutter_idle_cached_paths[2] = {nullptr, nullptr};

static const char* kMutterIdlePaths[] = {
    "/org/gnome/Mutter/IdleMonitor/Core",
    "/org/gnome/Mutter/IdleMonitor",
    nullptr,
};

static bool parse_idletime_variant(GVariant* result, int64_t* idle_ms) {
  if (result == nullptr) {
    return false;
  }

  GVariant* value = result;
  g_autoptr(GVariant) child = nullptr;
  if (g_variant_is_of_type(result, G_VARIANT_TYPE("(t)")) ||
      g_variant_is_of_type(result, G_VARIANT_TYPE("(u)")) ||
      g_variant_is_of_type(result, G_VARIANT_TYPE("(x)")) ||
      g_variant_is_of_type(result, G_VARIANT_TYPE("(i)"))) {
    child = g_variant_get_child_value(result, 0);
    value = child;
  }

  if (g_variant_is_of_type(value, G_VARIANT_TYPE_UINT64)) {
    *idle_ms = static_cast<int64_t>(g_variant_get_uint64(value));
    return true;
  }
  if (g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    *idle_ms = static_cast<int64_t>(g_variant_get_uint32(value));
    return true;
  }
  if (g_variant_is_of_type(value, G_VARIANT_TYPE_INT64)) {
    *idle_ms = g_variant_get_int64(value);
    return true;
  }
  if (g_variant_is_of_type(value, G_VARIANT_TYPE_INT32)) {
    *idle_ms = g_variant_get_int32(value);
    return true;
  }

  return false;
}

static bool mutter_get_idle_milliseconds(int64_t* idle_ms) {
  g_autoptr(GDBusConnection) connection = g_bus_get_sync(
      G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (connection == nullptr) {
    return false;
  }

  const char* const* paths = kMutterIdlePaths;
  if (g_mutter_idle_path != nullptr) {
    g_mutter_idle_cached_paths[0] = g_mutter_idle_path;
    g_mutter_idle_cached_paths[1] = nullptr;
    paths = g_mutter_idle_cached_paths;
  }

  for (gint i = 0; paths[i] != nullptr; i++) {
    g_autoptr(GVariant) result = g_dbus_connection_call_sync(
        connection, "org.gnome.Mutter.IdleMonitor", paths[i],
        "org.gnome.Mutter.IdleMonitor", "GetIdletime", nullptr, nullptr,
        G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr);
    if (result == nullptr) {
      continue;
    }

    if (parse_idletime_variant(result, idle_ms)) {
      if (g_mutter_idle_path == nullptr) {
        g_mutter_idle_path = paths[i];
      }
      return true;
    }
  }

  return false;
}

static bool x11_get_idle_milliseconds(int64_t* idle_ms) {
#if defined(GDK_WINDOWING_X11) && defined(STRUCTURAL_HAS_XSCREENSAVER)
  GdkDisplay* display = gdk_display_get_default();
  if (display == nullptr || !GDK_IS_X11_DISPLAY(display)) {
    return false;
  }

  Display* xdisplay = gdk_x11_display_get_xdisplay(display);
  if (xdisplay == nullptr) {
    return false;
  }

  XScreenSaverInfo* info = XScreenSaverAllocInfo();
  if (info == nullptr) {
    return false;
  }

  const Window root = DefaultRootWindow(xdisplay);
  const Status status = XScreenSaverQueryInfo(xdisplay, root, info);
  if (status == 0) {
    XFree(info);
    return false;
  }

  *idle_ms = static_cast<int64_t>(info->idle);
  XFree(info);
  return true;
#else
  return false;
#endif
}

static void ensure_mutter_idle_available() {
  if (g_mutter_idle_available) {
    return;
  }

  int64_t idle_ms = 0;
  g_mutter_idle_available = mutter_get_idle_milliseconds(&idle_ms);
}

static void ensure_x11_idle_available() {
  if (g_x11_idle_available || g_idle_support_probed) {
    return;
  }

#if defined(GDK_WINDOWING_X11) && defined(STRUCTURAL_HAS_XSCREENSAVER)
  GdkDisplay* display = gdk_display_get_default();
  if (display != nullptr && GDK_IS_X11_DISPLAY(display)) {
    int64_t idle_ms = 0;
    g_x11_idle_available = x11_get_idle_milliseconds(&idle_ms);
  }
#endif

  g_idle_support_probed = true;
}

static bool linux_is_system_idle_supported() {
  ensure_mutter_idle_available();
  ensure_x11_idle_available();
  return g_mutter_idle_available || g_x11_idle_available;
}

static bool linux_get_idle_milliseconds(int64_t* idle_ms) {
  ensure_mutter_idle_available();
  ensure_x11_idle_available();

  if (g_mutter_idle_available && mutter_get_idle_milliseconds(idle_ms)) {
    return true;
  }

  if (g_x11_idle_available && x11_get_idle_milliseconds(idle_ms)) {
    return true;
  }

  return false;
}

static void system_idle_method_call_handler(FlMethodChannel* channel,
                                            FlMethodCall* method_call,
                                            gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isSupported") == 0) {
    g_autoptr(FlValue) supported =
        fl_value_new_bool(linux_is_system_idle_supported());
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(supported));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  if (strcmp(method, "getIdleMilliseconds") == 0) {
    int64_t idle_ms = 0;
    g_autoptr(FlValue) value = linux_get_idle_milliseconds(&idle_ms)
                                   ? fl_value_new_int(idle_ms)
                                   : fl_value_new_null();
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(value));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  g_autoptr(FlMethodResponse) not_implemented =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, not_implemented, nullptr);
}

static void register_system_idle_channel(FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      messenger, kSystemIdleChannel, FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, system_idle_method_call_handler, nullptr, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  // Flutter draws its own Material AppBar; a GTK HeaderBar stays light and does
  // not follow ThemeMode.system, which looks like a permanent white top strip.
  gboolean use_header_bar = FALSE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "structural");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "structural");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  register_system_idle_channel(view);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
