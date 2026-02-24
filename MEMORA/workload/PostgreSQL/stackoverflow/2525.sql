WITH UserScoreSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (8, 9) THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        TotalBounty,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) + TotalBounty DESC) AS UserRank
    FROM UserScoreSummary
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE((SELECT COUNT(*) FROM Comments WHERE PostId = P.Id), 0) AS CommentCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    RU.UserRank,
    RU.DisplayName,
    RU.PostCount,
    RU.CommentCount,
    AP.PostId,
    AP.Title,
    AP.CreationDate,
    AP.LastActivityDate,
    AP.CommentCount AS PostCommentCount
FROM RankedUsers RU
JOIN ActivePosts AP ON RU.PostCount > 0
ORDER BY RU.UserRank, AP.LastActivityDate DESC
LIMIT 25;