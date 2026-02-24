WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HotQuestions AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS HotRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 10 AND 
        (P.ViewCount IS NOT NULL OR P.ViewCount > 100)
),
ConnectionInfo AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        PostLinks PL
    JOIN 
        Posts P ON PL.PostId = P.Id
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        PL.PostId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closed,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS Reopened,
        MAX(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS Deleted
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    U.TotalBounty,
    HOT.Id AS HotPostId,
    HOT.Title AS HotPostTitle,
    HOT.Score AS HotPostScore,
    HOT.ViewCount AS HotPostViews,
    COALESCE(CI.RelatedPostCount, 0) AS RelatedPostCount,
    COALESCE(CI.Tags, 'No Tags') AS TagsAssigned,
    PHS.HistoryCount,
    PHS.Closed,
    PHS.Reopened,
    PHS.Deleted
FROM 
    UserStats U
LEFT JOIN 
    HotQuestions HOT ON U.QuestionCount > 0 AND U.UserId = HOT.Id
LEFT JOIN 
    ConnectionInfo CI ON HOT.Id = CI.PostId
LEFT JOIN 
    PostHistorySummary PHS ON HOT.Id = PHS.PostId
WHERE 
    U.ReputationRank <= 50 
    AND (U.TotalBounty > 100 OR U.QuestionCount > 5)
ORDER BY 
    U.Reputation DESC, 
    HOT.Score DESC NULLS LAST;
