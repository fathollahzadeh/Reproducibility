
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT V.PostId) AS TotalVotedPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Badges B WHERE B.UserId = P.OwnerUserId AND B.Class = 1), 0) AS GoldBadgeCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
), 
EnhancedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.CommentCount,
        PS.Score,
        PS.PostType,
        CASE 
            WHEN PS.Score < 0 THEN 'Poor'
            WHEN PS.Score BETWEEN 0 AND 10 THEN 'Average'
            WHEN PS.Score > 10 THEN 'Good'
            ELSE NULL 
        END AS ScoreCategory,
        ROW_NUMBER() OVER (PARTITION BY PS.PostType ORDER BY PS.Score DESC) AS Rank,
        FIRST_VALUE(PS.Title) OVER (PARTITION BY PS.PostType ORDER BY PS.Score DESC) AS TopPostTitle
    FROM PostStats PS
), 
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UV.UpvoteCount,
        UV.DownvoteCount,
        PS.PostId,
        PS.Title AS PostTitle,
        PS.ScoreCategory,
        PS.Rank
    FROM Users U
    LEFT JOIN UserVotes UV ON U.Id = UV.UserId
    LEFT JOIN EnhancedPosts PS ON U.Id = PS.PostId
)
SELECT 
    UE.UserId,
    UE.DisplayName,
    UE.Reputation,
    UE.UpvoteCount,
    UE.DownvoteCount,
    (SELECT COUNT(*) FROM EnhancedPosts EP WHERE EP.Rank = 1 AND EP.PostId IS NOT NULL) AS TopPostCount,
    STRING_AGG(DISTINCT CASE WHEN UE.ScoreCategory = 'Good' THEN UE.PostTitle END) AS GoodPosts,
    COUNT(DISTINCT UE.PostTitle) AS TotalEngagedPosts,
    COALESCE(NULLIF(NULLIF(MAX(UE.DownvoteCount), 0), NULL), 0) AS NegativeEngagementLevel
FROM UserEngagement UE
GROUP BY UE.UserId, UE.DisplayName, UE.Reputation, UE.UpvoteCount, UE.DownvoteCount
HAVING COUNT(UE.PostTitle) > 1
ORDER BY UE.Reputation DESC, UE.UpvoteCount DESC
LIMIT 50;
