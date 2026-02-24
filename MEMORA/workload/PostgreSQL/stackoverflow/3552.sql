
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COALESCE(p.Score, 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.Score, 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Score, p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEdited
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.Score,
    rp.CommentCount,
    ph.EditCount,
    ph.LastEdited,
    tu.DisplayName AS TopVoter,
    tu.NetVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
LEFT JOIN 
    (SELECT UserId, DisplayName, NetVotes FROM TopUsers ORDER BY NetVotes DESC LIMIT 1) tu ON 1=1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;
