
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankWithinType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > DATE '2024-10-01' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    COUNT(DISTINCT p.Id) AS PostsContributed,
    COALESCE(SUM(rp.Score), 0) AS TotalScoreFromPosts,
    COALESCE(SUM(ue.TotalVotes), 0) AS UserTotalVotes,
    CASE 
        WHEN up.Reputation > 1000 THEN 'High Reputation User'
        WHEN up.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User' 
    END AS ReputationCategory,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.UserId = up.Id AND c.CreationDate > DATE '2024-10-01' - INTERVAL '30 days'
    ) AS RecentCommentsCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN Tags t ON t.ExcerptPostId = p.Id 
     WHERE p.OwnerUserId = up.Id) AS TagList
FROM 
    Users up
LEFT JOIN 
    Posts p ON up.Id = p.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
LEFT JOIN 
    UserEngagement ue ON up.Id = ue.UserId
WHERE 
    up.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    AND (up.Location IS NOT NULL OR up.AboutMe IS NOT NULL)
GROUP BY 
    up.Id, up.DisplayName, up.Reputation
ORDER BY 
    TotalScoreFromPosts DESC, PostsContributed DESC
LIMIT 100
OFFSET 0;
