task :test, [:key] do |t, args|
  if args.key.nil?
    $stderr.puts "usage: rake test[<api_key>]" && exit
  end

  sh "TRANSLATOR_KEY=#{args.key} rspec test/*"
end
