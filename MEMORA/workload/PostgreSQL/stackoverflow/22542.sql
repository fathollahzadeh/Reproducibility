
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
        AND 
        ph.Comment IS NOT NULL
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    us.UserId,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    MAX(ph.PostHistoryTypeId) AS MostRecentEditTypeId,
    MIN(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10) AS FirstCloseDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStats us ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    us.BadgeCount > 0
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, us.UserId, us.UpVotes, us.DownVotes, us.BadgeCount
HAVING 
    COALESCE(AVG(rp.ViewCount), 0) > 50
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
