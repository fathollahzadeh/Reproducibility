WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PostVotingStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    (rp.Score * 1.0 / NULLIF(rp.ViewCount, 0)) AS ScorePerView,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreSentiment,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE 'Score Available'
    END AS ScoreAvailability
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostVotingStats pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC;