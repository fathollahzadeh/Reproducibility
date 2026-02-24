WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS GlobalPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount,
        rp.CommentCount,
        rp.Score,
        rp.OwnerPostRank,
        rp.GlobalPostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
)
SELECT 
    cs.*,
    CASE 
        WHEN cs.Score > 10 THEN 'High Score'
        WHEN cs.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = cs.OwnerPostRank AND p2.Score > cs.Score) AS HigherScoreCount
FROM 
    CombinedStats cs
WHERE 
    cs.OwnerPostRank = 1
ORDER BY 
    cs.GlobalPostRank, cs.Score DESC
LIMIT 10;