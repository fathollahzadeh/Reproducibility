WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Votes v 
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    au.DisplayName,
    au.Reputation,
    p.Title,
    p.ViewCount,
    COALESCE(pv.UpvoteCount, 0) AS Upvotes,
    COALESCE(pv.DownvoteCount, 0) AS Downvotes,
    CASE 
        WHEN au.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Active Contributor'
    END AS ContributorType,
    CASE 
        WHEN r.RecentRank = 1 THEN 'Most Recent Post'
        ELSE 'Previous Post'
    END AS PostRecency
FROM 
    ActiveUsers au
JOIN 
    RecentPosts r ON au.UserId = r.OwnerUserId
JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    PostVoteStats pv ON p.Id = pv.PostId
WHERE 
    (p.ViewCount > 100 OR pv.UpvoteCount > 10)
ORDER BY 
    au.Reputation DESC, 
    p.ViewCount DESC;