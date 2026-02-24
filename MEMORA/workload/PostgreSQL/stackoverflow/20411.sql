
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.ViewCount,
        COALESCE(NULLIF(UPPER(p.Tags), ''), 'No Tags') AS NormalizedTags, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Tags
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId AS EditorUserId,
        ph.Comment,
        STRING_AGG(COALESCE(pht.Name, 'Unknown'), ', ') AS HistoryTypeNames
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId, ph.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.HistoryTypeNames,
    ph.HistoryDate,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosePostCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenPostCount
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank = 1
    AND rp.ViewCount > 10
    AND u.Reputation BETWEEN 100 AND 1000
    AND (ph.PostHistoryTypeId IS NULL OR ph.HistoryDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.CommentCount, u.DisplayName, u.Reputation, ph.HistoryTypeNames, ph.HistoryDate
ORDER BY 
    rp.Score DESC, u.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
