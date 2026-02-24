WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END), 0) AS TotalScores,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalViews,
    us.TotalScores,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score AS PostScore,
    pp.ViewCount AS PostViewCount,
    rv.VoteCount AS RecentVoteCount,
    rv.UpVotes,
    rv.DownVotes
FROM 
    UserStats us
LEFT JOIN 
    PopularPosts pp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
LEFT JOIN 
    RecentVotes rv ON pp.PostId = rv.PostId
WHERE 
    us.UserRank <= 100
ORDER BY 
    us.Reputation DESC, pp.Score DESC
OFFSET 10 LIMIT 20;