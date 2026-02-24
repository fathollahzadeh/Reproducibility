
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ph.Comment, 'No history') AS PostHistory,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByOwner
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND (p.Score > 10 OR (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 5)
),
TopUsers AS (
    SELECT 
        uvs.DisplayName,
        uvs.Reputation,
        RANK() OVER (ORDER BY uvs.TotalVotes DESC) AS VoteRank
    FROM 
        UserVoteStats uvs
    WHERE 
        uvs.TotalVotes > 5
)

SELECT 
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.CommentCount,
    tu.DisplayName AS TopVoter,
    tu.Reputation AS VoterReputation
FROM 
    PostAnalytics pa
JOIN 
    TopUsers tu ON tu.VoteRank <= 5
WHERE 
    pa.RankByOwner = 1
ORDER BY 
    pa.Score DESC, pa.CommentCount DESC
LIMIT 10;
