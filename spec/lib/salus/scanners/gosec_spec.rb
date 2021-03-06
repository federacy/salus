require_relative '../../../spec_helper.rb'

describe Salus::Scanners::Gosec do
  describe '#run' do
    let(:scanner) { Salus::Scanners::Gosec.new(repository: repo, config: {}) }

    before { scanner.run }

    context 'non-go project' do
      let(:repo) { Salus::Repo.new('spec/fixtures/blank_repository') }

      it 'should record the STDERR of gosec' do
        expect(scanner.should_run?).to eq(false)
        expect(scanner.report.passed?).to eq(false)

        info = scanner.report.to_h.fetch(:info)
        errors = scanner.report.to_h.fetch(:errors).first
        expect(
          info[:stderr]
        ).to include(
          'No packages found' # debug information
        )
        expect(
          errors[:message]
        ).to include('0 lines of code were scanned')
      end
    end

    context 'go project with vulnerabilities' do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/vulnerable_goapp') }

      it 'should record failure and record the STDOUT from gosec' do
        expect(scanner.report.passed?).to eq(false)

        info = scanner.report.to_h.fetch(:info)
        logs = scanner.report.to_h.fetch(:logs)
        expect(info[:stdout]).not_to be_nil
        expect(info[:stdout]).not_to be_empty
        expect(logs).to include('Potential hardcoded credentials')
      end
    end

    context 'go project with vulnerabilities in a nested folder' do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/recursive_vulnerable_goapp') }

      it 'should record failure and record the STDOUT from gosec' do
        expect(scanner.report.passed?).to eq(false)

        info = scanner.report.to_h.fetch(:info)
        logs = scanner.report.to_h.fetch(:logs)
        expect(info[:stdout]).not_to be_nil
        expect(info[:stdout]).not_to be_empty
        expect(logs).to include('Potential hardcoded credentials')
      end
    end

    context 'go project with no known vulnerabilities' do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/safe_goapp') }

      it 'should report a passing scan' do
        expect(scanner.report.passed?).to eq(true)
      end
    end

    context 'go project with malformed go' do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/malformed_goapp') }

      it 'should report a failing scan' do
        expect(scanner.report.passed?).to eq(false)

        info = scanner.report.to_h.fetch(:info)
        logs = scanner.report.to_h.fetch(:logs)

        expect(info[:stdout]).to include('Golang errors', 'Pintl not declared by package fmt')
        expect(logs).to include('Golang errors', 'Pintl not declared by package fmt')
      end
    end
  end

  describe '#should_run?' do
    let(:scanner) { Salus::Scanners::Gosec.new(repository: repo, config: {}) }

    shared_examples_for "when go file types are present" do
      it 'returns true' do
        expect(scanner.should_run?).to eq(true)
      end
    end

    it_behaves_like "when go file types are present" do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/safe_goapp') }
    end

    it_behaves_like "when go file types are present" do
      let(:repo) { Salus::Repo.new('spec/fixtures/report_go_dep') }
    end

    it_behaves_like "when go file types are present" do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/mod_goapp') }
    end

    it_behaves_like "when go file types are present" do
      let(:repo) { Salus::Repo.new('spec/fixtures/gosec/sum_goapp') }
    end

    context 'when go file types are missing' do
      let(:repo) { Salus::Repo.new('spec/fixtures/blank_repository') }

      it 'returns false' do
        expect(scanner.should_run?).to eq(false)
      end
    end
  end
end
