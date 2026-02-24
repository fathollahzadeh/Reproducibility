WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostsWithBadges AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.AnswerCount,
        trp.CommentCount,
        trp.OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
    GROUP BY 
        trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.ViewCount, trp.AnswerCount, trp.CommentCount, trp.OwnerDisplayName
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.OwnerDisplayName,
    p.BadgeCount,
    CASE 
        WHEN p.Score > 10 THEN 'High Engagement'
        WHEN p.Score BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostsWithBadges p
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 50;