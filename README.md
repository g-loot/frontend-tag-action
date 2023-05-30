# Frontend Tag Action

This GitHub Action creates a tag for the frontend project. It is designed to be used within a workflow to automate the tagging process.

## Author

This action is developed by Stryda.

## Inputs

The action requires the following inputs:

- `branch`: The branch to tag.
- `production`: Indicates whether it is a production release.

Both inputs are required for the action to run successfully.

## Outputs

The action provides the following output:

- `tag`: The newly created tag.

## Usage

To use this action, include the following code in your workflow file:

```yaml
name: Frontend Tag Workflow

on:
  push:
    branches:
      - main

jobs:
  tag_frontend:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Tag Frontend
        id: tag_frontend
        uses: stryda/frontend-tag-action@v1
        with:
          branch: ${{ github.ref }}
          production: true

      - name: Display Tag
        run: echo "The newly created tag is ${{ steps.tag_frontend.outputs.tag }}"
