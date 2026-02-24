WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS CloseVotes,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), TopPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes,
        ps.CloseVotes,
        ps.AverageScore,
        ROW_NUMBER() OVER (ORDER BY ps.AverageScore DESC, ps.Upvotes DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.CloseVotes,
    tp.AverageScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    tp.Rank <= 10;