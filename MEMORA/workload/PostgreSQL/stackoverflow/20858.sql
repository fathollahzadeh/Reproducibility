WITH HistoricalEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
RecentActors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
TopBadgers AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(*) > 5
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(he.EditRank, 0) AS EditCount,
        COALESCE(ra.PostCount, 0) AS RecentPostCount,
        COALESCE(tb.BadgeCount, 0) AS BadgeCount,
        COALESCE(ra.UpVotes, 0) AS UpVotes,
        COALESCE(ra.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        HistoricalEdits he ON p.Id = he.PostId
    LEFT JOIN 
        RecentActors ra ON p.OwnerUserId = ra.UserId
    LEFT JOIN 
        TopBadgers tb ON p.OwnerUserId = tb.UserId
)
SELECT 
    ps.PostId,
    ps.EditCount,
    ps.RecentPostCount,
    ps.BadgeCount,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive Impact'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative Impact'
        ELSE 'Neutral Impact' 
    END AS VoteImpact,
    CASE 
        WHEN ps.EditCount = 0 THEN 'No Edits Made'
        WHEN ps.EditCount BETWEEN 1 AND 3 THEN 'Few Edits'
        ELSE 'Many Edits' 
    END AS EditFrequency
FROM 
    PostStatistics ps
WHERE 
    ps.EditCount IS NOT NULL
ORDER BY 
    ps.EditCount DESC, ps.RecentPostCount DESC 
LIMIT 100 OFFSET 20;