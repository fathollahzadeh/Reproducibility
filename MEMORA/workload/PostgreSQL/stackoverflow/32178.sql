WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    COALESCE((SELECT COUNT(v.Id)
              FROM Votes v 
              WHERE v.PostId = rp.PostId 
                AND v.VoteTypeId IN (2, 3, 4) 
             ), 0) AS VoteCount,
    (SELECT STRING_AGG(DISTINCT pht.Name, ', ') 
     FROM PostHistory ph
     JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
     WHERE ph.PostId = rp.PostId) AS PostHistoryActions,
    COALESCE(rph.UserDisplayName, 'No recent edits') AS LastEditor,
    COALESCE(rph.Comment, 'N/A') AS LastEditReason
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC;