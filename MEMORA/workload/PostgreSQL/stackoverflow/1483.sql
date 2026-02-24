
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    ur.DisplayName AS AuthorDisplayName,
    ur.Reputation AS AuthorReputation,
    COALESCE(phs.CloseReopenCount, 0) AS CloseReopenCount,
    AGE(TIMESTAMP '2024-10-01 12:34:56', phs.FirstEditDate) AS DurationSinceFirstEdit,
    CASE 
        WHEN phs.LastEditDate IS NULL THEN 'No Edits'
        ELSE CONCAT('Edited ', EXTRACT(DAY FROM AGE(TIMESTAMP '2024-10-01 12:34:56', phs.LastEditDate)), ' days ago')
    END AS EditStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100
OFFSET 0;
