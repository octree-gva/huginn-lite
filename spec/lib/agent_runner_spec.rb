require 'rails_helper'
# RSpec-Mocks is extremely unstable when threads are heavily involved, so stick with RR here.
require 'rr'

describe AgentRunner do
  context "without traps" do
    before do
      RR.stub.instance_of(Rufus::Scheduler).every
      RR.stub.instance_of(AgentRunner).set_traps
      @agent_runner = AgentRunner.new
    end

    after(:each) do
      @agent_runner.stop
      AgentRunner.class_variable_set(:@@agents, [])
      RR.reset
    end

    context "#run" do
      before do
        RR.mock(@agent_runner).run_workers
      end

      it "runs until stop is called" do
        RR.mock.instance_of(Rufus::Scheduler).join
        Thread.new { while @agent_runner.instance_variable_get(:@running) != false do sleep 0.1; @agent_runner.stop end }
        @agent_runner.run
      end

      it "handles signals" do
        @agent_runner.instance_variable_set(:@signal_queue, ['TERM'])
        @agent_runner.run
      end
    end

    context "#load_workers" do
      before do
        AgentRunner.class_variable_set(:@@agents, [HuginnScheduler, DelayedJobWorker])
      end

      it "loads all workers" do
        workers = @agent_runner.send(:load_workers)
        expect(workers).to be_a(Hash)
        expect(workers.keys).to eq(['HuginnScheduler', 'DelayedJobWorker'])
      end

      it "loads only the workers specified in the :only option" do
        agent_runner = AgentRunner.new(only: HuginnScheduler)
        workers = agent_runner.send(:load_workers)
        expect(workers.keys).to eq(['HuginnScheduler'])
        agent_runner.stop
      end

      it "does not load workers specified in the :except option" do
        agent_runner = AgentRunner.new(except: HuginnScheduler)
        workers = agent_runner.send(:load_workers)
        expect(workers.keys).to eq(['DelayedJobWorker'])

        agent_runner.stop
      end
    end

    context "running workers" do
      before do
        AgentRunner.class_variable_set(:@@agents, [HuginnScheduler, DelayedJobWorker])
        RR.stub.instance_of(HuginnScheduler).setup
        RR.stub.instance_of(DelayedJobWorker).setup
      end

      context "#run_workers" do
        it "runs all the workers" do
          RR.mock.instance_of(HuginnScheduler).run!
          RR.mock.instance_of(DelayedJobWorker).run!
          @agent_runner.send(:run_workers)
        end

        it "kills no long active workers" do
          RR.mock.instance_of(HuginnScheduler).run!
          RR.mock.instance_of(DelayedJobWorker).run!
          @agent_runner.send(:run_workers)
          AgentRunner.class_variable_set(:@@agents, [DelayedJobWorker])
          RR.mock.instance_of(HuginnScheduler).stop!
          @agent_runner.send(:run_workers)
        end
      end

      context "#restart_dead_workers" do
        before do
          RR.mock.instance_of(HuginnScheduler).run!
          RR.mock.instance_of(DelayedJobWorker).run!
          @agent_runner.send(:run_workers)

        end
        it "restarts dead workers" do
          RR.stub.instance_of(HuginnScheduler).thread { OpenStruct.new(alive?: false) }
          RR.mock.instance_of(HuginnScheduler).run!
          @agent_runner.send(:restart_dead_workers)
        end
      end
    end
  end

  context "#set_traps" do
    it "sets traps for INT TERM and QUIT" do
      agent_runner = AgentRunner.new
      RR.mock(Signal).trap('INT')
      RR.mock(Signal).trap('TERM')
      RR.mock(Signal).trap('QUIT')
      agent_runner.set_traps

      agent_runner.stop
    end
  end
end
