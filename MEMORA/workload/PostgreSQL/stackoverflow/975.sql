
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Title,
        p.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.Title, p.Tags
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.Score,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.Score DESC) AS PostRank
    FROM 
        RecentPosts rp
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.PostId,
    ps.Score,
    ps.PostSentiment,
    CASE 
        WHEN ps.PostRank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostType
FROM 
    RankedUsers u
JOIN 
    PostStatistics ps ON u.UserId = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    ps.Score DESC;
