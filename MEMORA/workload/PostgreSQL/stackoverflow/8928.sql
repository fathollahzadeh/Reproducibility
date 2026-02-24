
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
),
PostStatistics AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        COALESCE(AVG(vote.UserVoteCount), 0) AS AverageVotes
    FROM 
        TopQuestions tq
    LEFT JOIN 
        Comments c ON tq.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            v.PostId,
            COUNT(*) AS UserVoteCount
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ) vote ON tq.PostId = vote.PostId
    GROUP BY 
        tq.PostId, tq.Title, tq.OwnerDisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.TotalComments,
    ps.AverageVotes,
    COUNT(ph.Id) AS HistoricalEdits
FROM 
    PostStatistics ps
LEFT JOIN 
    PostHistory ph ON ps.PostId = ph.PostId
WHERE 
    ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
GROUP BY 
    ps.PostId, ps.Title, ps.OwnerDisplayName, ps.TotalComments, ps.AverageVotes
ORDER BY 
    ps.AverageVotes DESC, ps.TotalComments DESC;
