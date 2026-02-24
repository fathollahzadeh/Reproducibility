WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

PostSummaries AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(CAST(NULLIF(rp.ViewCount, 0) AS FLOAT) / NULLIF(SUM(rp.ViewCount) OVER (), 0), 0) AS PercentageOfTotalViews,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore,
        CASE 
            WHEN COUNT(c.Id) > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.rn <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

FinalAnalytics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.PercentageOfTotalViews,
        ps.UpvoteCount,
        ps.AvgCommentScore,
        ps.CommentStatus,
        COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadgeCount,
        COALESCE(ub.SilverBadges, 0) AS SilverBadgeCount,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadgeCount
    FROM 
        PostSummaries ps
    LEFT JOIN 
        Users u ON u.Id = ps.PostId 
    LEFT JOIN 
        UserBadges ub ON ub.UserId = u.Id
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    PercentageOfTotalViews,
    UpvoteCount,
    AvgCommentScore,
    CommentStatus,
    UserBadges,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM 
    FinalAnalytics
WHERE 
    Score > 10 OR AvgCommentScore > 5
ORDER BY 
    CreationDate DESC, Score DESC
LIMIT 50;