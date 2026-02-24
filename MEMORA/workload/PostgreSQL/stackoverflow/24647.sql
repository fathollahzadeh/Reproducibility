WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(PH.RevisionGUID, 'N/A') AS LastGUID,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 10)
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY PostId
),
FilteredPosts AS (
    SELECT 
        P.Title,
        P.Body,
        P.ViewCount,
        COALESCE(MC.CommentCount, 0) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY P.ViewCount DESC, COALESCE(MC.CommentCount, 0) DESC) AS CombinedRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN MostCommentedPosts MC ON P.Id = MC.PostId
    WHERE P.ClosedDate IS NULL AND P.ViewCount > 100
)
SELECT 
    U.DisplayName,
    U.Reputation,
    FP.Title,
    FP.ViewCount,
    FP.CommentCount,
    FP.CombinedRank
FROM RankedUsers U
JOIN FilteredPosts FP ON U.QuestionCount > 5 
WHERE U.Rank <= 10 
ORDER BY U.Rank, FP.CombinedRank
LIMIT 10;