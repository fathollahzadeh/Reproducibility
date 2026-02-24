
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN p.Score IS NULL THEN 1 ELSE 0 END) AS NullScorePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        PositivePosts,
        NegativePosts,
        NullScorePosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Ranking
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
RecentPostVotes AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.OwnerUserId, v.VoteTypeId
),
PostEngagements AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount,
        SUM(COALESCE(rv.VoteCount, 0)) AS RecentVoteCount,
        p.OwnerUserId,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        RecentPostVotes rv ON p.Id = rv.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
FinalReport AS (
    SELECT 
        u.DisplayName AS UserName,
        COUNT(DISTINCT pe.PostId) AS TotalEngagedPosts,
        SUM(pe.CommentCount) AS TotalComments,
        SUM(pe.RelatedPostsCount) AS TotalRelatedPosts,
        SUM(pe.RecentVoteCount) AS TotalRecentVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(pe.RecentVoteCount) DESC) AS VoteRanking
    FROM 
        Users u
    JOIN 
        PostEngagements pe ON u.Id = pe.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fu.UserName,
    fu.TotalEngagedPosts,
    fu.TotalComments,
    fu.TotalRelatedPosts,
    fu.TotalRecentVotes,
    CASE 
        WHEN fu.TotalRecentVotes > 10 THEN 'Highly Engaged' 
        WHEN fu.TotalRecentVotes BETWEEN 5 AND 10 THEN 'Moderately Engaged' 
        ELSE 'Less Engaged' 
    END AS EngagementLevel
FROM 
    FinalReport fu
WHERE 
    fu.TotalEngagedPosts > 5 
    AND fu.TotalComments IS NOT NULL
ORDER BY 
    fu.TotalRecentVotes DESC, 
    fu.TotalEngagedPosts DESC;
