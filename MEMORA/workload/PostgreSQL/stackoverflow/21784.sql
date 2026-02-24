WITH RankedPosts AS (
    SELECT
        P.Id AS PostID,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        RP.PostID,
        RP.Title,
        RP.CreationDate,
        COALESCE(U.DisplayName, 'Unknown') AS OwnerDisplayName,
        RP.Score,
        RP.UpvoteCount,
        RP.DownvoteCount,
        CASE 
            WHEN RP.Score < 0 THEN 'Negative'
            WHEN RP.Score > 0 THEN 'Positive'
            ELSE 'Neutral'
        END AS ScoreEvaluation,
        CASE 
            WHEN RP.RecentPostRank = 1 THEN 'Most Recent'
            ELSE 'Older Post'
        END AS PostAgeCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id
),
FinalResults AS (
    SELECT 
        PS.OwnerDisplayName,
        PS.Title,
        PS.CreationDate,
        PS.ScoreEvaluation,
        PS.UpvoteCount,
        PS.DownvoteCount,
        PS.PostAgeCategory,
        CASE 
            WHEN PS.PostAgeCategory = 'Most Recent' AND PS.ScoreEvaluation = 'Positive' THEN 'Promote'
            WHEN PS.PostAgeCategory = 'Most Recent' AND PS.ScoreEvaluation = 'Neutral' THEN 'Monitor'
            WHEN PS.PostAgeCategory = 'Most Recent' AND PS.ScoreEvaluation = 'Negative' THEN 'Review'
            ELSE 'Archive'
        END AS ActionRecommendation
    FROM 
        PostStatistics PS
)
SELECT 
    OwnerDisplayName,
    Title,
    CreationDate,
    UpvoteCount,
    DownvoteCount,
    ScoreEvaluation,
    PostAgeCategory,
    ActionRecommendation
FROM 
    FinalResults
WHERE 
    (UpvoteCount > DownvoteCount) OR (ScoreEvaluation = 'Negative' AND PostAgeCategory = 'Most Recent')
ORDER BY 
    CreationDate DESC
LIMIT 100;