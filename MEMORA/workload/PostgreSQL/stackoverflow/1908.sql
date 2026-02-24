
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.BountyAmount IS NOT NULL THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS UniqueTagCount
    FROM 
        Posts P
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, '><')) AS T(TagName) ON true
    GROUP BY 
        P.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        COALESCE(PH.UsersWhoEdited, 0) AS EditorCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(DISTINCT UserId) AS UsersWhoEdited
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5)  
        GROUP BY 
            PostId
    ) AS PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.AnswerCount,
    R.ViewCount,
    CURRENT_TIMESTAMP AS BenchmarkTimestamp,
    U.UserId,
    U.DisplayName,
    U.Upvotes,
    U.Downvotes,
    U.TotalBounty,
    PC.UniqueTagCount,
    CASE WHEN R.RowNum = 1 THEN TRUE ELSE FALSE END AS IsMostRecent
FROM 
    RecentPosts R
JOIN 
    UserVoteStats U ON R.OwnerUserId = U.UserId
LEFT JOIN 
    PostTagCounts PC ON R.PostId = PC.PostId
WHERE 
    U.TotalBounty > 100 AND 
    R.EditorCount > 3
ORDER BY 
    R.CreationDate DESC;
