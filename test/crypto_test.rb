# -*- encoding: utf-8 -*-
require 'test_helper'

describe GPGME do
  it "does the roundtrip encrypting" do
    encrypted = GPGME::Crypto.encrypt TEXT[:plain], :always_trust => true, :recipients => KEYS.first[:sha]
    assert_equal TEXT[:plain], GPGME::Crypto.decrypt(encrypted).read
  end

  it "does so even with armored encrypted stuff" do
    encrypted = GPGME::Crypto.encrypt TEXT[:plain], :always_trust => true, :armor => true
    assert_equal TEXT[:plain], GPGME::Crypto.decrypt(encrypted).read
  end

  describe :encrypt do
    it "should raise an error if the recipients aren't trusted" do
      assert_raises GPGME::Error::General do
        GPGME::Crypto.encrypt TEXT[:plain]
      end
    end


    # it "can specify which key(s) to use for encrypting with a string"
    # it "can specify which key to use for encrypting with a Key object"
    # it "can also sign at the same time"
    # it "can be signed by more than one person"
    # it "outputs to a file if specified"
    # it "outputs to something else that responds to write"
  end

  describe "symmetric encryption/decryption" do
    it "requires a password to encrypt" do
      assert_raises GPGME::Error::BadPassphrase do
        GPGME::Crypto.encrypt TEXT[:plain], :symmetric => true
      end
    end

    it "requires a password to decrypt" do
      encrypted_data = GPGME::Crypto.encrypt TEXT[:plain],
        :symmetric => true, :password => "gpgme"

      assert_raises GPGME::Error::BadPassphrase do
        GPGME::Crypto.decrypt encrypted_data
      end
    end

    it "can encrypt and decrypt with the same password" do
      encrypted_data = GPGME::Crypto.encrypt TEXT[:plain],
        :symmetric => true, :password => "gpgme"

      plain = GPGME::Crypto.decrypt encrypted_data, :password => "gpgme"
      assert_equal "Hi there", plain.read
    end

    it "but breaks with different ones" do
      encrypted_data = GPGME::Crypto.encrypt TEXT[:plain],
        :symmetric => true, :password => "gpgme"

      assert_raises GPGME::Error::DecryptFailed do
        GPGME::Crypto.decrypt encrypted_data, :password => "wrong one"
      end
    end
  end

  describe :decrypt do
    it "decrypts encrypted stuff" do
      assert_equal TEXT[:plain], GPGME::Crypto.decrypt(TEXT[:encrypted]).read
    end

    it "will not get into the signatures block if there's none" do
      GPGME::Crypto.decrypt(TEXT[:encrypted]) do |signature|
        flunk "If I'm here means there was some signature"
      end
      pass
    end

    it "will get signature elements if the encrypted thing was signed" do
      signatures = 0
      GPGME::Crypto.decrypt(TEXT[:signed]) do |signature|
        assert_instance_of GPGME::Signature, signature
        signatures += 1
      end
      assert_equal 1, signatures
    end

    it "writes to the output if passed" do
      buffer = GPGME::Data.new
      GPGME::Crypto.decrypt(TEXT[:encrypted], :output => buffer)
      assert_equal TEXT[:plain], buffer.read
    end

    # TODO find ways to test this
    # it "raises UnsupportedAlgorithm"
    # it "raises WrongKeyUsage"

    it "raises DecryptFailed when the decrypting key isn't available" do
      assert_raises GPGME::Error::DecryptFailed do
        GPGME::Crypto.decrypt(TEXT[:unavailable])
      end
    end
  end

  describe :sign do
    it "signs normal strings" do
      signatures = 0
      sign = GPGME::Crypto.sign "Hi there"

      GPGME::Crypto.verify(sign) do |signature|
        assert_instance_of GPGME::Signature, signature
        signatures += 1
      end

      assert_equal 1, signatures
    end
  end
end
