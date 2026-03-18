class IVChargeCounter : Inventory
{
    Default
    {
        Inventory.MaxAmount 4200;
    }
}

class IVActiveMarker : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
    }
}

class IVLureBeacon : Actor
{
    Default
    {
        Radius 8;
        Height 48;
        Health 1;
        Mass 1;

        +SHOOTABLE;
        +INVULNERABLE;
        +NOGRAVITY;
        +NOBLOOD;
        +DONTTHRUST;
        +NODAMAGETHRUST;
        +DONTSPLASH;
        +NOTELEPORT;
    }

    States
    {
    Spawn:
        INVI A -1;
        Stop;
    }
}