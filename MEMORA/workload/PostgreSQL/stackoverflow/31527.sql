WITH RecursiveVoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        PostId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        RecursiveVoteCounts rv ON p.Id = rv.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
)
SELECT 
    rp.Title,
    rp.RecentVoteCount,
    ur.Reputation,
    ur.ReputationRank,
    CASE 
        WHEN rp.RecentVoteCount = 0 THEN 'No Votes Yet'
        WHEN rp.RecentVoteCount > 10 THEN 'Popular Post'
        ELSE 'Moderately Active'
    END AS ActivityStatus
FROM 
    RecentPosts rp
INNER JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.RecentVoteCount > 0
ORDER BY 
    ur.Reputation DESC, 
    rp.RecentVoteCount DESC
LIMIT 20;