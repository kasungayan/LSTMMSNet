from tfrecords_handler.moving_window.tfrecord_mean_writer import TFRecordWriter

if __name__ == '__main__':
    # hourly data
    tfrecord_writer = TFRecordWriter(
        input_size = 30,
        output_size = 24,
        train_file_path = '../../../datasets/text_data/M4/moving_window/energy_prophet_30i24.txt',
        validate_file_path = '../../../datasets/text_data/M4/moving_window/energy_prophet_30i24v.txt',
        test_file_path = '../../../datasets/text_data/M4/moving_window/energy_prophet_test30i24.txt',
        binary_train_file_path = '../../../datasets/binary_data/M4/moving_window/energy_prophet_30i24.tfrecords',
        binary_validation_file_path = '../../../datasets/binary_data/M4/moving_window/energy_prophet_30i24v.tfrecords',
        binary_test_file_path = '../../../datasets/binary_data/M4/moving_window/energy_prophet_test30i24.tfrecords'
    )

    print("Stage1")
    tfrecord_writer.read_text_data()
    print("Stage2")
    tfrecord_writer.write_train_data_to_tfrecord_file()
    print("Stage3")
    tfrecord_writer.write_validation_data_to_tfrecord_file()
    print("Stage4")
    tfrecord_writer.write_test_data_to_tfrecord_file()
