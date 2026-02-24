WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
EligibleBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        eb.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        EligibleBadges eb ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = eb.UserId)
    WHERE 
        rp.RankScore <= 5 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
Analysis AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerDisplayName,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.BadgeCount,
        cp.CloseDate,
        cp.CloseReason
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        ClosedPosts cp ON fp.PostId = cp.PostId
)
SELECT 
    *,
    COALESCE(CAST(CASE 
        WHEN BadgeCount > 10 THEN 'Expert' 
        WHEN BadgeCount BETWEEN 5 AND 10 THEN 'Intermediate' 
        ELSE 'Beginner' 
    END AS VARCHAR), 'No Badges') AS UserExpertise,
    CASE 
        WHEN CloseReason IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed
FROM 
    Analysis
WHERE 
    Score > 10
ORDER BY 
    CreationDate DESC;