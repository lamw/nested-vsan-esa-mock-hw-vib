FROM lamw/vibauthor:latest

RUN yum install -y unzip zip

COPY create_nested_vsan_esa_mock_hw_vib.sh create_nested_vsan_esa_mock_hw_vib.sh
RUN chmod +x create_nested_vsan_esa_mock_hw_vib.sh

RUN /root/create_nested_vsan_esa_mock_hw_vib.sh

CMD ["/bin/bash"]
