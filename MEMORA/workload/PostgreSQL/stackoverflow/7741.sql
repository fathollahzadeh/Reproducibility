
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.OwnerName,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostId
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank <= 3
),
UserBadgeStats AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ubs.DisplayName AS UserName,
    ubs.TotalBadges,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViews,
    pi.CommentCount AS PostComments,
    pi.VoteCount AS PostVotes
FROM 
    UserBadgeStats ubs
LEFT JOIN 
    TopPosts tp ON ubs.DisplayName = tp.OwnerName
LEFT JOIN 
    PostInteractions pi ON tp.PostId = pi.PostId
ORDER BY 
    ubs.TotalBadges DESC, tp.Score DESC;
