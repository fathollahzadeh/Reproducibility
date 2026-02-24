
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestions
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RowNum,
        P.OwnerUserId AS UserId
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AcceptedAnswerId, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PS.*,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM PS.CreationDate) ORDER BY PS.Score DESC) AS ScoreRank
    FROM PostStatistics PS
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.ClosedQuestions,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.Score,
    PP.ViewCount,
    PP.AcceptedAnswerId,
    PP.Upvotes,
    PP.Downvotes,
    PP.CommentCount,
    PP.RowNum,
    PP.ScoreRank,
    CASE 
        WHEN PP.ScoreRank = 1 THEN 'Top Post'
        WHEN PP.ScoreRank <= 5 THEN 'Top 5 Post'
        ELSE 'Other Post'
    END AS PostRankCategory
FROM UserActivity UA
JOIN RankedPosts PP ON UA.TotalPosts > 0
    AND PP.UserId = UA.UserId
WHERE PP.ScoreRank <= 10
ORDER BY UA.Reputation DESC, PP.Score DESC, UA.DisplayName;
