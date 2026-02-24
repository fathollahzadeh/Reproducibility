
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(rp.Score), 0) AS UserPostScore,
        COUNT(rp.PostId) AS PostCount,
        AVG(CASE WHEN rp.UserPostRank = 1 THEN rp.Score END) AS AvgTopPostScore
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views
), 
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.Views,
        ue.UserPostScore,
        ue.PostCount,
        ue.AvgTopPostScore,
        RANK() OVER (ORDER BY ue.UserPostScore DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.Views,
    tu.UserPostScore,
    tu.PostCount,
    tu.AvgTopPostScore,
    CASE 
        WHEN tu.EngagementRank <= 10 THEN 'Top Engager'
        WHEN tu.EngagementRank <= 20 THEN 'Moderate Engager'
        ELSE 'New Engager'
    END AS EngagementLevel
FROM 
    TopEngagedUsers tu
WHERE 
    tu.UserPostScore > 0
ORDER BY 
    tu.UserPostScore DESC;
