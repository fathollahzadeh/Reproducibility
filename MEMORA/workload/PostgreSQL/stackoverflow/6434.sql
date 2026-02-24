WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
RankedPosts AS (
    SELECT 
        ps.*, 
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PopularityRank
    FROM 
        PostStatistics ps
)
SELECT 
    r.PostId, 
    r.Title, 
    r.CreationDate, 
    r.ViewCount, 
    r.Score, 
    r.UpVotes, 
    r.DownVotes, 
    r.CommentCount, 
    r.EditCount, 
    r.PopularityRank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    RankedPosts r
JOIN 
    Users u ON r.PostId = u.Id
WHERE 
    r.PopularityRank <= 10 
ORDER BY 
    r.PopularityRank;