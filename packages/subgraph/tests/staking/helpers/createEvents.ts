import { newMockEvent } from "matchstick-as";
import { Initialized as InitializedEvent } from "../../../generated/Staking/Staking";
import { stakingAddress, initDate } from "../../utils/constants";
import { createMockedFunctions } from "./createMockedFunctions";

export function createInitializedEvent(): InitializedEvent {
    createMockedFunctions();

    // @ts-ignore
    const newEvent = changetype<InitializedEvent>(newMockEvent());
    newEvent.address = stakingAddress;
    newEvent.block.timestamp = initDate;

    return newEvent;
}
