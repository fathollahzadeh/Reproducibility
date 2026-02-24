
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        COALESCE(PH.CreationDate, DATE '2000-01-01') AS LastHistoryDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),

FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        RP.AnswerCount,
        RP.OwnerDisplayName,
        RP.Reputation,
        RP.LastHistoryDate,
        CASE 
            WHEN RP.Reputation > 1000 THEN 'High Reputation User'
            WHEN RP.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
            ELSE 'Low Reputation User' 
        END AS ReputationCategory
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank = 1
),

AggregatedData AS (
    SELECT 
        ReputationCategory,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        FilteredPosts
    GROUP BY 
        ReputationCategory
)

SELECT 
    AD.ReputationCategory,
    AD.TotalPosts,
    AD.AvgViewCount,
    AD.TotalScore,
    AD.TotalAnswers,
    (CAST(AD.TotalScore AS decimal) / NULLIF(AD.TotalPosts, 0)) AS AvgScorePerPost
FROM 
    AggregatedData AD
ORDER BY 
    AD.TotalPosts DESC;
