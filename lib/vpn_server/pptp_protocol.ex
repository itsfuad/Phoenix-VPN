defmodule PhoenixVpn.PPTPProtocol do
  @moduledoc """
  Implements the PPTP (Point-to-Point Tunneling Protocol) specification.
  """

  # PPTP Message Types
  @message_types %{
    control_connection_request: 1,
    control_connection_reply: 2,
    echo_request: 3,
    echo_reply: 4,
    outgoing_call_request: 5,
    outgoing_call_reply: 6,
    incoming_call_request: 7,
    incoming_call_reply: 8,
    incoming_call_connected: 9,
    call_clear_request: 10,
    call_disconnect_notify: 11,
    wan_error_notify: 12,
    set_link_info: 13
  }

  defstruct [
    :version,
    :message_type,
    :length,
    :call_id,
    :sequence_number,
    :acknowledgment_number,
    :payload
  ]

  def parse_packet(data) do
    case data do
      <<version::8, _reserved::8, message_type::little-16, length::little-16, call_id::little-16,
        seq_num::little-32, ack_num::little-32, payload::binary>> ->
        {:ok,
         %__MODULE__{
           version: version,
           message_type: message_type,
           length: length,
           call_id: call_id,
           sequence_number: seq_num,
           acknowledgment_number: ack_num,
           payload: payload
         }}

      _ ->
        {:error, :invalid_packet_format}
    end
  end

  def build_packet(%__MODULE__{} = packet) do
    payload_size = byte_size(packet.payload)
    total_length = 12 + payload_size

    # Pad the payload to 4-byte boundary if needed
    padding_size = rem(4 - rem(payload_size, 4), 4)
    padded_payload = packet.payload <> :binary.copy(<<0>>, padding_size)

    <<
      packet.version::8,
      # Reserved
      0::8,
      packet.message_type::little-16,
      total_length::little-16,
      packet.call_id::little-16,
      packet.sequence_number::little-32,
      packet.acknowledgment_number::little-32,
      padded_payload::binary
    >>
  end

  def create_control_connection_reply(call_id, sequence_number) do
    %__MODULE__{
      version: 1,
      message_type: @message_types.control_connection_reply,
      length: 12,
      call_id: call_id,
      sequence_number: sequence_number,
      acknowledgment_number: 0,
      payload: <<>>
    }
  end

  def create_echo_reply(call_id, sequence_number) do
    %__MODULE__{
      version: 1,
      message_type: @message_types.echo_reply,
      length: 12,
      call_id: call_id,
      sequence_number: sequence_number,
      acknowledgment_number: 0,
      payload: <<>>
    }
  end
end
