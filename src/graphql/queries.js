export const myOwnedRooms = /* GraphQL */ `
  query MyOwnedRooms {
    myOwnedRooms {
      id
      name
      owner
      createdAt
    }
  }
`;

export const myActiveRooms = /* GraphQL */ `
  query MyActiveRooms {
    myActiveRooms {
      id
      name
      owner
      createdAt
    }
  }
`;

export const getRoom = /* GraphQL */ `
  query GetRoom($id: ID!) {
    getRoom(id: $id) {
      id
      name
      owner
      createdAt
    }
  }
`;

export const listMessages = /* GraphQL */ `
  query ListMessages($roomId: ID!, $limit: Int) {
    listMessages(roomId: $roomId, limit: $limit) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;
