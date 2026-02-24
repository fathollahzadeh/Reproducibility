WITH PostStats AS (
    SELECT 
        P.PostTypeId, 
        COUNT(P.Id) AS PostCount, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    P.PostTypeId,
    P.PostCount,
    P.UpVotes,
    P.DownVotes,
    U.Reputation,
    U.BadgeCount
FROM 
    PostStats P
JOIN 
    UserStats U ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE PostTypeId = P.PostTypeId LIMIT 1)
ORDER BY 
    P.PostTypeId;