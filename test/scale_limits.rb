#!/usr/bin/env ruby
# End-to-end range checks using an isolated, simulated kscreen-doctor.
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

script = File.expand_path('../kde-scale', __dir__)
cases = [
  [1.75, '10', nil],
  [1.75, '0', nil],
  [1.75, '49.9999', nil],
  [1.75, '300.0001', nil],
  [1.75, '9' * 400, nil],
  [1.75, '-200', nil],
  [1.75, '-125.01', nil],
  [1.75, '+125.01', nil],
  [0.5, '-5', nil],
  [3.0, '+10', nil],
  [1.75, '50', 0.5],
  [1.75, '300', 3.0],
  [1.75, '-125', 0.5],
  [1.75, '+125', 3.0],
  [1.75, '+10', 1.85],
  [1.75, '-5', 1.7],
  [0.1, '100', 1.0], # A previously invalid setting must still be recoverable.
]

Dir.mktmpdir('kde-scale-limits') do |dir|
  state = File.join(dir, 'state.json')
  calls = File.join(dir, 'setter-calls.jsonl')
  doctor = File.join(dir, 'kscreen-doctor')
  File.write(doctor, "#!#{RbConfig.ruby}\n" + <<~'RUBY')
    require 'json'
    path = ENV.fetch('SCALE_TEST_STATE')
    config = JSON.parse(File.read(path))
    if ARGV == ['-j']
      puts JSON.generate(config)
    else
      File.open(ENV.fetch('SCALE_TEST_CALLS'), 'a') { |file| file.puts JSON.generate(ARGV) }
      config['outputs'].first['scale'] = Float(ARGV.fetch(0).split('.', 4).last)
      File.write(path, JSON.generate(config))
    end
  RUBY
  File.chmod(0o755, doctor)
  env = {
    'PATH' => dir,
    'XDG_SESSION_TYPE' => 'wayland',
    'SCALE_TEST_STATE' => state,
    'SCALE_TEST_CALLS' => calls,
  }

  cases.each do |current, argument, expected|
    File.delete(calls) if File.exist?(calls)
    File.write(state, JSON.generate('outputs' => [
      { 'id' => 1, 'name' => 'eDP-1', 'connected' => true, 'scale' => current },
    ]))
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, script, '--no-osd', argument)
    actual = JSON.parse(File.read(state)).fetch('outputs').first.fetch('scale')
    if expected
      raise "#{argument}: #{stderr}" unless status.success?
      raise "#{argument}: unexpected output" unless stdout.empty? && stderr.empty?
      raise "#{argument}: incorrect applied scale #{actual}" unless actual == expected
      setters = File.readlines(calls).map { |line| JSON.parse(line) }
      raise "#{argument}: expected exactly one scale change" unless setters == [["output.1.scale.#{expected}"]]
    else
      raise "#{argument}: invalid scale accepted" if status.success?
      raise "#{argument}: missing range error" unless stderr.include?('between 50% and 300%')
      raise "#{argument}: unexpected stdout" unless stdout.empty?
      raise "#{argument}: invoked the display setter" if File.exist?(calls)
      raise "#{argument}: changed display state" unless actual == current
      raise 'Missing +10 hint' if argument == '10' && !stderr.include?('Use +10')
    end
  end
end

puts "#{cases.length} scaling-limit checks passed (no real display changes)"
