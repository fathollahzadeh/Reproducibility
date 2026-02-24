
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        p.Title,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserId, ph.Comment, p.Title
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.VoteCount,
    ROUND(AVG(ub.BadgeCount)) AS AverageBadges,
    COALESCE(phd.CloseCount, 0) AS TotalCloseReasons,
    COALESCE(phd.ReopenCount, 0) AS TotalReopenReasons,
    rp.Rank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.VoteCount, rp.Rank, phd.CloseCount, phd.ReopenCount
ORDER BY 
    rp.VoteCount DESC, rp.Title ASC;
