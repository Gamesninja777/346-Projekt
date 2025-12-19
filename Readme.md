# AWS Lambda Bilderkennung Projekt

Das Projekt FaceRecognitionLambda besteht aus:

- FaceRecognitionLambda.zip: eine ZIP-Datei, die den Code enthält
- init.sh: ein Script zur Initialisierung
- Test.jpg: ein Bild für Testzwecke
- FaceRecognitionLambda - SourceCode.zip: eine ZIP-Datei, die den Quellcode (C#) enthält. 

## Über das Projekt:

In diesem Projekt geht es um die automatische Gesichtsanalyse einer berühmten Persönlichkeit, nach Upload eines Fotos. 

## Wie funktioniert das:

Zuerst loggt man sich bei seinem AWS-Konto an. Dann öffnet man dort die CloudShell und lädt über Aktionen -> Datei hochladen folgende Dateien hoch:
1. FaceRecognitionLambda.zip
2. init.sh
3. Test.jpg (Wenn man sein eigenes Bild hochladen möchte, muss man es genau so benennen)

Danach führt man in der CloudShell folgende Commands aus:

- chmod +x init.sh
- ./init.sh

Dann muss man etwa 10s warten und daraufhin hat man eine Analyse des Bildes, die man auch im Buckets unter s3-buckets -> Face-Recognition-Out... finden kann. 


## Worauf soll beachtet wird:

Beim Bild "Test.jpg" muss der Name zwingend mit einem Grossbuchstaben beginnen. 
Es ist vorteilhaft, wenn das Bild unter 1 MB gross ist, allerdings gibt es keine Limitationen. 



