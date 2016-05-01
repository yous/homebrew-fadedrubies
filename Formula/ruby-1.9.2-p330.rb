class Ruby192P330 < Formula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p330.tar.bz2"
  sha256 "6d3487ea8a86ad0fa78a8535078ff3c7a91ca9f99eff0a6a08e66c6e6bf2040f"

  option :universal
  option "with-doc", "Install documentation"
  option "with-tcltk", "Install with Tcl/Tk support"

  # gcc47 isn't available on OS X 10.11.
  # https://github.com/Homebrew/homebrew-versions/issues/1056
  # gcc46, gcc45 can't compile on OS X 10.10.
  # gcc44 isn't available on OS X 10.10.
  depends_on MaximumMacOSRequirement => :mavericks

  depends_on "pkg-config" => :build
  depends_on "readline" => :recommended
  depends_on "gdbm" => :optional
  depends_on "libffi" => :optional
  depends_on "libyaml"
  depends_on "openssl098"
  depends_on :x11 if build.with? "tcltk"

  fails_with :clang do
    build 703
  end

  fails_with :gcc => "4.7"
  fails_with :gcc => "4.8"
  fails_with :gcc => "4.9"
  fails_with :gcc => "5"

  keg_only "Installing another version in parallel can cause conflicts."

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
    args << "--with-out-ext=tk" if build.without? "tcltk"
    args << "--disable-install-doc" if build.without? "doc"
    args << "--disable-dtrace" unless MacOS::CLT.installed?

    # Reported upstream: https://bugs.ruby-lang.org/issues/10272
    args << "--with-setjmp-type=setjmp" if MacOS.version == :lion

    paths = [
      Formula["libyaml"].opt_prefix,
      Formula["openssl098"].opt_prefix,
    ]

    %w[readline gdbm libffi].each do |dep|
      paths << Formula[dep].opt_prefix if build.with? dep
    end

    args << "--with-opt-dir=#{paths.join(":")}"

    system "./configure", *args

    ENV.deparallelize # Parallel compilation fails
    system "make"
    system "make", "install"
  end

  def program_suffix
    "-1.9.2-p330"
  end

  test do
    hello_text = shell_output("#{bin}/ruby#{program_suffix} -e 'puts :hello'")
    assert_equal "hello\n", hello_text
    system "#{bin}/gem#{program_suffix}", "list", "--local"
  end
end
