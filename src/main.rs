use opencv::{
    core::{GpuMat, Vector},
    highgui, imgcodecs,
    prelude::*,
    videoio::{self, VideoCaptureProperties as VCProps, VideoCaptureTrait},
    Result,
};

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

    // read frame & make jpeg
    let mut frame = Mat::default();

    cam.read(&mut frame)?;

    let im_params: Vector<i32> = Vector::default();
    imgcodecs::imwrite("frame.jpeg", &frame, &im_params)?;

    // read gpu frame & make jpeg
    let mut gpu_frame = GpuMat::default()?;
    cam.read(&mut gpu_frame)?;

    imgcodecs::imwrite("gpu_frame.jpeg", &gpu_frame, &im_params)?;

    // loop {
    // 	let mut frame = Mat::default();
    // 	cam.read(&mut frame)?;
    // 	if frame.size()?.width > 0 {
    // 		highgui::imshow(window, &mut frame)?;
    // 	}
    // 	let key = highgui::wait_key(10)?;
    // 	if key > 0 && key != 255 {
    // 		break;
    // 	}
    // }
    Ok(())
}
