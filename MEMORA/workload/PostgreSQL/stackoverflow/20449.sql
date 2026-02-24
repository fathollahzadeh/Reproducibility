WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.PostTypeId,
        rp.AcceptedAnswerId,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 10 
        AND rp.VoteCount > 5 
        AND rp.PostRank = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.Title,
    u.DisplayName,
    fp.CommentCount,
    fp.VoteCount,
    CASE 
        WHEN u.GoldBadges > 0 THEN 'Gold User'
        WHEN u.SilverBadges > 0 THEN 'Silver User'
        ELSE 'Regular User'
    END AS UserBadgeType,
    COALESCE(ph.Comment, 'No comment') AS PostHistoryComment,
    ROW_NUMBER() OVER (ORDER BY fp.VoteCount DESC) AS VoteRank
FROM 
    FilteredPosts fp
JOIN 
    UserStats u ON fp.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
WHERE 
    (fp.PostTypeId = 1 AND fp.AcceptedAnswerId IS NOT NULL) 
    OR (fp.PostTypeId = 2 AND ph.PostHistoryTypeId IN (10, 11)) 
ORDER BY 
    fp.VoteCount DESC, 
    u.DisplayName ASC;