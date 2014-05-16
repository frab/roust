require 'spec_helper'
require 'roust'

describe "Roust" do
  before do
    @credentials = {
      :server   => 'http://rt.example.org',
      :username => 'admin',
      :password => 'password'
    }
    mocks_path = Pathname.new(__FILE__).parent.join('mocks')

    stub_request(:post, "http://rt.example.org/index.html").
      with(:body => {
            "user"=>"admin",
            "pass"=>"password",
           }).
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/1/show").
      to_return(:status  => 200,
                :body    => mocks_path.join('ticket-1-show.txt').read,
                :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/search/ticket?format=s&orderby=%2Bid&query%5Bquery%5D=id%20=%201%20or%20id%20=%202").
       to_return(:status  => 200,
                 :body    => mocks_path.join('ticket-search-1-or-2.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/1/history?format=s").
       to_return(:status  => 200,
                 :body    => mocks_path.join('ticket-1-history-short.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/ticket/1/history?format=l").
       to_return(:status  => 200,
                 :body    => mocks_path.join('ticket-1-history-long.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/user/dan@us.example").
       to_return(:status  => 200,
                 :body    => mocks_path.join('user-dan@us.example.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/queue/13").
       to_return(:status => 200,
                 :body    => mocks_path.join('queue-13.txt').read,
                 :headers => {})

    stub_request(:get, "http://rt.example.org/REST/1.0/queue/nil").
       to_return(:status => 200,
                 :body    => mocks_path.join('queue-nil.txt').read,
                 :headers => {})
  end

  it "authenticates on instantiation" do
    rt = Roust.new(@credentials)
    rt.authenticated?.should be_true
  end

  it "can list tickets matching a query" do
    rt = Roust.new(@credentials)
    rt.authenticated?.should be_true

    results = rt.search(:query => "id = 1 or id = 2")
    results.size.should == 2
    results.each do |result|
      result.size.should == 2
    end
  end

  it "can fetch metadata on individual tickets" do
    rt = Roust.new(@credentials)
    rt.authenticated?.should be_true

    ticket = rt.show("1")
    ticket.should_not be_nil

    attrs = %w(id Subject Queue) +
            %w(Requestors Cc AdminCc Owner Creator) +
            %w(Resolved Status) +
            %w(Starts Started TimeLeft Due TimeWorked TimeEstimated) +
            %w(LastUpdated Created Told) +
            %w(Priority FinalPriority InitialPriority)

    attrs.each do |attr|
      ticket[attr].should_not be_nil, "#{attr} key doesn't exist"
    end

    %w(Requestors Cc AdminCc).each do |field|
      ticket[field].size.should > 1
    end
  end

  it "can fetch transactions on individual tickets" do
    rt = Roust.new(@credentials)
    rt.authenticated?.should be_true

    short = rt.history("1", :format => "short")

    short.size.should > 1
    short.each do |txn|
      txn.size.should == 2
      txn.first.should match(/^\d+$/)
      txn.last.should  match(/^\w.*\w$/)
    end

    #attrs = %w(ticket data oldvalue creator timetaken) +
    #        %w(id type field newvalue content description) +
    #        %w(attachments created)
    attrs = %w(ticket data oldvalue timetaken) +
            %w(id type field newvalue content description)

    long = rt.history("1", :format => "long")
    long.size.should > 0
    long.each do |txn|
      attrs.each do |attr|
        txn[attr].should_not be_nil, "#{attr} key doesn't exist"
      end
    end
  end

  it "can lookup user details" do
    rt = Roust.new(@credentials)
    rt.authenticated?.should be_true

    attrs = %w(name realname gecos nickname emailaddress id lang password)

    user = rt.user("dan@us.example")
    attrs.each do |attr|
      user[attr].should_not be_nil, "#{attr} key doesn't exist"
    end
  end

  describe 'queue' do
    it "can lookup queue details" do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      attrs = %w(id name description correspondaddress commentaddress) +
              %w(initialpriority finalpriority defaultduein)

      queue = rt.queue('13')
      attrs.each do |attr|
        queue[attr].should_not be_nil, "#{attr} key doesn't exist"
      end

    end

    it 'returns nil for unknown queues' do
      rt = Roust.new(@credentials)
      rt.authenticated?.should be_true

      queue = rt.queue('nil')
      queue.should be_nil
    end
  end
end
