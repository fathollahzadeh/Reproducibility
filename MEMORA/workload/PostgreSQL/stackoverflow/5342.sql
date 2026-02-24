WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
FinalResults AS (
    SELECT 
        tp.OwnerDisplayName,
        tp.PostCount,
        tp.AvgScore,
        tp.TotalViews,
        ub.BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserBadges ub ON tp.OwnerDisplayName = ub.DisplayName
)
SELECT 
    OwnerDisplayName,
    PostCount,
    AvgScore,
    TotalViews,
    COALESCE(BadgeCount, 0) AS BadgeCount
FROM 
    FinalResults
ORDER BY 
    TotalViews DESC, AvgScore DESC, PostCount DESC;
