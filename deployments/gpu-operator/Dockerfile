FROM gcr.io/rec-repo/container-tools:1.0.7

ARG CHART_NAME
ENV CHART_NAME ${CHART_NAME:-chart}

ARG CHART_VERSION
ENV CHART_VERSION ${CHART_VERSION:-1.0.0}

COPY . /invocation/${CHART_NAME}
RUN mv /invocation/${CHART_NAME}/install.sh /invocation/install.sh
WORKDIR /invocation
