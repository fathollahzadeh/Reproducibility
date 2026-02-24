
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE((SELECT SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes WHERE PostId = p.Id), 0) AS UpVotes,
        COALESCE((SELECT SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes WHERE PostId = p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
TopPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        ph.FirstEditDate,
        ph.EditCount,
        CASE 
            WHEN ph.EditCount > 3 THEN 'Frequent Edits'
            WHEN ph.EditCount BETWEEN 1 AND 3 THEN 'Infrequent Edits'
            ELSE 'No Edits'
        END AS EditFrequency,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn <= 10 
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.EditFrequency,
    ps.FirstEditDate,
    ROUND(CAST(ps.Score AS DECIMAL) / NULLIF(ps.EditCount, 0), 2) AS ScorePerEdit,
    CASE
        WHEN ps.FirstEditDate IS NULL THEN 'Never Edited'
        ELSE 'Edited'
    END AS EditStatus
FROM 
    TopPostStats ps
WHERE 
    ps.NetVotes >= 5 AND 
    (ps.EditFrequency = 'Frequent Edits' OR ps.EditFrequency = 'No Edits') 
ORDER BY 
    ps.Score DESC,
    ps.CreationDate DESC;
