
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.ScoreRank = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.OwnerDisplayName
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.CreationDate,
    tpd.Score,
    tpd.OwnerDisplayName,
    tpd.CommentCount,
    tpd.UpVoteCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tpd.PostId)) AS BadgeCount
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, 
    tpd.CommentCount DESC
LIMIT 10;
