
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopPostWithBadges AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.CreationDate,
        u.DisplayName AS OwnerName,
        ub.BadgeCount,
        CASE 
            WHEN r.Score > 100 THEN 'Highly Scored'
            WHEN r.Score > 50 THEN 'Moderately Scored'
            ELSE 'Low Scores'
        END AS ScoreCategory
    FROM 
        RankedPosts r
    INNER JOIN 
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        r.Rank <= 10 
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.OwnerName,
    tp.BadgeCount,
    pa.CommentCount,
    pa.Upvotes,
    pa.Downvotes,
    tp.ScoreCategory
FROM 
    TopPostWithBadges tp
JOIN 
    PostActivity pa ON tp.PostId = pa.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
