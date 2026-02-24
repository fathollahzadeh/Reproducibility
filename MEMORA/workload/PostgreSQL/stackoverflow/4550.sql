WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.UserId,
        us.DisplayName,
        us.TotalBounty,
        us.BadgeCount,
        PHD.HistoryDate,
        PHD.Comment
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostId = us.UserId
    LEFT JOIN 
        PostHistoryDetails PHD ON rp.PostId = PHD.PostId
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    tgt.*,
    CASE 
        WHEN tgt.HistoryDate IS NOT NULL THEN 'Edited'
        ELSE 'New'
    END AS PostStatus,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tgt
LEFT JOIN 
    Tags t ON tgt.PostId = t.ExcerptPostId
GROUP BY 
    tgt.PostId, tgt.Title, tgt.Score, tgt.ViewCount, tgt.UserId, tgt.DisplayName, tgt.TotalBounty, tgt.BadgeCount, tgt.HistoryDate, tgt.Comment
ORDER BY 
    tgt.Score DESC, tgt.ViewCount DESC;