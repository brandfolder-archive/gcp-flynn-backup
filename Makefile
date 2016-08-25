build:
	docker build -t brandfolder/flynn-backup .
push: build
	flynn docker push brandfolder/flynn-backup
