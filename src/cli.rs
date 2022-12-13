use clap::{self, Parser};

/// A program to perform image recognition on pi camera
#[derive(Parser, Debug)]
#[command(author, version, about, long_about=None)]
pub struct Args {
    /// Test argument
    #[arg(short, long, default_value_t = false)]
    pub disable_recognition: bool,

    /// Specify video device to use
    #[arg(long, default_value_t=0,value_parser=clap::value_parser!(i32).range(-1..99) )]
    pub video_device: i32,

    /// List camera backends available
    #[arg(long, default_value_t = false)]
    pub list_camera_backends: bool,

    /// List all backends
    #[arg(long, default_value_t = false)]
    pub list_backends: bool,
}
