import { Routes } from "@/routes/routes";
import { IonBackButton, IonButtons, IonHeader, IonToolbar } from "@ionic/react";
import { PropsWithChildren } from "react";

interface IProps extends PropsWithChildren {
  withBackButton?: boolean;
}

export default function AppHeader({ children, withBackButton }: IProps) {
  return (
    <IonHeader>
      <IonToolbar>
        {withBackButton === true && (
          <IonButtons slot="start">
            <IonBackButton defaultHref={Routes.Home} />
          </IonButtons>
        )}

        {children}
      </IonToolbar>
    </IonHeader>
  );
}
