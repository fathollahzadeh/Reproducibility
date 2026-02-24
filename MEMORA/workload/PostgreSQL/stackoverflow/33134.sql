WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = rp.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON b.UserId = rp.OwnerUserId
    WHERE 
        rp.PostRank <= 5
),
AggregatedData AS (
    SELECT 
        pe.OwnerName,
        SUM(pe.Score) AS TotalScore,
        SUM(pe.ViewCount) AS TotalViews,
        AVG(pe.CommentCount) AS AverageComments,
        SUM(pe.BadgeCount) AS TotalBadges
    FROM 
        PostEngagement pe
    GROUP BY 
        pe.OwnerName
)
SELECT 
    ad.OwnerName,
    ad.TotalScore,
    ad.TotalViews,
    ad.AverageComments,
    ad.TotalBadges,
    CASE 
        WHEN ad.TotalScore IS NULL THEN 'No Score'
        WHEN ad.TotalScore > 100 THEN 'Expert Contributor'
        ELSE 'Novice Contributor'
    END AS ContributorLevel
FROM 
    AggregatedData ad
WHERE 
    ad.TotalViews > 100
ORDER BY 
    ad.TotalScore DESC
LIMIT 10;