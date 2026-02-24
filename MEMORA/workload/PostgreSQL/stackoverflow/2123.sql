
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostLinkCount AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(pl.LinkCount, 0) AS LinkCount,
        COALESCE(us.TotalQuestions, 0) AS UserQuestions,
        COALESCE(us.GoldBadges, 0) AS GoldBadges,
        COALESCE(us.SilverBadges, 0) AS SilverBadges,
        COALESCE(us.BronzeBadges, 0) AS BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostLinkCount pl ON rp.PostId = pl.PostId
    WHERE 
        rp.OwnerRank <= 3
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    COALESCE(fp.Score, 0) AS TotalScore,
    COALESCE(fp.LinkCount, 0) AS TotalLinks,
    fp.ViewCount,
    fp.AnswerCount,
    CASE 
        WHEN fp.GoldBadges > 0 THEN 'Gold Member'
        WHEN fp.SilverBadges > 0 THEN 'Silver Member'
        WHEN fp.BronzeBadges > 0 THEN 'Bronze Member'
        ELSE 'New Member' 
    END AS MembershipStatus,
    CONCAT('User has earned ', COALESCE(fp.GoldBadges, 0), ' Gold, ', COALESCE(fp.SilverBadges, 0), ' Silver, and ', COALESCE(fp.BronzeBadges, 0), ' Bronze badges.') AS BadgeDetails
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 50;
