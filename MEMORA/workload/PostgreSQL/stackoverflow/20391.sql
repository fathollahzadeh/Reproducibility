WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pr.CloseReason,
        pr.CloseDate,
        ut.BadgeCount,
        ut.GoldBadges
    FROM 
        RankedPosts pp
    LEFT JOIN 
        PostClosureReasons pr ON pp.PostId = pr.PostId
    LEFT JOIN 
        UserBadges ut ON pp.PostId = ut.UserId
    WHERE 
        pp.Rank <= 10 
        AND (pr.CloseReason IS NOT NULL OR pp.ViewCount > 100)
),
FinalResults AS (
    SELECT 
        f.Title,
        f.Score,
        f.ViewCount,
        COALESCE(f.CloseReason, 'No Closure Reason') AS Closured,
        COALESCE(f.BadgeCount, 0) AS TotalBadges,
        COALESCE(f.GoldBadges, 0) AS TotalGoldBadges,
        CASE WHEN f.ViewCount > 500 THEN 'High Interest' ELSE 'Regular Interest' END AS InterestLevel
    FROM 
        FilteredPosts f
)
SELECT 
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.Closured,
    fr.TotalBadges,
    fr.TotalGoldBadges,
    fr.InterestLevel,
    string_agg(tt.TagName, ', ') AS AssociatedTags
FROM 
    FinalResults fr
LEFT JOIN 
    TopTags tt ON fr.Title LIKE '%' || tt.TagName || '%'
GROUP BY 
    fr.Title, fr.Score, fr.ViewCount, fr.Closured, fr.TotalBadges, fr.TotalGoldBadges, fr.InterestLevel
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;