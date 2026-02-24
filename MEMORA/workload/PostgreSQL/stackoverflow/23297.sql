
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ' ORDER BY c.Id) AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        ps.CommentCount,
        ps.Comments,
        rp.Score,
        us.TotalBountySpent,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostComments ps ON rp.PostId = ps.PostId
    LEFT JOIN 
        UserStatistics us ON u.Id = us.UserId
    WHERE 
        rp.RecentRank = 1 AND 
        (rp.Score > 5 OR us.Reputation > 100)
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.CommentCount,
    COALESCE(fp.Comments, 'No comments') AS CommentSummary,
    fp.Score,
    CONCAT(fp.GoldBadges, ' Gold, ', fp.SilverBadges, ' Silver, ', fp.BronzeBadges, ' Bronze') AS BadgeSummary,
    CASE 
        WHEN fp.TotalBountySpent > 100 THEN 'High Spender'
        WHEN fp.TotalBountySpent BETWEEN 50 AND 100 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS SpendingCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC
LIMIT 50 OFFSET 0;
