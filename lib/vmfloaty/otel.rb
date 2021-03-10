# frozen_string_literal: true

require 'opentelemetry-api'
require 'opentelemetry-instrumentation-faraday'
require 'opentelemetry-sdk'
require 'opentelemetry/exporter/jaeger'
require 'socket'
require 'vmfloaty/version'

class Otel
  def configure_tracing(service)
    span_processor = if service.config['jaeger_endpoint']
                       OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
                         exporter: OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(endpoint: tracing_jaeger_host)
                       )
                     else
                       OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
                         exporter: OpenTelemetry::SDK::Trace::Export::NoopSpanExporter.new
                       )
                     end

    OpenTelemetry::SDK.configure do |c|
      c.add_span_processor(span_processor)
      c.resource = OpenTelemetry::SDK::Resources::Resource.create(
        {
          'net.host.name' => Socket.gethostname,
          'net.peer.name' => URI.parse(service.config['url']).host
        }
      )
      c.service_name = 'vmfloaty'
      c.service_version = Vmfloaty::VERSION
      c.use 'OpenTelemetry::Instrumentation::Faraday'
    end
  end
end
