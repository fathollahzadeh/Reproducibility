WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN (v.VoteTypeId = 2) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN (v.VoteTypeId = 3) THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    us.DisplayName AS UserName,
    us.Upvotes,
    us.Downvotes,
    us.BadgeCount,
    pc.CommentCount,
    COALESCE(pc.CommentTexts, 'No comments') AS CommentTexts,
    CASE 
        WHEN rp.Score IS NULL THEN 'No interactions'
        WHEN rp.Score > 100 THEN 'Highly active'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately active'
        ELSE 'Less active'
    END AS ActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStats us ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId LIMIT 1)
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;