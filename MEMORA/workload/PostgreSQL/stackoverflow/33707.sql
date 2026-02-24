WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score
),
UserBadges AS (
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
),
TopPosts AS (
    SELECT 
        rp.*,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        RANK() OVER (ORDER BY rp.Score DESC) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.ViewCount > 100 AND rp.Rank <= 10
),
RecentActivity AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastActivityDate
    FROM 
        Comments
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        PostId
),
PostAdditionalInfo AS (
    SELECT 
        tp.*,
        ra.LastActivityDate,
        CASE 
            WHEN ra.LastActivityDate IS NOT NULL THEN 'Active' 
            ELSE 'Inactive' 
        END AS PostStatus
    FROM 
        TopPosts tp
    LEFT JOIN 
        RecentActivity ra ON tp.PostId = ra.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.BadgeCount,
    p.GoldBadges,
    p.SilverBadges,
    p.BronzeBadges,
    p.LastActivityDate,
    p.PostStatus
FROM 
    PostAdditionalInfo p
ORDER BY 
    p.OverallRank, p.Score DESC;