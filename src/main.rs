use opencv::{
    core::{Size, Vector},
    dnn, imgcodecs,
    prelude::*,
    videoio::{self, VideoCaptureProperties as VCProps, VideoCaptureTrait, VideoWriterTrait},
    Result,
};

use chrono::Utc;

fn main() -> Result<()> {
    // let window = "video capture";
    // highgui::named_window(window, highgui::WINDOW_AUTOSIZE)?;
    opencv::opencv_branch_32! {
        let mut cam = videoio::VideoCapture::new_default(0)?; // 0 is the default camera
        println!("opencv_branch_32");
    }
    opencv::not_opencv_branch_32! {
        println!("not_opencv_branch_32");
        //let mut cam = videoio::VideoCapture::new(0, videoio::CAP_ANY)?; // 0 is the default camera
        let props: Vector<i32> = Vector::from_slice(&[
            videoio::CAP_PROP_FRAME_WIDTH, 1920,
            videoio::CAP_PROP_FRAME_HEIGHT, 1080,
            videoio::CAP_PROP_FPS, 10
        ]);
        let mut cam = videoio::VideoCapture::new_with_params(0i32, videoio::CAP_V4L2, &props)?;

    }

    // let streams = Vector::from_slice(&[cam]);
    // let mut ready: Vector<i32> = Vector::new();
    // videoio::VideoCapture::wait_any(&streams, &mut ready, 1000000);
    let opened = videoio::VideoCapture::is_opened(&cam)?;
    if !opened {
        panic!("Unable to open default camera!");
    }

    // frame
    let mut frame = Mat::default();

    //video writer
    let mut vw = videoio::VideoWriter::new(
        &"video.mp4",
        //fourcc(Codec::MP4V)?,
        videoio::VideoWriter::fourcc('m', 'p', '4', 'v')?,
        cam.get(videoio::CAP_PROP_FPS)?,
        Size::new(
            cam.get(videoio::CAP_PROP_FRAME_WIDTH)? as i32,
            cam.get(videoio::CAP_PROP_FRAME_HEIGHT)? as i32,
        ),
        true,
    )?;

    let start_time = Utc::now().time();

    loop {
        cam.read(&mut frame)?;
        vw.write(&frame)?;

        let duration = Utc::now().time() - start_time;
        if duration.num_seconds() >= 10 {
            vw.release().expect("failed to release videowriter");
            break;
        }
    }

    Ok(())
}

#[derive(Debug)]
pub enum Codec {
    MJPG,
    XVID,
    MP4V,
    H264,
}

fn fourcc(codec: Codec) -> Result<i32> {
    match codec {
        Codec::H264 => videoio::VideoWriter::fourcc('h', '2', '6', '4'),
        Codec::XVID => videoio::VideoWriter::fourcc('x', 'v', 'i', 'd'),
        Codec::MP4V => videoio::VideoWriter::fourcc('m', 'p', '4', 'v'),
        Codec::MJPG => videoio::VideoWriter::fourcc('m', 'j', 'p', 'g'),
    }
}
