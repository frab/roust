require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  describe 'authentication' do
    it 'indicates authenticated status' do
      @rt = Roust.new(credentials)
      expect(@rt.authenticated?).to eq(true)
    end

    it 'errors on invalid credentials' do
      mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

      stub_request(:post, 'http://rt.example.org/index.html')
        .with(:body => {
                'user'=>'admin',
                'pass'=>'incorrect',
              })
        .to_return(:status => 200, :body => '', :headers => {})

      stub_request(:get, 'http://rt.example.org/REST/1.0/ticket/1/show')
        .to_return(:status  => 200,
                   :body    => mocks_path.join('ticket-1-show-unauthenticated.txt').read,
                   :headers => {})

      credentials.merge!({:username => 'admin', :password => 'incorrect'})

      expect { Roust.new(credentials) }.to raise_error(Unauthenticated)
    end

    it 'errors when API root is supplied in server url' do
      credentials[:server] = 'http://rt.example.org/REST/1.0'

      expect { Roust.new(credentials) }.to raise_error(ArgumentError)
    end
  end
end
