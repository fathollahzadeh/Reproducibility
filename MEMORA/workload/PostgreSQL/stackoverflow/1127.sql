WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS RN
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE U.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT * 
    FROM UserActivity 
    WHERE RN = 1
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        P.Score,
        P.ViewCount,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        COALESCE(PH.Revisions, 0) AS RevisionCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) PC ON PC.PostId = P.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS Revisions FROM PostHistory GROUP BY PostId) PH ON PH.PostId = P.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
      AND P.Score > 0
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (ORDER BY PD.ViewCount DESC, PD.Score DESC) AS PostRank
    FROM PostDetails PD
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.CommentCount,
    RP.RevisionCount
FROM TopUsers TU
JOIN RankedPosts RP ON RP.Author = TU.DisplayName
WHERE TU.Reputation > 1000 
ORDER BY TU.Reputation DESC, RP.ViewCount DESC
LIMIT 10;