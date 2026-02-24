
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        DENSE_RANK() OVER(PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
),
RecentPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.LastActivityDate,
        pa.CommentCount,
        us.DisplayName
    FROM 
        PostActivity pa
    JOIN 
        UserStatistics us ON pa.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = us.UserId)
    WHERE 
        pa.LastActivityDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
AggregatedData AS (
    SELECT 
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        COUNT(rp.PostId) AS RecentPostCount,
        AVG(COALESCE(rp.CommentCount, 0)) AS AvgCommentsPerPost
    FROM 
        UserStatistics us
    LEFT JOIN 
        RecentPosts rp ON us.DisplayName = rp.DisplayName
    GROUP BY 
        us.DisplayName, us.TotalPosts, us.TotalQuestions, us.TotalAnswers
)
SELECT 
    ad.DisplayName,
    ad.TotalPosts,
    ad.TotalQuestions,
    ad.TotalAnswers,
    ad.RecentPostCount,
    ad.AvgCommentsPerPost,
    CASE 
        WHEN ad.TotalPosts > 50 THEN 'Highly Active'
        WHEN ad.TotalPosts BETWEEN 21 AND 50 THEN 'Moderately Active'
        ELSE 'Less Active' 
    END AS ActivityLevel
FROM 
    AggregatedData ad
ORDER BY 
    ad.TotalPosts DESC, ad.TotalQuestions DESC, ad.TotalAnswers DESC;
