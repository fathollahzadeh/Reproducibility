
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.PostTypeId, 
        COUNT(C.ID) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(P.ViewCount) OVER (PARTITION BY P.OwnerUserId) AS TotalViews
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
PostHistoryAggregate AS (
    SELECT 
        PH.PostId, 
        MAX(PH.CreationDate) AS LastEdited,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    UR.UserId, 
    UR.DisplayName, 
    UR.Reputation, 
    PS.PostId, 
    PS.CommentCount, 
    PS.VoteCount, 
    PS.UpVotes, 
    PS.DownVotes, 
    PH.LastEdited,
    PH.CloseOpenCount,
    CASE 
        WHEN UR.Reputation > 1000 THEN 'Experienced' 
        WHEN UR.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS UserExperience,
    CASE 
        WHEN PS.VoteCount > 20 THEN 'Popular'
        WHEN PS.CommentCount > 15 THEN 'Engaging'
        ELSE 'Under the Radar'
    END AS PostEngagement
FROM UserReputation UR
JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN PostHistoryAggregate PH ON PS.PostId = PH.PostId
WHERE PS.CommentCount > 5 
  AND PS.UpVotes - PS.DownVotes > 0 
  AND PH.LastEdited < '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
ORDER BY UR.Reputation DESC, PS.VoteCount DESC
LIMIT 50;
