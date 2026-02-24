WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS DownVotes   
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.ViewCount
),
PostRanking AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.Score + ps.TotalCommentScore AS TotalScore,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.Score DESC, ps.ViewCount DESC) AS UserPostRank
    FROM 
        PostStatistics ps
)
SELECT 
    u.DisplayName,
    u.Reputation,
    uvs.TotalVotes,
    COALESCE(SUM(pr.TotalScore), 0) AS TotalPostScore,
    COALESCE(AVG(pr.UserPostRank), NULL) AS AveragePostRank,
    COALESCE(MAX(pr.UserPostRank), 0) AS HighestPostRank
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary uvs ON u.Id = uvs.UserId
LEFT JOIN 
    PostRanking pr ON u.Id = pr.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation, uvs.TotalVotes
HAVING 
    COALESCE(SUM(pr.TotalScore), 0) > 50 AND 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    u.Reputation DESC NULLS LAST,
    uvs.TotalVotes DESC;