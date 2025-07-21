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

# Query: myActiveRooms (パイプラインリゾルバー)
resource "aws_appsync_resolver" "my_active_rooms" {
  api_id = aws_appsync_graphql_api.chat_api.id
  field  = "myActiveRooms"
  type   = "Query"
  kind   = "PIPELINE"

  pipeline_config {
    functions = [
      aws_appsync_function.my_active_rooms_get_messages.function_id,
      aws_appsync_function.my_active_rooms_get_rooms.function_id
    ]
  }

  request_template  = "## Start pipeline\n{}"
  response_template = "$util.toJson($ctx.result)"
}

# パイプライン関数1: メッセージからルームIDを取得
resource "aws_appsync_function" "my_active_rooms_get_messages" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  data_source = aws_appsync_datasource.message_table.name
  name        = "getMessagesForActiveRooms"

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Pipeline_myActiveRooms_1_getMessages.js")
}

# パイプライン関数2: ルームIDからルーム情報を取得
resource "aws_appsync_function" "my_active_rooms_get_rooms" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  data_source = aws_appsync_datasource.room_table.name
  name        = "getRoomsFromIds"

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Pipeline_myActiveRooms_2_getRooms.js")
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

# 🤖 Mutation: analyzeMessageSentiment (Lambda リゾルバー)
resource "aws_appsync_resolver" "analyze_message_sentiment" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "analyzeMessageSentiment"
  type        = "Mutation"
  data_source = aws_appsync_datasource.lambda_sentiment.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/../resolvers/Lambda_analyzeMessageSentiment.js")
}
