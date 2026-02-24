WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM Posts p
    WHERE p.Score IS NOT NULL AND p.ViewCount IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  
),
PostWithLatestComment AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        (SELECT COALESCE(MAX(c.CreationDate), '1970-01-01') 
         FROM Comments c WHERE c.PostId = p.Id) AS LatestCommentDate
    FROM Posts p
    WHERE p.ViewCount > 1000
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.TotalPosts,
        COALESCE(cl.CloseRank, 0) AS IsClosed,
        ul.AvgReputation,
        ul.BadgeCount
    FROM RankedPosts rp
    LEFT JOIN ClosedPostHistory cl ON rp.PostId = cl.PostId
    JOIN UserReputation ul ON rp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE rp.rn <= 10  
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.ViewCount,
    t.CreationDate,
    t.IsClosed,
    ROUND(t.AvgReputation, 2) AS AvgUserReputation,
    t.BadgeCount,
    'Post Type: ' || (SELECT pt.Name FROM PostTypes pt WHERE pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = t.PostId)) AS PostType,
    STRING_AGG(DISTINCT CASE WHEN t.IsClosed > 0 THEN 'Closed' ELSE 'Open' END, ', ') AS Status
FROM TopPosts t
GROUP BY t.PostId, t.Title, t.Score, t.ViewCount, t.CreationDate, t.IsClosed, t.AvgReputation, t.BadgeCount
ORDER BY t.Score DESC, t.ViewCount DESC;