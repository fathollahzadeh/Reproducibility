WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS HasUpvote
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rb.PostId,
    rb.Title,
    rb.CreationDate,
    rb.Score,
    rb.ViewCount,
    rb.AnswerCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE WHEN rb.HasUpvote = 1 THEN 'Yes' ELSE 'No' END AS Upvoted,
    COALESCE(pht.Comment, 'No comments') AS LastEditComment,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    RankedPosts rb ON u.Id = rb.UserPostRank
LEFT JOIN 
    PostHistory pht ON pht.PostId = rb.PostId AND pht.PostHistoryTypeId IN (4, 6)
LEFT JOIN 
    Comments c ON c.PostId = rb.PostId
JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    rb.UserPostRank <= 5
GROUP BY 
    u.Id, rb.PostId, rb.Title, rb.CreationDate, rb.Score, rb.ViewCount, rb.AnswerCount, 
    ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, rb.HasUpvote, pht.Comment
ORDER BY 
    u.Reputation DESC, rb.Score DESC;