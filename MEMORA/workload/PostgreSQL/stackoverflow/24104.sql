WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes v
        JOIN 
            Posts p ON v.PostId = p.Id
        JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        WHERE 
            v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
        GROUP BY 
            p.Id
    ) v ON rp.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        WHERE 
            Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.PostRank <= 5
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
        AND pht.Id IN (10, 11, 12) 
    GROUP BY 
        ph.PostId
),
FinalMetrics AS (
    SELECT 
        pm.*,
        COALESCE(phc.HistoryCount, 0) AS HistoryCount
    FROM 
        PostMetrics pm
    LEFT JOIN PostHistoryCounts phc ON pm.PostId = phc.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.ViewCount,
    f.Score,
    f.UpVotes,
    f.DownVotes,
    f.BadgeCount,
    f.HistoryCount,
    CASE 
        WHEN f.HistoryCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    FinalMetrics f
WHERE 
    f.UpVotes > f.DownVotes
ORDER BY 
    f.Score DESC, f.ViewCount DESC;