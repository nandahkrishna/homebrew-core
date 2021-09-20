class Libsoup < Formula
  desc "HTTP client/server library for GNOME"
  homepage "https://wiki.gnome.org/Projects/libsoup"
  url "https://download.gnome.org/sources/libsoup/3.0/libsoup-3.0.0.tar.xz"
  sha256 "cde05f3e20114ce985cbd03d575ff74e5e41e70a218e5eb3068c4bf4710dbf2b"
  license "LGPL-2.0-or-later"

  bottle do
    sha256 arm64_big_sur: "18fb8d1e8cec64c10c52a3ded030d3fe4654b731f8b02b20dd8ffec3341d2f6e"
    sha256 big_sur:       "8700bd873ac856454488b0d939097325223d1057ca26115b3963f3c134007dc5"
    sha256 catalina:      "eb35014ddd40741eb402417c27e4c6f19d2e542068bc92cc21c5e109406f444e"
    sha256 mojave:        "4820560eb5d36deb401ee874ba94fa5be831c32534d725ec9519b06f29366b7e"
    sha256 x86_64_linux:  "25ea8679e3d63aacf2ea6c1760635b130397997c60333ee691ba9c7565cc0933"
  end

  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "vala" => :build
  depends_on "glib-networking"
  depends_on "gnutls"
  depends_on "libpsl"

  uses_from_macos "krb5"
  uses_from_macos "libxml2"

  def install
    mkdir "build" do
      system "meson", *std_meson_args, ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    # if this test start failing, the problem might very well be in glib-networking instead of libsoup
    (testpath/"test.c").write <<~EOS
      #include <libsoup/soup.h>

      int main(int argc, char *argv[]) {
        SoupMessage *msg = soup_message_new(SOUP_METHOD_GET, "https://brew.sh");
        SoupSession *session = soup_session_new();
        GError *error = NULL;
        GBytes *bytes = soup_session_send_and_read(session, msg, NULL, &error); // blocks

        if(error) {
          g_error_free(error);
          return 1;
        }

        g_object_unref(msg);
        g_object_unref(session);
        return 0;
      }
    EOS
    ENV.libxml2
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    flags = %W[
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}/libsoup-3.0
      -D_REENTRANT
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{lib}
      -lgio-2.0
      -lglib-2.0
      -lgobject-2.0
      -lsoup-3.0
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
