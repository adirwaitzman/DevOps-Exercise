# CI/CD Pipeline with GitHub Actions

The workflow in this git repo - .github/workflows - pipeline.yml

The pipeline is runing on every push to the master branch

    on:
        push:
            branches: [ "master" ]

The pipeline getting all the repo file and setting a jdk environment

    steps:
      - uses: actions/checkout@v3
  
      - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'

To increase the version I used environmental variable

      - name: Increase jar version
        working-directory: ./my-app
        run: mvn versions:set -DnewVersion=1.0.${{ vars.VERSION }}

And to increase the variable by 1 each time
(depending on the result of the pipeline to make sure that the build did indeed happen as it should and there will be no skipping between versions)

    increment_version:
        runs-on: ubuntu-latest
        needs: build
        if: ${{ success() }}
        steps:
        - name: version increanent
        uses: action-pack/increment@v2
        with:
            name: 'VERSION'
            token: ${{ secrets.REPO_ACCESS_TOKEN }}

Running `mvn package` to compile and creates the target directory, including a jar(artifact):

      - name: Compile and Package
        working-directory: ./my-app
        run: mvn clean package

Copy the artifact to the same directory of the Dockerfile

      - name: Create artifact
        run: cp ./my-app/target/my-app-1.0.${{ vars.VERSION }}.jar ./my-app-artifact.jar

The Dockerfile

    FROM openjdk:11-jre-slim
    WORKDIR /app
    RUN adduser --system --group adir
    RUN chown -R adir:adir /app
    USER adir
    COPY --chown=adir:adir my-app-artifact.jar app.jar
    CMD ["java", "-jar", "app.jar"]    

Build and Tag the Docker image

      - name: Build Docker image
        run: docker build -t my-app:1.0.${{ vars.VERSION }} .

      - name: Tag Docker image
        run: docker tag my-app:1.0.${{ vars.VERSION }} adirwaitzman/my-app:1.0.${{ vars.VERSION }}


Log in to Docker Hub and publish the image

      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_PASSWORD }}
  
      - name: Push Docker image to Docker Hub (Publish)
        run: docker push adirwaitzman/my-app:1.0.${{ vars.VERSION }}

SSH to the production environment (AWS EC2) and deploy the project

      - name: run the docker image (deploy)
        run: |
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > private_key && chmod 600 private_key
          ssh -o StrictHostKeyChecking=no -i private_key ${{secrets.USER_NAME}}@$${{secrets.IP_ADDRESS}} '

            docker pull adirwaitzman/my-app:1.0.${{ vars.VERSION }}
            docker run --name my-app adirwaitzman/my-app:1.0.${{ vars.VERSION }}
            ' 


Notes:

Because of this part of the POM

    <annotationProcessors>
        <annotationProcessor>org.checkerframework.checker.nullness.NullnessChecker</annotationProcessor>
    </annotationProcessors>

Maven's build is failing for some reason.
Even after removing variables that are equal to NULL in the code,
Need to come back and investigate


The deploy on the production environment needs to be improved,
- Stop the previous app bedore deploy a new one (for this particular app it's fine because it doesn't keep running in the background)
- Delete the previous version of the app and make sure that the storage does not fill up.