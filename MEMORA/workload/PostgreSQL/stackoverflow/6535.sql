
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS NumberOfPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
        AND u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
), RankedEngagement AS (
    SELECT 
        UserId,
        DisplayName,
        NumberOfPosts,
        Questions,
        Answers,
        TotalViews,
        UpVotes,
        DownVotes,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC, UpVotes - DownVotes DESC) AS EngagementRank
    FROM 
        UserEngagement
)
SELECT 
    re.UserId,
    re.DisplayName,
    re.NumberOfPosts,
    re.Questions,
    re.Answers,
    re.TotalViews,
    re.UpVotes,
    re.DownVotes,
    re.AverageScore,
    CASE 
        WHEN re.EngagementRank <= 10 THEN 'Top Contributor'
        WHEN re.EngagementRank <= 50 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS EngagementLevel
FROM 
    RankedEngagement re
WHERE 
    re.EngagementRank <= 100
ORDER BY 
    re.EngagementRank;
