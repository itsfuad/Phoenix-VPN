defmodule PhoenixVpn.PPTPProtocolTest do
  use ExUnit.Case
  alias PhoenixVpn.PPTPProtocol

  describe "parse_packet/1" do
    test "parses a valid PPTP packet" do
      # Create a test packet with little-endian values
      packet_data = <<
        # version
        1,
        # reserved
        0,
        # message_type (little-endian)
        1,
        0,
        # length (little-endian)
        20,
        0,
        # call_id (little-endian)
        1,
        0,
        # sequence_number (little-endian)
        1,
        0,
        0,
        0,
        # acknowledgment_number (little-endian)
        0,
        0,
        0,
        0,
        # payload
        "test"::binary,
        # padding to 4-byte boundary
        0,
        0,
        0,
        0
      >>

      assert {:ok, packet} = PPTPProtocol.parse_packet(packet_data)
      assert packet.version == 1
      # Should be 1 in little-endian
      assert packet.message_type == 1
      assert packet.length == 20
      assert packet.call_id == 1
      assert packet.sequence_number == 1
      assert packet.acknowledgment_number == 0
      # The payload includes padding, so we need to trim it
      assert String.trim_trailing(packet.payload, <<0>>) == "test"
    end

    test "returns error for invalid packet format" do
      # Invalid packet format
      data = <<1, 2, 3>>
      assert {:error, :invalid_packet_format} = PPTPProtocol.parse_packet(data)
    end
  end

  describe "build_packet/1" do
    test "builds a valid PPTP packet" do
      packet = %PPTPProtocol{
        version: 1,
        message_type: 1,
        length: 20,
        call_id: 1,
        sequence_number: 1,
        acknowledgment_number: 0,
        payload: "test"
      }

      built = PPTPProtocol.build_packet(packet)
      # Header size (12) + payload size (4) + padding (4)
      assert byte_size(built) == 20
      assert {:ok, parsed} = PPTPProtocol.parse_packet(built)
      assert parsed.version == packet.version
      # Should be 1 in little-endian
      assert parsed.message_type == packet.message_type
      assert parsed.call_id == packet.call_id
      assert parsed.sequence_number == packet.sequence_number
      assert parsed.acknowledgment_number == packet.acknowledgment_number
      # The payload includes padding, so we need to trim it
      assert String.trim_trailing(parsed.payload, <<0>>) == packet.payload
    end
  end

  describe "create_control_connection_reply/2" do
    test "creates a valid control connection reply" do
      call_id = 1
      sequence_number = 2
      reply = PPTPProtocol.create_control_connection_reply(call_id, sequence_number)

      assert reply.version == 1
      # control_connection_reply
      assert reply.message_type == 2
      assert reply.length == 12
      assert reply.call_id == call_id
      assert reply.sequence_number == sequence_number
      assert reply.acknowledgment_number == 0
      assert reply.payload == <<>>
    end
  end

  describe "create_echo_reply/2" do
    test "creates a valid echo reply" do
      call_id = 1
      sequence_number = 2
      reply = PPTPProtocol.create_echo_reply(call_id, sequence_number)

      assert reply.version == 1
      # echo_reply
      assert reply.message_type == 4
      assert reply.length == 12
      assert reply.call_id == call_id
      assert reply.sequence_number == sequence_number
      assert reply.acknowledgment_number == 0
      assert reply.payload == <<>>
    end
  end
end
