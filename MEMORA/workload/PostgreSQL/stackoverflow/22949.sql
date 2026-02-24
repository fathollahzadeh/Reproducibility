WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' 
        AND p.PostTypeId IN (1, 2) 
),
DistinctTags AS (
    SELECT
        DISTINCT TRIM(REGEXP_SPLIT_TO_TABLE(p.Tags, '>')) AS TagName,
        p.Id AS PostId
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
PostScores AS (
    SELECT 
        rp.PostId,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        rp.Reputation,
        (rp.Score + COALESCE(v.TotalVotes, 0) + COALESCE(b.BadgeCount, 0)) AS TotalScore
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON rp.OwnerUserId = b.UserId
)
SELECT 
    pt.TagName,
    COUNT(ps.PostId) AS PostsCount,
    AVG(ps.TotalScore) AS AverageScore
FROM 
    DistinctTags dt
JOIN 
    PostScores ps ON dt.PostId = ps.PostId
JOIN 
    Tags pt ON pt.TagName = dt.TagName
GROUP BY 
    pt.TagName
HAVING 
    AVG(ps.TotalScore) > (
        SELECT 
            AVG(TotalScore)
        FROM 
            PostScores
    ) * 0.75 
ORDER BY 
    AverageScore DESC
LIMIT 10;