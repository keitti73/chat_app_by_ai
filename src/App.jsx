import React, { useState } from 'react';
import { Amplify } from 'aws-amplify';
import MyRooms from './components/MyRooms';
import ChatRoom from './components/ChatRoom';

// TODO: Amplify設定を実際のAWS設定に置き換える
const amplifyConfig = {
  aws_project_region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  aws_appsync_graphqlEndpoint: import.meta.env.VITE_APPSYNC_GRAPHQL_ENDPOINT || 'https://your-appsync-endpoint.amazonaws.com/graphql',
  aws_appsync_region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  aws_appsync_authenticationType: import.meta.env.VITE_APPSYNC_AUTH_TYPE || 'API_KEY',
  aws_appsync_apiKey: import.meta.env.VITE_APPSYNC_API_KEY || 'your-api-key',
};

Amplify.configure(amplifyConfig);

function App() {
  const [currentView, setCurrentView] = useState('rooms'); // 'rooms' or 'chat'
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [username] = useState('demo-user'); // 実際の認証実装時はCognitoから取得

  const handleRoomSelect = (roomId, roomName) => {
    setSelectedRoom({ id: roomId, name: roomName });
    setCurrentView('chat');
  };

  const handleBackToRooms = () => {
    setCurrentView('rooms');
    setSelectedRoom(null);
  };

  return (
    <div style={{ fontFamily: 'Arial, sans-serif' }}>
      <header style={{
        backgroundColor: '#343a40',
        color: 'white',
        padding: '10px 20px',
        textAlign: 'center'
      }}>
        <h1>AppSync Chat App</h1>
        <small>ユーザー: {username}</small>
      </header>

      <main>
        {currentView === 'rooms' ? (
          <MyRooms 
            username={username} 
            onRoomSelect={handleRoomSelect}
          />
        ) : (
          <ChatRoom
            roomId={selectedRoom?.id}
            roomName={selectedRoom?.name}
            username={username}
            onBack={handleBackToRooms}
          />
        )}
      </main>
    </div>
  );
}

export default App;
