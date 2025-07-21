# Mutation: createRoom
resource "aws_appsync_resolver" "create_room" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "createRoom"
  type        = "Mutation"
  data_source = aws_appsync_datasource.room_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Mutation_createRoom.js")
}

# Mutation: postMessage
resource "aws_appsync_resolver" "post_message" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "postMessage"
  type        = "Mutation"
  data_source = aws_appsync_datasource.message_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Mutation_postMessage.js")
}

# Query: myOwnedRooms
resource "aws_appsync_resolver" "my_owned_rooms" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "myOwnedRooms"
  type        = "Query"
  data_source = aws_appsync_datasource.room_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Query_myOwnedRooms.js")
}

# Query: myActiveRooms (同じリゾルバーを使用、実際の実装では異なるロジック)
resource "aws_appsync_resolver" "my_active_rooms" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "myActiveRooms"
  type        = "Query"
  data_source = aws_appsync_datasource.message_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Query_myActiveRooms.js")
}

# Query: getRoom
resource "aws_appsync_resolver" "get_room" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "getRoom"
  type        = "Query"
  data_source = aws_appsync_datasource.room_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Query_getRoom.js")
}

# Query: listMessages
resource "aws_appsync_resolver" "list_messages" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "listMessages"
  type        = "Query"
  data_source = aws_appsync_datasource.message_table.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Query_listMessages.js")
}
