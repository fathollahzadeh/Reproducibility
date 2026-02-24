WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentPosts AS (
    SELECT
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 3
),
TopBadgers AS (
    SELECT 
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
    HAVING 
        COUNT(B.Id) > 5
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    TB.BadgeCount,
    CASE 
        WHEN RP.Score > 100 THEN 'High Score'
        WHEN RP.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    COALESCE(
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.ExcerptPostId = RP.Id),
        'No Tags') AS TagsUsed
FROM 
    RecentPosts RP
LEFT JOIN 
    TopBadgers TB ON RP.OwnerDisplayName = TB.DisplayName
ORDER BY 
    RP.CreationDate DESC;