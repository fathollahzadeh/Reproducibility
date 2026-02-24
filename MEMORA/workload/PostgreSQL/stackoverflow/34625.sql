
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserRanks AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        u.DisplayName,
        ur.TotalBadges,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        UserRanks ur
    INNER JOIN 
        Users u ON ur.UserId = u.Id
    WHERE 
        ur.TotalBadges > 0
),
PostHistoryEntries AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditDate,
        pt.Name AS PostHistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        au.DisplayName AS UserDisplayName,
        au.TotalBadges,
        ph.EditorId,
        ph.EditDate,
        ph.PostHistoryType
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers au ON rp.OwnerUserId = au.UserId
    LEFT JOIN 
        PostHistoryEntries ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn <= 3
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.UserDisplayName,
    fr.TotalBadges,
    fr.EditorId,
    fr.EditDate,
    fr.PostHistoryType
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
