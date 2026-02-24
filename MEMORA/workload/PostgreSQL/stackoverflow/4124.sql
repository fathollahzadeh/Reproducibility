
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC, ps.CommentCount DESC) AS PostRank
    FROM 
        PostStats ps
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.PostId IN (SELECT p.AcceptedAnswerId FROM Posts p WHERE p.AcceptedAnswerId IS NOT NULL) 
        THEN 'Accepted'
        ELSE 'Not Accepted' 
    END AS AcceptanceStatus,
    CASE 
        WHEN rp.UpVotes IS NULL THEN 'No Votes'
        ELSE 'Has Votes' 
    END AS VoteStatus
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1 
    AND (rp.Score > 5 OR rp.ViewCount > 100)
ORDER BY 
    rp.PostRank, rp.ViewCount DESC
LIMIT 10;
