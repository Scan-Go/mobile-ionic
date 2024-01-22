import { FirebaseCollections } from "@/models/firebase_collections.model";
import { IRegisterUserForm, IUser } from "@/models/user.model";
import { Auth, createUserWithEmailAndPassword } from "firebase/auth";
import { Firestore, doc, setDoc } from "firebase/firestore";
import { converter } from "./firebase.service";

export class FirebaseAuthService {
  private auth: Auth;
  private firestore: Firestore;

  constructor(auth: Auth, firestore: Firestore) {
    this.auth = auth;
    this.firestore = firestore;
  }

  async createUser(data: IRegisterUserForm) {
    try {
      const user = await createUserWithEmailAndPassword(
        this.auth,
        data.email,
        data.password
      );

      if (user) {
        const createProfile = await this.createProfile(user.user.uid, data);

        return true;
      }
    } catch (error) {
      throw error;
    }
  }

  private async createProfile(uid: string, data: IUser) {
    try {
      const docRef = doc(
        this.firestore,
        FirebaseCollections.Profiles,
        uid
      ).withConverter<IUser>(converter<IUser>());

      await setDoc<IUser>(docRef, {
        firstName: data.firstName,
        lastName: data.lastName,
        bio: "",
        profileImageRef: "",
      });
    } catch (error) {
      throw error;
    }
  }
}
