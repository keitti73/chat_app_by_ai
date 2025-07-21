export const createRoom = /* GraphQL */ `
  mutation CreateRoom($name: String!) {
    createRoom(name: $name) {
      id
      name
      owner
      createdAt
    }
  }
`;

export const postMessage = /* GraphQL */ `
  mutation PostMessage($roomId: ID!, $text: String!) {
    postMessage(roomId: $roomId, text: $text) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;
