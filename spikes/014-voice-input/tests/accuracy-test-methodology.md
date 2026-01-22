# Voice Input Accuracy Test Methodology

## Purpose

Evaluate transcription accuracy for coding-related dictation across voice input tools.

## Test Categories

### 1. Technical Terminology Test

Test phrases containing common programming terms:

```
Test Phrases:
1. "Create a new FastAPI endpoint that returns a JSON response"
2. "Import NumPy and Pandas for data analysis"
3. "The Kubernetes pod is failing its liveness probe"
4. "Use async await with the fetch API in TypeScript"
5. "Configure the PostgreSQL connection string in the environment variables"
6. "The React useState hook should initialize with an empty array"
7. "Run pytest with coverage and generate an HTML report"
8. "Deploy the Docker container to the AWS ECS cluster"
9. "The GraphQL mutation should validate the input schema"
10. "Use the OpenAI API to generate embeddings for the vector database"
```

**Scoring**: Count correctly transcribed technical terms out of total.

### 2. Variable Naming Convention Test

Test different naming conventions:

```
Test Phrases:
1. "Create a variable called userAccountBalance" (camelCase)
2. "Define a function named get_user_profile" (snake_case)
3. "The constant should be MAX_RETRY_COUNT" (SCREAMING_SNAKE_CASE)
4. "Create a class called UserAuthenticationService" (PascalCase)
5. "Name the file user-profile-component.tsx" (kebab-case)
6. "The method is called fetchDataFromAPIEndpoint"
7. "Set the variable isUserAuthenticated to true"
8. "Create OPENAI_API_KEY environment variable"
9. "The function parseJSONResponse handles the data"
10. "Import calculateTotalOrderAmount from utils"
```

**Scoring**: Correct formatting of variable names (case, separators).

### 3. Code Instruction Test

Test dictating actual code instructions:

```
Test Phrases:
1. "Write a function that takes a list of integers and returns the sum"
2. "Create an interface with properties name string, age number, and email string"
3. "Add a try catch block that logs the error message to the console"
4. "Write a SQL query to select all users where created_at is greater than yesterday"
5. "Create a bash script that loops through all .txt files in the current directory"
6. "Define a TypeScript type that is either a string or null"
7. "Add a middleware that checks if the request has a valid JWT token"
8. "Write a regex pattern that matches email addresses"
9. "Create a Python decorator that logs function execution time"
10. "Add a GitHub Actions workflow that runs tests on pull requests"
```

**Scoring**: Semantic accuracy of instruction intent.

### 4. Library and Framework Names Test

Test recognition of common libraries/frameworks:

```
Libraries to Test:
- React, Vue, Angular, Svelte
- FastAPI, Django, Flask, Express
- TensorFlow, PyTorch, scikit-learn
- Kubernetes, Docker, Terraform
- PostgreSQL, MongoDB, Redis, Elasticsearch
- Next.js, Nuxt.js, Remix, Astro
- Tailwind, Bootstrap, Material UI
- Jest, pytest, Mocha, Cypress
- Prisma, SQLAlchemy, TypeORM
- LangChain, LlamaIndex, OpenAI
```

**Scoring**: Correct capitalization and spelling of library names.

### 5. Mixed Language Test (Optional)

For multilingual support evaluation:

```
Test Phrases:
1. English + code: "Crea una función que retorne el usuario" (Spanish + code)
2. Technical in French: "Configurer le serveur nginx avec SSL"
3. Variable names in context: "La variable totalCommandes doit être initialisée"
```

## Test Procedure

### Setup
1. Use consistent microphone setup (built-in or external)
2. Quiet environment with minimal background noise
3. Normal speaking pace and volume
4. Record test session for verification

### Execution
1. Read each phrase naturally (not robotically)
2. Include brief pauses between phrases
3. Do not repeat or correct during initial pass
4. Note any UI feedback or confidence indicators

### Measurement
- **Word Error Rate (WER)**: (Substitutions + Deletions + Insertions) / Total Words
- **Technical Term Accuracy**: Correct technical terms / Total technical terms
- **Formatting Accuracy**: Correct case/formatting / Total formatted terms
- **Latency**: Time from speech end to text appearance

## Test Matrix

| Tool | Category 1 | Category 2 | Category 3 | Category 4 | Latency | Notes |
|------|-----------|-----------|-----------|-----------|---------|-------|
| Superwhisper | | | | | | |
| Wispr Flow | | | | | | |
| MacWhisper | | | | | | |
| Voibe | | | | | | |
| Talon | | | | | | |

## Pass/Fail Criteria

For **Must Have** requirements:
- Technical Term Accuracy: >= 90%
- Latency: < 2 seconds for average phrase
- Offline capability: Must work without internet

For **Should Have** requirements:
- Variable Naming Accuracy: >= 85%
- Code Instruction Clarity: >= 90% semantic accuracy

## Post-Processing Evaluation

For tools with LLM post-processing:
1. Run same test with post-processing enabled
2. Compare raw vs processed accuracy
3. Note processing time overhead
4. Evaluate formatting improvements

## Notes

- Tests should be repeated 3x for consistency
- Note environmental factors (noise, microphone quality)
- Document any tool-specific optimizations used
- Compare against baseline (macOS built-in dictation)
