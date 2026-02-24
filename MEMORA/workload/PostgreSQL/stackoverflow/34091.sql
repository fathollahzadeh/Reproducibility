WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        uc.UpVotes,
        uc.DownVotes,
        uc.TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        UserVoteCounts uc ON u.Id = uc.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostScoreStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Score, p.OwnerUserId
),
UserPostEngagement AS (
    SELECT 
        au.Id AS UserId,
        au.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsEngaged,
        SUM(ps.Score) AS TotalScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        ActiveUsers au
    LEFT JOIN 
        Posts p ON p.OwnerUserId = au.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostScoreStatistics ps ON ps.PostId = p.Id
    GROUP BY 
        au.Id, au.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsEngaged,
        TotalScore,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostEngagement
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    te.PostsEngaged,
    te.TotalScore,
    te.TotalComments,
    CASE 
        WHEN te.ScoreRank <= 10 THEN 'Top Engaged'
        ELSE 'Regular Engaged'
    END AS EngagementLevel
FROM 
    ActiveUsers u
JOIN 
    TopEngagedUsers te ON u.Id = te.UserId
ORDER BY 
    te.TotalScore DESC, te.PostsEngaged DESC;