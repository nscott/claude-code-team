# claude-code-team

This is a basic setup to get multiple agents talking together to work on a project..

Why have a separate Docker container for Claude? Because this lets it run with a sandbox around it, for both resources, and most important, file system containment. It's much simpler to then run with `--dangerously-skip-permissions`. Run whatever you want Mr. AI Agent, you're containerized. Risk is greatly reduced while letting it get on with finishing tasks.

## Creating

`docker compose build`

This build should automatically install the Claude CLI and mount a directory at `/opt/programmer` that is the directory *above this one*. That means this repository should be cloned *into a project* and ran from within it.

Claude Code creates a bunch of stuff in the home directory. That gets kept as a *Docker volume* - it is NOT mounted to the host file system. That means it's preserved between `docker compose down`s as well, which keeps e.g. your API keys and keeps you signed in. If you need to truly start over, make sure to delete the Docker volume.

## Running

`docker compose up`. You'll be using Claude on the command line with agents.
Connect to the container: `docker compose exec claude-wrapper /bin/bash`.
Run `claude`, generate the API key or use the OAuth workflow, and get to it.

If you want to use Serena, and you want it to *automatically* discover your project and add language server support, make sure to add `SERENA_AUTOGENERATE=1` to the docker compose file. Serena needs to scan a project, determine it's languages, and then generate it's own project config *for each directory*. It's really annoying but it's how it works. There's a script that will traverse your directories and try it's best to autogenerate project config and add it to serena_config.yml.

## Developing

This is equipped to use [OpenSpec](https://github.com/Fission-AI/OpenSpec/). Use `/openspec:proposal`, `/openspec:apply`, and `/openspec:archive` inside of Claude Code to work with the specs.

There are three major prompts to start with OpenSpec:

1. Populate your project context: "Please read openspec/project.md and help me fill it out with details about my project, tech stack, and conventions"

2. Create your first change proposal: "I want to add [YOUR FEATURE HERE]. Please create an OpenSpec change proposal for this feature"

3. Learn the OpenSpec workflow: "Please explain the OpenSpec workflow from openspec/AGENTS.md and how I should work with you on this project"

4. Open the Matrix web interface (http://localhost:8009) and log in with admin/admin. Congrats, your agents should be dumping info there.


## What is all of this even doing?
* Serena: MCP to allow symbolic code searching with LSPs
* Matrix Synapse: Matrix chat server that the agents join and communicate on
* Element: Web interface to the Matrix server, admin/admin
* CONTEXT7_API_KEY in .env.example: A Context7 API key for the MCP server to allow Claude to search docs for any frameworks.
