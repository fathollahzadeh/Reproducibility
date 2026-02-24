WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentsPerPost AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        SUM(c.Score) AS TotalScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostsWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(c.TotalScore, 0) AS TotalCommentScore,
        CASE 
            WHEN tp.Score IS NULL THEN -1
            ELSE tp.Score
        END AS PostScore
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsPerPost c ON tp.PostId = c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    p.Title,
    p.PostScore,
    p.CommentCount,
    p.TotalCommentScore,
    ub.Badges
FROM 
    Users up
LEFT JOIN 
    PostsWithComments p ON up.Id = p.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    p.PostScore > 0
    AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 1)
ORDER BY 
    p.PostScore DESC, 
    p.CommentCount DESC
LIMIT 10;