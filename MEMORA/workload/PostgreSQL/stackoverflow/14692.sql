
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.UpVotes, U.DownVotes
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.PostCount,
        U.BadgeCount,
        PS.PostId,
        PS.PostTypeId,
        PS.CommentCount,
        PS.TotalBounty
    FROM 
        UserStats U
    JOIN 
        PostStats PS ON U.UserId = PS.PostId
)
SELECT 
    F.UserId,
    F.Reputation,
    F.PostCount,
    F.BadgeCount,
    F.PostId,
    F.PostTypeId,
    F.CommentCount,
    F.TotalBounty,
    CASE 
        WHEN F.PostTypeId = 1 THEN 'Question'
        WHEN F.PostTypeId = 2 THEN 'Answer'
        WHEN F.PostTypeId = 3 THEN 'Wiki'
        ELSE 'Other'
    END AS PostTypeName
FROM 
    FinalStats F
ORDER BY 
    F.Reputation DESC, F.PostCount DESC;
