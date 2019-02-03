# frozen_string_literal: true

require_relative '../../lib/vmfloaty/service'

describe Service do

  describe '#initialize' do
    it 'store configuration options' do
      options = MockOptions.new({})
      config = {'url' => 'http://example.url'}
      service = Service.new(options, config)
      expect(service.config).to include config
    end
  end

  describe '#get_new_token' do
    it 'prompts the user for their password and retrieves a token' do
      config = { 'user' => 'first.last', 'url' => 'http://default.url' }
      service = Service.new(MockOptions.new, config)
      allow(STDOUT).to receive(:puts).with('Enter your pooler service password:')
      allow(Commander::UI).to(receive(:password)
                                  .with('Enter your pooler service password:', '*')
                                  .and_return('hunter2'))
      allow(Auth).to(receive(:get_token)
                         .with(nil, config['url'], config['user'], 'hunter2')
                         .and_return('token-value'))
      expect(service.get_new_token(nil)).to eql 'token-value'
    end

    it 'prompts the user for their username and password if the username is unknown' do
      config = { 'url' => 'http://default.url' }
      service = Service.new(MockOptions.new({}), config)
      allow(STDOUT).to receive(:puts).with 'Enter your pooler service username:'
      allow(STDOUT).to receive(:puts).with "\n"
      allow(STDIN).to receive(:gets).and_return('first.last')
      allow(Commander::UI).to(receive(:password)
                                  .with('Enter your pooler service password:', '*')
                                  .and_return('hunter2'))
      allow(Auth).to(receive(:get_token)
                         .with(nil, config['url'], 'first.last', 'hunter2')
                         .and_return('token-value'))
      expect(service.get_new_token(nil)).to eql 'token-value'
    end
  end

  describe '#delete_token' do
    it 'deletes a token' do
      service = Service.new(MockOptions.new,'user' => 'first.last', 'url' => 'http://default.url')
      allow(Commander::UI).to(receive(:password)
                                  .with('Enter your pooler service password:', '*')
                                  .and_return('hunter2'))
      allow(Auth).to(receive(:delete_token)
                         .with(nil, 'http://default.url', 'first.last', 'hunter2', 'token-value')
                         .and_return('ok' => true))
      expect(service.delete_token(nil, 'token-value')).to eql('ok' => true)
    end
  end

  describe '#token_status' do
    it 'reports the status of a token' do
      config = {
          'user' => 'first.last',
          'url' => 'http://default.url',
      }
      options = MockOptions.new('token' => 'token-value')
      service = Service.new(options, config)
      status = {
          'ok' => true,
          'user' => config['user'],
          'created' => '2017-09-22 02:04:18 +0000',
          'last_accessed' => '2017-09-22 02:04:28 +0000',
          'reserved_hosts' => [],
      }
      allow(Auth).to(receive(:token_status)
                         .with(nil, config['url'], 'token-value')
                         .and_return(status))
      expect(service.token_status(nil, 'token-value')).to eql(status)
    end
  end

end
