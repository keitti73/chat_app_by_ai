export const onRoomCreated = /* GraphQL */ `
  subscription OnRoomCreated {
    onRoomCreated {
      id
      name
      owner
      createdAt
    }
  }
`;

export const onMessagePosted = /* GraphQL */ `
  subscription OnMessagePosted($roomId: ID!) {
    onMessagePosted(roomId: $roomId) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;
