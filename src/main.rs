use clap::Parser;
use opencv::{
    core::{Size, Vector},
    dnn, imgcodecs,
    prelude::*,
    videoio::{self, VideoCaptureProperties as VCProps, VideoCaptureTrait, VideoWriterTrait},
    Result,
};

use chrono::Utc;

mod cli;

fn main() -> Result<()> {
    let args = cli::Args::parse();

    if args.list_camera_backends || args.list_backends {
        list_backends(&args)?;
    } else {
        run(&args)?;
    }

    Ok(())
}

fn list_backends(args: &cli::Args) -> Result<()> {
    if args.list_camera_backends {
        let apis = videoio::get_camera_backends()?;

        println!("{}", "Availabe Camera Backends");
        println!("{}", "-".repeat(10));
        for api in apis {
            println!("\t{}", videoio::get_backend_name(api)?);
        }
        println!();
    }

    if args.list_backends {
        let apis = videoio::get_backends()?;

        println!("{}", "All Backends");
        println!("{}", "-".repeat(10));
        for api in apis {
            println!("\t{}", videoio::get_backend_name(api)?);
        }
        println!();
    }

    Ok(())
}

fn run(args: &cli::Args) -> Result<()> {
    println!("video device: {}", args.video_device);

    opencv::opencv_branch_32! {
        let mut cam = videoio::VideoCapture::new_default(0)?; // 0 is the default camera
        println!("opencv_branch_32");
    }

    opencv::not_opencv_branch_32! {
        println!("not_opencv_branch_32");
        //let mut cam = videoio::VideoCapture::new(0, videoio::CAP_ANY)?; // 0 is the default camera
        let props: Vector<i32> = Vector::from_slice(&[
            videoio::CAP_PROP_FRAME_WIDTH, 640,
            videoio::CAP_PROP_FRAME_HEIGHT, 480,
            videoio::CAP_PROP_FPS, 10
        ]);
        let mut cam = videoio::VideoCapture::new_with_params(args.video_device, videoio::CAP_UEYE, &props)?;
    }

    let opened = videoio::VideoCapture::is_opened(&cam)?;
    if !opened {
        panic!("Unable to open default camera!");
    }

    // frame
    let mut frame = Mat::default();

    //video writer
    // let mut vw = videoio::VideoWriter::new(
    //     &"video.mp4",
    //     //fourcc(Codec::MP4V)?,
    //     videoio::VideoWriter::fourcc('m', 'p', '4', 'v')?,
    //     cam.get(videoio::CAP_PROP_FPS)?,
    //     Size::new(
    //         cam.get(videoio::CAP_PROP_FRAME_WIDTH)? as i32,
    //         cam.get(videoio::CAP_PROP_FRAME_HEIGHT)? as i32,
    //     ),
    //     true,
    // )?;

    let host = "192.168.86.108";
    let port = 5200_i32;
    let gst = format!(
        "appsrc ! \
        videoconvert ! \
        videoscale ! \
        videorate ! \
        video/x-raw,width={width},height={height},framerate={frame_rate}/1,format=YV12 ! \
        jpegenc ! \
        rtpjpegpay ! \
        udpsink host={host} port={port}",
        width = cam.get(videoio::CAP_PROP_FRAME_WIDTH)? as i32,
        height = cam.get(videoio::CAP_PROP_FRAME_HEIGHT)? as i32,
        frame_rate = cam.get(videoio::CAP_PROP_FPS)? as i32,
        host = host,
        port = port
    );

    let mut vw = videoio::VideoWriter::new_with_backend(
        gst.as_str(),
        videoio::CAP_GSTREAMER,
        0,
        cam.get(videoio::CAP_PROP_FPS)?,
        Size::new(
            cam.get(videoio::CAP_PROP_FRAME_WIDTH)? as i32,
            cam.get(videoio::CAP_PROP_FRAME_HEIGHT)? as i32,
        ),
        true,
    )?;

    if !vw.is_opened()? {
        println!("videowriter is not open");
    }

    // let start_time = Utc::now().time();

    // loop {
    //     cam.read(&mut frame)?;
    //     vw.write(&frame)?;

    //     let duration = Utc::now().time() - start_time;
    //     if duration.num_seconds() >= 10 {
    //         vw.release().expect("failed to release videowriter");
    //         break;
    //     }
    // }

    loop {
        cam.read(&mut frame)?;

        if !frame.empty() {
            vw.write(&frame)?;
        }
    }

    Ok(())
}
