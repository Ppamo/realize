#!/bin/bash
IMAGENAME=ppamo.cl/alpine-go.realize
IMAGETAG="v2.0"
IMAGEVERSION="v0.1"
MACHINE_NAME=go.realize
CMD=""

usage(){
	echo "./setup.sh [run|clean|clean_image]"
}

run(){
	# check if docker is running
	docker info > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "Cannot connect to the Docker daemon. Is the docker daemon running on this host?"
		exit -1
	fi

	# check if the Dockerfile is in the folder
	if [ ! -f Dockerfile ]
	then
		echo "Dockerfile is not present, please run the script from right folder"
		exit -1
	fi

	# check if the docker image exists
	docker images | grep "$IMAGENAME" | grep "$IMAGETAG" > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		# create the docker image
		docker build -t $IMAGENAME:$IMAGEVERSION -t $IMAGENAME:$IMAGETAG ./
		if [ $? -ne 0 ]
		then
			echo "docker build failed!"
			exit -1
		fi
	fi

	# set selinux permissions to be mounted as a volume in the container
	chcon -Rt svirt_sandbox_file_t $PWD/repos


	# if machine is running, just attach
	CONTAINER=$(docker ps | grep "$MACHINE_NAME" | awk '{ print $1 }')
	if [ "$CONTAINER" ]; then
		# attach to running container
		echo "==> attaching to container $CONTAINER"
		docker logs -f $CONTAINER
	else
		CONTAINER=$(docker ps -a | grep "$MACHINE_NAME" | awk '{ print $1 }')
		if [ "$CONTAINER" ]; then
			echo "==> restarting container $CONTAINER"
			# start and attach to stopped container
			docker start $CONTAINER
			sleep 1
			docker exec -ti $CONTAINER /bin/bash
		else
			# run a container from $IMAGENAME image
			echo "==> creating container named $MACHINE_NAME"
			docker run --privileged=true -di -p 3000:3000 --name "$MACHINE_NAME" "$IMAGENAME:$IMAGETAG" $CMD
			CONTAINER=$(docker ps | grep "$MACHINE_NAME" | awk '{ print $1 }')
			echo "==> attaching to container's logs"
			docker logs -f $CONTAINER
		fi

	fi
}


# check for command
case "$1" in
	run)
		run
	;;
	clean)
		CONTAINER=$(docker ps -a | grep "$MACHINE_NAME" | awk '{ print $1 }')
		if [ "$CONTAINER" ]; then
			echo "==> Destroying container $CONTAINER"
			docker stop $CONTAINER
			docker rm $CONTAINER
		else
			echo "==> Container does not exists!"
		fi
		exit 0
	;;
	clean_image)
		if docker images | grep "$IMAGENAME" ; then
			echo "==> Deleting image $IMAGENAME"
			docker rmi $IMAGENAME:$IMAGEVERSION
			docker rmi $IMAGENAME:$IMAGETAG
		else
			echo "==> Image does not exists!"
		fi
		exit 0
	;;
	*)
		usage
	;;
esac
	
