
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    pu.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.Id) AS PostsCount,
    SUM(COALESCE(pvs.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(pvs.DownVotes, 0)) AS TotalDownVotes,
    AVG(COALESCE(rp.Score, 0)) AS AveragePostScore,
    MAX(rp.CreationDate) AS LastPostDate
FROM 
    TopUsers pu
LEFT JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
WHERE 
    pu.UserRank <= 10
GROUP BY 
    pu.DisplayName
ORDER BY 
    TotalUpVotes DESC, AveragePostScore DESC;
