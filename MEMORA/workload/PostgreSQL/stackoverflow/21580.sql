WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY u.CreationDate) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
AverageScores AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount  
    FROM 
        Posts p
    LEFT JOIN (SELECT 
                 PostId,
                 SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                 SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
                 SUM(CASE WHEN VoteTypeId = 5 THEN 1 ELSE 0 END) AS FavoriteCount
                FROM Votes 
                GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN (SELECT 
                 PostId,
                 COUNT(*) AS CommentCount 
                FROM Comments 
                GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    up.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.PostId) AS QuestionCount,
    MAX(uh.Reputation) AS MaxReputation,
    AVG(pm.AvgScore) AS AvgPostScore,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    COUNT(DISTINCT pt.Id) FILTER (WHERE pt.Id IS NOT NULL) AS DistinctPostTypeCount,
    CASE 
        WHEN MAX(uh.Reputation) IS NULL THEN 'No Reputation'
        ELSE 'Has Reputation'
    END AS ReputationStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserReputationHistory uh ON uh.UserId = up.Id
LEFT JOIN 
    AverageScores pm ON pm.OwnerUserId = up.Id
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostTypes pt ON rp.PostId = pt.Id
GROUP BY 
    up.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    MaxReputation DESC, QuestionCount DESC;