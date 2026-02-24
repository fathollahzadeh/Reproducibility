
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.OwnerUserId, u.DisplayName
),
FilteredTags AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER(ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    STRING_AGG(DISTINCT ft.TagName, ', ') AS Tags,
    rp.CommentCount,
    rp.VoteCount,
    ur.DisplayName AS TopOwnerUser,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.TotalViews,
    rp.OwnerPostRank
FROM 
    RankedPosts rp
JOIN 
    FilteredTags ft ON rp.Tags LIKE CONCAT('%', ft.TagName, '%')
JOIN 
    UserRankings ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.OwnerPostRank = 1
GROUP BY 
    rp.PostId, rp.Title, rp.CommentCount, rp.VoteCount, ur.DisplayName, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges, ur.TotalViews, rp.OwnerPostRank
ORDER BY 
    rp.VoteCount DESC, rp.CommentCount DESC
LIMIT 50;
