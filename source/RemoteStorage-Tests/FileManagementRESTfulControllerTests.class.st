Class {
	#name : #FileManagementRESTfulControllerTests,
	#superclass : #TestCase,
	#instVars : [
		'fileManagementSystem',
		'resourceController'
	],
	#category : #'RemoteStorage-Tests-API'
}

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> baseUrl [
	^ 'https://api.remotestorage.net' asZnUrl
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> createExampleFile [
	fileManagementSystem
		writeFileNamed: 'example.txt'
		withContents: #(1 2 3 4 5 6 7 8 9 0 1 2 3 4 5) asByteArray
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> deleteExampleFile [
	fileManagementSystem deleteFileNamed: 'example.txt'
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> getAllFiles [
	^ resourceController
		getFilesBasedOn: (self requestToGet: self resourceUrl accepting: '*/*')
		within: self newHttpRequestContext
]

{ #category : #accessing }
FileManagementRESTfulControllerTests >> newHttpRequestContext [
	^ HttpRequestContext new
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> requestToDeleteFile: aRSFileToDelete [
	^ TeaRequest
		fromZnRequest: (ZnRequest delete: (self urlOf: aRSFileToDelete))
		pathParams:
			(Dictionary new
				at: #identifier put: aRSFileToDelete uuid;
				yourself)
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> requestToGet: anUrl accepting: anAcceptHeader [
	^ TeaRequest
		fromZnRequest:
			((ZnRequest get: anUrl)
				setAccept: anAcceptHeader;
				yourself)
]

{ #category : #accessing }
FileManagementRESTfulControllerTests >> resourceUrl [
	^ self baseUrl / resourceController specification endpoint
]

{ #category : #running }
FileManagementRESTfulControllerTests >> setUp [

	super setUp.
	self setUpResourceController.
	resourceController serverUrl: self baseUrl asZnUrl
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> setUpResourceController [
	fileManagementSystem := FileManagementSystem new.
	resourceController := FileManagementRESTfulController
		within: fileManagementSystem
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> testDeleteFile [
	| updateResponse |
	self assert: fileManagementSystem getAllFiles isEmpty.
	self createExampleFile.
	self assert: fileManagementSystem getAllFiles size equals: 1.
	updateResponse := resourceController
		deleteFileBasedOn: (self requestToDeleteFile: fileManagementSystem getAllFiles first)
		within: self newHttpRequestContext.
	self
		assert: updateResponse isSuccess;
		assert: fileManagementSystem getAllFiles isEmpty
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> testGetFilesWhenEmptyfiles [
	| response |
	response := self getAllFiles.
	self
		assert: response isSuccess;
		assert: response status equals: 200;
		assert: response contentType asMediaType
			equals: 'application/vnd.remotestorage.file+json;version=1.0.0' asMediaType.
	self
		withJsonFromContentsIn: response
		do: [ :files | self assert: files isEmpty ]
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> testGetFilesWhenThereIsAFile [
	[ | response |
	self createExampleFile.
	response := self getAllFiles.
	self
		assert: response isSuccess;
		assert: response status equals: 200;
		assert: response contentType asMediaType
			equals: 'application/vnd.remotestorage.file+json;version=1.0.0' asMediaType.
	self
		withJsonFromContentsIn: response
		do: [ :files | 
			| file |
			file := files first.
			self
				assert: file name equals: 'example.txt';
				assert: file sizeAsBytes equals: 15;
				assert:
					((file links at: #self)
						beginsWith:
							('https://api.remotestorage.net/rsfiles/<1s>'
								expandMacrosWith: fileManagementSystem getAllFiles first uuid printString)) ] ]
		ensure: [ self deleteExampleFile ]
]

{ #category : #'private - support' }
FileManagementRESTfulControllerTests >> urlOf: aRSFile [
	^ (self resourceUrl / aRSFile uuid asString) asString
]

{ #category : #actions }
FileManagementRESTfulControllerTests >> withJsonFromContentsIn: httpResponse do: aBlock [
	aBlock value: (NeoJSONObject fromString: httpResponse contents)
]
