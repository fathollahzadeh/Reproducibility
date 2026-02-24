
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COUNT(C.Id) AS TotalComments
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
      AND P.PostTypeId = 1
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation
    FROM UserReputation UR
    WHERE UR.Reputation > 1000
      AND UR.ReputationRank <= 10
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        UR.DisplayName AS OwnerName,
        RP.Score,
        RP.TotalComments
    FROM RecentPosts RP
    JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.OwnerName,
    PD.Score,
    PD.TotalComments,
    CASE 
        WHEN PD.TotalComments = 0 THEN 'No Comments'
        WHEN PD.TotalComments < 5 THEN 'Few Comments'
        ELSE 'Many Comments'
    END AS CommentLevel,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PD.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PD.PostId AND V.VoteTypeId = 3) AS DownVotes,
    COALESCE((SELECT STRING_AGG(T.TagName, ', ') 
              FROM Tags T 
              JOIN Posts P ON T.ExcerptPostId = P.Id 
              WHERE P.Id = PD.PostId), 'No Tags') AS Tags
FROM PostDetails PD
JOIN TopUsers TU ON PD.OwnerName = TU.DisplayName
ORDER BY PD.CreationDate DESC
LIMIT 50;
