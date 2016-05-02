class Ruby191Preview2 < Formula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-preview2.tar.bz2"
  version "1.9.1-preview2"
  sha256 "2c419dc325c6a75fb7b961496c0dd54f2729e6e01730589c4fb06e34ddd7a7cc"

  keg_only "Installing another version in parallel can cause conflicts."

  option :universal
  option "with-doc", "Install documentation"
  option "with-tcltk", "Install with Tcl/Tk support"

  depends_on "pkg-config" => :build
  depends_on "readline" => :recommended
  depends_on "gdbm" => :optional
  depends_on "openssl098"
  depends_on :x11 if build.with? "tcltk"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --with-sitedir=#{HOMEBREW_PREFIX}/lib/ruby/site_ruby
      --with-vendordir=#{HOMEBREW_PREFIX}/lib/ruby/vendor_ruby
    ]

    if build.universal?
      ENV.universal_binary
      args << "--with-arch=#{Hardware::CPU.universal_archs.join(",")}"
    end

    args << "--program-suffix=#{program_suffix}"
    args << "--enable-tcltk-framework" if build.with? "tcltk"
    args << "--disable-install-doc" if build.without? "doc"
    args << "--disable-dtrace" unless MacOS::CLT.installed?

    # Reported upstream: https://bugs.ruby-lang.org/issues/10272
    args << "--with-setjmp-type=setjmp" if MacOS.version == :lion

    paths = [
      Formula["openssl098"].opt_prefix,
    ]

    %w[readline gdbm].each do |dep|
      paths << Formula[dep].opt_prefix if build.with? dep
    end

    args << "--with-search-path=#{paths.join(":")}"

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  def program_suffix
    "-1.9.1-preview2"
  end

  test do
    hello_text = shell_output("#{bin}/ruby#{program_suffix} -e 'puts :hello'")
    assert_equal "hello\n", hello_text
    system "#{bin}/gem#{program_suffix}", "list", "--local"
  end
end
