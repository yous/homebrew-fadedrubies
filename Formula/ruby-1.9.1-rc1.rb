class Ruby191Rc1 < Formula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-rc1.tar.bz2"
  sha256 "35acfb6b8d9dd9159ef308ac763c629092cda2e8c9f41254e72a7b9fa454c27f"

  keg_only "Installing another version in parallel can cause conflicts."

  option :universal
  option "with-doc", "Install documentation"
  option "with-tcltk", "Install with Tcl/Tk support"

  # gcc47 isn't available on OS X 10.11.
  # https://github.com/Homebrew/homebrew-versions/issues/1056
  # gcc44 isn't available on OS X 10.10.
  depends_on MaximumMacOSRequirement => :mavericks

  depends_on "pkg-config" => :build
  depends_on "readline" => :recommended
  depends_on "gdbm" => :optional
  depends_on "openssl098"
  depends_on :x11 if build.with? "tcltk"

  fails_with :clang do
    build 703
  end

  fails_with :gcc => "4.4"
  fails_with :gcc => "4.5"
  fails_with :gcc => "4.6"
  fails_with :gcc => "4.7"
  fails_with :gcc => "4.8"
  fails_with :gcc => "4.9"
  fails_with :gcc => "5"

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
    "-1.9.1-rc1"
  end

  test do
    hello_text = shell_output("#{bin}/ruby#{program_suffix} -e 'puts :hello'")
    assert_equal "hello\n", hello_text
    system "#{bin}/gem#{program_suffix}", "list", "--local"
  end
end
