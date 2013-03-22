package FileDump;

my $options = {
  file => "",
  split => 0
};

my $handle = {
  file => "",
  fh   => 0
};

sub writeToFile {
  $options->{file}  = shift;
  $options->{split} = shift;
  $handle->{file} = makeFileName();
  
  openHandle();
}

sub makeFileName() {
  if ($options->{split}) {
    my @local = localtime(time);
    my $hour = $local[2];
    
    return $options->{file} . "_" . $hour . "h";
  }  

  return $options->{file};
}

sub write {
  my $message = shift;
  
  my $file = makeFileName();
  
  if ($file ne $handle->{file}) {
    reopenHandle($file);
  }

  print { $handle->{fh} } $message, "\n";
}

sub openHandle {
  open($handle->{fh}, ">:encoding(UTF-8)", $handle->{file});
}

sub reopenHandle {
  $handle->{file} = shift;
  closeHandle();
  openHandle();
}

sub closeHandle {
  close($handle->{fh});
}

sub close {
  closeHandle();
}

1;