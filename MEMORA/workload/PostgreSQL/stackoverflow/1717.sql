
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId), 0) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        CASE 
            WHEN rp.UpVotes - rp.DownVotes > 0 THEN 'Positive'
            WHEN rp.UpVotes - rp.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteTrend,
        LEAD(rp.CreationDate) OVER (ORDER BY rp.CreationDate) AS NextPostDate
    FROM 
        RecentPosts rp
),
MergedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.NetVotes,
        ps.VoteTrend,
        ps.NextPostDate,
        CASE 
            WHEN ps.NextPostDate IS NOT NULL AND ps.NextPostDate - ps.CreationDate < INTERVAL '1 day' THEN 'Merged'
            ELSE 'Standalone'
        END AS PostType
    FROM 
        PostSummary ps
)
SELECT 
    mp.PostId,
    mp.Title,
    mp.CreationDate,
    mp.ViewCount,
    mp.NetVotes,
    mp.VoteTrend,
    mp.PostType,
    CASE 
        WHEN mp.NetVotes > 10 THEN 'Highly Engaged'
        WHEN mp.NetVotes BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    MergedPosts mp
WHERE 
    mp.ViewCount > 100
ORDER BY 
    mp.NetVotes DESC,
    mp.CreationDate DESC
LIMIT 50;
