FROM centos:7
EXPOSE 8080
CMD ["/rust-http"]
COPY ./ /