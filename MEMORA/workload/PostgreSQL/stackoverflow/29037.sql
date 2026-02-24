WITH KeywordCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(*) AS KeywordCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        LATERAL unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '>')) AS T(TagName) ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        V.PostId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(KC.KeywordCount, 0) AS KeywordCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        KeywordCounts KC ON P.Id = KC.PostId
    LEFT JOIN 
        RecentVotes RV ON P.Id = RV.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.KeywordCount,
    PS.RecentVoteCount,
    CASE 
        WHEN PS.RecentVoteCount > 10 THEN 'Hot'
        WHEN PS.KeywordCount > 5 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostStatistics PS
WHERE 
    PS.KeywordCount > 0
ORDER BY 
    PS.RecentVoteCount DESC, 
    PS.KeywordCount DESC;