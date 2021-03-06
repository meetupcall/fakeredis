require 'spec_helper'

module FakeRedis
  describe "HashesMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should delete a hash field" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      expect(@client.hdel("key1", "k1")).to be(1)

      expect(@client.hget("key1", "k1")).to be_nil
      expect(@client.hget("key1", "k2")).to eq("val2")
    end

    it "should delete array of fields" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      @client.hset("key1", "k3", "val3")
      expect(@client.hdel("key1", ["k1", "k2"])).to be(2)

      expect(@client.hget("key1", "k1")).to be_nil
      expect(@client.hget("key1", "k2")).to be_nil
      expect(@client.hget("key1", "k3")).to eq("val3")
    end

    it "should remove a hash with no keys left" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      expect(@client.hdel("key1", "k1")).to be(1)
      expect(@client.hdel("key1", "k2")).to be(1)

      expect(@client.exists("key1")).to eq(false)
    end

    it "should convert key to a string for hset" do
      m = double("key")
      allow(m).to receive(:to_s).and_return("foo")

      @client.hset("key1", m, "bar")
      expect(@client.hget("key1", "foo")).to eq("bar")
    end

    it "should convert key to a string for hget" do
      m = double("key")
      allow(m).to receive(:to_s).and_return("foo")

      @client.hset("key1", "foo", "bar")
      expect(@client.hget("key1", m)).to eq("bar")
    end

    it "should determine if a hash field exists" do
      @client.hset("key1", "index", "value")

      expect(@client.hexists("key1", "index")).to be true
      expect(@client.hexists("key2", "i2")).to be false
    end

    it "should get the value of a hash field" do
      @client.hset("key1", "index", "value")

      expect(@client.hget("key1", "index")).to eq("value")
    end

    it "should get all the fields and values in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      expect(@client.hgetall("key1")).to eq({"i1" => "val1", "i2" => "val2"})
    end

    it "should increment the integer value of a hash field by the given number" do
      @client.hset("key1", "cont1", "5")
      expect(@client.hincrby("key1", "cont1", "5")).to eq(10)
      expect(@client.hget("key1", "cont1")).to eq("10")
    end

    it "should increment non existing hash keys" do
      expect(@client.hget("key1", "cont2")).to be_nil
      expect(@client.hincrby("key1", "cont2", "5")).to eq(5)
    end

    it "should increment the float value of a hash field by the given float" do
      @client.hset("key1", "cont1", 5.0)
      expect(@client.hincrbyfloat("key1", "cont1", 4.1)).to eq(9.1)
      expect(@client.hget("key1", "cont1")).to eq("9.1")
    end

    it "should increment non existing hash keys" do
      expect(@client.hget("key1", "cont2")).to be_nil
      expect(@client.hincrbyfloat("key1", "cont2", 5.5)).to eq(5.5)
    end

    it "should get all the fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      expect(@client.hkeys("key1")).to match_array(["i1", "i2"])
      expect(@client.hkeys("key2")).to eq([])
    end

    it "should get the number of fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      expect(@client.hlen("key1")).to eq(2)
    end

    it "should get the values of all the given hash fields" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      expect(@client.hmget("key1", "i1", "i2", "i3")).to match_array(["val1", "val2", nil])
      expect(@client.hmget("key1", ["i1", "i2", "i3"])).to match_array(["val1", "val2", nil])

      expect(@client.hmget("key2", "i1", "i2")).to eq([nil, nil])
    end

    it "should throw an argument error when you don't ask for any keys" do
      expect { @client.hmget("key1") }.to raise_error(Redis::CommandError)
    end

    it "should reject an empty list of values" do
      expect { @client.hmset("key") }.to raise_error(Redis::CommandError)
      expect(@client.exists("key")).to be false
    end

    it "rejects an insert with a key but no value" do
      expect { @client.hmset("key", 'foo') }.to raise_error(Redis::CommandError)
      expect { @client.hmset("key", 'foo', 3, 'bar') }.to raise_error(Redis::CommandError)
      expect(@client.exists("key")).to be false
    end

    it "should reject the wrong number of arguments" do
      expect { @client.hmset("hash", "foo1", "bar1", "foo2", "bar2", "foo3") }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for HMSET")
    end

    it "should set multiple hash fields to multiple values" do
      @client.hmset("key", "k1", "value1", "k2", "value2")

      expect(@client.hget("key", "k1")).to eq("value1")
      expect(@client.hget("key", "k2")).to eq("value2")
    end

    it "should set multiple hash fields from a ruby hash to multiple values" do
      @client.mapped_hmset("foo", :k1 => "value1", :k2 => "value2")

      expect(@client.hget("foo", "k1")).to eq("value1")
      expect(@client.hget("foo", "k2")).to eq("value2")
    end

    it "should set the string value of a hash field" do
      expect(@client.hset("key1", "k1", "val1")).to eq(true)
      expect(@client.hset("key1", "k1", "val1")).to eq(false)

      expect(@client.hget("key1", "k1")).to eq("val1")
    end

    it "should set the value of a hash field, only if the field does not exist" do
      @client.hset("key1", "k1", "val1")
      expect(@client.hsetnx("key1", "k1", "value")).to eq(false)
      expect(@client.hsetnx("key1", "k2", "val2")).to eq(true)
      expect(@client.hsetnx("key1", :k1, "value")).to eq(false)
      expect(@client.hsetnx("key1", :k3, "val3")).to eq(true)

      expect(@client.hget("key1", "k1")).to eq("val1")
      expect(@client.hget("key1", "k2")).to eq("val2")
      expect(@client.hget("key1", "k3")).to eq("val3")
    end

    it "should get all the values in a hash" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")

      expect(@client.hvals("key1")).to match_array(["val1", "val2"])
    end

    it "should accept a list of array pairs as arguments and not throw an invalid argument number error" do
      @client.hmset("key1", [:k1, "val1"], [:k2, "val2"], [:k3, "val3"])
      expect(@client.hget("key1", :k1)).to eq("val1")
      expect(@client.hget("key1", :k2)).to eq("val2")
      expect(@client.hget("key1", :k3)).to eq("val3")
    end

    it "should reject a list of arrays that contain an invalid number of arguments" do
      expect { @client.hmset("key1", [:k1, "val1"], [:k2, "val2", "bogus val"]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for HMSET")
    end

    it "should convert a integer field name to string for hdel" do
      @client.hset("key1", "1", 1)
      expect(@client.hdel("key1", 1)).to be(1)
    end

    it "should convert a integer field name to string for hexists" do
      @client.hset("key1", "1", 1)
      expect(@client.hexists("key1", 1)).to be true
    end

    it "should convert a integer field name to string for hincrby" do
      @client.hset("key1", 1, 0)
      expect(@client.hincrby("key1", 1, 1)).to be(1)
    end
  end
end
