WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
PostScores AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        TagCount,
        OwnerDisplayName,
        BadgeCount,
        (ViewCount + Score + TagCount + BadgeCount) AS TotalScore
    FROM 
        RankedPosts
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        PostScores
    WHERE 
        TotalScore > 0
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    p.BadgeCount,
    p.Rank
FROM 
    TopPosts p
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Rank;