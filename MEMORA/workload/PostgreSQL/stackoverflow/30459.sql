
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentsScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

RecentVotes AS (
    SELECT 
        v.UserId AS VoterId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalQuestions,
    ua.TotalScore,
    ra.PostId,
    ra.Title,
    ra.Score,
    ra.ScoreRank,
    ra.TotalPosts,
    rv.VoteCount,
    rv.UpVotes,
    rv.DownVotes
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts ra ON ua.UserId = ra.PostId
LEFT JOIN 
    RecentVotes rv ON ua.UserId = rv.VoterId
WHERE 
    ua.Reputation > 1000 
    AND (COALESCE(rv.UpVotes, 0) - COALESCE(rv.DownVotes, 0)) > 5 
ORDER BY 
    ua.Reputation DESC, 
    ra.Score DESC;
