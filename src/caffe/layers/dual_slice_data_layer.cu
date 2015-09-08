#include <vector>

#include "caffe/data_layers.hpp"

namespace caffe {

template <typename Dtype>
void DualSliceDataLayer<Dtype>::Forward_gpu(
    const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top) {
  // First, join the thread
  this->JoinPrefetchThread();
  // Reshape to loaded data.
  top[0]->ReshapeLike(this->prefetch_data_);
  // Copy the data
  caffe_copy(this->prefetch_data_.count(), this->prefetch_data_.gpu_data(),
      top[0]->mutable_gpu_data());
  if (this->output_labels_) {
    // Reshape to loaded labels.
    top[1]->ReshapeLike(this->prefetch_label_);
    // Copy the labels.
    caffe_copy(this->prefetch_label_.count(), this->prefetch_label_.gpu_data(),
        top[1]->mutable_gpu_data());
  }

  const auto sample_count = this->layer_param_.dual_slice_data_param().sample_count();
  for (auto blob : bottom) {
    auto data = blob->mutable_gpu_data();
    fetchFFTransformedData_gpu(data, sample_count);
    fetchFFTransformedData_gpu(data + sample_count, sample_count);
  }

  // Start a new prefetch thread
  this->CreatePrefetchThread();
}

template <typename Dtype>
void DualSliceDataLayer<Dtype>::fetchFFTransformedData_gpu(Dtype* data, int size) {
    if (this->layer_param_.dual_slice_data_param().fft()) {
        FastFourierTransform_gpu<Dtype> fft(size, this->layer_param_.dual_slice_data_param().fft_options());
        fft.process(data, size);
    }
}

INSTANTIATE_LAYER_GPU_FORWARD(DualSliceDataLayer);

}  // namespace caffe
