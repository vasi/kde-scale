#!/usr/bin/env ruby
# Copyright (c) 2026 Dave Vasilevsky
# SPDX-License-Identifier: BSD-2-Clause
# Exercise complete CLI changes without touching the real display server.
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

def output(name, id, width, height, scale, x, y)
  {
    'name' => name, 'id' => id, 'connected' => true, 'enabled' => true,
    'scale' => scale, 'size' => { 'width' => width, 'height' => height },
    'pos' => { 'x' => x, 'y' => y },
  }
end

top = output('DP-1', 1, 3840, 2160, 1.4, 0, 0)
bottom = output('eDP-1', 2, 2880, 1920, 1.6, 634, 1543)
right = output('eDP-1', 2, 2880, 1920, 1.6, 2743, 0)
third = output('HDMI-1', 3, 1920, 1080, 1.0, 634, 2743)
portrait = output('DP-1', 1, 2160, 3840, 1.4, 0, 0).merge('rotation' => 2)
below_portrait = output('eDP-1', 2, 2880, 1920, 1.6, 0, 2743)
disabled = output('HDMI-1', 3, 1920, 1080, 1.0, 9000, 9000).merge('enabled' => false)
cases = [
  ['upper display, scale down', [top, bottom], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1600] }],
  ['upper display, scale up', [top, bottom], 'DP-1', '145',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1490] }],
  ['lower display', [top, bottom], 'eDP-1', '165',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1543] }],
  ['output ordering', [bottom, top], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1600] }],
  ['left display, scale down', [top, right], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [2845, 0] }],
  ['left display, scale up', [top, right], 'DP-1', '145',
   { 'DP-1' => [0, 0], 'eDP-1' => [2649, 0] }],
  ['right display', [top, right], 'eDP-1', '165',
   { 'DP-1' => [0, 0], 'eDP-1' => [2743, 0] }],
  ['three stacked displays', [top, bottom, third], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1600], 'HDMI-1' => [634, 2800] }],
  ['rotated mode size', [portrait, below_portrait], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [0, 2845] }],
  ['fractional protocol rounding', [top, bottom], 'DP-1', '137',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1581] }],
  ['negative desktop origin', [top.merge('pos' => { 'x' => -100, 'y' => -100 }),
                               bottom.merge('pos' => { 'x' => 534, 'y' => 1443 })], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1600] }],
  ['offset on both axes', [top, bottom.merge('pos' => { 'x' => 2000, 'y' => 1543 })], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [2102, 1600] }],
  ['disabled output', [top, bottom, disabled], 'DP-1', '135',
   { 'DP-1' => [0, 0], 'eDP-1' => [634, 1600], 'HDMI-1' => [9000, 9000] }],
]

script = File.expand_path('../kde-scale', __dir__)
Dir.mktmpdir('kde-scale-layout') do |dir|
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
      ARGV.each do |argument|
        _, id, setting, value = argument.split('.', 4)
        output = config.fetch('outputs').find { |item| item.fetch('id') == Integer(id) }
        case setting
        when 'scale'
          output['scale'] = (Float(value) * 120).round / 120.0
        when 'position'
          next if ENV['SCALE_TEST_IGNORE_POSITION'] == '1'
          x, y = value.split(',').map { |coordinate| Integer(coordinate) }
          output['pos'] = { 'x' => x, 'y' => y }
        else
          abort "Unexpected setting: #{setting}"
        end
      end
      File.write(path, JSON.generate(config))
    end
  RUBY
  File.chmod(0o755, doctor)
  env = { 'PATH' => dir, 'XDG_SESSION_TYPE' => 'wayland',
          'SCALE_TEST_STATE' => state, 'SCALE_TEST_CALLS' => calls }

  cases.each do |label, displays, target, scale, expected|
    File.delete(calls) if File.exist?(calls)
    File.write(state, JSON.generate('outputs' => displays))
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, script, '--no-osd', '--output', target, scale)
    raise "#{label}: #{stderr}" unless status.success?
    raise "#{label}: unexpected output" unless stdout.empty? && stderr.empty?
    applied = JSON.parse(File.read(state)).fetch('outputs')
    actual = applied.to_h { |item| [item.fetch('name'), item.fetch('pos').values_at('x', 'y')] }
    raise "#{label}: expected #{expected}, got #{actual}" unless actual == expected
    invocations = File.readlines(calls).map { |line| JSON.parse(line) }
    raise "#{label}: scale and layout were applied separately" unless invocations.length == 1
    setters = invocations.first
    selected = applied.find { |item| item.fetch('name') == target }
    expected_scale = (Float(scale) / 100 * 120).round / 120.0
    raise "#{label}: incorrect target scale" unless selected.fetch('scale') == expected_scale
    raise "#{label}: missing scale command" unless setters.count { |arg| arg.include?('.scale.') } == 1
    applied.each do |item|
      original = displays.find { |old| old.fetch('name') == item.fetch('name') }
      raise "#{label}: changed another display's scale" unless item.fetch('name') == target || item.fetch('scale') == original.fetch('scale')
    end
  end

  # A compositor ignoring position requests must not be reported as success.
  File.write(state, JSON.generate('outputs' => [top, bottom]))
  stdout, stderr, status = Open3.capture3(env.merge('SCALE_TEST_IGNORE_POSITION' => '1'),
                                         RbConfig.ruby, script, '--no-osd', '--output', 'DP-1', '135')
  raise 'Ignored positions were accepted' if status.success? || !stdout.empty?
  raise 'Missing layout error' unless stderr.include?('expected position for eDP-1')
end

puts "#{cases.length + 1} display-layout checks passed (no real display changes)"
