import { Camera, CameraResultType, CameraSource } from "@capacitor/camera";
import { useCallback } from "react";

export function useGallery() {
  const getPhoto = useCallback(() => {
    return Camera.getPhoto({
      source: CameraSource.Photos,
      resultType: CameraResultType.DataUrl,
    });
  }, []);

  const initialize = useCallback(async () => {
    const allowed = await isAllowedPermissions();

    if (!allowed) {
      Camera.requestPermissions({
        permissions: ["photos"],
      });
    }
  }, []);

  const isAllowedPermissions = useCallback(async () => {
    const cameraPermissions = await Camera.checkPermissions();

    return cameraPermissions.photos === "granted";
  }, []);

  return {
    initialize,
    getPhoto,
  };
}