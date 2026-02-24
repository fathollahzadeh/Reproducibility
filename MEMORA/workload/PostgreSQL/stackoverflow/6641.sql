
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC, ps.CommentCount DESC) AS ScoreRank,
        RANK() OVER (ORDER BY ps.VoteCount DESC, ps.AvgUserReputation DESC) AS VoteRank
    FROM 
        PostStats ps
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    rp.AvgUserReputation,
    rp.ScoreRank,
    rp.VoteRank
FROM 
    RankedPosts rp
WHERE 
    rp.ScoreRank <= 10 AND rp.VoteRank <= 10
ORDER BY 
    rp.Score DESC, rp.VoteCount DESC;
