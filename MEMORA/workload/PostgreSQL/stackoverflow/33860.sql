
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS RankReputation
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(v.VoteTypeId) AS AverageVoteType,
        MAX(p.CreationDate) AS LatestActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.VoteCount,
        ps.AverageVoteType,
        ps.LatestActivity,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC, ps.CommentCount DESC) AS PostRank
    FROM 
        PostStatistics ps
),
ConsolidatedData AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        pp.Title,
        pp.CommentCount,
        pp.VoteCount,
        pp.LatestActivity,
        tu.RankReputation
    FROM 
        RankedUsers tu
    JOIN 
        Users u ON u.Id = tu.UserId
    LEFT JOIN 
        TopPosts pp ON pp.PostRank <= 10 AND pp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
)
SELECT 
    cd.DisplayName,
    cd.Reputation,
    cd.Title,
    cd.CommentCount,
    cd.VoteCount,
    cd.LatestActivity,
    CASE 
        WHEN cd.RankReputation IS NULL THEN 'Not Ranked'
        ELSE CONCAT(cd.RankReputation, 'th')
    END AS ReputationRank
FROM 
    ConsolidatedData cd
WHERE 
    cd.Reputation > 1000
ORDER BY 
    cd.Reputation DESC, 
    cd.VoteCount DESC;
