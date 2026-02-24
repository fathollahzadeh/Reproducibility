
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS LatestPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS VotedPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT v.PostId) > 10
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes cr ON ph.Comment::integer = cr.Id 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top 5 ' || pt.Name
        ELSE 'Other ' || pt.Name
    END AS PostCategory,
    tu.DisplayName AS TopVoter,
    tu.VotedPosts AS VoterCount,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasonDetails
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
LEFT JOIN 
    TopUsers tu ON rp.PostId IN (SELECT v.PostId FROM Votes v WHERE v.UserId = tu.UserId)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.LatestPosts <= 10
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
