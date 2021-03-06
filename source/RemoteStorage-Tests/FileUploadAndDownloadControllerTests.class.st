Class {
	#name : #FileUploadAndDownloadControllerTests,
	#superclass : #TestCase,
	#instVars : [
		'fileManagementSystem',
		'client'
	],
	#category : #'RemoteStorage-Tests-API'
}

{ #category : #running }
FileUploadAndDownloadControllerTests >> createExampleFile [
	fileManagementSystem
		writeFileNamed: 'example.txt'
		withContents: #(1 2 3 4 5 6 7 8 9 0 1 2 3 4 5) asByteArray
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> deleteExampleFile [
	fileManagementSystem deleteFileNamed: 'example.txt'
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> setUp [
	fileManagementSystem := FileManagementSystem new
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> tearDown [
	self deleteExampleFile.
	client server stop
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> testDownload [
	self
		withServerDo: [ :server | 
			| request |
			self createExampleFile.
			client := FileUploadAndDownloadController
				within: fileManagementSystem.
			client start.
			request := ZnRequest
				get:
					'http://localhost:6790/download/'
						, fileManagementSystem getAllFiles first uuid asString.
			client handleFileDownloadRequest: request ]
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> testUpload [
	self
		withServerDo: [ :server | 
			| request |
			client := FileUploadAndDownloadController
				within: fileManagementSystem.
			client start.
			request := ZnRequest post: 'http://localhost:6790/upload/'.
			request
				entity:
					(ZnMultiPartFormDataEntity new
						addPart:
							(ZnMimePart
								fieldName: 'file'
								fileName: 'example.txt'
								entity:
									(ZnEntity
										with: 'Some Contents'
										type: ZnMimeType textPlain clearCharSet))).
			client handleFileUploadRequest: request ]
]

{ #category : #running }
FileUploadAndDownloadControllerTests >> withServerDo: block [
	| server |
	server := ZnServer on: 1700 + 32 atRandom.
	[ server start.
	self
		assert: server isRunning & server isListening
		description:
			('Failed to start server on port {1}. Is there one already?'
				format: {server port}).
	server delegate: ZnImageExampleDelegate new.
	block cull: server ]
		ensure: [ server stop ]
]
