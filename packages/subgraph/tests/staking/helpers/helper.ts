import { handleInitialized } from "../../../src/mappings/staking";
import { createInitializedEvent } from "../helpers/createEvents";

export function initialize(): void {
    handleInitialized(createInitializedEvent());
}
