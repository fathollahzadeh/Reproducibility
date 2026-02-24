
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation IS NOT NULL AND 
        U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
RecentActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseAndReopenCount
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.AvgScore,
    PT.TagName,
    PT.PostCount AS PopularTagPostCount,
    RA.CloseAndReopenCount
FROM 
    UserActivity UA
LEFT JOIN 
    PopularTags PT ON UA.Rank <= 5
LEFT JOIN 
    RecentActivity RA ON UA.UserId = RA.OwnerUserId
WHERE 
    UA.PostCount > 0 AND 
    (RA.CloseAndReopenCount IS NULL OR RA.CloseAndReopenCount > 0)
ORDER BY 
    UA.Rank, PT.TagRank;
