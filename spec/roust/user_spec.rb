require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  before do
    mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')

    stub_request(:get, 'http://rt.example.org/REST/1.0/user/dan@us.example')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('user-dan@us.example.txt').read,
                  :headers => {})

    stub_request(:get, 'http://rt.example.org/REST/1.0/user/nil')
       .to_return(:status  => 200,
                  :body    => mocks_path.join('user-nil.txt').read,
                  :headers => {})

    stub_request(:post, 'http://rt.example.org/REST/1.0/user/dan@us.example/edit')
         .with(:body => 'content=id%3A%20user%2Fdan%40us.example%0ARealName%3A%20Daniel%20Smith')
         .to_return(:status => 200,
                    :body   => mocks_path.join('user-dan@us.example-edit.txt').read,
                    :headers => {})

    stub_request(:post, "http://rt.example.org/REST/1.0/user/new")
         .with(:body => "content=id%3A%20user%2Fnew%0AEmailAddress%3A%20erin%40us.example%0AName%3A%20erin%0ARealName%3A%20Erin%20Jones%0AGecos%3A%20erin%0ALang%3A%20en")
         .to_return(:status => 200,
                    :body => "",
                    :body   => mocks_path.join('user-erin@us.example-create.txt').read,
                    :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/user/erin@us.example")
         .to_return(:status => 200,
                    :body => "",
                    :body   => mocks_path.join('user-erin@us.example.txt').read,
                    :headers => {})

    @rt = Roust.new(credentials)
    expect(@rt.authenticated?).to eq(true)
  end

  describe 'user' do
    it 'can lookup user details' do
      attrs = %w(name realname gecos nickname emailaddress id lang password)

      user = @rt.user_show('dan@us.example')
      attrs.each do |attr|
        expect(user[attr]).to_not eq(nil), "#{attr} key doesn't exist"
      end
    end

    it 'returns nil for unknown users' do
      queue = @rt.user_show('nil')
      expect(queue).to eq(nil)
    end

    it 'can modify an existing user' do
      mocks_path = Pathname.new(__FILE__).parent.parent.join('mocks')
      stub_request(:get, 'http://rt.example.org/REST/1.0/user/dan@us.example')
         .to_return(:status  => 200,
                    :body    => mocks_path.join('user-dan@us.example-after-edit.txt').read,
                    :headers => {})

      attrs = {'RealName' => 'Daniel Smith'}
      user  = @rt.user_update('dan@us.example', attrs)

      expect(user['realname']).to eq('Daniel Smith')
    end

    it 'can create a new user' do
      attrs = {
        'EmailAddress' => 'erin@us.example',
        'Name' => 'erin',
        'RealName' => 'Erin Jones',
        'Gecos' => 'erin',
        'Lang' => 'en'
      }
      user = @rt.user_create(attrs)
      expect(user['realname']).to eq('Erin Jones')
      expect(user['emailaddress']).to eq('erin@us.example')
    end
  end
end
