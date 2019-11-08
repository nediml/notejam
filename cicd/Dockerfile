
# using python:2.7 docker image from docker hub
FROM python:2.7

# getting the build parameters
ARG app_port
ARG db_host
ARG db_port
ARG db_user
ARG db_pass

# assigning values of build parameters to environment variables
ENV APP_PORT=${app_port}
ENV DB_HOST=${db_host}
ENV DB_PORT=${db_port}
ENV DB_USER=${db_user}
ENV DB_PASS=${db_pass}

# setting the working directory
WORKDIR /usr/src/app

# copping application files
COPY django/notejam .
COPY django/requirements.txt .

# installing application requirements
RUN pip install -r requirements.txt

# exposing the application port
EXPOSE ${APP_PORT}

# running gunicorn on the application port
CMD gunicorn --pythonpath ./notejam/ notejam.wsgi:application \
	--bind 0.0.0.0:${APP_PORT} \
	--workers 3

