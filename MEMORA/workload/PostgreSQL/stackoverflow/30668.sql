
WITH RECURSIVE PostHierarchy AS (
    SELECT
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.OwnerUserId,
        0 AS Level
    FROM
        Posts P
    WHERE
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT
        P.Id,
        P.ParentId,
        P.Title,
        P.OwnerUserId,
        PH.Level + 1
    FROM
        Posts P
        JOIN PostHierarchy PH ON P.ParentId = PH.PostId
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT
        PH.PostId,
        PH.Title,
        U.DisplayName AS Owner,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY PH.OwnerUserId ORDER BY COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) DESC) AS Rank
    FROM
        PostHierarchy PH
        LEFT JOIN Comments C ON PH.PostId = C.PostId
        LEFT JOIN Votes V ON PH.PostId = V.PostId
        LEFT JOIN Users U ON PH.OwnerUserId = U.Id
    GROUP BY
        PH.PostId, PH.Title, PH.OwnerUserId, U.DisplayName
),
CombinedStats AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.Owner,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        UR.Reputation AS OwnerReputation,
        UR.PostCount AS OwnerPostCount,
        UR.TotalBounty AS OwnerTotalBounty,
        CASE 
            WHEN PS.UpVotes > PS.DownVotes THEN 'Positive'
            WHEN PS.UpVotes < PS.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM
        PostStats PS
    JOIN UserReputation UR ON PS.Owner = UR.DisplayName
)
SELECT
    CS.PostId,
    CS.Title,
    CS.Owner,
    CS.CommentCount,
    CS.UpVotes,
    CS.DownVotes,
    CS.OwnerReputation,
    CS.OwnerPostCount,
    CS.OwnerTotalBounty,
    CS.VoteSentiment
FROM
    CombinedStats CS
WHERE
    CS.OwnerReputation > 1000
ORDER BY
    CS.OwnerReputation DESC,
    CS.CommentCount DESC;
