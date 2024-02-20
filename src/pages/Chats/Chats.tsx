import AppInfoCard from "@/components/App/AppInfoCard";
import AppLoading from "@/components/App/AppLoading";
import Chat from "@/components/Chat/Chat";
import { useAuthContext } from "@/context/AuthContext";
import { QueryKeys } from "@/models/query_keys.model";
import { IRoom } from "@/models/room.model";
import { Routes } from "@/routes/routes";
import { messagesService } from "@/services/messages.service";
import {
  IonContent,
  IonHeader,
  IonList,
  IonPage,
  IonTitle,
  IonToolbar,
  useIonRouter,
} from "@ionic/react";
import { useQuery } from "@tanstack/react-query";

export default function ChatsPage() {
  const router = useIonRouter();
  const { user } = useAuthContext();

  const data = useQuery<IRoom[]>({
    queryKey: [QueryKeys.Chats, user?.id],
    queryFn: () => messagesService.fetchRooms(user!.id),
  });

  if (data.isLoading) {
    return <AppLoading />;
  }

  return (
    <IonPage>
      <IonHeader translucent={true}>
        <IonToolbar>
          <IonTitle>Chattar</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent>
        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">Chattar</IonTitle>
          </IonToolbar>
        </IonHeader>

        {!data.data ? (
          <AppInfoCard message="No messages found" />
        ) : (
          <IonList inset>
            {data.data.map((room) => {
              const roomUser = room.profiles
                .filter((v) => v.id !== user!.id)
                .at(0);

              return (
                <Chat
                  key={room.id}
                  onClick={() =>
                    router.push(Routes.Chat.replace(":roomUid", room.id))
                  }
                  onClickDelete={() => null}
                  subtitle=""
                  user={roomUser!}
                />
              );
            })}
          </IonList>
        )}
      </IonContent>
    </IonPage>
  );
}
